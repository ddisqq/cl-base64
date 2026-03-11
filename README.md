# cl-base64

A pure Common Lisp implementation of RFC 4648 Base64 encoding and decoding.

## Features

- RFC 4648 compliant Base64 encoding/decoding
- URL-safe Base64 variant (RFC 4648 Section 5)
- Optional line breaking for MIME compatibility
- Zero external dependencies
- Thread-safe (pure functions)

## Installation

Clone the repository and load with ASDF:

```lisp
(asdf:load-system :cl-base64)
```

## Usage

### Basic Encoding/Decoding

```lisp
;; Encode bytes to Base64
(cl-base64:base64-encode #(72 101 108 108 111))
;; => "SGVsbG8="

;; Decode Base64 to bytes
(cl-base64:base64-decode "SGVsbG8=")
;; => #(72 101 108 108 111)
```

### String Convenience Functions

```lisp
;; Encode string (UTF-8)
(cl-base64:base64-encode-string "Hello, World!")
;; => "SGVsbG8sIFdvcmxkIQ=="

;; Decode to string
(cl-base64:base64-decode-string "SGVsbG8sIFdvcmxkIQ==")
;; => "Hello, World!"
```

### URL-Safe Base64

```lisp
;; Use URL-safe alphabet (- and _ instead of + and /)
(cl-base64:base64-encode data :uri t)

;; Decoding accepts both standard and URL-safe
(cl-base64:base64-decode url-safe-string :uri t)
```

### Line Breaking (MIME)

```lisp
;; Insert line breaks every 76 characters
(cl-base64:base64-encode data :line-length 76)
```

## API Reference

### Encoding

- `base64-encode (bytes &key uri line-length line-break)` - Encode byte vector
- `base64-encode-string (string &key external-format)` - Encode string (UTF-8)
- `usb8-array-to-base64-string (array &key uri)` - Compatibility alias
- `string-to-base64-string (string &key external-format)` - Compatibility alias
- `encode-base64-bytes (bytes &key uri)` - Compatibility alias

### Decoding

- `base64-decode (string &key uri)` - Decode to byte vector
- `base64-decode-string (string &key external-format)` - Decode to string
- `base64-string-to-usb8-array (string &key uri)` - Compatibility alias

## Testing

```lisp
(asdf:test-system :cl-base64)
```

## License

BSD-3-Clause. See LICENSE file.
