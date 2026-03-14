;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; Copyright (C) 2025 Park Ian Co
;;;; License: MIT
;;;;
;;;; Implementation for CL_BASE64

(defvar *base64-chars* "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
(defvar *base64-pad* #\=)

(defun encode-base64 (data)
  "Encode DATA (string or byte vector) to RFC 4648 base64."
  (let ((bytes (if (stringp data)
                   (map 'vector #'char-code data)
                   data)))
    (with-output-to-string (out)
      (loop for i from 0 by 3 below (length bytes)
            for b1 = (aref bytes i)
            for b2 = (if (< (1+ i) (length bytes)) (aref bytes (1+ i)) 0)
            for b3 = (if (< (+ i 2) (length bytes)) (aref bytes (+ i 2)) 0)
            do
            ;; Encode 3 bytes to 4 base64 chars
            (write-char (aref *base64-chars* (ash b1 -2)) out)
            (write-char (aref *base64-chars* (logior (logand (ash b1 4) 48)
                                                       (ash b2 -4))) out)
            (if (< (1+ i) (length bytes))
                (write-char (aref *base64-chars* (logior (logand (ash b2 2) 60)
                                                           (ash b3 -6))) out)
                (write-char *base64-pad* out))
            (if (< (+ i 2) (length bytes))
                (write-char (aref *base64-chars* (logand b3 63)) out)
                (write-char *base64-pad* out))))))

(defun decode-base64 (encoded)
  "Decode RFC 4648 base64 string to byte vector."
  (let* ((s (string-trim '(#\Space #\Newline #\Return #\Tab) encoded))
         (result (make-array (length s) :element-type '(unsigned-byte 8) :fill-pointer 0)))
    (flet ((char-to-val (c)
             (cond
               ((char>= c #\A) (if (char>= c #\a)
                                   (+ 26 (- (char-code c) (char-code #\a)))
                                   (- (char-code c) (char-code #\A))))
               ((char>= c #\0) (+ 52 (- (char-code c) (char-code #\0))))
               ((char= c #\+) 62)
               ((char= c #\/) 63)
               ((char= c *base64-pad*) 0)
               (t (error "Invalid base64 character: ~A" c)))))
      (loop for i from 0 by 4 below (length s)
            for c1 = (char-to-val (aref s i))
            for c2 = (if (< (1+ i) (length s)) (char-to-val (aref s (1+ i))) 0)
            for c3 = (if (< (+ i 2) (length s)) (char-to-val (aref s (+ i 2))) 0)
            for c4 = (if (< (+ i 3) (length s)) (char-to-val (aref s (+ i 3))) 0)
            do
            (vector-push (logior (ash c1 2) (ash c2 -4)) result)
            (unless (char= (if (< (+ i 2) (length s)) (aref s (+ i 2)) *base64-pad*) *base64-pad*)
              (vector-push (logior (ash (logand c2 15) 4) (ash c3 -2)) result))
            (unless (char= (if (< (+ i 3) (length s)) (aref s (+ i 3)) *base64-pad*) *base64-pad*)
              (vector-push (logior (ash (logand c3 3) 6) c4) result))))
    result))

(defun validate-base64 (encoded)
  "Return T if ENCODED is valid RFC 4648 base64, NIL otherwise."
  (let ((s (string-trim '(#\Space #\Newline #\Return #\Tab) encoded)))
    (and (= (mod (length s) 4) 0)
         (loop for c across s
               always (or (position c *base64-chars*)
                          (char= c *base64-pad*))))))

