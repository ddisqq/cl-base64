;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base64)

(define-condition cl-base64-error (error)
  ((message :initarg :message :reader cl-base64-error-message))
  (:report (lambda (condition stream)
             (format stream "cl-base64 error: ~A" (cl-base64-error-message condition)))))
