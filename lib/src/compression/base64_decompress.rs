//! Base64 decode and decompress functions

use base64::Engine as _;
use flate2::read::GzDecoder;
use std::ffi::{CStr, CString};
use std::io::Read;
use std::os::raw::c_char;

/// Decode a Base64 string, decompress it, and convert to a string in one operation
///
/// This function combines Base64 decoding, Gzip decompression, and string conversion
/// into a single FFI call, reducing the overhead of multiple round-trips between
/// PowerShell and Rust.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn base64_to_decompressed_string(
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

    let compressed_bytes = match base64::engine::general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            return std::ptr::null_mut();
        }
    };

    let mut decoder = GzDecoder::new(compressed_bytes.as_slice());
    let mut decompressed = Vec::new();

    if let Err(e) = decoder.read_to_end(&mut decompressed) {
        crate::error::set_error(format!("Decompression failed: {}", e));
        return std::ptr::null_mut();
    }

    let result_string = match crate::base64::convert_bytes_to_string(&decompressed, encoding_str) {
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
            crate::error::set_error(
                "Failed to create C string from decompressed result".to_string(),
            );
            std::ptr::null_mut()
        }
    }
}

/// Decode a Base64 string, decompress it, and convert to a string with Latin-1 fallback
///
/// This is a lenient version of `base64_to_decompressed_string` that automatically
/// falls back to Latin-1 (ISO-8859-1) encoding when the decompressed bytes are invalid
/// for the specified encoding.
///
/// # Safety
/// Same safety requirements as `base64_to_decompressed_string`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn base64_to_decompressed_string_lenient(
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

    let compressed_bytes = match base64::engine::general_purpose::STANDARD.decode(input_str) {
        Ok(bytes) => bytes,
        Err(e) => {
            crate::error::set_error(format!("Failed to decode Base64: {}", e));
            return std::ptr::null_mut();
        }
    };

    let mut decoder = GzDecoder::new(compressed_bytes.as_slice());
    let mut decompressed = Vec::new();

    if let Err(e) = decoder.read_to_end(&mut decompressed) {
        crate::error::set_error(format!("Decompression failed: {}", e));
        return std::ptr::null_mut();
    }

    let result_string =
        match crate::base64::convert_bytes_to_string_with_fallback(&decompressed, encoding_str) {
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
            crate::error::set_error(
                "Failed to create C string from decompressed result".to_string(),
            );
            std::ptr::null_mut()
        }
    }
}
