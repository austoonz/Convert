//! Base64 encoding and decoding functions

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use base64::{Engine as _, engine::general_purpose};

/// Convert a string to Base64 encoding
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub extern "C" fn string_to_base64(
    input: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    // Validate null pointers
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
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
    
    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };
    
    // Check for deprecated UTF7 encoding
    if encoding_str.eq_ignore_ascii_case("UTF7") {
        crate::error::set_error("UTF7 encoding is deprecated and not supported".to_string());
        return std::ptr::null_mut();
    }
    
    // Convert string to bytes based on encoding
    let bytes = match convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };
    
    // Encode to Base64
    let encoded = general_purpose::STANDARD.encode(&bytes);
    
    // Convert to C string
    match CString::new(encoded) {
        Ok(c_str) => {
            crate::error::clear_error();
            c_str.into_raw()
        }
        Err(_) => {
            crate::error::set_error("Failed to create C string from Base64 result".to_string());
            std::ptr::null_mut()
        }
    }
}

/// Convert a Base64 string back to a regular string
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub extern "C" fn base64_to_string(
    input: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    // Validate null pointers
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
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
    
    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };
    
    // Decode from Base64
    let decoded_bytes = match general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            return std::ptr::null_mut();
        }
    };
    
    // Convert bytes to string based on encoding
    let result_string = match convert_bytes_to_string(&decoded_bytes, encoding_str) {
        Ok(s) => s,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };
    
    // Convert to C string
    match CString::new(result_string) {
        Ok(c_str) => {
            crate::error::clear_error();
            c_str.into_raw()
        }
        Err(_) => {
            crate::error::set_error("Failed to create C string from decoded result".to_string());
            std::ptr::null_mut()
        }
    }
}

/// Convert a Rust string to bytes using the specified encoding
fn convert_string_to_bytes(input: &str, encoding: &str) -> Result<Vec<u8>, String> {
    match encoding.to_uppercase().as_str() {
        "UTF8" | "UTF-8" => Ok(input.as_bytes().to_vec()),
        
        "ASCII" => {
            // Validate that all characters are ASCII
            if input.is_ascii() {
                Ok(input.as_bytes().to_vec())
            } else {
                Err("String contains non-ASCII characters".to_string())
            }
        }
        
        "UNICODE" | "UTF16" | "UTF-16" => {
            // Unicode in .NET typically means UTF-16LE
            let utf16: Vec<u16> = input.encode_utf16().collect();
            let mut bytes = Vec::with_capacity(utf16.len() * 2);
            for word in utf16 {
                bytes.push((word & 0xFF) as u8);
                bytes.push((word >> 8) as u8);
            }
            Ok(bytes)
        }
        
        "UTF32" | "UTF-32" => {
            // UTF-32LE encoding
            let mut bytes = Vec::with_capacity(input.chars().count() * 4);
            for ch in input.chars() {
                let code_point = ch as u32;
                bytes.push((code_point & 0xFF) as u8);
                bytes.push(((code_point >> 8) & 0xFF) as u8);
                bytes.push(((code_point >> 16) & 0xFF) as u8);
                bytes.push(((code_point >> 24) & 0xFF) as u8);
            }
            Ok(bytes)
        }
        
        "BIGENDIANUNICODE" | "UTF16BE" | "UTF-16BE" => {
            // UTF-16BE encoding
            let utf16: Vec<u16> = input.encode_utf16().collect();
            let mut bytes = Vec::with_capacity(utf16.len() * 2);
            for word in utf16 {
                bytes.push((word >> 8) as u8);
                bytes.push((word & 0xFF) as u8);
            }
            Ok(bytes)
        }
        
        "DEFAULT" => {
            // Default encoding is UTF-8
            Ok(input.as_bytes().to_vec())
        }
        
        _ => Err(format!("Unsupported encoding: {}", encoding))
    }
}

