module bignum::bigint {
    // BigInt: arbitrary-precision unsigned integer using base 2^32 limbs
    public struct BigInt has copy, drop, store {
        limbs: vector<u32>, // least significant limb first
    }

    // Error codes
    const ErrDivisionByZero: u64 = 1;
    const ErrInvalidConversion: u64 = 2;

    // === BigInt Implementation ===

    // Create a BigInt from u64
    public fun bi_from_u64(value: u64): BigInt {
        if (value == 0) {
            return BigInt { limbs: vector[0] }
        };

        let mut limbs = vector::empty<u32>();
        let low = (value as u32);
        let high = ((value >> 32) as u32);

        vector::push_back(&mut limbs, low);
        if (high != 0) {
            vector::push_back(&mut limbs, high);
        };

        BigInt { limbs }
    }

    // Create zero BigInt
    public fun bi_zero(): BigInt {
        BigInt { limbs: vector[0] }
    }

    // Create one BigInt
    public fun bi_one(): BigInt {
        BigInt { limbs: vector[1] }
    }

    // Check if BigInt is zero
    public fun bi_is_zero(x: &BigInt): bool {
        vector::length(&x.limbs) == 1 && *vector::borrow(&x.limbs, 0) == 0
    }

    // Normalize BigInt (remove leading zeros)
    fun bi_normalize(x: &mut BigInt) {
        while (vector::length(&x.limbs) > 1) {
            let last_idx = vector::length(&x.limbs) - 1;
            if (*vector::borrow(&x.limbs, last_idx) == 0) {
                vector::pop_back(&mut x.limbs);
            } else {
                break
            }
        }
    }

    // Compare two BigInts: 0 = equal, 1 = a > b, 2 = a < b
    public fun bi_cmp(a: &BigInt, b: &BigInt): u8 {
        let a_len = vector::length(&a.limbs);
        let b_len = vector::length(&b.limbs);

        if (a_len < b_len) return 2;
        if (a_len > b_len) return 1;

        let mut i = a_len;
        while (i > 0) {
            i = i - 1;
            let a_limb = *vector::borrow(&a.limbs, i);
            let b_limb = *vector::borrow(&b.limbs, i);
            if (a_limb > b_limb) return 1;
            if (a_limb < b_limb) return 2;
        };
        0
    }

    // Add two BigInts
    public fun bi_add(a: &BigInt, b: &BigInt): BigInt {
        let mut result_limbs = vector::empty<u32>();
        let mut carry: u64 = 0;
        let mut i = 0;
        let max_len = if (vector::length(&a.limbs) > vector::length(&b.limbs)) {
            vector::length(&a.limbs)
        } else {
            vector::length(&b.limbs)
        };

        while (i < max_len || carry > 0) {
            let a_limb = if (i < vector::length(&a.limbs)) {
                (*vector::borrow(&a.limbs, i) as u64)
            } else { 0 };
            let b_limb = if (i < vector::length(&b.limbs)) {
                (*vector::borrow(&b.limbs, i) as u64)
            } else { 0 };

            let sum = a_limb + b_limb + carry;
            vector::push_back(&mut result_limbs, (sum as u32));
            carry = sum >> 32;
            i = i + 1;
        };

        let mut result = BigInt { limbs: result_limbs };
        bi_normalize(&mut result);
        result
    }

    // Subtract b from a (assumes a >= b)
    public fun bi_sub(a: &BigInt, b: &BigInt): BigInt {
        assert!(bi_cmp(a, b) != 2, ErrInvalidConversion); // a >= b

        let mut result_limbs = vector::empty<u32>();
        let mut borrow: u64 = 0;
        let mut i = 0;

        while (i < vector::length(&a.limbs)) {
            let a_limb = (*vector::borrow(&a.limbs, i) as u64);
            let b_limb = if (i < vector::length(&b.limbs)) {
                (*vector::borrow(&b.limbs, i) as u64)
            } else { 0 };

            if (a_limb >= b_limb + borrow) {
                let diff = a_limb - b_limb - borrow;
                vector::push_back(&mut result_limbs, (diff as u32));
                borrow = 0;
            } else {
                let diff = a_limb + (1u64 << 32) - b_limb - borrow;
                vector::push_back(&mut result_limbs, (diff as u32));
                borrow = 1;
            };
            i = i + 1;
        };

        let mut result = BigInt { limbs: result_limbs };
        bi_normalize(&mut result);
        result
    }

    // Multiply two BigInts
    public fun bi_mul(a: &BigInt, b: &BigInt): BigInt {
        if (bi_is_zero(a) || bi_is_zero(b)) {
            return bi_zero()
        };

        let result_len = vector::length(&a.limbs) + vector::length(&b.limbs);
        let mut result_limbs = vector::empty<u32>();
        let mut k = 0;
        while (k < result_len) {
            vector::push_back(&mut result_limbs, 0);
            k = k + 1;
        };

        let mut i = 0;
        while (i < vector::length(&a.limbs)) {
            let mut carry: u64 = 0;
            let mut j = 0;
            while (j < vector::length(&b.limbs)) {
                let a_limb = (*vector::borrow(&a.limbs, i) as u64);
                let b_limb = (*vector::borrow(&b.limbs, j) as u64);
                let current = (*vector::borrow(&result_limbs, i + j) as u64);
                
                let prod = a_limb * b_limb + current + carry;
                *vector::borrow_mut(&mut result_limbs, i + j) = (prod as u32);
                carry = prod >> 32;
                j = j + 1;
            };
            if (carry > 0 && i + j < result_len) {
                *vector::borrow_mut(&mut result_limbs, i + j) = (carry as u32);
            };
            i = i + 1;
        };

        let mut result = BigInt { limbs: result_limbs };
        bi_normalize(&mut result);
        result
    }

    // Divide a by b, returning (quotient, remainder)
    public fun bi_divmod(a: &BigInt, b: &BigInt): (BigInt, BigInt) {
        assert!(!bi_is_zero(b), ErrDivisionByZero);

        if (bi_cmp(a, b) == 2) { // a < b
            return (bi_zero(), *a)
        };

        if (bi_cmp(a, b) == 0) { // a == b
            return (bi_one(), bi_zero())
        };

        // Simple long division algorithm
        let mut quotient = bi_zero();
        let mut remainder = *a;

        while (bi_cmp(&remainder, b) != 2) { // remainder >= b
            remainder = bi_sub(&remainder, b);
            quotient = bi_add(&quotient, &bi_one());
        };

        (quotient, remainder)
    }

    // Convert BigInt to u64 (returns option)
    public fun bi_to_u64(x: &BigInt): Option<u64> {
        if (bi_is_zero(x)) {
            return option::some(0)
        };

        let len = vector::length(&x.limbs);
        if (len > 2) {
            return option::none()
        };

        if (len == 1) {
            return option::some((*vector::borrow(&x.limbs, 0) as u64))
        };

        // len == 2
        let low = (*vector::borrow(&x.limbs, 0) as u64);
        let high = (*vector::borrow(&x.limbs, 1) as u64);
        option::some((high << 32) | low)
    }

    // GCD using Euclidean algorithm
    public fun bi_gcd(a: &BigInt, b: &BigInt): BigInt {
        let mut x = *a;
        let mut y = *b;

        while (!bi_is_zero(&y)) {
            let (_, remainder) = bi_divmod(&x, &y);
            x = y;
            y = remainder;
        };
        x
    }
}