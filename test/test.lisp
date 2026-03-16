;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-base64.test
  (:use #:cl #:cl-base64)
  (:export #:run-tests))

(in-package #:cl-base64.test)

(defun run-tests ()
  (format t "~%Running tests for cl-base64...~%")
  (test-encoding-decoding)
  (format t "~%All cl-base64 tests passed!~%")
  t)

(defun test-encoding-decoding ()
  (format t "  Testing encoding and decoding...~%")
  (let* ((data (make-array 3 :element-type '(unsigned-byte 8) :initial-contents '(77 97 110)))
         (encoded (encode-base64 data)))
    (assert (string= "TWFu" encoded))
    (assert (equalp data (decode-base64 encoded))))
  (let* ((data (make-array 2 :element-type '(unsigned-byte 8) :initial-contents '(77 97)))
         (encoded (encode-base64 data)))
    (assert (string= "TWE=" encoded))
    (assert (equalp data (decode-base64 encoded))))
  (let* ((data (make-array 1 :element-type '(unsigned-byte 8) :initial-contents '(77)))
         (encoded (encode-base64 data)))
    (assert (string= "TQ==" encoded))
    (assert (equalp data (decode-base64 encoded))))
  (let* ((data (make-array 5 :element-type '(unsigned-byte 8) :initial-contents '(1 2 3 4 5))))
    (assert (equalp data (decode-base64 (encode-base64 data))))))
