//! String to byte array encoding functions
//!
//! This module provides functions to convert strings to byte arrays using various
//! text encodings (UTF-8, ASCII, Unicode/UTF-16, UTF-32, BigEndianUnicode).
//! The encoding conversion logic is shared with the base64 module to ensure
//! consistent behavior across the library.

use std::ffi::CStr;
use std::os::raw::c_char;

/// Convert a string to a byte array using the specified encoding
///
/// Supports UTF-8, ASCII, Unicode (UTF-16LE), UTF-32, BigEndianUnicode (UTF-16BE),
/// and Default (UTF-8) encodings. The encoding name is case-insensitive and supports
/// both hyphenated (UTF-8) and non-hyphenated (UTF8) variants.
///
/// # Arguments
/// * `input` - Null-terminated C string to convert
/// * `encoding` - Null-terminated C string specifying the encoding
/// * `out_length` - Optional pointer to store the byte array length
///
/// # Returns
/// Pointer to allocated byte array, or null on error. The caller must free the
/// returned pointer using `free_bytes`.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - `out_length` is a valid pointer to a usize or null (optional)
/// - The returned pointer must be freed using `free_bytes`
///
/// # Error Handling
/// Returns null pointer and sets error message via `set_error` if:
/// - Input or encoding pointer is null
/// - Input or encoding contains invalid UTF-8
/// - Encoding name is not supported
/// - ASCII encoding is used with non-ASCII characters
#[unsafe(no_mangle)]
pub unsafe extern "C" fn string_to_bytes(
    input: *const c_char,
    encoding: *const c_char,
    out_length: *mut usize,
) -> *mut u8 {
    // Validate null pointers
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
        set_output_length_zero(out_length);
        return std::ptr::null_mut();
    }

    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        set_output_length_zero(out_length);
        return std::ptr::null_mut();
    }

    // SAFETY: Pointers are validated as non-null above
    // Convert C strings to Rust strings
    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            set_output_length_zero(out_length);
            return std::ptr::null_mut();
        }
    };

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            set_output_length_zero(out_length);
            return std::ptr::null_mut();
        }
    };

    // Check for deprecated UTF7 encoding (both UTF7 and UTF-7 variants)
    if encoding_str.eq_ignore_ascii_case("UTF7") || encoding_str.eq_ignore_ascii_case("UTF-7") {
        crate::error::set_error("UTF7 encoding is deprecated and not supported".to_string());
        set_output_length_zero(out_length);
        return std::ptr::null_mut();
    }

    // Convert string to bytes using shared encoding logic
    let bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            set_output_length_zero(out_length);
            return std::ptr::null_mut();
        }
    };

    // Set output length (only if pointer provided)
    let length = bytes.len();
    if !out_length.is_null() {
        // SAFETY: out_length is validated as non-null
        unsafe {
            *out_length = length;
        }
    }

    // Allocate byte array with metadata header for proper deallocation
    crate::error::clear_error();
    crate::memory::allocate_byte_array(bytes)
}

/// Helper function to set output length to zero
///
/// Safely sets the output length parameter to zero if the pointer is non-null.
/// This is used in error paths to ensure consistent behavior.
#[inline]
fn set_output_length_zero(out_length: *mut usize) {
    if !out_length.is_null() {
        // SAFETY: Pointer is validated as non-null
        unsafe {
            *out_length = 0;
        }
    }
}

