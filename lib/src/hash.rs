//! Cryptographic hash functions (MD5, SHA1, SHA256, SHA384, SHA512, HMAC)

use hmac::{Hmac, Mac};
use md5::Md5;
use sha1::Sha1;
use sha2::{Digest, Sha256, Sha384, Sha512};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

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
///
/// # Returns
/// Hex-encoded hash string, or null on error
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hash(
    input: *const c_char,
    algorithm: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    crate::error::clear_error();

    // Validate null pointers
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

    // Convert C strings to Rust strings
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

    // Convert string to bytes based on encoding
    let bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    // Compute hash based on algorithm (uppercase hex for .NET compatibility)
    let hash_hex = match algorithm_str.to_uppercase().as_str() {
        "MD5" => {
            let mut hasher = Md5::new();
            hasher.update(&bytes);
            format!("{:X}", hasher.finalize())
        }
        "SHA1" => {
            let mut hasher = Sha1::new();
            hasher.update(&bytes);
            format!("{:X}", hasher.finalize())
        }
        "SHA256" => {
            let mut hasher = Sha256::new();
            hasher.update(&bytes);
            format!("{:X}", hasher.finalize())
        }
        "SHA384" => {
            let mut hasher = Sha384::new();
            hasher.update(&bytes);
            format!("{:X}", hasher.finalize())
        }
        "SHA512" => {
            let mut hasher = Sha512::new();
            hasher.update(&bytes);
            format!("{:X}", hasher.finalize())
        }
        _ => {
            crate::error::set_error(format!(
                "Unsupported algorithm: {}. Supported: MD5, SHA1, SHA256, SHA384, SHA512",
                algorithm_str
            ));
            return std::ptr::null_mut();
        }
    };

    // Convert to C string
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

/// Compute HMAC using the specified algorithm
///
/// Helper function that encapsulates the algorithm-specific HMAC computation.
/// Returns uppercase hexadecimal string for .NET compatibility.
///
/// # Arguments
/// * `algorithm` - Algorithm name (case-insensitive)
/// * `key` - Secret key bytes
/// * `input` - Input data bytes
///
/// # Returns
/// Uppercase hex-encoded HMAC string, or error message
fn compute_hmac_with_algorithm(
    algorithm: &str,
    key: &[u8],
    input: &[u8],
) -> Result<String, String> {
    match algorithm.to_uppercase().as_str() {
        "MD5" => compute_hmac_md5(key, input),
        "SHA1" => compute_hmac_sha1(key, input),
        "SHA256" => compute_hmac_sha256(key, input),
        "SHA384" => compute_hmac_sha384(key, input),
        "SHA512" => compute_hmac_sha512(key, input),
        _ => Err(format!(
            "Unsupported algorithm: {}. Supported: MD5, SHA1, SHA256, SHA384, SHA512",
            algorithm
        )),
    }
}

/// Compute an HMAC from a string with specified encoding
///
/// This function accepts a string input and encoding parameter, handling the
/// string-to-bytes conversion internally using the same encoding logic as
/// other functions in this library. This ensures consistent encoding behavior.
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
///
/// # Returns
/// Pointer to null-terminated hex-encoded HMAC string, or null on error.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hmac_with_encoding(
    input: *const c_char,
    key: *const u8,
    key_length: usize,
    algorithm: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    crate::error::clear_error();

    // Validate null pointers
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

    // SAFETY: input is guaranteed non-null by check above
    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            return std::ptr::null_mut();
        }
    };

    // SAFETY: algorithm is guaranteed non-null by check above
    let algorithm_str = match unsafe { CStr::from_ptr(algorithm).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in algorithm string".to_string());
            return std::ptr::null_mut();
        }
    };

    // SAFETY: encoding is guaranteed non-null by check above
    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    // Convert string to bytes using the specified encoding
    let input_bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    // SAFETY: key is guaranteed non-null and key_length is provided by caller
    let key_slice = unsafe { std::slice::from_raw_parts(key, key_length) };

    // Compute HMAC using the specified algorithm
    let hmac_hex = match compute_hmac_with_algorithm(algorithm_str, key_slice, &input_bytes) {
        Ok(hex) => hex,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    // Convert to C string
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
/// encoding conversions when working with binary data. This is the preferred
/// method when the input is already in byte form (e.g., from a MemoryStream
/// or byte array).
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
///
/// # Returns
/// Pointer to null-terminated hex-encoded HMAC string, or null on error.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hmac_bytes(
    input_bytes: *const u8,
    input_length: usize,
    key: *const u8,
    key_length: usize,
    algorithm: *const c_char,
) -> *mut c_char {
    crate::error::clear_error();

    // Validate key pointer
    if key.is_null() {
        crate::error::set_error("Key pointer is null".to_string());
        return std::ptr::null_mut();
    }

    // Validate algorithm pointer
    if algorithm.is_null() {
        crate::error::set_error("Algorithm pointer is null".to_string());
        return std::ptr::null_mut();
    }

    // SAFETY: algorithm is guaranteed non-null by check above
    let algorithm_str = match unsafe { CStr::from_ptr(algorithm).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in algorithm string".to_string());
            return std::ptr::null_mut();
        }
    };

    // Handle empty input case
    let input_slice = if input_length == 0 {
        &[]
    } else {
        // Validate input pointer only when length > 0
        if input_bytes.is_null() {
            crate::error::set_error("Input bytes pointer is null".to_string());
            return std::ptr::null_mut();
        }
        // SAFETY: input_bytes is non-null and input_length is provided by caller
        unsafe { std::slice::from_raw_parts(input_bytes, input_length) }
    };

    // SAFETY: key is guaranteed non-null and key_length is provided by caller
    let key_slice = unsafe { std::slice::from_raw_parts(key, key_length) };

    // Compute HMAC using the specified algorithm
    let hmac_hex = match compute_hmac_with_algorithm(algorithm_str, key_slice, input_slice) {
        Ok(hex) => hex,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    // Convert to C string
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

/// Compute HMAC-MD5
#[inline]
fn compute_hmac_md5(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacMd5 = Hmac<Md5>;
    let mut mac = HmacMd5::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-MD5 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA1
#[inline]
fn compute_hmac_sha1(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha1 = Hmac<Sha1>;
    let mut mac = HmacSha1::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA1 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA256
#[inline]
fn compute_hmac_sha256(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha256 = Hmac<Sha256>;
    let mut mac = HmacSha256::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA256 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA384
#[inline]
fn compute_hmac_sha384(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha384 = Hmac<Sha384>;
    let mut mac = HmacSha384::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA384 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA512
#[inline]
fn compute_hmac_sha512(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha512 = Hmac<Sha512>;
    let mut mac = HmacSha512::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA512 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
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

    // ========== Tests for compute_hmac_bytes ==========

    #[test]
    fn test_compute_hmac_bytes_known_vectors() {
        // Same test vectors as compute_hmac - "test" as bytes with key "secret"
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
        // Verify that compute_hmac_bytes produces the same result as compute_hmac_with_encoding
        // for the same input data (UTF-8 encoding)
        let input_str = CString::new("Hello, World!").unwrap();
        let input_bytes = b"Hello, World!";
        let key = b"my_secret_key";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        // Get result from string version with encoding
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

        // Get result from bytes version
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

        // Empty input with null pointer and zero length
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
        // Test with binary data that isn't valid UTF-8
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
        let large_input: Vec<u8> = vec![0x41; 1_000_000]; // 1MB of 'A' bytes
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

        // Null input pointer with non-zero length should fail
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

    // ========== Tests for compute_hmac_with_encoding ==========

    #[test]
    fn test_compute_hmac_with_encoding_utf8() {
        // Test with UTF8 encoding - should match compute_hmac result
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
        // Verify compute_hmac_with_encoding produces same result as compute_hmac_bytes for UTF8
        let input = CString::new("Hello, World!").unwrap();
        let input_bytes = b"Hello, World!";
        let key = b"my_secret_key";
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        // Get result from compute_hmac_bytes
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

        // Get result from compute_hmac_with_encoding with UTF8
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
        // ASCII and UTF8 produce same bytes for ASCII characters
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "0329A06B62CD16B33EB6792BE8C60B158D89A2EE3A876FCE9A881EBB488C0914",
            "HMAC-SHA256 with ASCII encoding should match UTF8 for ASCII input"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_with_encoding_unicode() {
        // Unicode (UTF-16LE) produces different bytes than UTF8
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
        // UTF-16LE "test" = [0x74, 0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00]
        // This should produce a different HMAC than UTF8
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
