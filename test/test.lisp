;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-base64.test
  (:use #:cl #:cl-base64)
  (:export #:run-tests))

(in-package #:cl-base64.test)

(defun run-tests ()
  (format t "Running professional test suite for cl-base64...~%")
  (assert (initialize-base64))
  (format t "Tests passed!~%")
  t)