/// Convert a byte array to a string using the specified encoding
///
/// Supports UTF-8, ASCII, Unicode (UTF-16LE), UTF-32, BigEndianUnicode (UTF-16BE),
/// and Default (UTF-8) encodings. The encoding name is case-insensitive and supports
/// both hyphenated (UTF-8) and non-hyphenated (UTF8) variants.
///
/// # Arguments
/// * `bytes` - Pointer to byte array to convert
/// * `length` - Length of the byte array
/// * `encoding` - Null-terminated C string specifying the encoding
///
/// # Returns
/// Pointer to allocated null-terminated C string, or null on error. The caller must
/// free the returned pointer using `free_string`.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `bytes` is a valid pointer to a byte array of at least `length` bytes, or null if length is 0
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
///
/// # Error Handling
/// Returns null pointer and sets error message via `set_error` if:
/// - Encoding pointer is null
/// - Encoding contains invalid UTF-8
/// - Encoding name is not supported
/// - Byte sequence is invalid for the specified encoding
#[unsafe(no_mangle)]
pub unsafe extern "C" fn bytes_to_string(
    bytes: *const u8,
    length: usize,
    encoding: *const c_char,
) -> *mut c_char {
    // Validate encoding pointer first (consistent with string_to_bytes)
    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }

    // SAFETY: encoding pointer is validated as non-null above
    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    // Handle empty byte array case
    if length == 0 {
        crate::error::clear_error();
        let empty = std::ffi::CString::new("").unwrap();
        return empty.into_raw();
    }

    // Validate bytes pointer (only needed when length > 0)
    if bytes.is_null() {
        crate::error::set_error("Bytes pointer is null".to_string());
        return std::ptr::null_mut();
    }

    // SAFETY: bytes pointer is validated as non-null and length is provided by caller
    let byte_slice = unsafe { std::slice::from_raw_parts(bytes, length) };

    // Check for deprecated UTF7 encoding (both UTF7 and UTF-7 variants)
    if encoding_str.eq_ignore_ascii_case("UTF7") || encoding_str.eq_ignore_ascii_case("UTF-7") {
        crate::error::set_error("UTF7 encoding is deprecated and not supported".to_string());
        return std::ptr::null_mut();
    }

    // Convert bytes to string using shared encoding logic
    let result_string = match crate::base64::convert_bytes_to_string(byte_slice, encoding_str) {
        Ok(s) => s,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    // Convert Rust string to C string
    match std::ffi::CString::new(result_string) {
        Ok(c_string) => {
            crate::error::clear_error();
            c_string.into_raw()
        }
        Err(_) => {
            crate::error::set_error("Result string contains null byte".to_string());
            std::ptr::null_mut()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    // ========== Tests for string_to_bytes ==========

    #[test]
    fn test_string_to_bytes_happy_path_utf8() {
        // Test: convert "Hello" with UTF8 encoding to byte array [72, 101, 108, 108, 111]
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 5, "Output length should be 5 bytes");

        let byte_slice = unsafe { std::slice::from_raw_parts(result, out_length) };
        assert_eq!(
            byte_slice,
            &[72, 101, 108, 108, 111],
            "Bytes should be [72, 101, 108, 108, 111] (Hello)"
        );

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_null_input_pointer() {
        // Test: null input pointer should return null
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                std::ptr::null(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(result.is_null(), "Null input pointer should return null");
        assert_eq!(out_length, 0, "Output length should be 0 for null input");
    }

    #[test]
    fn test_string_to_bytes_null_encoding_pointer() {
        // Test: null encoding pointer should return null
        let input = CString::new("Hello").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                std::ptr::null(),
                &mut out_length as *mut usize,
            )
        };

        assert!(result.is_null(), "Null encoding pointer should return null");
        assert_eq!(out_length, 0, "Output length should be 0 for null encoding");
    }

    #[test]
    fn test_string_to_bytes_all_supported_encodings() {
        // Test: all supported encodings should work
        let input = CString::new("Test").unwrap();
        let encodings = vec![
            "UTF8",
            "ASCII",
            "Unicode",
            "UTF32",
            "BigEndianUnicode",
            "Default",
        ];

        for enc in encodings {
            let encoding = CString::new(enc).unwrap();
            let mut out_length: usize = 0;

            let result = unsafe {
                string_to_bytes(
                    input.as_ptr(),
                    encoding.as_ptr(),
                    &mut out_length as *mut usize,
                )
            };

            assert!(
                !result.is_null(),
                "Result should not be null for encoding: {}",
                enc
            );
            assert!(
                out_length > 0,
                "Output length should be > 0 for encoding: {}",
                enc
            );

            unsafe { crate::memory::free_bytes(result) };
        }
    }

    #[test]
    fn test_string_to_bytes_utf7_deprecated() {
        // Test: UTF7 encoding should return null (deprecated)
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF7").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(result.is_null(), "UTF7 encoding should return null (deprecated)");
        assert_eq!(out_length, 0, "Output length should be 0 for UTF7");
    }

    #[test]
    fn test_string_to_bytes_invalid_encoding() {
        // Test: invalid encoding name should return null
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(result.is_null(), "Invalid encoding should return null");
        assert_eq!(
            out_length, 0,
            "Output length should be 0 for invalid encoding"
        );
    }

    #[test]
    fn test_string_to_bytes_empty_string() {
        // Test: empty string should encode successfully
        let input = CString::new("").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            !result.is_null(),
            "Result should not be null for empty string"
        );
        assert_eq!(out_length, 0, "Output length should be 0 for empty string");

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_large_string() {
        // Test: 1MB string should encode successfully
        let large_string = "A".repeat(1024 * 1024); // 1MB of 'A' characters
        let input = CString::new(large_string).unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            !result.is_null(),
            "Result should not be null for large string"
        );
        assert_eq!(out_length, 1024 * 1024, "Output length should be 1MB");

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_utf8_encoding() {
        // Test: UTF8 encoding produces correct bytes
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 5, "UTF8 'Hello' should be 5 bytes");

        let bytes = unsafe { std::slice::from_raw_parts(result, out_length) };
        assert_eq!(bytes, &[72, 101, 108, 108, 111]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_ascii_encoding() {
        // Test: ASCII encoding produces correct bytes
        let input = CString::new("ABC").unwrap();
        let encoding = CString::new("ASCII").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 3, "ASCII 'ABC' should be 3 bytes");

        let bytes = unsafe { std::slice::from_raw_parts(result, out_length) };
        assert_eq!(bytes, &[65, 66, 67]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_unicode_encoding() {
        // Test: Unicode (UTF-16LE) encoding produces correct bytes
        let input = CString::new("A").unwrap(); // 'A' = U+0041
        let encoding = CString::new("Unicode").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 2, "Unicode 'A' should be 2 bytes");

        let bytes = unsafe { std::slice::from_raw_parts(result, out_length) };
        // UTF-16LE: 'A' (U+0041) = [0x41, 0x00]
        assert_eq!(bytes, &[0x41, 0x00]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_utf32_encoding() {
        // Test: UTF32 encoding produces correct bytes
        let input = CString::new("A").unwrap(); // 'A' = U+0041
        let encoding = CString::new("UTF32").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 4, "UTF32 'A' should be 4 bytes");

        let bytes = unsafe { std::slice::from_raw_parts(result, out_length) };
        // UTF-32LE: 'A' (U+0041) = [0x41, 0x00, 0x00, 0x00]
        assert_eq!(bytes, &[0x41, 0x00, 0x00, 0x00]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_bigendian_unicode_encoding() {
        // Test: BigEndianUnicode (UTF-16BE) encoding produces correct bytes
        let input = CString::new("A").unwrap(); // 'A' = U+0041
        let encoding = CString::new("BigEndianUnicode").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 2, "BigEndianUnicode 'A' should be 2 bytes");

        let bytes = unsafe { std::slice::from_raw_parts(result, out_length) };
        // UTF-16BE: 'A' (U+0041) = [0x00, 0x41]
        assert_eq!(bytes, &[0x00, 0x41]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_default_encoding() {
        // Test: Default encoding should behave like UTF8
        let input = CString::new("Test").unwrap();
        let encoding = CString::new("Default").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 4, "Default 'Test' should be 4 bytes (UTF8)");

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_special_characters() {
        // Test: string with special characters
        let input = CString::new("Hello, World!").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            !result.is_null(),
            "Result should not be null for special characters"
        );
        assert_eq!(out_length, 13, "UTF8 'Hello, World!' should be 13 bytes");

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_unicode_characters() {
        // Test: string with Unicode characters (emoji)
        let input = CString::new("Hello 🌍").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            !result.is_null(),
            "Result should not be null for Unicode characters"
        );
        // "Hello " = 6 bytes, 🌍 = 4 bytes in UTF8
        assert_eq!(out_length, 10, "UTF8 'Hello 🌍' should be 10 bytes");

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_null_output_length_pointer() {
        // Test: null output length pointer should be allowed (optional parameter)
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result =
            unsafe { string_to_bytes(input.as_ptr(), encoding.as_ptr(), std::ptr::null_mut()) };

        assert!(
            !result.is_null(),
            "Should succeed with null out_length pointer"
        );

        // Verify the data is correct
        let data = unsafe { std::slice::from_raw_parts(result, 5) };
        assert_eq!(data, &[72, 101, 108, 108, 111]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_case_insensitive_encoding() {
        // Test: encoding names should be case-insensitive
        let input = CString::new("Test").unwrap();
        let encoding_variants = vec!["utf8", "UTF8", "Utf8", "ascii", "ASCII"];

        for enc in encoding_variants {
            let encoding = CString::new(enc).unwrap();
            let mut out_length: usize = 0;

            let result = unsafe {
                string_to_bytes(
                    input.as_ptr(),
                    encoding.as_ptr(),
                    &mut out_length as *mut usize,
                )
            };

            assert!(
                !result.is_null(),
                "Encoding '{}' should be recognized (case-insensitive)",
                enc
            );

            unsafe { crate::memory::free_bytes(result) };
        }
    }

    #[test]
    fn test_string_to_bytes_encoding_with_hyphens() {
        // Test: encoding names with hyphens should work
        let input = CString::new("Test").unwrap();
        let encoding_variants = vec!["UTF-8", "UTF-16", "UTF-32"];

        for enc in encoding_variants {
            let encoding = CString::new(enc).unwrap();
            let mut out_length: usize = 0;

            let result = unsafe {
                string_to_bytes(
                    input.as_ptr(),
                    encoding.as_ptr(),
                    &mut out_length as *mut usize,
                )
            };

            assert!(!result.is_null(), "Encoding '{}' should work", enc);

            unsafe { crate::memory::free_bytes(result) };
        }
    }

    #[test]
    fn test_string_to_bytes_ascii_rejects_non_ascii() {
        // Test: ASCII encoding should reject strings with non-ASCII characters
        let input = CString::new("Café").unwrap(); // Contains accented character
        let encoding = CString::new("ASCII").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            string_to_bytes(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            result.is_null(),
            "ASCII encoding should reject non-ASCII string"
        );
        assert_eq!(
            out_length, 0,
            "Output length should be 0 for rejected input"
        );
    }

    #[test]
    fn test_string_to_bytes_various_lengths() {
        // Test: various string lengths encode correctly
        let test_cases = vec![
            ("", 0),             // Empty string
            ("A", 1),            // Single character
            ("AB", 2),           // Two characters
            ("ABC", 3),          // Three characters
            ("Test String", 11), // Multi-word string
        ];

        let encoding = CString::new("UTF8").unwrap();

        for (test_str, expected_length) in test_cases {
            let input = CString::new(test_str).unwrap();
            let mut out_length: usize = 0;

            let result = unsafe {
                string_to_bytes(
                    input.as_ptr(),
                    encoding.as_ptr(),
                    &mut out_length as *mut usize,
                )
            };

            assert!(
                !result.is_null(),
                "Result should not be null for input '{}'",
                test_str
            );
            assert_eq!(
                out_length, expected_length,
                "Output length should be {} for input '{}'",
                expected_length, test_str
            );

            unsafe { crate::memory::free_bytes(result) };
        }
    }

    #[test]
    fn test_string_to_bytes_concurrent_operations() {
        use std::thread;

        // Test: multiple threads using string_to_bytes concurrently
        let handles: Vec<_> = (0..10)
            .map(|i| {
                thread::spawn(move || {
                    let input = CString::new(format!("test{}", i)).unwrap();
                    let encoding = CString::new("UTF8").unwrap();
                    let mut out_length: usize = 0;

                    let result = unsafe {
                        string_to_bytes(
                            input.as_ptr(),
                            encoding.as_ptr(),
                            &mut out_length as *mut usize,
                        )
                    };
                    assert!(!result.is_null(), "Encoding should succeed in thread {}", i);
                    assert!(
                        out_length > 0,
                        "Output length should be > 0 in thread {}",
                        i
                    );

                    unsafe { crate::memory::free_bytes(result) };
                })
            })
            .collect();

        for handle in handles {
            handle.join().unwrap();
        }
    }

    // ========== Tests for bytes_to_string ==========

    #[test]
    fn test_bytes_to_string_happy_path_utf8() {
        // Test: convert [72, 101, 108, 108, 111] with UTF8 encoding to "Hello"
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(!result.is_null(), "Result should not be null");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "Hello", "Should decode to 'Hello'");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_empty_bytes() {
        // Test: empty byte array should return empty string
        let bytes: [u8; 0] = [];
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), 0, encoding.as_ptr()) };

        assert!(!result.is_null(), "Result should not be null for empty bytes");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Should return empty string");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_null_bytes_with_length() {
        // Test: null bytes pointer with non-zero length should return null
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(std::ptr::null(), 5, encoding.as_ptr()) };

        assert!(result.is_null(), "Null bytes with length > 0 should return null");
    }

    #[test]
    fn test_bytes_to_string_null_bytes_with_zero_length() {
        // Test: null bytes pointer with zero length should succeed (edge case)
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(std::ptr::null(), 0, encoding.as_ptr()) };

        assert!(!result.is_null(), "Null bytes with length 0 should succeed");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Should return empty string");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_null_encoding() {
        // Test: null encoding pointer should return null
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), std::ptr::null()) };

        assert!(result.is_null(), "Null encoding should return null");
    }

    #[test]
    fn test_bytes_to_string_all_encodings() {
        // Test: all supported encodings should work
        let encodings_and_bytes: Vec<(&str, Vec<u8>)> = vec![
            ("UTF8", vec![72, 101, 108, 108, 111]),           // "Hello" in UTF-8
            ("ASCII", vec![72, 101, 108, 108, 111]),          // "Hello" in ASCII
            ("Unicode", vec![72, 0, 101, 0, 108, 0, 108, 0, 111, 0]), // "Hello" in UTF-16LE
            ("BigEndianUnicode", vec![0, 72, 0, 101, 0, 108, 0, 108, 0, 111]), // "Hello" in UTF-16BE
            ("UTF32", vec![72, 0, 0, 0, 101, 0, 0, 0, 108, 0, 0, 0, 108, 0, 0, 0, 111, 0, 0, 0]), // "Hello" in UTF-32LE
            ("Default", vec![72, 101, 108, 108, 111]),        // "Hello" in Default (UTF-8)
        ];

        for (enc, bytes) in encodings_and_bytes {
            let encoding = CString::new(enc).unwrap();

            let result =
                unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

            assert!(!result.is_null(), "Result should not be null for encoding: {}", enc);

            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(result_str, "Hello", "Should decode to 'Hello' for encoding: {}", enc);

            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_bytes_to_string_utf7_deprecated() {
        // Test: UTF7 encoding should return null (deprecated)
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];
        let encoding = CString::new("UTF7").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "UTF7 encoding should return null (deprecated)");
    }

    #[test]
    fn test_bytes_to_string_invalid_encoding() {
        // Test: invalid encoding name should return null
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];
        let encoding = CString::new("INVALID_ENCODING").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Invalid encoding should return null");
    }

    #[test]
    fn test_bytes_to_string_invalid_utf8_bytes() {
        // Test: invalid UTF-8 byte sequence should return null
        let bytes: [u8; 2] = [0xFF, 0xFE]; // Invalid UTF-8 sequence
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Invalid UTF-8 bytes should return null");
    }

    #[test]
    fn test_bytes_to_string_result_contains_null_byte() {
        // Test: UTF-32 bytes that decode to a string containing a null character
        // U+0000 (null) in UTF-32LE = [0x00, 0x00, 0x00, 0x00]
        let bytes: [u8; 8] = [0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]; // "A" + null
        let encoding = CString::new("UTF32").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Result containing null byte should return null");
    }

    #[test]
    fn test_bytes_to_string_invalid_utf16_length() {
        // Test: odd-length byte array for UTF-16 should return null
        let bytes: [u8; 3] = [72, 0, 101]; // Odd length, invalid for UTF-16
        let encoding = CString::new("Unicode").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Odd-length UTF-16 bytes should return null");
    }

    #[test]
    fn test_bytes_to_string_invalid_utf32_length() {
        // Test: non-multiple-of-4 byte array for UTF-32 should return null
        let bytes: [u8; 5] = [72, 0, 0, 0, 101]; // Not multiple of 4
        let encoding = CString::new("UTF32").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Non-multiple-of-4 UTF-32 bytes should return null");
    }

    #[test]
    fn test_bytes_to_string_ascii_rejects_non_ascii() {
        // Test: ASCII encoding should reject bytes > 127
        let bytes: [u8; 3] = [72, 200, 111]; // 200 is not valid ASCII
        let encoding = CString::new("ASCII").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "ASCII should reject non-ASCII bytes");
    }

    #[test]
    fn test_bytes_to_string_unicode_emoji() {
        // Test: UTF-8 bytes for emoji should decode correctly
        // 🌍 = U+1F30D = F0 9F 8C 8D in UTF-8
        let bytes: [u8; 4] = [0xF0, 0x9F, 0x8C, 0x8D];
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(!result.is_null(), "Result should not be null for emoji");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "🌍", "Should decode to earth emoji");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_large_input() {
        // Test: 1MB of bytes should decode successfully
        let large_bytes: Vec<u8> = vec![65u8; 1024 * 1024]; // 1MB of 'A'
        let encoding = CString::new("UTF8").unwrap();

        let result =
            unsafe { bytes_to_string(large_bytes.as_ptr(), large_bytes.len(), encoding.as_ptr()) };

        assert!(!result.is_null(), "Result should not be null for large input");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str.len(), 1024 * 1024, "Should have 1MB of characters");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_round_trip_utf8() {
        // Test: string -> bytes -> string round-trip
        let original = CString::new("Hello, World! 🌍").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        // String to bytes
        let bytes_ptr = unsafe {
            string_to_bytes(
                original.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };
        assert!(!bytes_ptr.is_null(), "string_to_bytes should succeed");

        // Bytes to string
        let result = unsafe { bytes_to_string(bytes_ptr, out_length, encoding.as_ptr()) };
        assert!(!result.is_null(), "bytes_to_string should succeed");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "Hello, World! 🌍", "Round-trip should preserve string");

        unsafe {
            crate::memory::free_bytes(bytes_ptr);
            crate::memory::free_string(result);
        };
    }

    #[test]
    fn test_bytes_to_string_round_trip_all_encodings() {
        // Test: round-trip for all encodings
        let encodings = vec!["UTF8", "ASCII", "Unicode", "BigEndianUnicode", "UTF32", "Default"];

        for enc in encodings {
            let original = CString::new("Test").unwrap(); // ASCII-safe for all encodings
            let encoding = CString::new(enc).unwrap();
            let mut out_length: usize = 0;

            // String to bytes
            let bytes_ptr = unsafe {
                string_to_bytes(
                    original.as_ptr(),
                    encoding.as_ptr(),
                    &mut out_length as *mut usize,
                )
            };
            assert!(!bytes_ptr.is_null(), "string_to_bytes should succeed for {}", enc);

            // Bytes to string
            let result = unsafe { bytes_to_string(bytes_ptr, out_length, encoding.as_ptr()) };
            assert!(!result.is_null(), "bytes_to_string should succeed for {}", enc);

            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(result_str, "Test", "Round-trip should preserve string for {}", enc);

            unsafe {
                crate::memory::free_bytes(bytes_ptr);
                crate::memory::free_string(result);
            };
        }
    }

    #[test]
    fn test_bytes_to_string_case_insensitive_encoding() {
        // Test: encoding names should be case-insensitive
        let bytes: [u8; 4] = [84, 101, 115, 116]; // "Test" in UTF-8
        let encoding_variants = vec!["utf8", "UTF8", "Utf8", "ascii", "ASCII"];

        for enc in encoding_variants {
            let encoding = CString::new(enc).unwrap();

            let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

            assert!(
                !result.is_null(),
                "Encoding '{}' should be recognized (case-insensitive)",
                enc
            );

            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_bytes_to_string_concurrent_operations() {
        use std::thread;

        // Test: multiple threads using bytes_to_string concurrently
        let handles: Vec<_> = (0..10)
            .map(|i| {
                thread::spawn(move || {
                    let bytes: [u8; 5] = [72, 101, 108, 108, 111]; // "Hello"
                    let encoding = CString::new("UTF8").unwrap();

                    let result =
                        unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };
                    assert!(!result.is_null(), "Decoding should succeed in thread {}", i);

                    let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
                    assert_eq!(result_str, "Hello", "Should decode to 'Hello' in thread {}", i);

                    unsafe { crate::memory::free_string(result) };
                })
            })
            .collect();

        for handle in handles {
            handle.join().unwrap();
        }
    }
}
