//! HMAC computation operations

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use super::algorithms::compute_hmac_internal;

/// Compute an HMAC from a string with specified encoding
///
/// This function accepts a string input and encoding parameter, handling the
/// string-to-bytes conversion internally using the same encoding logic as
/// other functions in this library.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `key` is a valid pointer to a byte array of at least `key_length` bytes or null
/// - `algorithm` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
///
/// # Supported Algorithms
/// - MD5 (not recommended for security-critical applications)
/// - SHA1 (not recommended for security-critical applications)
/// - SHA256 (recommended)
/// - SHA384
/// - SHA512
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hmac_with_encoding(
    input: *const c_char,
    key: *const u8,
    key_length: usize,
    algorithm: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    crate::error::clear_error();

    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
        return std::ptr::null_mut();
    }

    if key.is_null() {
        crate::error::set_error("Key pointer is null".to_string());
        return std::ptr::null_mut();
    }

    if algorithm.is_null() {
        crate::error::set_error("Algorithm pointer is null".to_string());
        return std::ptr::null_mut();
    }

    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            return std::ptr::null_mut();
        }
    };

    let algorithm_str = match unsafe { CStr::from_ptr(algorithm).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in algorithm string".to_string());
            return std::ptr::null_mut();
        }
    };

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    let input_bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    let key_slice = unsafe { std::slice::from_raw_parts(key, key_length) };

    let hmac_hex = match compute_hmac_internal(algorithm_str, key_slice, &input_bytes) {
        Ok(hex) => hex,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    match CString::new(hmac_hex) {
        Ok(c_str) => {
            crate::error::clear_error();
            c_str.into_raw()
        }
        Err(_) => {
            crate::error::set_error("Failed to create C string from HMAC result".to_string());
            std::ptr::null_mut()
        }
    }
}

