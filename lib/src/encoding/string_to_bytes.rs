//! String to byte array conversion

use std::ffi::CStr;
use std::os::raw::c_char;

use super::helpers::set_output_length_zero;

/// Convert a string to a byte array using the specified encoding
///
/// Supports UTF-8, ASCII, Unicode (UTF-16LE), UTF-32, BigEndianUnicode (UTF-16BE),
/// and Default (UTF-8) encodings. The encoding name is case-insensitive and supports
/// both hyphenated (UTF-8) and non-hyphenated (UTF8) variants.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - `out_length` is a valid pointer to a usize or null (optional)
/// - The returned pointer must be freed using `free_bytes`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn string_to_bytes(
    input: *const c_char,
    encoding: *const c_char,
    out_length: *mut usize,
) -> *mut u8 {
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

    if encoding_str.eq_ignore_ascii_case("UTF7") || encoding_str.eq_ignore_ascii_case("UTF-7") {
        crate::error::set_error("UTF7 encoding is deprecated and not supported".to_string());
        set_output_length_zero(out_length);
        return std::ptr::null_mut();
    }

    let bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            set_output_length_zero(out_length);
            return std::ptr::null_mut();
        }
    };

    let length = bytes.len();
    if !out_length.is_null() {
        unsafe {
            *out_length = length;
        }
    }

    crate::error::clear_error();
    crate::memory::allocate_byte_array(bytes)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_string_to_bytes_happy_path_utf8() {
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

        assert!(
            result.is_null(),
            "UTF7 encoding should return null (deprecated)"
        );
        assert_eq!(out_length, 0, "Output length should be 0 for UTF7");
    }

    #[test]
    fn test_string_to_bytes_invalid_encoding() {
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
        let large_string = "A".repeat(1024 * 1024);
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
        let input = CString::new("A").unwrap();
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
        assert_eq!(bytes, &[0x41, 0x00]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_utf32_encoding() {
        let input = CString::new("A").unwrap();
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
        assert_eq!(bytes, &[0x41, 0x00, 0x00, 0x00]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_bigendian_unicode_encoding() {
        let input = CString::new("A").unwrap();
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
        assert_eq!(bytes, &[0x00, 0x41]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_default_encoding() {
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
        assert_eq!(out_length, 10, "UTF8 'Hello 🌍' should be 10 bytes");

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_null_output_length_pointer() {
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result =
            unsafe { string_to_bytes(input.as_ptr(), encoding.as_ptr(), std::ptr::null_mut()) };

        assert!(
            !result.is_null(),
            "Should succeed with null out_length pointer"
        );

        let data = unsafe { std::slice::from_raw_parts(result, 5) };
        assert_eq!(data, &[72, 101, 108, 108, 111]);

        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_string_to_bytes_case_insensitive_encoding() {
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
        let input = CString::new("Café").unwrap();
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
        let test_cases = vec![
            ("", 0),
            ("A", 1),
            ("AB", 2),
            ("ABC", 3),
            ("Test String", 11),
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
}
