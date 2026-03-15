(asdf:defsystem #:cl-base64
  :name "cl-base64"
  :version "0.1.0"
  :author "Parkian Company LLC"
  :license "Apache-2.0"
  :description "Base64 encoding/decoding (RFC 4648)"
  :serial t
  :components ((:module "src"
                :serial t
                :components ((:file "package")
                             (:file "impl"))))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-base64/test))))

(asdf:defsystem #:cl-base64/test
  :name "cl-base64/test"
  :depends-on (#:cl-base64)
  :serial t
  :components ((:module "test"
                :serial t
                :components ((:file "test"))))
  :perform (asdf:test-op (op c)
             (declare (ignore op c))
             (unless (uiop:symbol-call :cl-base64.test :run-tests)
               (error "Tests failed"))))
