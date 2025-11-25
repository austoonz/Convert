//! URL encoding and decoding functions

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Encode a string for use in URLs using percent-encoding
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
/// 
/// # Arguments
/// * `input` - The string to encode
/// 
/// # Returns
/// Pointer to encoded string, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn url_encode(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return std::ptr::null_mut();
    }

    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            return std::ptr::null_mut();
        }
    };

    // Define the set of characters to encode (everything except unreserved characters)
    // Unreserved characters per RFC 3986: A-Z a-z 0-9 - _ .
    // Note: ~ is also unreserved per RFC 3986, but we encode it for compatibility with .NET
    const FRAGMENT: &percent_encoding::AsciiSet = &percent_encoding::CONTROLS
        .add(b' ')
        .add(b'"')
        .add(b'<')
        .add(b'>')
        .add(b'`')
        .add(b'#')
        .add(b'?')
        .add(b'{')
        .add(b'}')
        .add(b'%')
        .add(b'/')
        .add(b':')
        .add(b';')
        .add(b'=')
        .add(b'@')
        .add(b'[')
        .add(b'\\')
        .add(b']')
        .add(b'^')
        .add(b'|')
        .add(b'&')
        .add(b'+')
        .add(b',')
        .add(b'$')
        .add(b'!')
        .add(b'\'')
        .add(b'(')
        .add(b')')
        .add(b'~');

    let encoded = percent_encoding::utf8_percent_encode(input_str, FRAGMENT).to_string();

    match CString::new(encoded) {
        Ok(c_str) => c_str.into_raw(),
        Err(_) => {
            crate::error::set_error("Failed to create C string".to_string());
            std::ptr::null_mut()
        }
    }
}

