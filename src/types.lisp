;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base64)

;;; Core types for cl-base64
(deftype cl-base64-id () '(unsigned-byte 64))
(deftype cl-base64-status () '(member :ready :active :error :shutdown))
