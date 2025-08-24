# bignum

A Move library for arbitrary-precision arithmetic on the Sui blockchain, providing both integer and floating-point operations with unlimited precision.

## Overview

This library implements two main types:
- **BigInt**: Arbitrary-precision unsigned integers using base 2^32 limbs
- **BigFloat**: Signed rational numbers (numerator/denominator) with arbitrary precision

## Features

### BigInt
- Arbitrary-precision unsigned integer arithmetic
- Basic operations: addition, subtraction, multiplication, division
- Comparison operations
- Conversion from/to standard integer types
- Memory-efficient base 2^32 limb representation

### BigFloat
- Signed rational number representation
- Arbitrary-precision decimal arithmetic
- Built on top of BigInt for maximum precision
- Support for all standard floating-point operations

## Installation

Add this package to your `Move.toml`:

```toml
[dependencies]
bignum = { git = "https://github.com/your-username/bignum.git" }
```

## Usage

### BigInt Examples

```move
use bignum::bigint;

// Create BigInt from u64
let a = bigint::bi_from_u64(12345);
let b = bigint::bi_from_u64(67890);

// Basic arithmetic
let sum = bigint::bi_add(a, b);
let product = bigint::bi_mul(a, b);

// Comparisons
let is_greater = bigint::bi_gt(&a, &b);
```

### BigFloat Examples

```move
use bignum::bigfloat;

// Create BigFloat from u64
let x = bigfloat::bf_from_u64(123);
let y = bigfloat::bf_from_u64(456);

// Arithmetic operations
let sum = bigfloat::bf_add(x, y);
let quotient = bigfloat::bf_div(x, y);
```

## Development

### Building

```bash
sui move build
```

### Testing

```bash
sui move test
```

## Project Structure

```
bignum/
├── Move.toml           # Package configuration
├── sources/
│   ├── bigint.move     # BigInt implementation
│   └── bigfloat.move   # BigFloat implementation
└── tests/
    └── bigfloat_tests.move  # Test suite
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.