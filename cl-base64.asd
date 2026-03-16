;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(asdf:defsystem #:cl-base64
  :name "cl-base64"
  :version "0.1.0"
  :description "A robust Base64 encoder and decoder for Common Lisp."
  :author "Parkian Company LLC"
  :license "Apache-2.0"
  :components ((:module "src"
                :components ((:file "package")
                             (:file "cl-base64" :depends-on ("package")))))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-base64/test))))

(asdf:defsystem #:cl-base64/test
  :depends-on (#:cl-base64)
  :components ((:module "test"
                :components ((:file "test"))))
  :perform (asdf:test-op (op c) (uiop:symbol-call :cl-base64.test :run-tests)))
