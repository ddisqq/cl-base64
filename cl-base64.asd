;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(asdf:defsystem #:cl-base64
  :description "RFC 4648 Base64 encoding/decoding for Common Lisp"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
  :version "0.1.0"
  :serial t
  :components ((:file "package")
               (:module "src"
                :components ((:file "base64"))))
  :in-order-to ((asdf:test-op (test-op #:cl-base64/test))))

(asdf:defsystem #:cl-base64/test
  :description "Tests for cl-base64"
  :depends-on (#:cl-base64)
  :serial t
  :components ((:module "test"
                :components ((:file "test-base64"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-base64.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
