;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; test-base64.lisp - Tests for cl-base64

(defpackage #:cl-base64.test
  (:use #:cl #:cl-base64)
  (:export #:run-tests))

(in-package #:cl-base64.test)

(defvar *test-count* 0)
(defvar *pass-count* 0)
(defvar *fail-count* 0)

(defmacro deftest (name &body body)
  `(defun ,name ()
     (incf *test-count*)
     (handler-case
         (progn
           ,@body
           (incf *pass-count*)
           (format t "~&PASS: ~A~%" ',name))
       (error (e)
         (incf *fail-count*)
         (format t "~&FAIL: ~A - ~A~%" ',name e)))))

(defmacro assert-equal (expected actual)
  `(let ((exp ,expected)
         (act ,actual))
     (unless (equal exp act)
       (error "Expected ~S but got ~S" exp act))))

(defmacro assert-equalp (expected actual)
  `(let ((exp ,expected)
         (act ,actual))
     (unless (equalp exp act)
       (error "Expected ~S but got ~S" exp act))))

;;; ============================================================================
;;; Test Cases
;;; ============================================================================

(deftest test-encode-empty
  (assert-equal "" (base64-encode #())))

(deftest test-decode-empty
  (assert-equalp #() (base64-decode "")))

(deftest test-encode-hello
  (assert-equal "SGVsbG8=" (base64-encode #(72 101 108 108 111))))

(deftest test-decode-hello
  (assert-equalp #(72 101 108 108 111) (base64-decode "SGVsbG8=")))

(deftest test-encode-string
  (assert-equal "SGVsbG8=" (base64-encode-string "Hello")))

(deftest test-decode-string
  (assert-equal "Hello" (base64-decode-string "SGVsbG8=")))

(deftest test-round-trip-bytes
  (let ((data #(0 1 2 3 4 5 255 254 253)))
    (assert-equalp data (base64-decode (base64-encode data)))))

(deftest test-round-trip-string
  (let ((str "The quick brown fox jumps over the lazy dog."))
    (assert-equal str (base64-decode-string (base64-encode-string str)))))

(deftest test-padding-1
  ;; 1 byte input = 2 chars + 2 padding
  (assert-equal "QQ==" (base64-encode #(65))))

(deftest test-padding-2
  ;; 2 byte input = 3 chars + 1 padding
  (assert-equal "QUI=" (base64-encode #(65 66))))

(deftest test-no-padding
  ;; 3 byte input = 4 chars, no padding
  (assert-equal "QUJD" (base64-encode #(65 66 67))))

(deftest test-url-safe-encode
  (let ((data #(251 255 254)))  ; Would produce +/
    (let ((standard (base64-encode data))
          (url-safe (base64-encode data :uri t)))
      ;; URL-safe should not contain + or /
      (assert-equal nil (find #\+ url-safe))
      (assert-equal nil (find #\/ url-safe)))))

(deftest test-url-safe-decode
  ;; Should decode both standard and URL-safe
  (assert-equalp (base64-decode "ab+/")
                 (base64-decode "ab-_")))

(deftest test-whitespace-ignored
  (assert-equalp #(72 101 108 108 111)
                 (base64-decode "SGVs
bG8=")))

(deftest test-rfc4648-vectors
  ;; RFC 4648 test vectors
  (assert-equal "" (base64-encode-string ""))
  (assert-equal "Zg==" (base64-encode-string "f"))
  (assert-equal "Zm8=" (base64-encode-string "fo"))
  (assert-equal "Zm9v" (base64-encode-string "foo"))
  (assert-equal "Zm9vYg==" (base64-encode-string "foob"))
  (assert-equal "Zm9vYmE=" (base64-encode-string "fooba"))
  (assert-equal "Zm9vYmFy" (base64-encode-string "foobar")))

(deftest test-binary-data
  ;; All byte values
  (let ((all-bytes (make-array 256 :element-type '(unsigned-byte 8))))
    (dotimes (i 256)
      (setf (aref all-bytes i) i))
    (assert-equalp all-bytes (base64-decode (base64-encode all-bytes)))))

(deftest test-compatibility-aliases
  ;; Test cl-base64 compatibility
  (let ((data #(1 2 3 4 5)))
    (assert-equalp data (base64-string-to-usb8-array
                         (usb8-array-to-base64-string data)))
    (assert-equal "SGVsbG8=" (string-to-base64-string "Hello"))
    (assert-equal "SGVsbG8=" (encode-base64-bytes #(72 101 108 108 111)))))

;;; ============================================================================
;;; Test Runner
;;; ============================================================================

(defun run-tests ()
  (setf *test-count* 0
        *pass-count* 0
        *fail-count* 0)
  (format t "~&Running cl-base64 tests...~%")
  (format t "~&========================================~%")

  (test-encode-empty)
  (test-decode-empty)
  (test-encode-hello)
  (test-decode-hello)
  (test-encode-string)
  (test-decode-string)
  (test-round-trip-bytes)
  (test-round-trip-string)
  (test-padding-1)
  (test-padding-2)
  (test-no-padding)
  (test-url-safe-encode)
  (test-url-safe-decode)
  (test-whitespace-ignored)
  (test-rfc4648-vectors)
  (test-binary-data)
  (test-compatibility-aliases)

  (format t "~&========================================~%")
  (format t "~&Tests: ~D  Passed: ~D  Failed: ~D~%"
          *test-count* *pass-count* *fail-count*)
  (zerop *fail-count*))

;;; End of test-base64.lisp
