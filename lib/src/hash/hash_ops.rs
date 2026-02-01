//! Hash computation operations

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use super::algorithms::compute_hash_bytes;

/// Compute a cryptographic hash of a string
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `algorithm` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
///
/// # Supported Algorithms
/// - MD5
/// - SHA1
/// - SHA256
/// - SHA384
/// - SHA512
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hash(
    input: *const c_char,
    algorithm: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    crate::error::clear_error();

    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
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

    let bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    let hash_hex = match compute_hash_bytes(&bytes, algorithm_str) {
        Ok(hex) => hex,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    match CString::new(hash_hex) {
        Ok(c_str) => {
            crate::error::clear_error();
            c_str.into_raw()
        }
        Err(_) => {
            crate::error::set_error("Failed to create C string from hash result".to_string());
            std::ptr::null_mut()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_compute_hash_known_vectors() {
        let test_cases = vec![
            ("MD5", "098F6BCD4621D373CADE4E832627B4F6"),
            ("SHA1", "A94A8FE5CCB19BA61C4C0873D391E987982FBBD3"),
            (
                "SHA256",
                "9F86D081884C7D659A2FEAA0C55AD015A3BF4F1B2B0B822CD15D6C15B0F00A08",
            ),
            (
                "SHA384",
                "768412320F7B0AA5812FCE428DC4706B3CAE50E02A64CAA16A782249BFE8EFC4B7EF1CCB126255D196047DFEDF17A0A9",
            ),
            (
                "SHA512",
                "EE26B0DD4AF7E749AA1A8EE3C10AE9923F618980772E473F8819A5D4940E0DB27AC185F8A0E1D5F84F88BC887FD67B143732C304CC5FA9AD8E6F57F50028A8FF",
            ),
        ];

        for (algorithm, expected_hash) in test_cases {
            let input = CString::new("test").unwrap();
            let algo = CString::new(algorithm).unwrap();
            let encoding = CString::new("UTF8").unwrap();

            let result = unsafe { compute_hash(input.as_ptr(), algo.as_ptr(), encoding.as_ptr()) };

            assert!(!result.is_null(), "{} result should not be null", algorithm);
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str, expected_hash,
                "{} hash of 'test' should match known vector",
                algorithm
            );
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_compute_hash_null_input_returns_null() {
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result =
            unsafe { compute_hash(std::ptr::null(), algorithm.as_ptr(), encoding.as_ptr()) };

        assert!(result.is_null(), "Null input should return null");
    }

    #[test]
    fn test_compute_hash_null_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { compute_hash(input.as_ptr(), std::ptr::null(), encoding.as_ptr()) };

        assert!(result.is_null(), "Null algorithm should return null");
    }

    #[test]
    fn test_compute_hash_null_encoding_returns_null() {
        let input = CString::new("test").unwrap();
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe { compute_hash(input.as_ptr(), algorithm.as_ptr(), std::ptr::null()) };

        assert!(result.is_null(), "Null encoding should return null");
    }

    #[test]
    fn test_compute_hash_unsupported_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let algorithm = CString::new("UNSUPPORTED").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { compute_hash(input.as_ptr(), algorithm.as_ptr(), encoding.as_ptr()) };

        assert!(result.is_null(), "Unsupported algorithm should return null");
    }

    #[test]
    fn test_compute_hash_empty_string() {
        let input = CString::new("").unwrap();
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { compute_hash(input.as_ptr(), algorithm.as_ptr(), encoding.as_ptr()) };

        assert!(!result.is_null(), "Empty string should produce a hash");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
            "SHA256 hash of empty string should match known vector"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hash_large_string() {
        let large_input = "A".repeat(1_000_000);
        let input = CString::new(large_input).unwrap();
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { compute_hash(input.as_ptr(), algorithm.as_ptr(), encoding.as_ptr()) };

        assert!(!result.is_null(), "Large string should produce a hash");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str.len(),
            64,
            "SHA256 hash should be 64 hex characters"
        );
        unsafe { crate::memory::free_string(result) };
    }
}
