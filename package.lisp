;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(defpackage #:cl-base64
  (:use #:cl)
  (:export
   ;; Main API
   #:base64-encode
   #:base64-decode

   ;; String convenience
   #:base64-encode-string
   #:base64-decode-string

   ;; Compatibility aliases (cl-base64 library compatible)
   #:usb8-array-to-base64-string
   #:base64-string-to-usb8-array
   #:string-to-base64-string
   #:encode-base64-bytes

   ;; Constants
   #:+base64-alphabet+
   #:+base64-url-alphabet+
   #:+base64-pad-char+))
