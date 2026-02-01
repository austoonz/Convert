//! Byte array-based Base64 encoding and decoding functions

use base64::{Engine as _, engine::general_purpose};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Convert a byte array to Base64 encoding
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `bytes` is a valid pointer to a byte array or null
/// - `length` accurately represents the number of bytes to read
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn bytes_to_base64(bytes: *const u8, length: usize) -> *mut c_char {
    if bytes.is_null() {
        crate::error::set_error("Byte array pointer is null".to_string());
        return std::ptr::null_mut();
    }

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

    let byte_slice = unsafe { std::slice::from_raw_parts(bytes, length) };
    let encoded = general_purpose::STANDARD.encode(byte_slice);

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
pub unsafe extern "C" fn base64_to_bytes(input: *const c_char, out_length: *mut usize) -> *mut u8 {
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        return std::ptr::null_mut();
    }

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

    if input_str.is_empty() {
        crate::error::clear_error();
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        return crate::memory::allocate_byte_array(Vec::<u8>::new());
    }

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

    let length = decoded_bytes.len();
    if !out_length.is_null() {
        unsafe { *out_length = length; }
    }

    crate::error::clear_error();
    crate::memory::allocate_byte_array(decoded_bytes)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_bytes_to_base64_happy_path() {
        let bytes: Vec<u8> = vec![72, 101, 108, 108, 111];
        let result = unsafe { bytes_to_base64(bytes.as_ptr(), bytes.len()) };
        assert!(!result.is_null());
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "SGVsbG8=");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_bytes_to_base64_null_pointer() {
        let result = unsafe { bytes_to_base64(std::ptr::null(), 10) };
        assert!(result.is_null());
    }

    #[test]
    fn test_bytes_to_base64_zero_length() {
        let bytes: Vec<u8> = vec![1, 2, 3];
        let result = unsafe { bytes_to_base64(bytes.as_ptr(), 0) };
        assert!(!result.is_null());
        let result_str = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(result_str, "");
        unsafe { crate::memory::free_string(result) };
    }

    #[test]
    fn test_base64_to_bytes_happy_path() {
        let input = CString::new("SGVsbG8=").unwrap();
        let mut out_length: usize = 0;
        let result = unsafe { base64_to_bytes(input.as_ptr(), &mut out_length as *mut usize) };
        assert!(!result.is_null());
        assert_eq!(out_length, 5);
        let byte_slice = unsafe { std::slice::from_raw_parts(result, out_length) };
        assert_eq!(byte_slice, &[72, 101, 108, 108, 111]);
        unsafe { crate::memory::free_bytes(result) };
    }

    #[test]
    fn test_base64_to_bytes_null_pointer() {
        let mut out_length: usize = 0;
        let result = unsafe { base64_to_bytes(std::ptr::null(), &mut out_length as *mut usize) };
        assert!(result.is_null());
        assert_eq!(out_length, 0);
    }

    #[test]
    fn test_base64_to_bytes_round_trip() {
        let original_bytes: Vec<u8> = vec![0, 1, 2, 3, 4, 5, 255, 254, 253];
        let encoded_ptr = unsafe { bytes_to_base64(original_bytes.as_ptr(), original_bytes.len()) };
        assert!(!encoded_ptr.is_null());
        let mut out_length: usize = 0;
        let decoded_ptr = unsafe { base64_to_bytes(encoded_ptr, &mut out_length as *mut usize) };
        assert!(!decoded_ptr.is_null());
        assert_eq!(out_length, original_bytes.len());
        let decoded_slice = unsafe { std::slice::from_raw_parts(decoded_ptr, out_length) };
        assert_eq!(decoded_slice, original_bytes.as_slice());
        unsafe {
            crate::memory::free_string(encoded_ptr);
            crate::memory::free_bytes(decoded_ptr);
        };
    }
}
