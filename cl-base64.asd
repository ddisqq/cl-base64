(asdf:defsystem #:cl-base64
  :name "cl-base64"
  :version "0.1.0"
  :author "Park Ian Co"
  :license "Apache-2.0"
  :description "Base64 encoding/decoding (RFC 4648)"
  :serial t
  :components ((:module "src"
                :components ((:file "package")
                             (:file "conditions" :depends-on ("package"))
                             (:file "types" :depends-on ("package"))
                             (:file "cl-base64" :depends-on ("package" "conditions" "types"))))))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-base64/test))))

(asdf:defsystem #:cl-base64/test
  :name "cl-base64"
  :depends-on (#:cl-base64)
  :serial t
  :components ((:module "test"
                :serial t
                :components ((:file "test"))))
  :perform (asdf:test-op (op c)
             (declare (ignore op c))
             (unless (uiop:symbol-call :cl-base64.test :run-tests)
               (error "Tests failed"))))
