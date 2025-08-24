#[test_only]
module bignum::bigfloat_tests {
    use bignum::bigfloat::{
        bf_from_u64, bf_from_ratio_u64, bf_zero, bf_add, bf_sub, bf_mul, bf_div, bf_to_u64_trunc, bf_eq
    };
    use bignum::bigint::{
        bi_from_u64, bi_add, bi_sub, bi_mul, bi_divmod, bi_to_u64,
    };

    #[test]
    fun test_bigint_basic() {
        let a = bi_from_u64(123);
        let b = bi_from_u64(456);
        
        let sum = bi_add(&a, &b);
        assert!(option::extract(&mut bi_to_u64(&sum)) == 579, 1);
        
        let diff = bi_sub(&b, &a);
        assert!(option::extract(&mut bi_to_u64(&diff)) == 333, 2);
        
        let prod = bi_mul(&a, &b);
        assert!(option::extract(&mut bi_to_u64(&prod)) == 56088, 3);
        
        let (quotient, remainder) = bi_divmod(&b, &a);
        assert!(option::extract(&mut bi_to_u64(&quotient)) == 3, 4);
        assert!(option::extract(&mut bi_to_u64(&remainder)) == 87, 5);
    }

    #[test]
    fun test_bigfloat_basic() {
        let a = bf_from_u64(10);
        let b = bf_from_u64(20);
        
        let sum = bf_add(&a, &b);
        assert!(option::extract(&mut bf_to_u64_trunc(&sum)) == 30, 1);
        
        let diff = bf_sub(&b, &a);
        assert!(option::extract(&mut bf_to_u64_trunc(&diff)) == 10, 2);
        
        let prod = bf_mul(&a, &b);
        assert!(option::extract(&mut bf_to_u64_trunc(&prod)) == 200, 3);
        
        let quotient = bf_div(&b, &a);
        assert!(option::extract(&mut bf_to_u64_trunc(&quotient)) == 2, 4);
    }

    #[test]
    fun test_bigfloat_fractions() {
        let one = bf_from_u64(1);
        let two = bf_from_u64(2);
        let three = bf_from_u64(3);
        
        // 1/2
        let half = bf_div(&one, &two);
        
        // 1/3  
        let third = bf_div(&one, &three);
        
        // 1/2 + 1/3 = 5/6
        let sum = bf_add(&half, &third);
        
        // Should truncate to 0
        assert!(option::extract(&mut bf_to_u64_trunc(&sum)) == 0, 1);
        
        // 5/6 + 5/6 = 10/6 = 5/3, should truncate to 1
        let double_sum = bf_add(&sum, &sum);
        assert!(option::extract(&mut bf_to_u64_trunc(&double_sum)) == 1, 2);
    }

    #[test]
    fun test_bigfloat_zero() {
        let zero = bf_zero();
        let nonzero = bf_from_u64(42);
        
        let sum = bf_add(&zero, &nonzero);
        assert!(option::extract(&mut bf_to_u64_trunc(&sum)) == 42, 1);
        
        let prod = bf_mul(&zero, &nonzero);
        assert!(option::extract(&mut bf_to_u64_trunc(&prod)) == 0, 2);
    }

    #[test]
    fun test_bigfloat_negative() {
        let a = bf_from_u64(10);
        let b = bf_from_u64(20);
        
        // 10 - 20 = -10, should return none for u64 conversion
        let diff = bf_sub(&a, &b);
        assert!(option::is_none(&bf_to_u64_trunc(&diff)), 1);
    }

    #[test]
    fun test_bigfloat_from_ratio() {
        // Test 3/4 creation and comparison
        let three_fourths = bf_from_ratio_u64(3, 4);
        let expected_three_fourths = bf_from_ratio_u64(3, 4);
        assert!(bf_eq(&three_fourths, &expected_three_fourths), 1);
        
        // Test 8/4 = 2/1 (should auto-reduce)
        let eight_fourths = bf_from_ratio_u64(8, 4);
        let two_ones = bf_from_ratio_u64(2, 1);
        assert!(bf_eq(&eight_fourths, &two_ones), 2);
        
        // Test 0/5 = 0/1
        let zero = bf_from_ratio_u64(0, 5);
        let zero_expected = bf_zero();
        assert!(bf_eq(&zero, &zero_expected), 3);
        
        // Test arithmetic with ratios: 1/3 + 1/6 = 1/2
        let one_third = bf_from_ratio_u64(1, 3);
        let one_sixth = bf_from_ratio_u64(1, 6);
        let sum = bf_add(&one_third, &one_sixth);
        let expected_half = bf_from_ratio_u64(1, 2);
        // 1/3 + 1/6 = 2/6 + 1/6 = 3/6 = 1/2
        assert!(bf_eq(&sum, &expected_half), 4);
        
        // Test 6/9 = 2/3 (reduction)
        let six_ninths = bf_from_ratio_u64(6, 9);
        let two_thirds = bf_from_ratio_u64(2, 3);
        assert!(bf_eq(&six_ninths, &two_thirds), 5);
        
        // Test fraction multiplication: 1/2 * 2/3 = 2/6 = 1/3
        let half = bf_from_ratio_u64(1, 2);
        let two_thirds = bf_from_ratio_u64(2, 3);
        let product = bf_mul(&half, &two_thirds);
        let expected_third = bf_from_ratio_u64(1, 3);
        assert!(bf_eq(&product, &expected_third), 6);
    }
}