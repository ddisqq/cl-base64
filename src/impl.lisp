;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package :cl-base64)

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
