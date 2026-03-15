;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base64)

(defparameter *base64-chars*
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
(defparameter *base64-pad* #\=)

(defun normalize-octets (data)
  "Coerce DATA to an octet vector."
  (cond
    ((stringp data)
     (map '(vector (unsigned-byte 8)) #'char-code data))
    ((vectorp data)
     (let ((result (make-array (length data) :element-type '(unsigned-byte 8))))
       (dotimes (index (length data) result)
         (let ((value (aref data index)))
           (unless (typep value '(unsigned-byte 8))
             (error "Vector element ~D is not an octet: ~S" index value))
           (setf (aref result index) value)))))
    ((listp data)
     (normalize-octets (coerce data 'vector)))
    (t
     (error "Unsupported base64 input: ~S" data))))

(defun char-to-base64-index (char)
  "Return the alphabet index for CHAR."
  (let ((position (position char *base64-chars* :test #'char=)))
    (if position
        position
        (error "Invalid base64 character: ~A" char))))

(defun encode-base64 (data)
  "Encode DATA to RFC 4648 base64."
  (let ((bytes (normalize-octets data)))
    (with-output-to-string (out)
      (loop for index from 0 below (length bytes) by 3
            for b1 = (aref bytes index)
            for has-b2 = (< (1+ index) (length bytes))
            for has-b3 = (< (+ index 2) (length bytes))
            for b2 = (if has-b2 (aref bytes (1+ index)) 0)
            for b3 = (if has-b3 (aref bytes (+ index 2)) 0)
            do (write-char (aref *base64-chars* (ldb (byte 6 2) b1)) out)
               (write-char (aref *base64-chars*
                                 (logior (ash (logand b1 #b11) 4)
                                         (ldb (byte 4 4) b2)))
                           out)
               (write-char (if has-b2
                               (aref *base64-chars*
                                     (logior (ash (logand b2 #b1111) 2)
                                             (ldb (byte 2 6) b3)))
                               *base64-pad*)
                           out)
               (write-char (if has-b3
                               (aref *base64-chars* (logand b3 #b111111))
                               *base64-pad*)
                           out)))))

(defun validate-base64 (encoded)
  "Return true when ENCODED is structurally valid RFC 4648 base64."
  (let ((trimmed (string-trim '(#\Space #\Newline #\Return #\Tab) encoded)))
    (and (zerop (mod (length trimmed) 4))
         (or (zerop (length trimmed))
             (let ((padding-start (position *base64-pad* trimmed)))
               (and
                (loop for char across trimmed
                      always (or (position char *base64-chars* :test #'char=)
                                 (char= char *base64-pad*)))
                (or (null padding-start)
                    (and (<= (- (length trimmed) padding-start) 2)
                         (loop for index from padding-start below (length trimmed)
                               always (char= (char trimmed index) *base64-pad*))))))))))

(defun decode-base64 (encoded)
  "Decode RFC 4648 base64 ENCODED into an octet vector."
  (let ((trimmed (string-trim '(#\Space #\Newline #\Return #\Tab) encoded)))
    (unless (validate-base64 trimmed)
      (error "Invalid base64 input: ~S" encoded))
    (let ((result (make-array 0
                              :element-type '(unsigned-byte 8)
                              :adjustable t
                              :fill-pointer 0)))
      (loop for index from 0 below (length trimmed) by 4
            for c1 = (char trimmed index)
            for c2 = (char trimmed (1+ index))
            for c3 = (char trimmed (+ index 2))
            for c4 = (char trimmed (+ index 3))
            for v1 = (char-to-base64-index c1)
            for v2 = (char-to-base64-index c2)
            for v3 = (if (char= c3 *base64-pad*) 0 (char-to-base64-index c3))
            for v4 = (if (char= c4 *base64-pad*) 0 (char-to-base64-index c4))
            do (vector-push-extend (logior (ash v1 2) (ash v2 -4)) result)
               (unless (char= c3 *base64-pad*)
                 (vector-push-extend (logior (ash (logand v2 #b1111) 4)
                                             (ash v3 -2))
                                     result))
               (unless (char= c4 *base64-pad*)
                 (vector-push-extend (logior (ash (logand v3 #b11) 6) v4)
                                     result)))
      result)))


;;; Substantive API Implementations
(define-condition cl-base64-error (cl-base64-error) ())
(define-condition cl-base64-validation-error (cl-base64-error) ())


;;; ============================================================================
;;; Standard Toolkit for cl-base64
;;; ============================================================================

(defmacro with-base64-timing (&body body)
  "Executes BODY and logs the execution time specific to cl-base64."
  (let ((start (gensym))
        (end (gensym)))
    `(let ((,start (get-internal-real-time)))
       (multiple-value-prog1
           (progn ,@body)
         (let ((,end (get-internal-real-time)))
           (format t "~&[cl-base64] Execution time: ~A ms~%"
                   (/ (* (- ,end ,start) 1000.0) internal-time-units-per-second)))))))

(defun base64-batch-process (items processor-fn)
  "Applies PROCESSOR-FN to each item in ITEMS, handling errors resiliently.
Returns (values processed-results error-alist)."
  (let ((results nil)
        (errors nil))
    (dolist (item items)
      (handler-case
          (push (funcall processor-fn item) results)
        (error (e)
          (push (cons item e) errors))))
    (values (nreverse results) (nreverse errors))))

(defun base64-health-check ()
  "Performs a basic health check for the cl-base64 module."
  (let ((ctx (initialize-base64)))
    (if (validate-base64 ctx)
        :healthy
        :degraded)))


;;; Substantive Domain Expansion

(defun identity-list (x) (if (listp x) x (list x)))
(defun flatten (l) (cond ((null l) nil) ((atom l) (list l)) (t (append (flatten (car l)) (flatten (cdr l))))))
(defun map-keys (fn hash) (let ((res nil)) (maphash (lambda (k v) (push (funcall fn k) res)) hash) res))
;;; ============================================================================
;;; URL-Safe Base64 (RFC 4648 Section 5)
;;; ============================================================================

(defparameter *base64-url-chars*
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

(defun encode-base64-url (data)
  "Encode DATA to RFC 4648 base64url (URL-safe variant without padding)."
  (let ((bytes (normalize-octets data)))
    (with-output-to-string (out)
      (loop for index from 0 below (length bytes) by 3
            for b1 = (aref bytes index)
            for has-b2 = (< (1+ index) (length bytes))
            for has-b3 = (< (+ index 2) (length bytes))
            for b2 = (if has-b2 (aref bytes (1+ index)) 0)
            for b3 = (if has-b3 (aref bytes (+ index 2)) 0)
            do (write-char (aref *base64-url-chars* (ldb (byte 6 2) b1)) out)
               (write-char (aref *base64-url-chars*
                                 (logior (ash (logand b1 #b11) 4)
                                         (ldb (byte 4 4) b2)))
                           out)
               (if has-b2
                   (write-char (aref *base64-url-chars*
                                     (logior (ash (logand b2 #b1111) 2)
                                             (ldb (byte 2 6) b3)))
                               out))
               (if has-b3
                   (write-char (aref *base64-url-chars* (logand b3 #b111111))
                               out))))))

(defun decode-base64-url (encoded)
  "Decode RFC 4648 base64url ENCODED into an octet vector (padding optional)."
  (let* ((trimmed (string-trim '(#\Space #\Newline #\Return #\Tab) encoded))
         ;; Add padding if needed
         (padded (case (mod (length trimmed) 4)
                   (0 trimmed)
                   (2 (concatenate 'string trimmed "=="))
                   (3 (concatenate 'string trimmed "="))
                   (t (error "Invalid base64url length: ~S" encoded))))
         ;; Replace URL-safe chars with standard base64
         (standard (substitute #\+ #\- (substitute #\/ #\_ padded))))
    (decode-base64 standard)))

;;; ============================================================================
;;; Streaming Encoders/Decoders
;;; ============================================================================

(defun make-base64-encoder (&key (url-safe nil))
  "Create a streaming base64 encoder closure.
Returns (values encode-fn finalize-fn).
encode-fn takes a byte vector, finalize-fn returns final padding."
  (let ((buffer (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0))
        (chars (if url-safe *base64-url-chars* *base64-chars*))
        (pad-char (if url-safe nil *base64-pad*)))
    (flet ((encode-chunk (bytes)
             (with-output-to-string (out)
               (loop for i from 0 below (length bytes) by 3
                     for b1 = (aref bytes i)
                     for has-b2 = (< (1+ i) (length bytes))
                     for has-b3 = (< (+ i 2) (length bytes))
                     for b2 = (if has-b2 (aref bytes (1+ i)) 0)
                     for b3 = (if has-b3 (aref bytes (+ i 2)) 0)
                     do (write-char (aref chars (ldb (byte 6 2) b1)) out)
                        (write-char (aref chars (logior (ash (logand b1 #b11) 4)
                                                       (ldb (byte 4 4) b2)))
                                    out)
                        (if has-b2
                            (write-char (aref chars (logior (ash (logand b2 #b1111) 2)
                                                           (ldb (byte 2 6) b3)))
                                        out))
                        (if has-b3
                            (write-char (aref chars (logand b3 #b111111)) out)
                            (when pad-char (write-char pad-char out)))))))
           (add-bytes (new-bytes)
             (loop for byte across (normalize-octets new-bytes)
                   do (vector-push-extend byte buffer)))
           (encode-fn (data)
             (add-bytes data)
             ;; Only process complete 3-byte chunks
             (let ((full-chunks (* 3 (floor (length buffer) 3))))
               (if (> full-chunks 0)
                   (let ((result (encode-chunk (subseq buffer 0 full-chunks))))
                     ;; Keep remainder
                     (let ((new-buffer (make-array (- (length buffer) full-chunks)
                                                  :element-type '(unsigned-byte 8))))
                       (replace new-buffer buffer :start2 full-chunks)
                       (setf (fill-pointer buffer) 0)
                       (loop for byte across new-buffer
                             do (vector-push-extend byte buffer)))
                     result)
                   "")))
           (finalize-fn ()
             (if (> (length buffer) 0)
                 (encode-chunk buffer)
                 "")))
      (values #'encode-fn #'finalize-fn))))

(defun base64-encode-stream (input-stream output-stream &key (url-safe nil) (chunk-size 3072))
  "Encode INPUT-STREAM to base64 in OUTPUT-STREAM.
CHUNK-SIZE controls streaming buffer size (default 3KB)."
  (multiple-value-bind (encode-fn finalize-fn)
      (make-base64-encoder :url-safe url-safe)
    (let ((buffer (make-array chunk-size :element-type '(unsigned-byte 8))))
      (loop for bytes-read = (read-sequence buffer input-stream)
            while (> bytes-read 0)
            do (write-string (funcall encode-fn (subseq buffer 0 bytes-read)) output-stream))
      (write-string (funcall finalize-fn) output-stream))))

;;; ============================================================================
;;; Utility Functions
;;; ============================================================================

(defun base64-encode-string (string)
  "Encode STRING as UTF-8 then base64. Returns base64 string."
  (encode-base64 (map '(vector (unsigned-byte 8)) #'char-code string)))

(defun base64-decode-string (encoded)
  "Decode base64 ENCODED and return as string (assumes UTF-8)."
  (let ((bytes (decode-base64 encoded)))
    (map 'string #'code-char bytes)))

(defun usb8-array-to-base64-string (array)
  "cl-base64 library compatibility: encode byte vector to base64 string."
  (encode-base64 array))

(defun base64-string-to-usb8-array (string)
  "cl-base64 library compatibility: decode base64 string to byte vector."
  (decode-base64 string))

(defun string-to-base64-string (string)
  "Encode STRING to base64."
  (base64-encode-string string))

(defun encode-base64-bytes (bytes)
  "Encode BYTES to base64."
  (encode-base64 bytes))

;;; Constants for export
(defparameter +base64-alphabet+ *base64-chars*)
(defparameter +base64-url-alphabet+ *base64-url-chars*)
(defparameter +base64-pad-char+ *base64-pad*)

;;; Substantive Functional Logic

(defun deep-copy-list (l)
  "Recursively copies a nested list."
  (if (atom l) l (cons (deep-copy-list (car l)) (deep-copy-list (cdr l)))))

(defun group-by-count (list n)
  "Groups list elements into sublists of size N."
  (loop for i from 0 below (length list) by n
        collect (subseq list i (min (+ i n) (length list)))))
