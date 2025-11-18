//! Cryptographic hash functions (MD5, SHA1, SHA256, SHA384, SHA512, HMAC)

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use md5::Md5;
use sha1::Sha1;
use sha2::{Sha256, Sha384, Sha512, Digest};
use hmac::{Hmac, Mac};

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
pub extern "C" fn compute_hash(
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
    
    // Compute hash based on algorithm
    let hash_hex = match algorithm_str.to_uppercase().as_str() {
        "MD5" => {
            let mut hasher = Md5::new();
            hasher.update(&bytes);
            format!("{:x}", hasher.finalize())
        }
        "SHA1" => {
            let mut hasher = Sha1::new();
            hasher.update(&bytes);
            format!("{:x}", hasher.finalize())
        }
        "SHA256" => {
            let mut hasher = Sha256::new();
            hasher.update(&bytes);
            format!("{:x}", hasher.finalize())
        }
        "SHA384" => {
            let mut hasher = Sha384::new();
            hasher.update(&bytes);
            format!("{:x}", hasher.finalize())
        }
        "SHA512" => {
            let mut hasher = Sha512::new();
            hasher.update(&bytes);
            format!("{:x}", hasher.finalize())
        }
        _ => {
            crate::error::set_error(format!("Unsupported algorithm: {}. Supported: MD5, SHA1, SHA256, SHA384, SHA512", algorithm_str));
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
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `key` is a valid pointer to a byte array or null
/// - `key_length` accurately represents the number of key bytes
/// - `algorithm` is a valid null-terminated C string or null
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
/// Hex-encoded HMAC string, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn compute_hmac(
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
    
    // Create key slice
    let key_slice = unsafe {
        std::slice::from_raw_parts(key, key_length)
    };
    
    // Convert input to bytes (always UTF-8 for HMAC)
    let input_bytes = input_str.as_bytes();
    
    // Compute HMAC based on algorithm
    let hmac_hex = match algorithm_str.to_uppercase().as_str() {
        "MD5" => {
            type HmacMd5 = Hmac<Md5>;
            let mut mac = match HmacMd5::new_from_slice(key_slice) {
                Ok(m) => m,
                Err(_) => {
                    crate::error::set_error("Failed to create HMAC instance".to_string());
                    return std::ptr::null_mut();
                }
            };
            mac.update(input_bytes);
            format!("{:x}", mac.finalize().into_bytes())
        }
        "SHA1" => {
            type HmacSha1 = Hmac<Sha1>;
            let mut mac = match HmacSha1::new_from_slice(key_slice) {
                Ok(m) => m,
                Err(_) => {
                    crate::error::set_error("Failed to create HMAC instance".to_string());
                    return std::ptr::null_mut();
                }
            };
            mac.update(input_bytes);
            format!("{:x}", mac.finalize().into_bytes())
        }
        "SHA256" => {
            type HmacSha256 = Hmac<Sha256>;
            let mut mac = match HmacSha256::new_from_slice(key_slice) {
                Ok(m) => m,
                Err(_) => {
                    crate::error::set_error("Failed to create HMAC instance".to_string());
                    return std::ptr::null_mut();
                }
            };
            mac.update(input_bytes);
            format!("{:x}", mac.finalize().into_bytes())
        }
        "SHA384" => {
            type HmacSha384 = Hmac<Sha384>;
            let mut mac = match HmacSha384::new_from_slice(key_slice) {
                Ok(m) => m,
                Err(_) => {
                    crate::error::set_error("Failed to create HMAC instance".to_string());
                    return std::ptr::null_mut();
                }
            };
            mac.update(input_bytes);
            format!("{:x}", mac.finalize().into_bytes())
        }
        "SHA512" => {
            type HmacSha512 = Hmac<Sha512>;
            let mut mac = match HmacSha512::new_from_slice(key_slice) {
                Ok(m) => m,
                Err(_) => {
                    crate::error::set_error("Failed to create HMAC instance".to_string());
                    return std::ptr::null_mut();
                }
            };
            mac.update(input_bytes);
            format!("{:x}", mac.finalize().into_bytes())
        }
        _ => {
            crate::error::set_error(format!("Unsupported algorithm: {}. Supported: MD5, SHA1, SHA256, SHA384, SHA512", algorithm_str));
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
        || encoding.eq_ignore_ascii_case("UTF-16") {
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
        || encoding.eq_ignore_ascii_case("UTF-16BE") {
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
            ("MD5", "098f6bcd4621d373cade4e832627b4f6"),
            ("SHA1", "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"),
            ("SHA256", "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"),
            ("SHA384", "768412320f7b0aa5812fce428dc4706b3cae50e02a64caa16a782249bfe8efc4b7ef1ccb126255d196047dfedf17a0a9"),
            ("SHA512", "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff"),
        ];

        for (algorithm, expected_hash) in test_cases {
            let input = CString::new("test").unwrap();
            let algo = CString::new(algorithm).unwrap();
            let encoding = CString::new("UTF8").unwrap();

            let result = compute_hash(input.as_ptr(), algo.as_ptr(), encoding.as_ptr());

            assert!(!result.is_null(), "{} result should not be null", algorithm);
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str,
                expected_hash,
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

        let result = compute_hash(std::ptr::null(), algorithm.as_ptr(), encoding.as_ptr());

        assert!(result.is_null(), "Null input should return null");
    }

    #[test]
    fn test_compute_hash_null_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = compute_hash(input.as_ptr(), std::ptr::null(), encoding.as_ptr());

        assert!(result.is_null(), "Null algorithm should return null");
    }

    #[test]
    fn test_compute_hash_null_encoding_returns_null() {
        let input = CString::new("test").unwrap();
        let algorithm = CString::new("SHA256").unwrap();

        let result = compute_hash(input.as_ptr(), algorithm.as_ptr(), std::ptr::null());

        assert!(result.is_null(), "Null encoding should return null");
    }

    #[test]
    fn test_compute_hash_unsupported_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let algorithm = CString::new("UNSUPPORTED").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = compute_hash(input.as_ptr(), algorithm.as_ptr(), encoding.as_ptr());

        assert!(result.is_null(), "Unsupported algorithm should return null");
    }

    #[test]
    fn test_compute_hash_empty_string() {
        let input = CString::new("").unwrap();
        let algorithm = CString::new("SHA256").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = compute_hash(input.as_ptr(), algorithm.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Empty string should produce a hash");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(
            result_str,
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
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

        let result = compute_hash(input.as_ptr(), algorithm.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Large string should produce a hash");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str.len(), 64, "SHA256 hash should be 64 hex characters");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_compute_hmac_known_vectors() {
        let test_cases = vec![
            ("MD5", "63d6baf65df6bdee8f32b332e0930669"),
            ("SHA1", "1aa349585ed7ecbd3b9c486a30067e395ca4b356"),
            ("SHA256", "0329a06b62cd16b33eb6792be8c60b158d89a2ee3a876fce9a881ebb488c0914"),
            ("SHA384", "4e54a97be947e471e89cdd22c25b8ff704f458fdfcebd8a79a366ff0e52b607fe3f1e52bd1a839f89396d1a4b2cbe570"),
            ("SHA512", "f8a4f0a209167bc192a1bffaa01ecdb09e06c57f96530d92ec9ccea0090d290e55071306d6b654f26ae0c8721f7e48a2d7130b881151f2cec8d61d941a6be88a"),
        ];

        let input = CString::new("test").unwrap();
        let key = b"secret";

        for (algorithm, expected_hmac) in test_cases {
            let algo = CString::new(algorithm).unwrap();

            let result = compute_hmac(
                input.as_ptr(),
                key.as_ptr(),
                key.len(),
                algo.as_ptr()
            );

            assert!(!result.is_null(), "HMAC-{} result should not be null", algorithm);
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(
                result_str,
                expected_hmac,
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

        let result = compute_hmac(
            std::ptr::null(),
            key.as_ptr(),
            key.len(),
            algorithm.as_ptr()
        );

        assert!(result.is_null(), "Null input should return null");
    }

    #[test]
    fn test_compute_hmac_null_key_returns_null() {
        let input = CString::new("test").unwrap();
        let algorithm = CString::new("SHA256").unwrap();

        let result = compute_hmac(
            input.as_ptr(),
            std::ptr::null(),
            0,
            algorithm.as_ptr()
        );

        assert!(result.is_null(), "Null key should return null");
    }

    #[test]
    fn test_compute_hmac_null_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let key = b"secret";

        let result = compute_hmac(
            input.as_ptr(),
            key.as_ptr(),
            key.len(),
            std::ptr::null()
        );

        assert!(result.is_null(), "Null algorithm should return null");
    }

    #[test]
    fn test_compute_hmac_unsupported_algorithm_returns_null() {
        let input = CString::new("test").unwrap();
        let key = b"secret";
        let algorithm = CString::new("UNSUPPORTED").unwrap();

        let result = compute_hmac(
            input.as_ptr(),
            key.as_ptr(),
            key.len(),
            algorithm.as_ptr()
        );

        assert!(result.is_null(), "Unsupported algorithm should return null");
    }
}
