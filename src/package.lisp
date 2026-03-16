;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-user)

(defpackage #:cl-base64
  (:use #:cl)
  (:export
   #:base64-execute
   #:base64-context
   #:initialize-base64
   #:encode-base64
   #:decode-base64))
