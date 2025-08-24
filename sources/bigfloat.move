module bignum::bigfloat {
    use bignum::bigint;

    // BigFloat: signed rational number (numerator/denominator)
    public struct BigFloat has copy, drop, store {
        sign: bool,      // true = positive, false = negative
        num: bigint::BigInt,     // numerator (always non-negative)
        den: bigint::BigInt,     // denominator (always positive)
    }

    // Error codes
    const ErrDivisionByZero: u64 = 1;

    // === BigFloat Implementation ===

    // Create BigFloat from u64
    public fun bf_from_u64(value: u64): BigFloat {
        BigFloat {
            sign: true,
            num: bigint::bi_from_u64(value),
            den: bigint::bi_one(),
        }
    }

    // Create zero BigFloat
    public fun bf_zero(): BigFloat {
        BigFloat {
            sign: true,
            num: bigint::bi_zero(),
            den: bigint::bi_one(),
        }
    }

    // Create one BigFloat
    public fun bf_one(): BigFloat {
        BigFloat {
            sign: true,
            num: bigint::bi_one(),
            den: bigint::bi_one(),
        }
    }

    // Create BigFloat from u64 numerator and denominator
    public fun bf_from_ratio_u64(numerator: u64, denominator: u64): BigFloat {
        assert!(denominator != 0, ErrDivisionByZero);
        
        let mut result = BigFloat {
            sign: true,
            num: bigint::bi_from_u64(numerator),
            den: bigint::bi_from_u64(denominator),
        };
        bf_reduce(&mut result);
        result
    }

    // Check if BigFloat is zero
    public fun bf_is_zero(x: &BigFloat): bool {
       bigint::bi_is_zero(&x.num)
    }

    // Compare two BigFloat values for equality
    public fun bf_eq(a: &BigFloat, b: &BigFloat): bool {
        // Different signs => not equal (unless both are zero)
        if (a.sign != b.sign) {
            return bf_is_zero(a) && bf_is_zero(b)
        };

        // Same sign: compare cross products a.num * b.den == b.num * a.den
        let left = bigint::bi_mul(&a.num, &b.den);
        let right = bigint::bi_mul(&b.num, &a.den);
        bigint::bi_cmp(&left, &right) == 0
    }

    // Reduce BigFloat to lowest terms
    fun bf_reduce(x: &mut BigFloat) {
        if (bigint::bi_is_zero(&x.num)) {
            x.sign = true;
            x.num = bigint::bi_zero();
            x.den = bigint::bi_one();
            return
        };

        let gcd = bigint::bi_gcd(&x.num, &x.den);
        if (!bigint::bi_is_zero(&gcd) && bigint::bi_cmp(&gcd, &bigint::bi_one()) != 0) {
            let (new_num, _) = bigint::bi_divmod(&x.num, &gcd);
            let (new_den, _) = bigint::bi_divmod(&x.den, &gcd);
            x.num = new_num;
            x.den = new_den;
        }
    }

    // Add two BigFloats
    public fun bf_add(a: &BigFloat, b: &BigFloat): BigFloat {
        if (a.sign == b.sign) {
            // Same sign: add numerators
            let num1 = bigint::bi_mul(&a.num, &b.den);
            let num2 = bigint::bi_mul(&b.num, &a.den);
            let new_num = bigint::bi_add(&num1, &num2);
            let new_den = bigint::bi_mul(&a.den, &b.den);
            
            let mut result = BigFloat {
                sign: a.sign,
                num: new_num,
                den: new_den,
            };
            bf_reduce(&mut result);
            result
        } else {
            // Different signs: subtract
            let num1 = bigint::bi_mul(&a.num, &b.den);
            let num2 = bigint::bi_mul(&b.num, &a.den);
            let cmp = bigint::bi_cmp(&num1, &num2);
            
            let (new_num, sign) = if (cmp == 2) { // num1 < num2
                (bigint::bi_sub(&num2, &num1), b.sign)
            } else {
                (bigint::bi_sub(&num1, &num2), a.sign)
            };
            
            let new_den = bigint::bi_mul(&a.den, &b.den);
            let mut result = BigFloat {
                sign,
                num: new_num,
                den: new_den,
            };
            bf_reduce(&mut result);
            result
        }
    }

    // Subtract b from a
    public fun bf_sub(a: &BigFloat, b: &BigFloat): BigFloat {
        let neg_b = BigFloat {
            sign: !b.sign,
            num: b.num,
            den: b.den,
        };
        bf_add(a, &neg_b)
    }

    // Multiply two BigFloats
    public fun bf_mul(a: &BigFloat, b: &BigFloat): BigFloat {
        let mut result = BigFloat {
            sign: a.sign == b.sign,
            num: bigint::bi_mul(&a.num, &b.num),
            den: bigint::bi_mul(&a.den, &b.den),
        };
        bf_reduce(&mut result);
        result
    }

    // Divide a by b
    public fun bf_div(a: &BigFloat, b: &BigFloat): BigFloat {
        assert!(!bigint::bi_is_zero(&b.num), ErrDivisionByZero);
        
        let mut result = BigFloat {
            sign: a.sign == b.sign,
            num: bigint::bi_mul(&a.num, &b.den),
            den: bigint::bi_mul(&a.den, &b.num),
        };
        bf_reduce(&mut result);
        result
    }

    // Convert BigFloat to u64 (truncate toward zero)
    public fun bf_to_u64_trunc(x: &BigFloat): Option<u64> {
        if (!x.sign) {
            return option::none() // negative
        };

        if (bigint::bi_is_zero(&x.num)) {
            return option::some(0)
        };

        let (quotient, _) = bigint::bi_divmod(&x.num, &x.den);
        bigint::bi_to_u64(&quotient)
    }
}