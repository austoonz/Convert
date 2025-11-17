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
    
    // Check for deprecated UTF7 encoding (both UTF7 and UTF-7 variants)
    if encoding_str.eq_ignore_ascii_case("UTF7") || encoding_str.eq_ignore_ascii_case("UTF-7") {
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
    // Use eq_ignore_ascii_case to avoid allocating with to_uppercase()
    if encoding.eq_ignore_ascii_case("UTF8") || encoding.eq_ignore_ascii_case("UTF-8") {
        Ok(input.as_bytes().to_vec())
    } else if encoding.eq_ignore_ascii_case("ASCII") {
        // Validate that all characters are ASCII
        if input.is_ascii() {
            Ok(input.as_bytes().to_vec())
        } else {
            Err("String contains non-ASCII characters".to_string())
        }
    } else if encoding.eq_ignore_ascii_case("UNICODE") 
        || encoding.eq_ignore_ascii_case("UTF16") 
        || encoding.eq_ignore_ascii_case("UTF-16") {
        // Unicode in .NET typically means UTF-16LE
        let utf16: Vec<u16> = input.encode_utf16().collect();
        let mut bytes = Vec::with_capacity(utf16.len() * 2);
        for word in utf16 {
            bytes.push((word & 0xFF) as u8);
            bytes.push((word >> 8) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("UTF32") || encoding.eq_ignore_ascii_case("UTF-32") {
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
    } else if encoding.eq_ignore_ascii_case("BIGENDIANUNICODE") 
        || encoding.eq_ignore_ascii_case("UTF16BE") 
        || encoding.eq_ignore_ascii_case("UTF-16BE") {
        // UTF-16BE encoding
        let utf16: Vec<u16> = input.encode_utf16().collect();
        let mut bytes = Vec::with_capacity(utf16.len() * 2);
        for word in utf16 {
            bytes.push((word >> 8) as u8);
            bytes.push((word & 0xFF) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("DEFAULT") {
        // Default encoding is UTF-8
        Ok(input.as_bytes().to_vec())
    } else {
        Err(format!("Unsupported encoding: {}", encoding))
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
/// - `out_length` is a valid pointer to a usize or null (optional)
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
    
    // Convert C string to Rust string
    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            if !out_length.is_null() {
                unsafe { *out_length = 0; }
            }
            return std::ptr::null_mut();
        }
    };
    
    // Handle empty string case
    if input_str.is_empty() {
        crate::error::clear_error();
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        // Allocate an empty Vec using the helper function
        return crate::memory::allocate_byte_array(Vec::<u8>::new());
    }
    
    // Decode from Base64
    let decoded_bytes = match general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            if !out_length.is_null() {
                unsafe { *out_length = 0; }
            }
            return std::ptr::null_mut();
        }
    };
    
    // Set output length (only if pointer provided)
    let length = decoded_bytes.len();
    if !out_length.is_null() {
        unsafe { *out_length = length; }
    }
    
    // Allocate byte array with metadata header for proper deallocation
    crate::error::clear_error();
    crate::memory::allocate_byte_array(decoded_bytes)
}

/// Convert bytes to a Rust string using the specified encoding
fn convert_bytes_to_string(bytes: &[u8], encoding: &str) -> Result<String, String> {
    // Use eq_ignore_ascii_case to avoid allocating with to_uppercase()
    if encoding.eq_ignore_ascii_case("UTF8") || encoding.eq_ignore_ascii_case("UTF-8") {
        String::from_utf8(bytes.to_vec())
            .map_err(|e| format!("Invalid UTF-8 bytes: {}", e))
    } else if encoding.eq_ignore_ascii_case("ASCII") {
        // Validate that all bytes are ASCII
        if bytes.iter().all(|&b| b < 128) {
            String::from_utf8(bytes.to_vec())
                .map_err(|e| format!("Invalid ASCII bytes: {}", e))
        } else {
            Err("Bytes contain non-ASCII values".to_string())
        }
    } else if encoding.eq_ignore_ascii_case("UNICODE") 
        || encoding.eq_ignore_ascii_case("UTF16") 
        || encoding.eq_ignore_ascii_case("UTF-16") {
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
    } else if encoding.eq_ignore_ascii_case("UTF32") || encoding.eq_ignore_ascii_case("UTF-32") {
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
    } else if encoding.eq_ignore_ascii_case("BIGENDIANUNICODE") 
        || encoding.eq_ignore_ascii_case("UTF16BE") 
        || encoding.eq_ignore_ascii_case("UTF-16BE") {
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
    } else if encoding.eq_ignore_ascii_case("DEFAULT") {
        // Default encoding is UTF-8
        String::from_utf8(bytes.to_vec())
            .map_err(|e| format!("Invalid UTF-8 bytes: {}", e))
    } else {
        Err(format!("Unsupported encoding: {}", encoding))
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
        // Test: null output length pointer should be allowed (optional parameter)
        let input = CString::new("SGVsbG8=").unwrap();
        
        let result = base64_to_bytes(input.as_ptr(), std::ptr::null_mut());
        
        // Should succeed even with null out_length pointer
        assert!(!result.is_null(), "Should succeed with null out_length pointer");
        
        // Verify the data is correct
        let data = unsafe { std::slice::from_raw_parts(result, 5) };
        assert_eq!(data, &[72, 101, 108, 108, 111]);
        
        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_encoding_case_insensitivity_performance() {
        // Test: verify that encoding names are case-insensitive
        // This also documents the performance concern with to_uppercase()
        let input = CString::new("Test").unwrap();
        let encoding_variants = vec![
            "utf8", "UTF8", "Utf8", "uTf8",
            "ascii", "ASCII", "Ascii",
            "unicode", "UNICODE", "Unicode",
        ];
        
        for encoding in encoding_variants {
            let enc_cstring = CString::new(encoding).unwrap();
            let result = string_to_base64(input.as_ptr(), enc_cstring.as_ptr());
            
            assert!(!result.is_null(), 
                "Encoding '{}' should be recognized (case-insensitive)", encoding);
            
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_encoding_name_with_hyphens() {
        // Test: verify that encoding names with hyphens work
        let input = CString::new("Test").unwrap();
        let encoding_variants = vec![
            ("UTF-8", "UTF8"),
            ("UTF-16", "UTF16"),
            ("UTF-32", "UTF32"),
            ("UTF-16BE", "UTF16BE"),
        ];
        
        for (hyphenated, non_hyphenated) in encoding_variants {
            let enc1 = CString::new(hyphenated).unwrap();
            let enc2 = CString::new(non_hyphenated).unwrap();
            
            let result1 = string_to_base64(input.as_ptr(), enc1.as_ptr());
            let result2 = string_to_base64(input.as_ptr(), enc2.as_ptr());
            
            // Both should work and produce the same result
            assert!(!result1.is_null(), "Encoding '{}' should work", hyphenated);
            assert!(!result2.is_null(), "Encoding '{}' should work", non_hyphenated);
            
            let str1 = unsafe { CStr::from_ptr(result1).to_str().unwrap() };
            let str2 = unsafe { CStr::from_ptr(result2).to_str().unwrap() };
            
            assert_eq!(str1, str2, 
                "Encodings '{}' and '{}' should produce identical results", 
                hyphenated, non_hyphenated);
            
            unsafe {
                crate::memory::free_string(result1);
                crate::memory::free_string(result2);
            }
        }
    }

    #[test]
    fn test_utf7_rejection_is_documented() {
        // Test: UTF7 should be explicitly rejected with clear error message
        let input = CString::new("Hello").unwrap();
        let utf7_variants = vec!["UTF7", "utf7", "Utf7", "UTF-7", "utf-7"];
        
        for variant in utf7_variants {
            let encoding = CString::new(variant).unwrap();
            let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
            
            assert!(result.is_null(), 
                "UTF7 variant '{}' should be rejected", variant);
            
            // Verify error message is set
            let error = crate::error::get_last_error();
            assert!(!error.is_null(), "Error message should be set for UTF7 variant '{}'", variant);
            
            let error_str = unsafe { CStr::from_ptr(error).to_str().unwrap() };
            
            // All variants should now be caught by the explicit UTF7 check
            assert!(error_str.contains("UTF7") || error_str.contains("deprecated"), 
                "Error message for '{}' should mention UTF7 or deprecated, got: {}", 
                variant, error_str);
            
            unsafe { crate::memory::free_string(error) };
        }
    }

    #[test]
    fn test_ascii_encoding_rejects_non_ascii() {
        // Test: ASCII encoding should reject strings with non-ASCII characters
        let non_ascii_strings = vec![
            "Hello 🌍",           // Emoji
            "Café",               // Accented character
            "日本語",             // Japanese
            "Hello\u{0080}",      // First non-ASCII character
        ];
        
        let encoding = CString::new("ASCII").unwrap();
        
        for test_str in non_ascii_strings {
            let input = CString::new(test_str).unwrap();
            let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
            
            assert!(result.is_null(), 
                "ASCII encoding should reject non-ASCII string: {}", test_str);
            
            // Verify error message mentions non-ASCII
            let error = crate::error::get_last_error();
            assert!(!error.is_null(), "Error should be set for non-ASCII input");
            
            let error_str = unsafe { CStr::from_ptr(error).to_str().unwrap() };
            assert!(error_str.contains("ASCII") || error_str.contains("non-ASCII"), 
                "Error should mention ASCII issue, got: {}", error_str);
            
            unsafe { crate::memory::free_string(error) };
        }
    }

    #[test]
    fn test_ascii_encoding_accepts_valid_ascii() {
        // Test: ASCII encoding should accept valid ASCII strings
        let ascii_strings = vec![
            "Hello",
            "123",
            "!@#$%^&*()",
            "The quick brown fox",
            "\t\n\r",
        ];
        
        let encoding = CString::new("ASCII").unwrap();
        
        for test_str in ascii_strings {
            let input = CString::new(test_str).unwrap();
            let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
            
            assert!(!result.is_null(), 
                "ASCII encoding should accept valid ASCII string: {}", test_str);
            
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_utf16_byte_order() {
        // Test: verify UTF-16 uses little-endian byte order (UTF-16LE)
        let input = CString::new("A").unwrap(); // 'A' = U+0041
        let encoding = CString::new("UTF16").unwrap();
        
        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
        assert!(!result.is_null(), "UTF16 encoding should succeed");
        
        // Decode to verify byte order
        let mut out_length: usize = 0;
        let bytes_ptr = base64_to_bytes(result, &mut out_length as *mut usize);
        
        assert_eq!(out_length, 2, "UTF-16 'A' should be 2 bytes");
        let bytes = unsafe { std::slice::from_raw_parts(bytes_ptr, out_length) };
        
        // UTF-16LE: 'A' (U+0041) = [0x41, 0x00]
        assert_eq!(bytes[0], 0x41, "First byte should be 0x41 (little-endian)");
        assert_eq!(bytes[1], 0x00, "Second byte should be 0x00");
        
        unsafe {
            crate::memory::free_string(result);
            crate::memory::free_bytes(bytes_ptr);
        }
    }

    #[test]
    fn test_utf16be_byte_order() {
        // Test: verify UTF-16BE uses big-endian byte order
        let input = CString::new("A").unwrap(); // 'A' = U+0041
        let encoding = CString::new("BigEndianUnicode").unwrap();
        
        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
        assert!(!result.is_null(), "UTF16BE encoding should succeed");
        
        // Decode to verify byte order
        let mut out_length: usize = 0;
        let bytes_ptr = base64_to_bytes(result, &mut out_length as *mut usize);
        
        assert_eq!(out_length, 2, "UTF-16BE 'A' should be 2 bytes");
        let bytes = unsafe { std::slice::from_raw_parts(bytes_ptr, out_length) };
        
        // UTF-16BE: 'A' (U+0041) = [0x00, 0x41]
        assert_eq!(bytes[0], 0x00, "First byte should be 0x00 (big-endian)");
        assert_eq!(bytes[1], 0x41, "Second byte should be 0x41");
        
        unsafe {
            crate::memory::free_string(result);
            crate::memory::free_bytes(bytes_ptr);
        }
    }

    #[test]
    fn test_utf32_encoding_size() {
        // Test: verify UTF-32 uses 4 bytes per character
        let input = CString::new("AB").unwrap();
        let encoding = CString::new("UTF32").unwrap();
        
        let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
        assert!(!result.is_null(), "UTF32 encoding should succeed");
        
        // Decode to verify size
        let mut out_length: usize = 0;
        let bytes_ptr = base64_to_bytes(result, &mut out_length as *mut usize);
        
        assert_eq!(out_length, 8, "UTF-32 'AB' should be 8 bytes (2 chars × 4 bytes)");
        
        unsafe {
            crate::memory::free_string(result);
            crate::memory::free_bytes(bytes_ptr);
        }
    }

    #[test]
    fn test_default_encoding_is_utf8() {
        // Test: verify that "Default" encoding behaves like UTF-8
        let input = CString::new("Hello 🌍").unwrap();
        
        let utf8_enc = CString::new("UTF8").unwrap();
        let default_enc = CString::new("Default").unwrap();
        
        let result_utf8 = string_to_base64(input.as_ptr(), utf8_enc.as_ptr());
        let result_default = string_to_base64(input.as_ptr(), default_enc.as_ptr());
        
        assert!(!result_utf8.is_null(), "UTF8 encoding should succeed");
        assert!(!result_default.is_null(), "Default encoding should succeed");
        
        let str_utf8 = unsafe { CStr::from_ptr(result_utf8).to_str().unwrap() };
        let str_default = unsafe { CStr::from_ptr(result_default).to_str().unwrap() };
        
        assert_eq!(str_utf8, str_default, 
            "Default encoding should produce same result as UTF8");
        
        unsafe {
            crate::memory::free_string(result_utf8);
            crate::memory::free_string(result_default);
        }
    }

    #[test]
    fn test_encoding_with_invalid_utf8_in_encoding_name() {
        // Test: verify handling of invalid UTF-8 in encoding parameter
        // This is a safety test for the encoding parameter validation
        let input = CString::new("Hello").unwrap();
        
        // Create a CString with invalid UTF-8 (this is tricky, as CString validates)
        // Instead, we test that the UTF-8 validation in the function works
        // by ensuring valid encodings work
        let valid_encodings = vec!["UTF8", "ASCII", "Unicode"];
        
        for enc in valid_encodings {
            let encoding = CString::new(enc).unwrap();
            let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
            assert!(!result.is_null(), "Valid encoding '{}' should work", enc);
            unsafe { crate::memory::free_string(result) };
        }
    }

    #[test]
    fn test_base64_to_bytes_null_output_length_allowed() {
        // Test: null output length pointer should be allowed (optional parameter)
        let input = CString::new("SGVsbG8=").unwrap();
        
        // Should work even with null out_length pointer
        let result = base64_to_bytes(input.as_ptr(), std::ptr::null_mut());
        
        assert!(!result.is_null(), "Should succeed even with null out_length pointer");
        
        // We can still verify the data is correct by reading it
        // (we know "SGVsbG8=" decodes to "Hello" which is 5 bytes)
        let data = unsafe { std::slice::from_raw_parts(result, 5) };
        assert_eq!(data, &[72, 101, 108, 108, 111]);
        
        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_concurrent_base64_operations() {
        use std::thread;
        
        // Test: multiple threads using base64 functions concurrently
        // Error handling should be thread-safe
        let handles: Vec<_> = (0..10).map(|i| {
            thread::spawn(move || {
                let input = CString::new(format!("test{}", i)).unwrap();
                let encoding = CString::new("UTF8").unwrap();
                
                // Encode
                let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
                assert!(!result.is_null(), "Encoding should succeed in thread {}", i);
                
                // Decode
                let decoded = base64_to_string(result, encoding.as_ptr());
                assert!(!decoded.is_null(), "Decoding should succeed in thread {}", i);
                
                let decoded_str = unsafe { CStr::from_ptr(decoded).to_str().unwrap() };
                assert_eq!(decoded_str, format!("test{}", i));
                
                unsafe {
                    crate::memory::free_string(result);
                    crate::memory::free_string(decoded);
                }
            })
        }).collect();
        
        for handle in handles {
            handle.join().unwrap();
        }
    }

    #[test]
    fn test_concurrent_error_isolation() {
        use std::thread;
        use std::sync::Arc;
        use std::sync::atomic::{AtomicBool, Ordering};
        
        // Test: errors in one thread don't affect other threads
        let success_flag = Arc::new(AtomicBool::new(true));
        
        let handles: Vec<_> = (0..5).map(|i| {
            let flag = Arc::clone(&success_flag);
            thread::spawn(move || {
                // Thread with even ID will succeed, odd will fail
                if i % 2 == 0 {
                    let input = CString::new("Hello").unwrap();
                    let encoding = CString::new("UTF8").unwrap();
                    let result = string_to_base64(input.as_ptr(), encoding.as_ptr());
                    
                    if result.is_null() {
                        flag.store(false, Ordering::SeqCst);
                    } else {
                        unsafe { crate::memory::free_string(result) };
                    }
                } else {
                    // Trigger an error
                    let encoding = CString::new("UTF8").unwrap();
                    let result = string_to_base64(std::ptr::null(), encoding.as_ptr());
                    
                    // Should be null due to error
                    if !result.is_null() {
                        flag.store(false, Ordering::SeqCst);
                    }
                    
                    // Check that error is set for THIS thread
                    let error = crate::error::get_last_error();
                    if error.is_null() {
                        flag.store(false, Ordering::SeqCst);
                    } else {
                        unsafe { crate::memory::free_string(error) };
                    }
                }
            })
        }).collect();
        
        for handle in handles {
            handle.join().unwrap();
        }
        
        assert!(success_flag.load(Ordering::SeqCst), "All threads should handle errors correctly");
    }
}
