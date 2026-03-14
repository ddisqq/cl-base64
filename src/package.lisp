;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; Copyright (C) 2025 Park Ian Co
;;;; License: MIT
;;;;
;;;; Package definition for CL_BASE64

(in-package :cl-user)

(defpackage :CL_BASE64
  (:nicknames :base64)
  (:use :cl)
  (:export
   #:encode-base64
   #:decode-base64
   #:validate-base64))

(in-package :CL_BASE64)
