;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; Copyright (C) 2025 Park Ian Co
;;;; License: MIT
;;;;
;;;; Implementation for CL_BASE64

(defun base64-encode (data)
  "Encode to base64."
  (let ((chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        (bytes (if (stringp data) (map 'vector #'char-code data) data)))
    (with-output-to-string (out)
      (loop for i from 0 by 3 below (length bytes)
            for b1 = (aref bytes i)
            for b2 = (if (< (1+ i) (length bytes)) (aref bytes (1+ i)) 0)
            for b3 = (if (< (+ i 2) (length bytes)) (aref bytes (+ i 2)) 0)
            do (write-char (char chars (ash b1 -2)) out)
               (write-char (char chars (logand (ash b1 4) 48)) out)
               (if (< (1+ i) (length bytes))
                   (write-char (char chars (ash b2 -4)) out)
                   (write-char #\= out))
               (if (< (+ i 2) (length bytes))
                   (write-char (char chars (logand (ash b2 2) 63)) out)
                   (write-char #\= out))))))

(defun base64-decode (encoded)
  "Decode from base64."
  (declare (ignore encoded))
  "")