/// Decode a percent-encoded URL string
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
/// 
/// # Arguments
/// * `input` - The percent-encoded string to decode
/// 
/// # Returns
/// Pointer to decoded string, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn url_decode(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return std::ptr::null_mut();
    }

    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            return std::ptr::null_mut();
        }
    };

    // Validate percent encoding before decoding
    let mut chars = input_str.chars().peekable();
    while let Some(ch) = chars.next() {
        if ch == '%' {
            // Must be followed by exactly 2 hex digits
            let hex1 = chars.next();
            let hex2 = chars.next();
            
            match (hex1, hex2) {
                (Some(h1), Some(h2)) if h1.is_ascii_hexdigit() && h2.is_ascii_hexdigit() => {
                    // Valid percent sequence
                }
                _ => {
                    crate::error::set_error("Invalid percent-encoding sequence".to_string());
                    return std::ptr::null_mut();
                }
            }
        }
    }

    let decoded = match percent_encoding::percent_decode_str(input_str).decode_utf8() {
        Ok(s) => s.to_string(),
        Err(_) => {
            crate::error::set_error("Invalid percent-encoding or non-UTF-8 result".to_string());
            return std::ptr::null_mut();
        }
    };

    match CString::new(decoded) {
        Ok(c_str) => c_str.into_raw(),
        Err(_) => {
            crate::error::set_error("Failed to create C string".to_string());
            std::ptr::null_mut()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    // ===== Test Helpers =====

    /// RAII guard for automatic cleanup of encoded strings
    struct EncodedString {
        ptr: *mut c_char,
    }

    impl EncodedString {
        fn new(ptr: *mut c_char) -> Self {
            Self { ptr }
        }

        fn is_null(&self) -> bool {
            self.ptr.is_null()
        }

        fn to_str(&self) -> Result<&str, std::str::Utf8Error> {
            if self.ptr.is_null() {
                panic!("Cannot convert null pointer to string");
            }
            unsafe { CStr::from_ptr(self.ptr).to_str() }
        }
    }

    impl Drop for EncodedString {
        fn drop(&mut self) {
            if !self.ptr.is_null() {
                unsafe { crate::memory::free_string(self.ptr) };
            }
        }
    }

    // ===== Tests for url_encode =====

    #[test]
    fn test_url_encode_happy_path() {
        // Test: encode "hello world" to "hello%20world"
        let input = CString::new("hello world").unwrap();
        let result = EncodedString::new(url_encode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(result.to_str().unwrap(), "hello%20world");
    }

    #[test]
    fn test_url_encode_special_characters() {
        // Test: special characters should be percent-encoded
        let test_cases = vec![
            ("hello&world", "hello%26world"),
            ("key=value", "key%3Dvalue"),
            ("path?query", "path%3Fquery"),
            ("anchor#section", "anchor%23section"),
            ("a+b", "a%2Bb"),
            ("50%", "50%25"),
            ("a/b", "a%2Fb"),
            ("a:b", "a%3Ab"),
            ("a@b", "a%40b"),
        ];

        for (input_str, expected) in test_cases {
            let input = CString::new(input_str).unwrap();
            let result = EncodedString::new(url_encode(input.as_ptr()));
            
            assert!(!result.is_null(), "Result should not be null for: {}", input_str);
            assert_eq!(result.to_str().unwrap(), expected, 
                "Failed to encode: {}", input_str);
        }
    }

    #[test]
    fn test_url_encode_null_pointer() {
        // Test: null pointer should return null
        let result = url_encode(std::ptr::null());
        
        assert!(result.is_null(), "Result should be null for null pointer");
    }

    #[test]
    fn test_url_encode_empty_string() {
        // Test: empty string should return empty string
        let input = CString::new("").unwrap();
        let result = EncodedString::new(url_encode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null for empty string");
        assert_eq!(result.to_str().unwrap(), "");
    }

    #[test]
    fn test_url_encode_already_encoded() {
        // Test: already encoded string should be double-encoded
        let input = CString::new("hello%20world").unwrap();
        let result = EncodedString::new(url_encode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(result.to_str().unwrap(), "hello%2520world");
    }

    #[test]
    fn test_url_encode_alphanumeric_unchanged() {
        // Test: alphanumeric characters should not be encoded
        let input = CString::new("abc123XYZ").unwrap();
        let result = EncodedString::new(url_encode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(result.to_str().unwrap(), "abc123XYZ");
    }

    #[test]
    fn test_url_encode_unreserved_characters() {
        // Test: unreserved characters (- _ . ~) should not be encoded
        let input = CString::new("test-file_name.txt~").unwrap();
        let result = EncodedString::new(url_encode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(result.to_str().unwrap(), "test-file_name.txt~");
    }

    // ===== Tests for url_decode =====

    #[test]
    fn test_url_decode_happy_path() {
        // Test: decode "hello%20world" to "hello world"
        let input = CString::new("hello%20world").unwrap();
        let result = EncodedString::new(url_decode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null");
        assert_eq!(result.to_str().unwrap(), "hello world");
    }

    #[test]
    fn test_url_decode_round_trip() {
        // Test: encode then decode should return original string
        let original = "hello world & special=chars?test#anchor";
        let input = CString::new(original).unwrap();
        
        let encoded = EncodedString::new(url_encode(input.as_ptr()));
        assert!(!encoded.is_null(), "Encoded result should not be null");
        
        let decoded = EncodedString::new(url_decode(encoded.ptr));
        assert!(!decoded.is_null(), "Decoded result should not be null");
        assert_eq!(decoded.to_str().unwrap(), original);
    }

    #[test]
    fn test_url_decode_null_pointer() {
        // Test: null pointer should return null
        let result = url_decode(std::ptr::null());
        
        assert!(result.is_null(), "Result should be null for null pointer");
    }

    #[test]
    fn test_url_decode_invalid_percent_encoding() {
        // Test: invalid percent encoding should return null
        let test_cases = vec![
            "hello%2",      // Incomplete percent sequence
            "hello%",       // Incomplete percent sequence
            "hello%GG",     // Invalid hex characters
            "hello%2G",     // Invalid hex character
        ];

        for input_str in test_cases {
            let input = CString::new(input_str).unwrap();
            let result = url_decode(input.as_ptr());
            
            assert!(result.is_null(), 
                "Result should be null for invalid encoding: {}", input_str);
        }
    }

    #[test]
    fn test_url_decode_empty_string() {
        // Test: empty string should return empty string
        let input = CString::new("").unwrap();
        let result = EncodedString::new(url_decode(input.as_ptr()));
        
        assert!(!result.is_null(), "Result should not be null for empty string");
        assert_eq!(result.to_str().unwrap(), "");
    }
}