/// Compute an HMAC from raw bytes
///
/// This function accepts raw byte input directly, avoiding the need for
/// encoding conversions when working with binary data.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input_bytes` is a valid pointer to a byte array of at least `input_length` bytes, or null if length is 0
/// - `key` is a valid pointer to a byte array of at least `key_length` bytes or null
/// - `algorithm` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
///
/// # Supported Algorithms
/// - MD5 (not recommended for security-critical applications)
/// - SHA1 (not recommended for security-critical applications)
/// - SHA256 (recommended)
/// - SHA384
/// - SHA512
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hmac_bytes(
    input_bytes: *const u8,
    input_length: usize,
    key: *const u8,
    key_length: usize,
    algorithm: *const c_char,
) -> *mut c_char {
    crate::error::clear_error();

    if key.is_null() {
        crate::error::set_error("Key pointer is null".to_string());
        return std::ptr::null_mut();
    }

    if algorithm.is_null() {
        crate::error::set_error("Algorithm pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let algorithm_str = match unsafe { CStr::from_ptr(algorithm).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in algorithm string".to_string());
            return std::ptr::null_mut();
        }
    };

    let input_slice = if input_length == 0 {
        &[]
    } else {
        if input_bytes.is_null() {
            crate::error::set_error("Input bytes pointer is null".to_string());
            return std::ptr::null_mut();
        }
        unsafe { std::slice::from_raw_parts(input_bytes, input_length) }
    };

    let key_slice = unsafe { std::slice::from_raw_parts(key, key_length) };

    let hmac_hex = match compute_hmac_internal(algorithm_str, key_slice, input_slice) {
        Ok(hex) => hex,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    match CString::new(hmac_hex) {
        Ok(c_str) => {
            crate::error::clear_error();
            c_str.into_raw()
        }
        Err(_) => {
            crate::error::set_error("Failed to create C string from HMAC result".to_string());
            std::ptr::null_mut()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_compute_hmac_bytes_known_vectors() {
        let test_cases = vec![
            ("MD5", "63D6BAF65DF6BDEE8F32B332E0930669"),
            ("SHA1", "1AA349585ED7ECBD3B9C486A30067E395CA4B356"),
            (
                "SHA256",
                "0329A06B62CD16B33EB6792BE8C60B158D89A2EE3A876FCE9A881EBB488C0914",
            ),
            (
                "SHA384",
                "4E54A97BE947E471E89CDD22C25B8FF704F458FDFCEBD8A79A366FF0E52B607FE3F1E52BD1A839F89396D1A4B2CBE570",
            ),
            (
                "SHA512",
                "F8A4F0A209167BC192A1BFFAA01ECDB09E06C57F96530D92EC9CCEA0090D290E55071306D6B654F26AE0C8721F7E48A2D7130B881151F2CEC8D61D941A6BE88A",
            ),
        ];

        let input_bytes = b"test";
        let key = b"secret";

        for (algorithm, expected_hmac) in test_cases {
            let algo = CString::new(algorithm).unwrap();

            let result = unsafe {
                compute_hmac_bytes(
                    input_bytes.as_ptr(),
                    input_bytes.len(),
                    key.as_ptr(),
                    key.len(),
                    algo.as_ptr(),
                )
            };

            assert!(
                !result.is_null(),
                "HMAC-{} bytes result should not be null",
                algorithm
            );
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str, expected_hmac,
                "HMAC-{} of bytes 'test' with key 'secret' should match known vector",
                algorithm
            );
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_compute_hmac_bytes_matches_encoding_version() {
        let input_str = CString::new("Hello, World!").unwrap();
        let input_bytes = b"Hello, World!";
        let key = b"my_secret_key";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let string_result = unsafe {
            compute_hmac_with_encoding(
                input_str.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };
        assert!(!string_result.is_null());
        let string_hmac = unsafe { CStr::from_ptr(string_result).to_str().unwrap().to_string() };

        let bytes_result = unsafe {
            compute_hmac_bytes(
                input_bytes.as_ptr(),
                input_bytes.len(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };
        assert!(!bytes_result.is_null());
        let bytes_hmac = unsafe { CStr::from_ptr(bytes_result).to_str().unwrap() };

        assert_eq!(
            string_hmac, bytes_hmac,
            "compute_hmac_with_encoding (UTF8) and compute_hmac_bytes should produce identical results"
        );

        unsafe {
            crate::memory::free_string(string_result);
            crate::memory::free_string(bytes_result);
        };
    }

    #[test]
    fn test_compute_hmac_bytes_null_key_returns_null() {
        let input_bytes = b"test";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac_bytes(
                input_bytes.as_ptr(),
                input_bytes.len(),
                std::ptr::null(),
                0,
                algorithm.as_ptr(),
            )
        };

        assert!(result.is_null(), "Null key should return null");
    }

    #[test]
    fn test_compute_hmac_bytes_null_algorithm_returns_null() {
        let input_bytes = b"test";
        let key = b"secret";

        let result = unsafe {
            compute_hmac_bytes(
                input_bytes.as_ptr(),
                input_bytes.len(),
                key.as_ptr(),
                key.len(),
                std::ptr::null(),
            )
        };

        assert!(result.is_null(), "Null algorithm should return null");
    }

    #[test]
    fn test_compute_hmac_bytes_empty_input() {
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac_bytes(
                std::ptr::null(),
                0,
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };

        assert!(!result.is_null(), "Empty input should produce an HMAC");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "F9E66E179B6747AE54108F82F8ADE8B3C25D76FD30AFDE6C395822C530196169",
            "HMAC-SHA256 of empty bytes with key 'secret' should match known vector"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_bytes_binary_data() {
        let binary_input: &[u8] = &[0x00, 0x01, 0xFF, 0xFE, 0x80, 0x81];
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac_bytes(
                binary_input.as_ptr(),
                binary_input.len(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };

        assert!(!result.is_null(), "Binary data should produce an HMAC");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str.len(),
            64,
            "HMAC-SHA256 should be 64 hex characters"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_bytes_large_input() {
        let large_input: Vec<u8> = vec![0x41; 1_000_000];
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac_bytes(
                large_input.as_ptr(),
                large_input.len(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };

        assert!(!result.is_null(), "Large input should produce an HMAC");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str.len(),
            64,
            "HMAC-SHA256 should be 64 hex characters"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_bytes_unsupported_algorithm_returns_null() {
        let input_bytes = b"test";
        let key = b"secret";
        let algorithm = CString::new("UNSUPPORTED").unwrap();

        let result = unsafe {
            compute_hmac_bytes(
                input_bytes.as_ptr(),
                input_bytes.len(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };

        assert!(result.is_null(), "Unsupported algorithm should return null");
    }

    #[test]
    fn test_compute_hmac_bytes_null_input_with_nonzero_length_returns_null() {
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac_bytes(
                std::ptr::null(),
                10,
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };

        assert!(
            result.is_null(),
            "Null input with non-zero length should return null"
        );
    }

    #[test]
    fn test_compute_hmac_with_encoding_utf8() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe {
            compute_hmac_with_encoding(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };

        assert!(!result.is_null(), "Result should not be null");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "0329A06B62CD16B33EB6792BE8C60B158D89A2EE3A876FCE9A881EBB488C0914",
            "HMAC-SHA256 with UTF8 encoding should match known vector"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_with_encoding_matches_bytes_version() {
        let input = CString::new("Hello, World!").unwrap();
        let input_bytes = b"Hello, World!";
        let key = b"my_secret_key";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let bytes_result = unsafe {
            compute_hmac_bytes(
                input_bytes.as_ptr(),
                input_bytes.len(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };
        assert!(!bytes_result.is_null());
        let bytes_hmac = unsafe { CStr::from_ptr(bytes_result).to_str().unwrap().to_string() };

        let encoding_result = unsafe {
            compute_hmac_with_encoding(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };
        assert!(!encoding_result.is_null());
        let encoding_hmac = unsafe { CStr::from_ptr(encoding_result).to_str().unwrap() };

        assert_eq!(
            bytes_hmac, encoding_hmac,
            "compute_hmac_bytes and compute_hmac_with_encoding (UTF8) should produce identical results"
        );

        unsafe {
            crate::memory::free_string(bytes_result);
            crate::memory::free_string(encoding_result);
        };
    }

    #[test]
    fn test_compute_hmac_with_encoding_ascii() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("ASCII").unwrap();

        let result = unsafe {
            compute_hmac_with_encoding(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };

        assert!(
            !result.is_null(),
            "ASCII encoding should work for ASCII input"
        );
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "0329A06B62CD16B33EB6792BE8C60B158D89A2EE3A876FCE9A881EBB488C0914",
            "HMAC-SHA256 with ASCII encoding should match UTF8 for ASCII input"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_with_encoding_unicode() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("Unicode").unwrap();

        let result = unsafe {
            compute_hmac_with_encoding(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };

        assert!(!result.is_null(), "Unicode encoding should work");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_ne!(
            result_str, "0329A06B62CD16B33EB6792BE8C60B158D89A2EE3A876FCE9A881EBB488C0914",
            "Unicode encoding should produce different HMAC than UTF8"
        );
        assert_eq!(
            result_str.len(),
            64,
            "HMAC-SHA256 should be 64 hex characters"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_with_encoding_null_input_returns_null() {
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe {
            compute_hmac_with_encoding(
                std::ptr::null(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };

        assert!(result.is_null(), "Null input should return null");
    }

    #[test]
    fn test_compute_hmac_with_encoding_null_encoding_returns_null() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac_with_encoding(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                std::ptr::null(),
            )
        };

        assert!(result.is_null(), "Null encoding should return null");
    }

    #[test]
    fn test_compute_hmac_with_encoding_invalid_encoding_returns_null() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();

        let result = unsafe {
            compute_hmac_with_encoding(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
                encoding.as_ptr(),
            )
        };

        assert!(result.is_null(), "Invalid encoding should return null");
    }

    #[test]
    fn test_compute_hmac_with_encoding_all_algorithms() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let encoding = CString::new("UTF8").unwrap();

        let test_cases = vec![
            ("MD5", 32),
            ("SHA1", 40),
            ("SHA256", 64),
            ("SHA384", 96),
            ("SHA512", 128),
        ];

        for (algo, expected_len) in test_cases {
            let algorithm = CString::new(algo).unwrap();

            let result = unsafe {
                compute_hmac_with_encoding(
                    input.as_ptr(),
                    key.as_ptr(),
                    key.len(),
                    algorithm.as_ptr(),
                    encoding.as_ptr(),
                )
            };

            assert!(!result.is_null(), "HMAC-{} should not return null", algo);
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str.len(),
                expected_len,
                "HMAC-{} should be {} hex characters",
                algo,
                expected_len
            );
            unsafe { crate::memory::free_string(result) };
        }
    }
}
