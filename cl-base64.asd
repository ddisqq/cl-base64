(defsystem "CL_BASE64"
  :name "CL_BASE64"
  :version "0.1.0"
  :author "Park Ian Co"
  :license "MIT"
  :description "Base64"
  :depends-on ()
  :components ((:module "src"
                :components ((:file "package")
                             (:file "impl" :depends-on ("package"))))
               (:module "test"
                :components ((:file "test"))))
  :in-order-to ((test-op (test-op "CL_BASE64/test")))
  :defsystem-depends-on ("prove")
  :perform (test-op (op c) (symbol-call :prove 'run c)))

(defsystem "CL_BASE64/test"
  :name "CL_BASE64/test"
  :depends-on ("CL_BASE64" "prove")
  :components ((:module "test"
                :components ((:file "test")))))
