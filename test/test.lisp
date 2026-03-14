;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; Copyright (C) 2025 Park Ian Co
;;;; License: MIT
;;;;
;;;; Tests for CL_BASE64

(in-package :CL_BASE64)

(defun run-tests ()
  "Run all tests."
  (let ((passed 0) (failed 0))
    ;; Test 1: Encode simple string
    (let ((result (encode-base64 "hello")))
      (if (string= result "aGVsbG8=")
          (incf passed)
          (progn
            (format t "FAIL: encode-base64 'hello'~%  Expected: aGVsbG8=~%  Got: ~A~%" result)
            (incf failed))))

    ;; Test 2: Encode empty string
    (let ((result (encode-base64 "")))
      (if (string= result "")
          (incf passed)
          (progn
            (format t "FAIL: encode-base64 empty~%  Expected: ''~%  Got: '~A'~%" result)
            (incf failed))))

    ;; Test 3: Round-trip
    (let* ((original "test string")
           (encoded (encode-base64 original))
           (decoded (decode-base64 encoded))
           (decoded-str (coerce decoded 'string)))
      (if (string= decoded-str original)
          (incf passed)
          (progn
            (format t "FAIL: round-trip 'test string'~%  Got: ~A~%" decoded-str)
            (incf failed))))

    ;; Test 4: Validate base64
    (if (validate-base64 "aGVsbG8=")
        (incf passed)
        (progn
          (format t "FAIL: validate-base64 should accept valid base64~%")
          (incf failed)))

    ;; Test 5: Validate invalid base64
    (if (not (validate-base64 "!!!INVALID"))
        (incf passed)
        (progn
          (format t "FAIL: validate-base64 should reject invalid~%")
          (incf failed)))

    ;; Test 6: Large data
    (let* ((original (make-string 1000 :initial-element #\a))
           (encoded (encode-base64 original))
           (decoded (decode-base64 encoded))
           (decoded-str (coerce decoded 'string)))
      (if (string= decoded-str original)
          (incf passed)
          (progn
            (format t "FAIL: large data round-trip~%")
            (incf failed))))

    (format t "~%Base64 Tests: ~D passed, ~D failed~%" passed failed)
    (zerop failed)))
