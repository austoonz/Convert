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
    let bytes = match convert_string_to_bytes(input_str, encoding_str) {
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

/// Compute an HMAC (Hash-based Message Authentication Code)
///
/// Computes a keyed-hash message authentication code using the specified
/// cryptographic hash algorithm. The input is always treated as UTF-8 encoded.
/// Returns the HMAC as an uppercase hexadecimal string for compatibility with
/// .NET implementations.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `key` is a valid pointer to a byte array of at least `key_length` bytes or null
/// - `key_length` accurately represents the number of key bytes
/// - `algorithm` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
/// - This function is thread-safe: uses thread-local error storage
///
/// # Supported Algorithms
/// - MD5 (not recommended for security-critical applications)
/// - SHA1 (not recommended for security-critical applications)
/// - SHA256 (recommended)
/// - SHA384
/// - SHA512
///
/// # Arguments
/// * `input` - Null-terminated UTF-8 string to compute HMAC for
/// * `key` - Byte array containing the secret key
/// * `key_length` - Number of bytes in the key array
/// * `algorithm` - Null-terminated string specifying the hash algorithm
///
/// # Returns
/// Pointer to null-terminated hex-encoded HMAC string, or null on error.
/// The caller must free the returned pointer using `free_string`.
///
/// # Error Handling
/// Returns null and sets thread-local error message on:
/// - Null pointer arguments
/// - Invalid UTF-8 in input or algorithm strings
/// - Unsupported algorithm name
/// - HMAC computation failure
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compute_hmac(
    input: *const c_char,
    key: *const u8,
    key_length: usize,
    algorithm: *const c_char,
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

    // SAFETY: input is guaranteed non-null by check above
    // CStr::from_ptr requires a valid null-terminated C string
    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            return std::ptr::null_mut();
        }
    };

    // SAFETY: algorithm is guaranteed non-null by check above
    // CStr::from_ptr requires a valid null-terminated C string
    let algorithm_str = match unsafe { CStr::from_ptr(algorithm).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in algorithm string".to_string());
            return std::ptr::null_mut();
        }
    };

    // SAFETY: key is guaranteed non-null and key_length is provided by caller
    // from_raw_parts requires that key points to at least key_length valid bytes
    let key_slice = unsafe { std::slice::from_raw_parts(key, key_length) };

    // Convert input to bytes (always UTF-8 for HMAC)
    let input_bytes = input_str.as_bytes();

    // Compute HMAC using the specified algorithm
    let hmac_hex = match compute_hmac_with_algorithm(algorithm_str, key_slice, input_bytes) {
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

/// Convert a Rust string to bytes using the specified encoding
fn convert_string_to_bytes(input: &str, encoding: &str) -> Result<Vec<u8>, String> {
    if encoding.eq_ignore_ascii_case("UTF8") || encoding.eq_ignore_ascii_case("UTF-8") {
        Ok(input.as_bytes().to_vec())
    } else if encoding.eq_ignore_ascii_case("ASCII") {
        if input.is_ascii() {
            Ok(input.as_bytes().to_vec())
        } else {
            Err("String contains non-ASCII characters".to_string())
        }
    } else if encoding.eq_ignore_ascii_case("UNICODE")
        || encoding.eq_ignore_ascii_case("UTF16")
        || encoding.eq_ignore_ascii_case("UTF-16")
    {
        let utf16: Vec<u16> = input.encode_utf16().collect();
        let mut bytes = Vec::with_capacity(utf16.len() * 2);
        for word in utf16 {
            bytes.push((word & 0xFF) as u8);
            bytes.push((word >> 8) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("UTF32") || encoding.eq_ignore_ascii_case("UTF-32") {
        let mut bytes = Vec::with_capacity(input.chars().count() * 4);
        for ch in input.chars() {
            let code_point = ch as u32;
            bytes.push((code_point & 0xFF) as u8);
            bytes.push(((code_point >> 8) & 0xFF) as u8);
            bytes.push(((code_point >> 16) & 0xFF) as u8);
            bytes.push(((code_point >> 24) & 0xFF) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("BIGENDIANUNICODE")
        || encoding.eq_ignore_ascii_case("UTF16BE")
        || encoding.eq_ignore_ascii_case("UTF-16BE")
    {
        let utf16: Vec<u16> = input.encode_utf16().collect();
        let mut bytes = Vec::with_capacity(utf16.len() * 2);
        for word in utf16 {
            bytes.push((word >> 8) as u8);
            bytes.push((word & 0xFF) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("DEFAULT") {
        Ok(input.as_bytes().to_vec())
    } else {
        Err(format!("Unsupported encoding: {}", encoding))
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

    #[test]
    fn test_compute_hmac_known_vectors() {
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

        let input = CString::new("test").unwrap();
        let key = b"secret";

        for (algorithm, expected_hmac) in test_cases {
            let algo = CString::new(algorithm).unwrap();

            let result =
                unsafe { compute_hmac(input.as_ptr(), key.as_ptr(), key.len(), algo.as_ptr()) };

            assert!(
                !result.is_null(),
                "HMAC-{} result should not be null",
                algorithm
            );
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str, expected_hmac,
                "HMAC-{} of 'test' with key 'secret' should match known vector",
                algorithm
            );
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_compute_hmac_null_input_returns_null() {
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result = unsafe {
            compute_hmac(
                std::ptr::null(),
                key.as_ptr(),
                key.len(),
                algorithm.as_ptr(),
            )
        };

        assert!(result.is_null(), "Null input should return null");
    }

    #[test]
    fn test_compute_hmac_null_key_returns_null() {
        let input = CString::new("test").unwrap();
        let algorithm = CString::new("SHA256").unwrap();

        let result =
            unsafe { compute_hmac(input.as_ptr(), std::ptr::null(), 0, algorithm.as_ptr()) };

        assert!(result.is_null(), "Null key should return null");
    }

    #[test]
    fn test_compute_hmac_null_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let key = b"secret";

        let result =
            unsafe { compute_hmac(input.as_ptr(), key.as_ptr(), key.len(), std::ptr::null()) };

        assert!(result.is_null(), "Null algorithm should return null");
    }

    #[test]
    fn test_compute_hmac_unsupported_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("UNSUPPORTED").unwrap();

        let result =
            unsafe { compute_hmac(input.as_ptr(), key.as_ptr(), key.len(), algorithm.as_ptr()) };

        assert!(result.is_null(), "Unsupported algorithm should return null");
    }

    #[test]
    fn test_compute_hmac_empty_input() {
        let input = CString::new("").unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result =
            unsafe { compute_hmac(input.as_ptr(), key.as_ptr(), key.len(), algorithm.as_ptr()) };

        assert!(!result.is_null(), "Empty input should produce an HMAC");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str, "F9E66E179B6747AE54108F82F8ADE8B3C25D76FD30AFDE6C395822C530196169",
            "HMAC-SHA256 of empty string with key 'secret' should match known vector"
        );
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_large_input() {
        let large_input = "A".repeat(1_000_000);
        let input = CString::new(large_input).unwrap();
        let key = b"secret";
        let algorithm = CString::new("SHA256").unwrap();

        let result =
            unsafe { compute_hmac(input.as_ptr(), key.as_ptr(), key.len(), algorithm.as_ptr()) };

        assert!(!result.is_null(), "Large input should produce an HMAC");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str.len(),
            64,
            "HMAC-SHA256 should be 64 hex characters"
        );
        unsafe { crate::memory::free_string(result) };
    }
}
