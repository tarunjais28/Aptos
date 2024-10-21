module utils::i64 {
    use utils::error;

    /// Maximum positive magnitude for I64
    const MAX_POSITIVE_MAGNITUDE: u64 = (1 << 63) - 1;
    // Maximum negative magnitude for I64
    const MAX_NEGATIVE_MAGNITUDE: u64 = (1 << 63);

    /// Define a struct named `I64` with copy, drop, and store attributes
    struct I64 has copy, drop, store {
        // Boolean flag indicating whether the number is negative
        negative: bool,
        // Magnitude of the number
        magnitude: u64,
    }

    /// Function to create a new instance of `I64`
    public fun new(magnitude: u64, negative: bool): I64 {
        // Determine the maximum magnitude based on whether the number is negative
        let max_magnitude = if (negative) { MAX_NEGATIVE_MAGNITUDE } else { MAX_POSITIVE_MAGNITUDE };
        assert!(magnitude <= max_magnitude, error::magnitude_too_large());

        // Ensure a single zero representation: (0, false). (0, true) is invalid.
        if (magnitude == 0) {
            negative = false;
        };

        // Return a new instance of `I64`
        I64 {
            magnitude,
            negative,
        }
    }

    /// Function to retrieve the sign of the number from an `I64` instance
    public fun get_is_negative(i: &I64): bool {
        // Return the sign (negative) of the number
        i.negative
    }

    /// Function to retrieve the magnitude of the number if it's positive
    public fun get_magnitude_if_positive(in: &I64): u64 {
        assert!(!in.negative, error::negative_value());
        // Return the magnitude of the positive number
        in.magnitude
    }

    /// Function to retrieve the magnitude of the number if it's negative
    public fun get_magnitude_if_negative(in: &I64): u64 {
        assert!(in.negative, error::positive_value());
        // Return the magnitude of the negative number
        in.magnitude
    }

    /// Function to create an `I64` instance from a `u64` number
    public fun from_u64(from: u64): I64 {
        // Use the MSB to determine whether the number is negative or not
        let negative = (from >> 63) == 1;
        // Parse the magnitude of the number
        let magnitude = parse_magnitude(from, negative);

        // Create and return a new instance of `I64`
        new(magnitude, negative)
    }

    /// Helper function to parse the magnitude of the number
    fun parse_magnitude(from: u64, negative: bool): u64 {
        // If positive, return the input verbatim
        if (!negative) {
            return from
        };

        // Otherwise, convert from two's complement by inverting and adding 1
        let inverted = from ^ 0xFFFFFFFFFFFFFFFF;
        inverted + 1
    }

    // Test to ensure that the maximum positive magnitude for I64 can be created
    #[test]
    fun test_max_positive_magnitude() {
        // Create an instance with the maximum positive magnitude
        new(0x7FFFFFFFFFFFFFFF, false);
        // Assert that the result from `from_u64` matches the expected value
        assert!(&new(1<<63 - 1, false) == &from_u64(1<<63 - 1), 1);
    }

    // Test to ensure that attempting to create a magnitude larger than the maximum allowed for positive numbers fails
    #[test]
    #[expected_failure(abort_code = 65539, location = Self)]
    fun test_magnitude_too_large_positive() {
        // Attempt to create an instance with a magnitude larger than the maximum allowed for positive numbers
        new(0x8000000000000000, false);
    }

    // Test to ensure that the maximum negative magnitude for I64 can be created
    #[test]
    fun test_max_negative_magnitude() {
        // Create an instance with the maximum negative magnitude
        new(0x8000000000000000, true);
        // Assert that the result from `from_u64` matches the expected value
        assert!(&new(1<<63, true) == &from_u64(1<<63), 1);
    }

    // Test to ensure that attempting to create a magnitude larger than the maximum allowed for negative numbers fails
    #[test]
    #[expected_failure(abort_code = 65539, location = Self)]
    fun test_magnitude_too_large_negative() {
        // Attempt to create an instance with a magnitude larger than the maximum allowed for negative numbers
        new(0x8000000000000001, true);
    }

    // Test to ensure that an `I64` instance can be created from a positive `u64` number
    #[test]
    fun test_from_u64_positive() {
        // Assert that the result from `from_u64` matches the expected value
        assert!(from_u64(0x64673) == new(0x64673, false), 1);
    }

    // Test to ensure that an `I64` instance can be created from a negative `u64` number
    #[test]
    fun test_from_u64_negative() {
        // Assert that the result from `from_u64` matches the expected value
        assert!(from_u64(0xFFFFFFFFFFFEDC73) == new(0x1238D, true), 1);
    }

    // Test to ensure that the `get_is_negative` function returns the correct result
    #[test]
    fun test_get_is_negative() {
        // Assert that the result from `get_is_negative` matches the expected value for both positive and negative numbers
        assert!(get_is_negative(&new(234, true)) == true, 1);
        assert!(get_is_negative(&new(767, false)) == false, 1);
    }

    // Test to ensure that the `get_magnitude_if_positive` function returns the correct magnitude for positive numbers
    #[test]
    fun test_get_magnitude_if_positive_positive() {
        // Assert that the result from `get_magnitude_if_positive` matches the expected value for a positive number
        assert!(get_magnitude_if_positive(&new(7686, false)) == 7686, 1);
    }

    // Test to ensure that attempting to get the magnitude for a negative number using `get_magnitude_if_positive`
    // fails
    #[test]
    #[expected_failure(abort_code = 196609, location = Self)]
    fun test_get_magnitude_if_positive_negative() {
        // Attempt to get the magnitude for a negative number using `get_magnitude_if_positive`
        assert!(get_magnitude_if_positive(&new(7686, true)) == 7686, 1);
    }

    // Test to ensure that the `get_magnitude_if_negative` function returns the correct magnitude for negative numbers
    #[test]
    fun test_get_magnitude_if_negative_negative() {
        // Assert that the result from `get_magnitude_if_negative` matches the expected value for a negative number
        assert!(get_magnitude_if_negative(&new(7686, true)) == 7686, 1);
    }

    // Test to ensure that attempting to get the magnitude for a positive number using `get_magnitude_if_negative`
    // fails
    #[test]
    #[expected_failure(abort_code = 196610, location = Self)]
    fun test_get_magnitude_if_negative_positive() {
        // Attempt to get the magnitude for a positive number using `get_magnitude_if_negative`
        assert!(get_magnitude_if_negative(&new(7686, false)) == 7686, 1);
    }

    // Test to ensure that instances with zero magnitude, both positive and negative, are equal
    #[test]
    fun test_single_zero_representation() {
        assert!(&new(0, true) == &new(0, false), 1);
        // Assert that instances with zero magnitude, both positive and negative, created from u64 are equal
        assert!(&new(0, true) == &from_u64(0), 1);
        assert!(&new(0, false) == &from_u64(0), 1);
    }

}