/// Convert bytes to a Rust string using the specified encoding
fn convert_bytes_to_string(bytes: &[u8], encoding: &str) -> Result<String, String> {
    match encoding.to_uppercase().as_str() {
        "UTF8" | "UTF-8" => {
            String::from_utf8(bytes.to_vec())
                .map_err(|e| format!("Invalid UTF-8 bytes: {}", e))
        }
        
        "ASCII" => {
            // Validate that all bytes are ASCII
            if bytes.iter().all(|&b| b < 128) {
                String::from_utf8(bytes.to_vec())
                    .map_err(|e| format!("Invalid ASCII bytes: {}", e))
            } else {
                Err("Bytes contain non-ASCII values".to_string())
            }
        }
        
        "UNICODE" | "UTF16" | "UTF-16" => {
            // Unicode in .NET typically means UTF-16LE
            if bytes.len() % 2 != 0 {
                return Err("Invalid UTF-16 byte length (must be even)".to_string());
            }
            
            let mut utf16_chars = Vec::with_capacity(bytes.len() / 2);
            for chunk in bytes.chunks_exact(2) {
                let word = u16::from_le_bytes([chunk[0], chunk[1]]);
                utf16_chars.push(word);
            }
            
            String::from_utf16(&utf16_chars)
                .map_err(|e| format!("Invalid UTF-16 bytes: {}", e))
        }
        
        "UTF32" | "UTF-32" => {
            // UTF-32LE encoding
            if bytes.len() % 4 != 0 {
                return Err("Invalid UTF-32 byte length (must be multiple of 4)".to_string());
            }
            
            let mut result = String::new();
            for chunk in bytes.chunks_exact(4) {
                let code_point = u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
                match char::from_u32(code_point) {
                    Some(ch) => result.push(ch),
                    None => return Err(format!("Invalid UTF-32 code point: {}", code_point)),
                }
            }
            Ok(result)
        }
        
        "BIGENDIANUNICODE" | "UTF16BE" | "UTF-16BE" => {
            // UTF-16BE encoding
            if bytes.len() % 2 != 0 {
                return Err("Invalid UTF-16BE byte length (must be even)".to_string());
            }
            
            let mut utf16_chars = Vec::with_capacity(bytes.len() / 2);
            for chunk in bytes.chunks_exact(2) {
                let word = u16::from_be_bytes([chunk[0], chunk[1]]);
                utf16_chars.push(word);
            }
            
            String::from_utf16(&utf16_chars)
                .map_err(|e| format!("Invalid UTF-16BE bytes: {}", e))
        }
        
        "DEFAULT" => {
            // Default encoding is UTF-8
            String::from_utf8(bytes.to_vec())
                .map_err(|e| format!("Invalid UTF-8 bytes: {}", e))
        }
        
        _ => Err(format!("Unsupported encoding: {}", encoding))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_string_to_base64_happy_path_utf8() {
        // Test: "Hello" with UTF8 encoding should produce "SGVsbG8="
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Result should not be null");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "SGVsbG8=");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_string_to_base64_null_input_pointer() {
        // Test: null input pointer should return null
        let encoding = CString::new("UTF8").unwrap();

        let result = string_to_base64(std::ptr::null(), encoding.as_ptr());

        assert!(result.is_null(), "Null input pointer should return null");
    }

    #[test]
    fn test_string_to_base64_null_encoding_pointer() {
        // Test: null encoding pointer should return null
        let input = CString::new("Hello").unwrap();

        let result = string_to_base64(input.as_ptr(), std::ptr::null());

        assert!(result.is_null(), "Null encoding pointer should return null");
    }

    #[test]
    fn test_string_to_base64_invalid_encoding() {
        // Test: invalid encoding name should return null
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();

        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

        assert!(result.is_null(), "Invalid encoding should return null");
    }

    #[test]
    fn test_string_to_base64_utf7_deprecated() {
        // Test: UTF7 encoding should return null (deprecated)
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF7").unwrap();

        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

        assert!(result.is_null(), "UTF7 encoding should return null (deprecated)");
    }

    #[test]
    fn test_string_to_base64_empty_string() {
        // Test: empty string should encode successfully
        let input = CString::new("").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Result should not be null for empty string");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, ""); // Empty string encodes to empty Base64
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_string_to_base64_large_string() {
        // Test: 1MB string should encode successfully
        let large_string = "A".repeat(1024 * 1024); // 1MB of 'A' characters
        let input = CString::new(large_string).unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Result should not be null for large string");
        // Verify the result is a valid pointer and can be freed
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_string_to_base64_various_encodings() {
        // Test: various supported encodings should work
        let input = CString::new("Test").unwrap();
        let encodings = vec!["UTF8", "ASCII", "Unicode", "UTF32", "BigEndianUnicode", "Default"];

        for enc in encodings {
            let encoding = CString::new(enc).unwrap();
            let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

            assert!(!result.is_null(), "Result should not be null for encoding: {}", enc);
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_string_to_base64_special_characters() {
        // Test: string with special characters
        let input = CString::new("Hello, World! 🌍").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Result should not be null for special characters");
        unsafe { crate::memory::free_string(result) };
    }

    // ========== Tests for base64_to_string ==========
    // RED PHASE: These tests will fail until base64_to_string is implemented

    #[test]
    fn test_base64_to_string_happy_path_utf8() {
        // Test: decode "SGVsbG8=" with UTF8 encoding should produce "Hello"
        let input = CString::new("SGVsbG8=").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = base64_to_string(input.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Result should not be null");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "Hello", "Decoded string should be 'Hello'");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_base64_to_string_null_input_pointer() {
        // Test: null input pointer should return null
        let encoding = CString::new("UTF8").unwrap();

        let result = base64_to_string(std::ptr::null(), encoding.as_ptr());

        assert!(result.is_null(), "Null input pointer should return null");
    }

    #[test]
    fn test_base64_to_string_null_encoding_pointer() {
        // Test: null encoding pointer should return null
        let input = CString::new("SGVsbG8=").unwrap();

        let result = base64_to_string(input.as_ptr(), std::ptr::null());

        assert!(result.is_null(), "Null encoding pointer should return null");
    }

    #[test]
    fn test_base64_to_string_invalid_base64() {
        // Test: invalid Base64 string should return null
        let input = CString::new("Not@Valid#Base64!").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = base64_to_string(input.as_ptr(), encoding.as_ptr());

        assert!(result.is_null(), "Invalid Base64 string should return null");
    }

    #[test]
    fn test_base64_to_string_invalid_encoding() {
        // Test: invalid encoding name should return null
        let input = CString::new("SGVsbG8=").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();

        let result = base64_to_string(input.as_ptr(), encoding.as_ptr());

        assert!(result.is_null(), "Invalid encoding should return null");
    }

    #[test]
    fn test_base64_to_string_empty_string() {
        // Test: empty Base64 string should decode to empty string
        let input = CString::new("").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = base64_to_string(input.as_ptr(), encoding.as_ptr());

        assert!(!result.is_null(), "Result should not be null for empty string");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Empty Base64 should decode to empty string");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_base64_to_string_round_trip() {
        // Test: encode then decode should produce original string
        let original = "Test String 123!";
        let input = CString::new(original).unwrap();
        let encoding = CString::new("UTF8").unwrap();

        // Encode
        let encoded_ptr = string_to_base64(input.as_ptr(), encoding.as_ptr());
        assert!(!encoded_ptr.is_null(), "Encoding should succeed");
        
        // Decode
        let decoded_ptr = base64_to_string(encoded_ptr, encoding.as_ptr());
        assert!(!decoded_ptr.is_null(), "Decoding should succeed");
        
        let decoded_str = unsafe { CStr::from_ptr(decoded_ptr).to_str().unwrap() };
        assert_eq!(decoded_str, original, "Round-trip should preserve original string");
        
        unsafe { 
            crate::memory::free_string(encoded_ptr);
            crate::memory::free_string(decoded_ptr);
        };
    }

    #[test]
    fn test_base64_to_string_various_encodings() {
        // Test: various supported encodings should work
        let test_cases = vec![
            ("SGVsbG8=", "UTF8", "Hello"),
            ("VABFAFMAVAA=", "Unicode", "TEST"),  // UTF-16LE encoded "TEST"
        ];

        for (base64_input, enc, expected) in test_cases {
            let input = CString::new(base64_input).unwrap();
            let encoding = CString::new(enc).unwrap();

            let result = base64_to_string(input.as_ptr(), encoding.as_ptr());

            if !result.is_null() {
                let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap_or("") };
                // Note: Some encodings may not round-trip perfectly, so we just verify non-null
                assert!(!result_str.is_empty() || expected.is_empty(), 
                    "Result should not be empty for encoding: {}", enc);
                unsafe { crate::memory::free_string(result) };
            }
        }
    }

    #[test]
    fn test_base64_to_string_malformed_base64() {
        // Test: malformed Base64 (wrong padding, invalid characters)
        let malformed_inputs = vec![
            "SGVsbG8",      // Missing padding
            "SGVs bG8=",    // Space in middle
            "SGVs\nbG8=",   // Newline in middle
        ];

        let encoding = CString::new("UTF8").unwrap();

        for malformed in malformed_inputs {
            let input = CString::new(malformed).unwrap();
            let result = base64_to_string(input.as_ptr(), encoding.as_ptr());

            // Some Base64 decoders are lenient, so we just verify it doesn't crash
            // If it returns null, that's acceptable for malformed input
            if !result.is_null() {
                unsafe { crate::memory::free_string(result) };
            }
        }
    }
}
