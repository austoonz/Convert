//! Byte array to string conversion

use std::ffi::CStr;
use std::os::raw::c_char;

/// Convert a byte array to a string using the specified encoding
///
/// Supports UTF-8, ASCII, Unicode (UTF-16LE), UTF-32, BigEndianUnicode (UTF-16BE),
/// and Default (UTF-8) encodings. The encoding name is case-insensitive and supports
/// both hyphenated (UTF-8) and non-hyphenated (UTF8) variants.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `bytes` is a valid pointer to a byte array of at least `length` bytes, or null if length is 0
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn bytes_to_string(
    bytes: *const u8,
    length: usize,
    encoding: *const c_char,
) -> *mut c_char {
    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    if length == 0 {
        crate::error::clear_error();
        let empty = std::ffi::CString::new("").unwrap();
        return empty.into_raw();
    }

    if bytes.is_null() {
        crate::error::set_error("Bytes pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let byte_slice = unsafe { std::slice::from_raw_parts(bytes, length) };

    if encoding_str.eq_ignore_ascii_case("UTF7") || encoding_str.eq_ignore_ascii_case("UTF-7") {
        crate::error::set_error("UTF7 encoding is deprecated and not supported".to_string());
        return std::ptr::null_mut();
    }

    let result_string = match crate::base64::convert_bytes_to_string(byte_slice, encoding_str) {
        Ok(s) => s,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

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

/// Convert a byte array to a string using the specified encoding with Latin-1 fallback
///
/// This is a lenient version of `bytes_to_string` that automatically falls back to
/// Latin-1 (ISO-8859-1) encoding when the byte sequence is invalid for the specified
/// encoding. This is useful for handling binary data (like certificates) that may not
/// be valid text in any standard encoding.
///
/// Use this function when you want best-effort conversion without errors.
/// Use `bytes_to_string` when you want strict validation of the encoding.
///
/// # Safety
/// Same safety requirements as `bytes_to_string`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn bytes_to_string_lenient(
    bytes: *const u8,
    length: usize,
    encoding: *const c_char,
) -> *mut c_char {
    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    if length == 0 {
        crate::error::clear_error();
        let empty = std::ffi::CString::new("").unwrap();
        return empty.into_raw();
    }

    if bytes.is_null() {
        crate::error::set_error("Bytes pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let byte_slice = unsafe { std::slice::from_raw_parts(bytes, length) };

    if encoding_str.eq_ignore_ascii_case("UTF7") || encoding_str.eq_ignore_ascii_case("UTF-7") {
        crate::error::set_error("UTF7 encoding is deprecated and not supported".to_string());
        return std::ptr::null_mut();
    }

    let result_string =
        match crate::base64::convert_bytes_to_string_with_fallback(byte_slice, encoding_str) {
            Ok(s) => s,
            Err(e) => {
                crate::error::set_error(e);
                return std::ptr::null_mut();
            }
        };

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

    #[test]
    fn test_bytes_to_string_happy_path_utf8() {
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
        let bytes: [u8; 0] = [];
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), 0, encoding.as_ptr()) };

        assert!(
            !result.is_null(),
            "Result should not be null for empty bytes"
        );

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Should return empty string");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_null_bytes_with_length() {
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(std::ptr::null(), 5, encoding.as_ptr()) };

        assert!(
            result.is_null(),
            "Null bytes with length > 0 should return null"
        );
    }

    #[test]
    fn test_bytes_to_string_null_bytes_with_zero_length() {
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(std::ptr::null(), 0, encoding.as_ptr()) };

        assert!(!result.is_null(), "Null bytes with length 0 should succeed");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Should return empty string");

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_null_encoding() {
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), std::ptr::null()) };

        assert!(result.is_null(), "Null encoding should return null");
    }

    #[test]
    fn test_bytes_to_string_all_encodings() {
        let encodings_and_bytes: Vec<(&str, Vec<u8>)> = vec![
            ("UTF8", vec![72, 101, 108, 108, 111]),
            ("ASCII", vec![72, 101, 108, 108, 111]),
            ("Unicode", vec![72, 0, 101, 0, 108, 0, 108, 0, 111, 0]),
            (
                "BigEndianUnicode",
                vec![0, 72, 0, 101, 0, 108, 0, 108, 0, 111],
            ),
            (
                "UTF32",
                vec![
                    72, 0, 0, 0, 101, 0, 0, 0, 108, 0, 0, 0, 108, 0, 0, 0, 111, 0, 0, 0,
                ],
            ),
            ("Default", vec![72, 101, 108, 108, 111]),
        ];

        for (enc, bytes) in encodings_and_bytes {
            let encoding = CString::new(enc).unwrap();

            let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

            assert!(
                !result.is_null(),
                "Result should not be null for encoding: {}",
                enc
            );

            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str, "Hello",
                "Should decode to 'Hello' for encoding: {}",
                enc
            );

            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_bytes_to_string_utf7_deprecated() {
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];
        let encoding = CString::new("UTF7").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(
            result.is_null(),
            "UTF7 encoding should return null (deprecated)"
        );
    }

    #[test]
    fn test_bytes_to_string_invalid_encoding() {
        let bytes: [u8; 5] = [72, 101, 108, 108, 111];
        let encoding = CString::new("INVALID_ENCODING").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Invalid encoding should return null");
    }

    #[test]
    fn test_bytes_to_string_invalid_utf8_bytes() {
        let bytes: [u8; 2] = [0xFF, 0xFE];
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "Invalid UTF-8 bytes should return null");
    }

    #[test]
    fn test_bytes_to_string_result_contains_null_byte() {
        let bytes: [u8; 8] = [0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let encoding = CString::new("UTF32").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(
            result.is_null(),
            "Result containing null byte should return null"
        );
    }

    #[test]
    fn test_bytes_to_string_invalid_utf16_length() {
        let bytes: [u8; 3] = [72, 0, 101];
        let encoding = CString::new("Unicode").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(
            result.is_null(),
            "Odd-length UTF-16 bytes should return null"
        );
    }

    #[test]
    fn test_bytes_to_string_invalid_utf32_length() {
        let bytes: [u8; 5] = [72, 0, 0, 0, 101];
        let encoding = CString::new("UTF32").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(
            result.is_null(),
            "Non-multiple-of-4 UTF-32 bytes should return null"
        );
    }

    #[test]
    fn test_bytes_to_string_ascii_rejects_non_ascii() {
        let bytes: [u8; 3] = [72, 200, 111];
        let encoding = CString::new("ASCII").unwrap();

        let result = unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };

        assert!(result.is_null(), "ASCII should reject non-ASCII bytes");
    }

    #[test]
    fn test_bytes_to_string_unicode_emoji() {
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
        let large_bytes: Vec<u8> = vec![65u8; 1024 * 1024];
        let encoding = CString::new("UTF8").unwrap();

        let result =
            unsafe { bytes_to_string(large_bytes.as_ptr(), large_bytes.len(), encoding.as_ptr()) };

        assert!(
            !result.is_null(),
            "Result should not be null for large input"
        );

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str.len(),
            1024 * 1024,
            "Should have 1MB of characters"
        );

        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_string_round_trip_utf8() {
        let original = CString::new("Hello, World! 🌍").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let bytes_ptr = unsafe {
            crate::encoding::string_to_bytes(
                original.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };
        assert!(!bytes_ptr.is_null(), "string_to_bytes should succeed");

        let result = unsafe { bytes_to_string(bytes_ptr, out_length, encoding.as_ptr()) };
        assert!(!result.is_null(), "bytes_to_string should succeed");

        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "Hello, World! 🌍",
            "Round-trip should preserve string"
        );

        unsafe {
            crate::memory::free_bytes(bytes_ptr);
            crate::memory::free_string(result);
        };
    }

    #[test]
    fn test_bytes_to_string_round_trip_all_encodings() {
        let encodings = vec![
            "UTF8",
            "ASCII",
            "Unicode",
            "BigEndianUnicode",
            "UTF32",
            "Default",
        ];

        for enc in encodings {
            let original = CString::new("Test").unwrap();
            let encoding = CString::new(enc).unwrap();
            let mut out_length: usize = 0;

            let bytes_ptr = unsafe {
                crate::encoding::string_to_bytes(
                    original.as_ptr(),
                    encoding.as_ptr(),
                    &mut out_length as *mut usize,
                )
            };
            assert!(
                !bytes_ptr.is_null(),
                "string_to_bytes should succeed for {}",
                enc
            );

            let result = unsafe { bytes_to_string(bytes_ptr, out_length, encoding.as_ptr()) };
            assert!(
                !result.is_null(),
                "bytes_to_string should succeed for {}",
                enc
            );

            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str, "Test",
                "Round-trip should preserve string for {}",
                enc
            );

            unsafe {
                crate::memory::free_bytes(bytes_ptr);
                crate::memory::free_string(result);
            };
        }
    }

    #[test]
    fn test_bytes_to_string_case_insensitive_encoding() {
        let bytes: [u8; 4] = [84, 101, 115, 116];
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

        let handles: Vec<_> = (0..10)
            .map(|i| {
                thread::spawn(move || {
                    let bytes: [u8; 5] = [72, 101, 108, 108, 111];
                    let encoding = CString::new("UTF8").unwrap();

                    let result =
                        unsafe { bytes_to_string(bytes.as_ptr(), bytes.len(), encoding.as_ptr()) };
                    assert!(!result.is_null(), "Decoding should succeed in thread {}", i);

                    let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
                    assert_eq!(
                        result_str, "Hello",
                        "Should decode to 'Hello' in thread {}",
                        i
                    );

                    unsafe { crate::memory::free_string(result) };
                })
            })
            .collect();

        for handle in handles {
            handle.join().unwrap();
        }
    }
}
