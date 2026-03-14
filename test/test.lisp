;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

(defpackage :cl-base64.test
  (:use :cl :cl-base64)
  (:export :run-tests))

(in-package :cl-base64.test)

(defmacro check (condition format-string &rest args)
  `(unless ,condition
     (error ,format-string ,@args)))

(defun octets-to-string (octets)
  (coerce (map 'list #'code-char octets) 'string))

(defun run-tests ()
  "Run the base64 regression suite."
  (check (string= "aGVsbG8=" (encode-base64 "hello"))
         "Expected hello vector to encode correctly")
  (check (string= "" (encode-base64 ""))
         "Expected empty string to encode to empty string")
  (let* ((original "test string")
         (encoded (encode-base64 original))
         (decoded (decode-base64 encoded)))
    (check (string= original (octets-to-string decoded))
           "Expected round-trip string, got ~S" decoded))
  (check (string= "AQIDBA==" (encode-base64 #(1 2 3 4)))
         "Expected byte vector to encode correctly")
  (check (equalp #(1 2 3 4) (decode-base64 "AQIDBA=="))
         "Expected byte vector round-trip")
  (check (validate-base64 "aGVsbG8=") "Expected valid base64 to pass validation")
  (check (not (validate-base64 "aGVsbG8")) "Expected missing padding to fail validation")
  (check (not (validate-base64 "!!!INVALID")) "Expected invalid alphabet to fail validation")
  t)
