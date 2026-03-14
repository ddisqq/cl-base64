# Base64

RFC 4648 base64 encoding and decoding utilities for Common Lisp.

## Features

- Encode strings, octet vectors, or octet lists to base64
- Decode base64 strings into octet vectors
- Validate base64 structure before decoding

## Installation

```lisp
(asdf:load-system :cl-base64)
```

## Usage

```lisp
(let* ((encoded (cl-base64:encode-base64 "hello"))
       (decoded (cl-base64:decode-base64 encoded)))
  (values encoded decoded))
```

## Testing

```lisp
(asdf:test-system :cl-base64)
```

## API

- `encode-base64` encodes strings or octet sequences to RFC 4648 base64.
- `decode-base64` decodes a base64 string to an octet vector.
- `validate-base64` checks padding and alphabet validity.

## License

BSD-3-Clause License - See LICENSE file for details.

---
Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
