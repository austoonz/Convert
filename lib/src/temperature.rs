//! Temperature conversion functions (Fahrenheit/Celsius)

use std::os::raw::c_double;

/// Convert Fahrenheit to Celsius
///
/// Formula: C = (F - 32) * 5/9
///
/// # Arguments
/// * `fahrenheit` - Temperature in Fahrenheit
///
/// # Returns
/// Temperature in Celsius
///
/// # Safety
/// This function performs simple arithmetic and has no unsafe operations.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn fahrenheit_to_celsius(fahrenheit: c_double) -> c_double {
    (fahrenheit - 32.0) * 5.0 / 9.0
}

/// Convert Celsius to Fahrenheit
///
/// Formula: F = C * 9/5 + 32
///
/// # Arguments
/// * `celsius` - Temperature in Celsius
///
/// # Returns
/// Temperature in Fahrenheit
///
/// # Safety
/// This function performs simple arithmetic and has no unsafe operations.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn celsius_to_fahrenheit(celsius: c_double) -> c_double {
    celsius * 9.0 / 5.0 + 32.0
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    #[test]
    fn test_fahrenheit_to_celsius_freezing_point() {
        // Test: 32°F should equal 0°C (freezing point of water)
        let result = unsafe { fahrenheit_to_celsius(32.0) };
        assert_eq!(result, 0.0, "32°F should convert to 0°C");
    }

    #[test]
    fn test_fahrenheit_to_celsius_boiling_point() {
        // Test: 212°F should equal 100°C (boiling point of water)
        let result = unsafe { fahrenheit_to_celsius(212.0) };
        assert_eq!(result, 100.0, "212°F should convert to 100°C");
    }

    #[test]
    fn test_fahrenheit_to_celsius_body_temperature() {
        // Test: 98.6°F should equal 37°C (normal body temperature)
        let result = unsafe { fahrenheit_to_celsius(98.6) };
        assert_eq!(result, 37.0, "98.6°F should convert to 37°C");
    }

    #[test]
    fn test_fahrenheit_to_celsius_negative_temperature() {
        // Test: -40°F should equal -40°C (same value in both scales)
        let result = unsafe { fahrenheit_to_celsius(-40.0) };
        assert_eq!(result, -40.0, "-40°F should convert to -40°C");
    }

    #[test]
    fn test_fahrenheit_to_celsius_zero() {
        // Test: 0°F should equal approximately -17.78°C
        let result = unsafe { fahrenheit_to_celsius(0.0) };
        let expected = -17.77777777777778;
        assert!(
            (result - expected).abs() < 0.0001,
            "0°F should convert to approximately -17.78°C, got {}",
            result
        );
    }

    #[test]
    fn test_celsius_to_fahrenheit_freezing_point() {
        // Test: 0°C should equal 32°F (freezing point of water)
        let result = unsafe { celsius_to_fahrenheit(0.0) };
        assert_eq!(result, 32.0, "0°C should convert to 32°F");
    }

    #[test]
    fn test_celsius_to_fahrenheit_boiling_point() {
        // Test: 100°C should equal 212°F (boiling point of water)
        let result = unsafe { celsius_to_fahrenheit(100.0) };
        assert_eq!(result, 212.0, "100°C should convert to 212°F");
    }

    #[test]
    fn test_celsius_to_fahrenheit_body_temperature() {
        // Test: 37°C should equal 98.6°F (normal body temperature)
        let result = unsafe { celsius_to_fahrenheit(37.0) };
        assert_eq!(result, 98.6, "37°C should convert to 98.6°F");
    }

    #[test]
    fn test_celsius_to_fahrenheit_negative_temperature() {
        // Test: -40°C should equal -40°F (same value in both scales)
        let result = unsafe { celsius_to_fahrenheit(-40.0) };
        assert_eq!(result, -40.0, "-40°C should convert to -40°F");
    }

    #[test]
    fn test_celsius_to_fahrenheit_negative_cold() {
        // Test: -20°C should equal -4°F
        let result = unsafe { celsius_to_fahrenheit(-20.0) };
        assert_eq!(result, -4.0, "-20°C should convert to -4°F");
    }

    // ===== Property-Based Tests =====

    proptest! {
        /// Property: Round-trip conversion (C->F->C) should preserve the original value
        #[test]
        fn prop_round_trip_celsius(celsius in -273.15f64..1000.0f64) {
            let fahrenheit = unsafe { celsius_to_fahrenheit(celsius) };
            let back_to_celsius = unsafe { fahrenheit_to_celsius(fahrenheit) };

            // Allow small floating-point error
            prop_assert!((back_to_celsius - celsius).abs() < 0.0001,
                "Round-trip C->F->C failed: {} -> {} -> {}",
                celsius, fahrenheit, back_to_celsius);
        }

        /// Property: Round-trip conversion (F->C->F) should preserve the original value
        #[test]
        fn prop_round_trip_fahrenheit(fahrenheit in -459.67f64..1832.0f64) {
            let celsius = unsafe { fahrenheit_to_celsius(fahrenheit) };
            let back_to_fahrenheit = unsafe { celsius_to_fahrenheit(celsius) };

            // Allow small floating-point error
            prop_assert!((back_to_fahrenheit - fahrenheit).abs() < 0.0001,
                "Round-trip F->C->F failed: {} -> {} -> {}",
                fahrenheit, celsius, back_to_fahrenheit);
        }

        /// Property: Celsius to Fahrenheit is a linear transformation
        /// If C2 > C1, then F2 > F1 (monotonicity)
        #[test]
        fn prop_celsius_to_fahrenheit_monotonic(c1 in -273.15f64..999.0f64, delta in 0.1f64..100.0f64) {
            let c2 = c1 + delta;
            let f1 = unsafe { celsius_to_fahrenheit(c1) };
            let f2 = unsafe { celsius_to_fahrenheit(c2) };

            prop_assert!(f2 > f1,
                "Monotonicity violated: C({}) -> F({}) but C({}) -> F({})",
                c1, f1, c2, f2);
        }

        /// Property: Fahrenheit to Celsius is a linear transformation
        /// If F2 > F1, then C2 > C1 (monotonicity)
        #[test]
        fn prop_fahrenheit_to_celsius_monotonic(f1 in -459.67f64..1831.0f64, delta in 0.1f64..100.0f64) {
            let f2 = f1 + delta;
            let c1 = unsafe { fahrenheit_to_celsius(f1) };
            let c2 = unsafe { fahrenheit_to_celsius(f2) };

            prop_assert!(c2 > c1,
                "Monotonicity violated: F({}) -> C({}) but F({}) -> C({})",
                f1, c1, f2, c2);
        }

        /// Property: The difference between two temperatures should scale correctly
        /// If ΔC = 1, then ΔF = 1.8 (since F = C * 9/5 + 32)
        #[test]
        fn prop_temperature_difference_scaling(c1 in -273.15f64..999.0f64) {
            let c2 = c1 + 1.0;
            let f1 = unsafe { celsius_to_fahrenheit(c1) };
            let f2 = unsafe { celsius_to_fahrenheit(c2) };
            let delta_f = f2 - f1;

            // 1°C difference = 1.8°F difference
            prop_assert!((delta_f - 1.8).abs() < 0.0001,
                "Temperature difference scaling failed: ΔC=1 should give ΔF=1.8, got {}",
                delta_f);
        }

        /// Property: Absolute zero in Celsius (-273.15°C) equals absolute zero in Fahrenheit (-459.67°F)
        #[test]
        fn prop_absolute_zero_relationship(offset in 0.0f64..100.0f64) {
            let celsius = -273.15 + offset;
            let fahrenheit = unsafe { celsius_to_fahrenheit(celsius) };
            let expected_fahrenheit = -459.67 + (offset * 1.8);

            prop_assert!((fahrenheit - expected_fahrenheit).abs() < 0.0001,
                "Absolute zero relationship failed: {}°C should be {}°F, got {}°F",
                celsius, expected_fahrenheit, fahrenheit);
        }

        /// Property: Converting the same temperature twice should yield the same result (idempotency)
        #[test]
        fn prop_conversion_idempotent(celsius in -273.15f64..1000.0f64) {
            let f1 = unsafe { celsius_to_fahrenheit(celsius) };
            let f2 = unsafe { celsius_to_fahrenheit(celsius) };

            prop_assert_eq!(f1, f2,
                "Conversion not idempotent: {}°C gave {}°F and {}°F",
                celsius, f1, f2);
        }
    }
}
