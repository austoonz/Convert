//! String-based Base64 encoding and decoding functions

use base64::{Engine as _, engine::general_purpose};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use super::encoding::{convert_string_to_bytes, convert_bytes_to_string, convert_bytes_to_string_with_fallback};

/// Convert a string to Base64 encoding
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn string_to_base64(
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

    let bytes = match convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

    let encoded = general_purpose::STANDARD.encode(&bytes);

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
pub unsafe extern "C" fn base64_to_string(
    input: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
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

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    let decoded_bytes = match general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            return std::ptr::null_mut();
        }
    };

    let result_string = match convert_bytes_to_string(&decoded_bytes, encoding_str) {
        Ok(s) => s,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

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

/// Decode a Base64 string to a string with Latin-1 fallback for binary data
///
/// Lenient version that automatically falls back to Latin-1 (ISO-8859-1) encoding
/// when the decoded bytes are invalid for the specified encoding.
///
/// # Safety
/// Same safety requirements as `base64_to_string`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn base64_to_string_lenient(
    input: *const c_char,
    encoding: *const c_char,
) -> *mut c_char {
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
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

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    let decoded_bytes = match general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            return std::ptr::null_mut();
        }
    };

    let result_string = match convert_bytes_to_string_with_fallback(&decoded_bytes, encoding_str) {
        Ok(s) => s,
        Err(e) => {
            crate::error::set_error(e);
            return std::ptr::null_mut();
        }
    };

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

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_string_to_base64_happy_path_utf8() {
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { string_to_base64(input.as_ptr(), encoding.as_ptr()) };

        assert!(!result.is_null());
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "SGVsbG8=");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_string_to_base64_null_input_pointer() {
        let encoding = CString::new("UTF8").unwrap();
        let result = unsafe { string_to_base64(std::ptr::null(), encoding.as_ptr()) };
        assert!(result.is_null());
    }

    #[test]
    fn test_string_to_base64_null_encoding_pointer() {
        let input = CString::new("Hello").unwrap();
        let result = unsafe { string_to_base64(input.as_ptr(), std::ptr::null()) };
        assert!(result.is_null());
    }

    #[test]
    fn test_string_to_base64_invalid_encoding() {
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();
        let result = unsafe { string_to_base64(input.as_ptr(), encoding.as_ptr()) };
        assert!(result.is_null());
    }

    #[test]
    fn test_string_to_base64_utf7_deprecated() {
        let input = CString::new("Hello").unwrap();
        let encoding = CString::new("UTF7").unwrap();
        let result = unsafe { string_to_base64(input.as_ptr(), encoding.as_ptr()) };
        assert!(result.is_null());
    }

    #[test]
    fn test_string_to_base64_empty_string() {
        let input = CString::new("").unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let result = unsafe { string_to_base64(input.as_ptr(), encoding.as_ptr()) };
        assert!(!result.is_null());
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_string_to_base64_large_string() {
        let large_string = "A".repeat(1024 * 1024);
        let input = CString::new(large_string).unwrap();
        let encoding = CString::new("UTF8").unwrap();
        let result = unsafe { string_to_base64(input.as_ptr(), encoding.as_ptr()) };
        assert!(!result.is_null());
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_string_to_base64_various_encodings() {
        let input = CString::new("Test").unwrap();
        let encodings = vec!["UTF8", "ASCII", "Unicode", "UTF32", "BigEndianUnicode", "Default"];
        for enc in encodings {
            let encoding = CString::new(enc).unwrap();
            let result = unsafe { string_to_base64(input.as_ptr(), encoding.as_ptr()) };
            assert!(!result.is_null());
            unsafe { crate::memory::free_string(result) };
        }
    }
}
