;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0
;;;;
;;;; base64.lisp - RFC 4648 Base64 encoding/decoding
;;;;
;;;; Standards: RFC 4648 (Base64 encoding)
;;;; Thread Safety: Yes (pure functions)
;;;; Performance: O(n) where n is input size

(in-package #:cl-base64)

;;; ============================================================================
;;; CONSTANTS
;;; ============================================================================

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar +base64-alphabet+
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    "Standard Base64 alphabet (RFC 4648).")

  (defvar +base64-url-alphabet+
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    "URL-safe Base64 alphabet (RFC 4648 Section 5).")

  (defvar +base64-pad-char+ #\=
    "Base64 padding character."))

;;; Pre-computed decode table for standard alphabet
(defvar *base64-decode-table*
  (let ((table (make-array 128 :element-type '(signed-byte 8) :initial-element -1)))
    (loop for char across +base64-alphabet+
          for index from 0
          do (setf (aref table (char-code char)) index))
    ;; Handle padding character
    (setf (aref table (char-code #\=)) -2)
    table)
  "Decode lookup table for Base64. -1 = invalid, -2 = padding.")

;;; ============================================================================
;;; INTERNAL UTILITIES
;;; ============================================================================

(defun string-to-bytes (string)
  "Convert STRING to UTF-8 byte vector."
  (let* ((len (length string))
         (bytes (make-array len :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0)))
    (loop for char across string
          for code = (char-code char)
          do (cond
               ;; ASCII
               ((< code #x80)
                (vector-push-extend code bytes))
               ;; 2-byte UTF-8
               ((< code #x800)
                (vector-push-extend (logior #xC0 (ash code -6)) bytes)
                (vector-push-extend (logior #x80 (logand code #x3F)) bytes))
               ;; 3-byte UTF-8
               ((< code #x10000)
                (vector-push-extend (logior #xE0 (ash code -12)) bytes)
                (vector-push-extend (logior #x80 (logand (ash code -6) #x3F)) bytes)
                (vector-push-extend (logior #x80 (logand code #x3F)) bytes))
               ;; 4-byte UTF-8
               (t
                (vector-push-extend (logior #xF0 (ash code -18)) bytes)
                (vector-push-extend (logior #x80 (logand (ash code -12) #x3F)) bytes)
                (vector-push-extend (logior #x80 (logand (ash code -6) #x3F)) bytes)
                (vector-push-extend (logior #x80 (logand code #x3F)) bytes))))
    (coerce bytes '(simple-array (unsigned-byte 8) (*)))))

(defun bytes-to-string (bytes)
  "Convert UTF-8 byte vector to string."
  (let ((result (make-array (length bytes) :element-type 'character :adjustable t :fill-pointer 0))
        (i 0)
        (len (length bytes)))
    (loop while (< i len)
          for b = (aref bytes i)
          do (cond
               ;; ASCII
               ((< b #x80)
                (vector-push-extend (code-char b) result)
                (incf i))
               ;; 2-byte UTF-8
               ((and (< b #xE0) (< (+ i 1) len))
                (let ((code (logior (ash (logand b #x1F) 6)
                                   (logand (aref bytes (+ i 1)) #x3F))))
                  (vector-push-extend (code-char code) result))
                (incf i 2))
               ;; 3-byte UTF-8
               ((and (< b #xF0) (< (+ i 2) len))
                (let ((code (logior (ash (logand b #x0F) 12)
                                   (ash (logand (aref bytes (+ i 1)) #x3F) 6)
                                   (logand (aref bytes (+ i 2)) #x3F))))
                  (vector-push-extend (code-char code) result))
                (incf i 3))
               ;; 4-byte UTF-8
               ((< (+ i 3) len)
                (let ((code (logior (ash (logand b #x07) 18)
                                   (ash (logand (aref bytes (+ i 1)) #x3F) 12)
                                   (ash (logand (aref bytes (+ i 2)) #x3F) 6)
                                   (logand (aref bytes (+ i 3)) #x3F))))
                  (vector-push-extend (code-char code) result))
                (incf i 4))
               ;; Invalid - skip
               (t (incf i))))
    (coerce result 'string)))

;;; ============================================================================
;;; ENCODING
;;; ============================================================================

(defun base64-encode (bytes &key (uri nil) (line-length nil) (line-break #.(format nil "~C~C" #\Return #\Linefeed)))
  "Encode BYTES to Base64 string.

PARAMETERS:
  BYTES       - Byte vector (simple-array (unsigned-byte 8))
  URI         - Use URL-safe alphabet (default NIL)
  LINE-LENGTH - Insert line breaks every N chars (default NIL = no breaks)
  LINE-BREAK  - Line break string (default CRLF)

RETURNS:
  String - Base64 encoded string

EXAMPLES:
  (base64-encode #(72 101 108 108 111))  ; => \"SGVsbG8=\""
  (let* ((alphabet (if uri +base64-url-alphabet+ +base64-alphabet+))
         (input-length (length bytes))
         ;; Output is 4/3 of input, rounded up to multiple of 4
         (output-length (* 4 (ceiling input-length 3)))
         (line-break-count (if line-length
                               (floor (1- output-length) line-length)
                               0))
         (total-length (+ output-length (* line-break-count (length line-break))))
         (result (make-string total-length))
         (output-index 0)
         (chars-on-line 0))
    (flet ((emit-char (char)
             (when (and line-length (>= chars-on-line line-length))
               (loop for c across line-break
                     do (setf (char result output-index) c)
                        (incf output-index))
               (setf chars-on-line 0))
             (setf (char result output-index) char)
             (incf output-index)
             (incf chars-on-line)))
      ;; Process 3-byte groups
      (loop for i from 0 below input-length by 3
            for b0 = (aref bytes i)
            for b1 = (if (< (1+ i) input-length) (aref bytes (1+ i)) 0)
            for b2 = (if (< (+ i 2) input-length) (aref bytes (+ i 2)) 0)
            for remaining = (- input-length i)
            do
               ;; First character: bits 7-2 of byte 0
               (emit-char (char alphabet (ash b0 -2)))
               ;; Second character: bits 1-0 of byte 0 + bits 7-4 of byte 1
               (emit-char (char alphabet (logior (ash (logand b0 #x03) 4)
                                                 (ash b1 -4))))
               ;; Third character: bits 3-0 of byte 1 + bits 7-6 of byte 2
               (if (> remaining 1)
                   (emit-char (char alphabet (logior (ash (logand b1 #x0f) 2)
                                                     (ash b2 -6))))
                   (emit-char +base64-pad-char+))
               ;; Fourth character: bits 5-0 of byte 2
               (if (> remaining 2)
                   (emit-char (char alphabet (logand b2 #x3f)))
                   (emit-char +base64-pad-char+))))
    ;; Return possibly shorter string if no padding
    (if uri
        (subseq result 0 output-index)  ; URL-safe often omits padding
        result)))

(defun usb8-array-to-base64-string (array &key (uri nil))
  "Encode byte array to Base64 string (cl-base64 compatible).

PARAMETERS:
  ARRAY - Byte vector
  URI   - Use URL-safe alphabet

RETURNS:
  String - Base64 encoded"
  (base64-encode array :uri uri))

(defun base64-encode-string (string &key (external-format :utf-8))
  "Encode STRING to Base64.

PARAMETERS:
  STRING          - String to encode
  EXTERNAL-FORMAT - Character encoding (default :utf-8)

RETURNS:
  String - Base64 encoded

EXAMPLES:
  (base64-encode-string \"Hello\")  ; => \"SGVsbG8=\""
  (declare (ignore external-format))  ; We always use UTF-8 internally
  (base64-encode (string-to-bytes string)))

(defun string-to-base64-string (string &key (external-format :utf-8))
  "Encode STRING to Base64 (alias for base64-encode-string).

PARAMETERS:
  STRING          - String to encode
  EXTERNAL-FORMAT - Character encoding (default :utf-8)

RETURNS:
  String - Base64 encoded"
  (base64-encode-string string :external-format external-format))

(defun encode-base64-bytes (bytes &key (uri nil))
  "Encode byte array to Base64 string (alias for base64-encode).

PARAMETERS:
  BYTES - Byte vector
  URI   - Use URL-safe alphabet

RETURNS:
  String - Base64 encoded"
  (base64-encode bytes :uri uri))

;;; ============================================================================
;;; DECODING
;;; ============================================================================

(defun base64-char-value (char)
  "Get numeric value for Base64 character.

PARAMETERS:
  CHAR - Base64 character

RETURNS:
  Integer 0-63 or 0 for padding"
  (let ((code (char-code char)))
    (cond
      ;; Standard alphabet
      ((<= (char-code #\A) code (char-code #\Z))
       (- code (char-code #\A)))
      ((<= (char-code #\a) code (char-code #\z))
       (+ 26 (- code (char-code #\a))))
      ((<= (char-code #\0) code (char-code #\9))
       (+ 52 (- code (char-code #\0))))
      ((or (char= char #\+) (char= char #\-))  ; + or URL-safe -
       62)
      ((or (char= char #\/) (char= char #\_))  ; / or URL-safe _
       63)
      ((char= char +base64-pad-char+)
       0)  ; Padding returns 0 (handled specially in decode)
      (t (error "Invalid Base64 character: ~C" char)))))

(defun base64-decode (string &key (uri nil))
  "Decode Base64 STRING to byte vector.

PARAMETERS:
  STRING - Base64 encoded string
  URI    - Accept URL-safe alphabet (default NIL)

RETURNS:
  Vector - Byte vector (simple-array (unsigned-byte 8))

SIGNALS:
  Error on invalid Base64 input

EXAMPLES:
  (base64-decode \"SGVsbG8=\")  ; => #(72 101 108 108 111)"
  (declare (ignore uri))  ; We accept both alphabets
  ;; Remove whitespace and compute output size
  (let* ((clean-string (remove-if (lambda (c)
                                    (member c '(#\Space #\Tab #\Newline #\Return)))
                                  string))
         (input-length (length clean-string))
         ;; Find padding
         (pad-count (count +base64-pad-char+ clean-string :from-end t))
         ;; Output is 3/4 of input minus padding
         (output-length (- (* 3 (floor input-length 4)) pad-count))
         (result (make-array output-length :element-type '(unsigned-byte 8)))
         (output-index 0))
    ;; Validate length
    (unless (zerop (mod input-length 4))
      (error "Invalid Base64 length: ~D (must be multiple of 4)" input-length))
    ;; Process 4-character groups
    (loop for i from 0 below input-length by 4
          for c0 = (char clean-string i)
          for c1 = (char clean-string (1+ i))
          for c2 = (char clean-string (+ i 2))
          for c3 = (char clean-string (+ i 3))
          for v0 = (base64-char-value c0)
          for v1 = (base64-char-value c1)
          for v2 = (base64-char-value c2)
          for v3 = (base64-char-value c3)
          do
             ;; First byte: all 6 bits of v0 + top 2 bits of v1
             (when (< output-index output-length)
               (setf (aref result output-index)
                     (logior (ash v0 2) (ash v1 -4)))
               (incf output-index))
             ;; Second byte: bottom 4 bits of v1 + top 4 bits of v2
             (when (and (< output-index output-length) (not (char= c2 +base64-pad-char+)))
               (setf (aref result output-index)
                     (logior (ash (logand v1 #x0f) 4) (ash v2 -2)))
               (incf output-index))
             ;; Third byte: bottom 2 bits of v2 + all 6 bits of v3
             (when (and (< output-index output-length) (not (char= c3 +base64-pad-char+)))
               (setf (aref result output-index)
                     (logior (ash (logand v2 #x03) 6) v3))
               (incf output-index)))
    result))

(defun base64-string-to-usb8-array (string &key (uri nil))
  "Decode Base64 string to byte array (cl-base64 compatible).

PARAMETERS:
  STRING - Base64 encoded string
  URI    - Accept URL-safe alphabet

RETURNS:
  Vector - Byte vector"
  (base64-decode string :uri uri))

(defun base64-decode-string (string &key (external-format :utf-8))
  "Decode Base64 STRING to regular string.

PARAMETERS:
  STRING          - Base64 encoded string
  EXTERNAL-FORMAT - Character encoding (default :utf-8)

RETURNS:
  String - Decoded string

EXAMPLES:
  (base64-decode-string \"SGVsbG8=\")  ; => \"Hello\""
  (declare (ignore external-format))  ; We always use UTF-8 internally
  (bytes-to-string (base64-decode string)))

;;; End of base64.lisp
