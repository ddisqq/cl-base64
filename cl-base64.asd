(asdf:defsystem #:cl-base64
  :depends-on (#:alexandria #:bordeaux-threads)
  :components ((:module "src"
                :components ((:file "package")
                             (:file "cl-base64" :depends-on ("package"))))))