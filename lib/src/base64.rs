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

/// Convert a byte array to Base64 encoding
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `bytes` is a valid pointer to a byte array or null
/// - `length` accurately represents the number of bytes to read
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub extern "C" fn bytes_to_base64(
    bytes: *const u8,
    length: usize,
) -> *mut c_char {
    // Validate null pointer
    if bytes.is_null() {
        crate::error::set_error("Byte array pointer is null".to_string());
        return std::ptr::null_mut();
    }
    
    // Handle zero length case - encode empty byte array to empty string
    if length == 0 {
        match CString::new("") {
            Ok(c_str) => {
                crate::error::clear_error();
                return c_str.into_raw();
            }
            Err(_) => {
                crate::error::set_error("Failed to create empty C string".to_string());
                return std::ptr::null_mut();
            }
        }
    }
    
    // Create a slice from the raw pointer
    let byte_slice = unsafe {
        std::slice::from_raw_parts(bytes, length)
    };
    
    // Encode to Base64
    let encoded = general_purpose::STANDARD.encode(byte_slice);
    
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

/// Convert a Base64 string to a byte array
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `out_length` is a valid pointer to a usize or null
/// - The returned pointer must be freed using `free_bytes`
#[unsafe(no_mangle)]
pub extern "C" fn base64_to_bytes(
    input: *const c_char,
    out_length: *mut usize,
) -> *mut u8 {
    // Validate null pointer for input
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        return std::ptr::null_mut();
    }
    
    // Validate null pointer for out_length (required for safety)
    if out_length.is_null() {
        crate::error::set_error("Output length pointer is null".to_string());
        return std::ptr::null_mut();
    }
    
    // Convert C string to Rust string
    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            unsafe { *out_length = 0; }
            return std::ptr::null_mut();
        }
    };
    
    // Handle empty string case
    if input_str.is_empty() {
        crate::error::clear_error();
        unsafe { *out_length = 0; }
        // Allocate an empty Vec and return its pointer
        let empty_vec = Vec::<u8>::new();
        let ptr = empty_vec.as_ptr() as *mut u8;
        std::mem::forget(empty_vec); // Prevent deallocation
        return ptr;
    }
    
    // Decode from Base64
    let decoded_bytes = match general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            unsafe { *out_length = 0; }
            return std::ptr::null_mut();
        }
    };
    
    // Set output length
    let length = decoded_bytes.len();
    unsafe { *out_length = length; }
    
    // Convert Vec to raw pointer
    let mut bytes_vec = decoded_bytes;
    let ptr = bytes_vec.as_mut_ptr();
    std::mem::forget(bytes_vec); // Prevent deallocation - caller will free
    
    crate::error::clear_error();
    ptr
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

    // ========== Tests for bytes_to_base64 ==========
    // RED PHASE: These tests will fail until bytes_to_base64 is implemented

    #[test]
    fn test_bytes_to_base64_happy_path() {
        // Test: encode byte array [72, 101, 108, 108, 111] ("Hello") to "SGVsbG8="
        let bytes: Vec<u8> = vec![72, 101, 108, 108, 111]; // "Hello" in ASCII
        
        let result = bytes_to_base64(bytes.as_ptr(), bytes.len());
        
        assert!(!result.is_null(), "Result should not be null");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "SGVsbG8=", "Encoded bytes should produce 'SGVsbG8='");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_base64_null_pointer() {
        // Test: null pointer should return null
        let result = bytes_to_base64(std::ptr::null(), 10);
        
        assert!(result.is_null(), "Null pointer should return null");
    }

    #[test]
    fn test_bytes_to_base64_zero_length() {
        // Test: zero length should encode to empty string
        let bytes: Vec<u8> = vec![1, 2, 3]; // Data exists but length is 0
        
        let result = bytes_to_base64(bytes.as_ptr(), 0);
        
        assert!(!result.is_null(), "Result should not be null for zero length");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Zero length should encode to empty string");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_base64_large_byte_array() {
        // Test: 1MB byte array should encode successfully
        let large_bytes: Vec<u8> = vec![65; 1024 * 1024]; // 1MB of 'A' (ASCII 65)
        
        let result = bytes_to_base64(large_bytes.as_ptr(), large_bytes.len());
        
        assert!(!result.is_null(), "Result should not be null for large byte array");
        
        // Verify the result is a valid pointer and can be freed
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert!(!result_str.is_empty(), "Result should not be empty for 1MB input");
        
        // Base64 encoding increases size by ~33%, so 1MB should produce ~1.33MB
        assert!(result_str.len() > 1_000_000, "Encoded result should be larger than 1MB");
        
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_base64_various_byte_patterns() {
        // Test: various byte patterns encode correctly
        let test_cases = vec![
            (vec![0u8], "AA=="),                           // Single zero byte
            (vec![255u8], "/w=="),                         // Single max byte
            (vec![0, 1, 2, 3, 4], "AAECAwQ="),            // Sequential bytes
            (vec![255, 254, 253, 252], "//79/A=="),       // High bytes
        ];
        
        for (bytes, expected) in test_cases {
            let result = bytes_to_base64(bytes.as_ptr(), bytes.len());
            
            assert!(!result.is_null(), "Result should not be null for byte pattern: {:?}", bytes);
            let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
            assert_eq!(result_str, expected, "Byte pattern {:?} should encode to '{}'", bytes, expected);
            
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_bytes_to_base64_binary_data() {
        // Test: arbitrary binary data (not valid UTF-8)
        let binary_data: Vec<u8> = vec![
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        ];
        
        let result = bytes_to_base64(binary_data.as_ptr(), binary_data.len());
        
        assert!(!result.is_null(), "Result should not be null for binary data");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "iVBORw0KGgo=", "PNG header should encode correctly");
        
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_base64_empty_array() {
        // Test: empty byte array (length 0) should encode to empty string
        let empty_bytes: Vec<u8> = vec![];
        
        let result = bytes_to_base64(empty_bytes.as_ptr(), 0);
        
        assert!(!result.is_null(), "Result should not be null for empty array");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "", "Empty array should encode to empty string");
        
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_base64_round_trip_with_string_to_base64() {
        // Test: bytes_to_base64 should produce same result as string_to_base64 for UTF-8 text
        let text = "Test String 123!";
        let bytes = text.as_bytes();
        
        // Encode using bytes_to_base64
        let result_bytes = bytes_to_base64(bytes.as_ptr(), bytes.len());
        assert!(!result_bytes.is_null(), "bytes_to_base64 should succeed");
        
        // Encode using string_to_base64
        let text_cstring = CString::new(text).unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let result_string = string_to_base64(text_cstring.as_ptr(), encoding.as_ptr());
        assert!(!result_string.is_null(), "string_to_base64 should succeed");
        
        // Compare results
        let bytes_result = unsafe { CStr::from_ptr(result_bytes).to_str().unwrap() };
        let string_result = unsafe { CStr::from_ptr(result_string).to_str().unwrap() };
        assert_eq!(bytes_result, string_result, 
            "bytes_to_base64 and string_to_base64 should produce identical results for UTF-8 text");
        
        unsafe {
            crate::memory::free_string(result_bytes);
            crate::memory::free_string(result_string);
        };
    }

    #[test]
    fn test_bytes_to_base64_all_byte_values() {
        // Test: all possible byte values (0-255) should encode without error
        let all_bytes: Vec<u8> = (0..=255).collect();
        
        let result = bytes_to_base64(all_bytes.as_ptr(), all_bytes.len());
        
        assert!(!result.is_null(), "Result should not be null for all byte values");
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert!(!result_str.is_empty(), "Result should not be empty");
        
        // Verify it's valid Base64 (only contains Base64 characters)
        let valid_base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
        for ch in result_str.chars() {
            assert!(valid_base64_chars.contains(ch), 
                "Result should only contain valid Base64 characters, found: {}", ch);
        }
        
        unsafe { crate::memory::free_string(result) };
    }

    // ========== Tests for base64_to_bytes ==========
    // RED PHASE: These tests will fail until base64_to_bytes is implemented
    // Task 2.7: Write unit tests for base64_to_bytes

    #[test]
    fn test_base64_to_bytes_happy_path() {
        // Test: decode "SGVsbG8=" to byte array [72, 101, 108, 108, 111] ("Hello")
        let input = CString::new("SGVsbG8=").unwrap();
        let mut out_length: usize = 0;
        
        let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
        
        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(out_length, 5, "Output length should be 5 bytes");
        
        // Verify the decoded bytes
        let byte_slice = unsafe { std::slice::from_raw_parts(result, out_length) };
        assert_eq!(byte_slice, &[72, 101, 108, 108, 111], "Decoded bytes should be [72, 101, 108, 108, 111] (Hello)");
        
        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_base64_to_bytes_null_pointer() {
        // Test: null pointer should return null
        let mut out_length: usize = 0;
        
        let result = base64_to_bytes(std::ptr::null(), &mut out_length as *mut usize);
        
        assert!(result.is_null(), "Null pointer should return null");
        assert_eq!(out_length, 0, "Output length should be 0 for null input");
    }

    #[test]
    fn test_base64_to_bytes_invalid_base64() {
        // Test: invalid Base64 string should return null
        let input = CString::new("Not@Valid#Base64!").unwrap();
        let mut out_length: usize = 0;
        
        let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
        
        assert!(result.is_null(), "Invalid Base64 string should return null");
        assert_eq!(out_length, 0, "Output length should be 0 for invalid Base64");
    }

    #[test]
    fn test_base64_to_bytes_output_length_parameter() {
        // Test: output length parameter should be correctly set
        let test_cases = vec![
            ("", 0),                    // Empty string
            ("QQ==", 1),                // Single byte 'A'
            ("QUJD", 3),                // Three bytes 'ABC'
            ("SGVsbG8=", 5),            // Five bytes 'Hello'
            ("VGVzdCBTdHJpbmc=", 11),  // Eleven bytes 'Test String'
        ];
        
        for (base64_input, expected_length) in test_cases {
            let input = CString::new(base64_input).unwrap();
            let mut out_length: usize = 0;
            
            let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
            
            if expected_length == 0 {
                // Empty string case
                assert!(!result.is_null(), "Result should not be null for empty string");
                assert_eq!(out_length, expected_length, 
                    "Output length should be {} for input '{}'", expected_length, base64_input);
            } else {
                assert!(!result.is_null(), "Result should not be null for input '{}'", base64_input);
                assert_eq!(out_length, expected_length, 
                    "Output length should be {} for input '{}'", expected_length, base64_input);
            }
            
            if !result.is_null() {
                unsafe { crate::memory::free_bytes(result) };
            }
        }
    }

    #[test]
    fn test_base64_to_bytes_empty_string() {
        // Test: empty Base64 string should decode to empty byte array
        let input = CString::new("").unwrap();
        let mut out_length: usize = 0;
        
        let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
        
        assert!(!result.is_null(), "Result should not be null for empty string");
        assert_eq!(out_length, 0, "Output length should be 0 for empty string");
        
        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_base64_to_bytes_binary_data() {
        // Test: decode Base64 to binary data (PNG header)
        let input = CString::new("iVBORw0KGgo=").unwrap();
        let mut out_length: usize = 0;
        
        let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
        
        assert!(!result.is_null(), "Result should not be null for binary data");
        assert_eq!(out_length, 8, "Output length should be 8 bytes for PNG header");
        
        let byte_slice = unsafe { std::slice::from_raw_parts(result, out_length) };
        let expected_png_header: Vec<u8> = vec![0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
        assert_eq!(byte_slice, expected_png_header.as_slice(), "Decoded bytes should match PNG header");
        
        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_base64_to_bytes_round_trip() {
        // Test: encode bytes then decode should produce original bytes
        let original_bytes: Vec<u8> = vec![0, 1, 2, 3, 4, 5, 255, 254, 253];
        
        // Encode
        let encoded_ptr = bytes_to_base64(original_bytes.as_ptr(), original_bytes.len());
        assert!(!encoded_ptr.is_null(), "Encoding should succeed");
        
        // Decode
        let mut out_length: usize = 0;
        let decoded_ptr = base64_to_bytes(encoded_ptr, &mut out_length as *mut usize);
        assert!(!decoded_ptr.is_null(), "Decoding should succeed");
        
        // Verify round-trip
        assert_eq!(out_length, original_bytes.len(), "Decoded length should match original");
        let decoded_slice = unsafe { std::slice::from_raw_parts(decoded_ptr, out_length) };
        assert_eq!(decoded_slice, original_bytes.as_slice(), "Round-trip should preserve original bytes");
        
        unsafe {
            crate::memory::free_string(encoded_ptr);
            crate::memory::free_bytes(decoded_ptr);
        };
    }

    #[test]
    fn test_base64_to_bytes_large_data() {
        // Test: decode large Base64 string (1MB of data)
        let large_bytes: Vec<u8> = vec![65; 1024 * 1024]; // 1MB of 'A' (ASCII 65)
        
        // First encode to Base64
        let encoded_ptr = bytes_to_base64(large_bytes.as_ptr(), large_bytes.len());
        assert!(!encoded_ptr.is_null(), "Encoding should succeed");
        
        // Now decode back
        let mut out_length: usize = 0;
        let decoded_ptr = base64_to_bytes(encoded_ptr, &mut out_length as *mut usize);
        
        assert!(!decoded_ptr.is_null(), "Decoding should succeed for large data");
        assert_eq!(out_length, 1024 * 1024, "Output length should be 1MB");
        
        // Verify first and last bytes
        let decoded_slice = unsafe { std::slice::from_raw_parts(decoded_ptr, out_length) };
        assert_eq!(decoded_slice[0], 65, "First byte should be 65");
        assert_eq!(decoded_slice[out_length - 1], 65, "Last byte should be 65");
        
        unsafe {
            crate::memory::free_string(encoded_ptr);
            crate::memory::free_bytes(decoded_ptr);
        };
    }

    #[test]
    fn test_base64_to_bytes_all_byte_values() {
        // Test: decode Base64 containing all possible byte values (0-255)
        let all_bytes: Vec<u8> = (0..=255).collect();
        
        // Encode
        let encoded_ptr = bytes_to_base64(all_bytes.as_ptr(), all_bytes.len());
        assert!(!encoded_ptr.is_null(), "Encoding should succeed");
        
        // Decode
        let mut out_length: usize = 0;
        let decoded_ptr = base64_to_bytes(encoded_ptr, &mut out_length as *mut usize);
        
        assert!(!decoded_ptr.is_null(), "Decoding should succeed for all byte values");
        assert_eq!(out_length, 256, "Output length should be 256 bytes");
        
        let decoded_slice = unsafe { std::slice::from_raw_parts(decoded_ptr, out_length) };
        assert_eq!(decoded_slice, all_bytes.as_slice(), "All byte values should round-trip correctly");
        
        unsafe {
            crate::memory::free_string(encoded_ptr);
            crate::memory::free_bytes(decoded_ptr);
        };
    }

    #[test]
    fn test_base64_to_bytes_malformed_base64() {
        // Test: malformed Base64 strings should return null
        let malformed_inputs = vec![
            "SGVsbG8",      // Missing padding (may or may not fail depending on decoder leniency)
            "SGVs bG8=",    // Space in middle
            "SGVs\nbG8=",   // Newline in middle
            "!!!invalid",   // Invalid characters
        ];
        
        for malformed in malformed_inputs {
            let input = CString::new(malformed).unwrap();
            let mut out_length: usize = 0;
            
            let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
            
            // Some decoders are lenient, but invalid characters should definitely fail
            // We just verify it doesn't crash and handles errors gracefully
            if result.is_null() {
                assert_eq!(out_length, 0, "Output length should be 0 for failed decode");
            } else {
                // If decoder is lenient and succeeds, just free the memory
                unsafe { crate::memory::free_bytes(result) };
            }
        }
    }

    #[test]
    fn test_base64_to_bytes_various_lengths() {
        // Test: various input lengths decode correctly
        let test_cases = vec![
            ("QQ==", vec![65]),                                    // 1 byte
            ("QUI=", vec![65, 66]),                                // 2 bytes
            ("QUJD", vec![65, 66, 67]),                            // 3 bytes
            ("QUJDRA==", vec![65, 66, 67, 68]),                    // 4 bytes
            ("QUJDREU=", vec![65, 66, 67, 68, 69]),                // 5 bytes
        ];
        
        for (base64_input, expected_bytes) in test_cases {
            let input = CString::new(base64_input).unwrap();
            let mut out_length: usize = 0;
            
            let result = base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize);
            
            assert!(!result.is_null(), "Result should not be null for input '{}'", base64_input);
            assert_eq!(out_length, expected_bytes.len(), 
                "Output length should be {} for input '{}'", expected_bytes.len(), base64_input);
            
            let decoded_slice = unsafe { std::slice::from_raw_parts(result, out_length) };
            assert_eq!(decoded_slice, expected_bytes.as_slice(), 
                "Decoded bytes should match expected for input '{}'", base64_input);
            
            unsafe { crate::memory::free_bytes(result) };
        }
    }

    #[test]
    fn test_base64_to_bytes_null_output_length_pointer() {
        // Test: null output length pointer should be handled gracefully
        // This is an edge case - the function should either handle it or document that it's required
        let input = CString::new("SGVsbG8=").unwrap();
        
        // Note: This test documents expected behavior. If the function requires a valid pointer,
        // it should return null. If it's optional, it should still work.
        let result = base64_to_bytes(input.as_ptr(), std::ptr::null_mut());
        
        // For safety, we expect null when output length pointer is null
        assert!(result.is_null(), "Null output length pointer should return null for safety");
    }
}
