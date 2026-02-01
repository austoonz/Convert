//! Gzip decompression functions

use flate2::read::GzDecoder;
use std::ffi::{CStr, CString};
use std::io::Read;
use std::os::raw::c_char;

/// Decompress a Gzip-compressed byte array to a string
///
/// Decompresses the input byte array using Gzip, then converts the decompressed
/// bytes to a string using the specified encoding. Handles special characters,
/// Unicode, and various encodings correctly.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `bytes` is a valid pointer to a byte array or null
/// - `length` accurately represents the number of bytes to read
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn decompress_string(
    bytes: *const u8,
    length: usize,
    encoding: *const c_char,
) -> *mut c_char {
    if bytes.is_null() {
        crate::error::set_error("Byte array pointer is null".to_string());
        return std::ptr::null_mut();
    }

    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    let compressed_slice = unsafe { std::slice::from_raw_parts(bytes, length) };

    let mut decoder = GzDecoder::new(compressed_slice);
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

/// Decompress a Gzip-compressed byte array to a string with Latin-1 fallback
///
/// This is a lenient version of `decompress_string` that automatically falls back to
/// Latin-1 (ISO-8859-1) encoding when the decompressed byte sequence is invalid for
/// the specified encoding. This is useful for handling binary data (like certificates)
/// that may not be valid text in any standard encoding.
///
/// Use this function when you want best-effort conversion without errors.
/// Use `decompress_string` when you want strict validation of the encoding.
///
/// # Safety
/// Same safety requirements as `decompress_string`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn decompress_string_lenient(
    bytes: *const u8,
    length: usize,
    encoding: *const c_char,
) -> *mut c_char {
    if bytes.is_null() {
        crate::error::set_error("Byte array pointer is null".to_string());
        return std::ptr::null_mut();
    }

    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };

    let compressed_slice = unsafe { std::slice::from_raw_parts(bytes, length) };

    let mut decoder = GzDecoder::new(compressed_slice);
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    struct CompressedBytes {
        ptr: *mut u8,
        length: usize,
    }

    impl CompressedBytes {
        fn new(ptr: *mut u8, length: usize) -> Self {
            Self { ptr, length }
        }

        fn as_ptr(&self) -> *const u8 {
            self.ptr
        }

        fn len(&self) -> usize {
            self.length
        }

        fn is_null(&self) -> bool {
            self.ptr.is_null()
        }
    }

    impl Drop for CompressedBytes {
        fn drop(&mut self) {
            if !self.ptr.is_null() {
                unsafe { crate::memory::free_bytes(self.ptr) };
            }
        }
    }

    struct DecompressedString {
        ptr: *mut c_char,
    }

    impl DecompressedString {
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

    impl Drop for DecompressedString {
        fn drop(&mut self) {
            if !self.ptr.is_null() {
                unsafe { crate::memory::free_string(self.ptr) };
            }
        }
    }

    fn compress_with_encoding(input: &str, encoding: &str) -> CompressedBytes {
        let input_cstr = CString::new(input).unwrap();
        let encoding_cstr = CString::new(encoding).unwrap();
        let mut out_length: usize = 0;

        let ptr = unsafe {
            crate::compression::compress_string(
                input_cstr.as_ptr(),
                encoding_cstr.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        CompressedBytes::new(ptr, out_length)
    }

    fn decompress_with_encoding(bytes: &CompressedBytes, encoding: &str) -> DecompressedString {
        let encoding_cstr = CString::new(encoding).unwrap();

        let ptr = unsafe { decompress_string(bytes.as_ptr(), bytes.len(), encoding_cstr.as_ptr()) };

        DecompressedString::new(ptr)
    }

    fn round_trip(input: &str, encoding: &str) -> String {
        let compressed = compress_with_encoding(input, encoding);
        assert!(!compressed.is_null(), "Compression failed for: {}", input);

        let decompressed = decompress_with_encoding(&compressed, encoding);
        assert!(
            !decompressed.is_null(),
            "Decompression failed for: {}",
            input
        );

        decompressed.to_str().unwrap().to_string()
    }

    #[test]
    fn test_decompress_string_happy_path() {
        let original = "test string for decompression";
        let result = round_trip(original, "UTF8");

        assert_eq!(
            result, original,
            "Decompressed string should match original"
        );
    }

    #[test]
    fn test_decompress_string_round_trip() {
        let repetitive_data = "A".repeat(1000);
        let test_cases = vec![
            "Simple text",
            "Text with numbers 12345",
            "Special chars: !@#$%^&*()",
            "Unicode: Hello 世界 🌍",
            repetitive_data.as_str(),
        ];

        for original in test_cases {
            let result = round_trip(original, "UTF8");
            assert_eq!(
                result, original,
                "Round-trip should preserve data for: {}",
                original
            );
        }
    }

    #[test]
    fn test_decompress_string_null_pointer() {
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { decompress_string(std::ptr::null(), 0, encoding.as_ptr()) };

        assert!(result.is_null(), "Result should be null for null pointer");
    }

    #[test]
    fn test_decompress_string_invalid_compressed_data() {
        let invalid_data = [0xFF, 0xFE, 0xFD, 0xFC];
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe {
            decompress_string(invalid_data.as_ptr(), invalid_data.len(), encoding.as_ptr())
        };

        assert!(
            result.is_null(),
            "Result should be null for invalid compressed data"
        );
    }

    #[test]
    fn test_decompress_string_various_encodings() {
        let original = "Test String";
        let encodings = vec!["UTF8", "ASCII"];

        for encoding_name in encodings {
            let result = round_trip(original, encoding_name);
            assert_eq!(
                result, original,
                "Round-trip should preserve data for encoding: {}",
                encoding_name
            );
        }
    }

    #[test]
    fn test_decompress_string_null_encoding_pointer() {
        let data = [0x1F, 0x8B];

        let result = unsafe { decompress_string(data.as_ptr(), data.len(), std::ptr::null()) };

        assert!(
            result.is_null(),
            "Result should be null for null encoding pointer"
        );
    }

    #[test]
    fn test_decompress_string_empty_compressed_data() {
        let encoding = CString::new("UTF8").unwrap();

        let result = unsafe { decompress_string(std::ptr::null(), 0, encoding.as_ptr()) };

        assert!(
            result.is_null(),
            "Result should be null for empty compressed data"
        );
    }

    #[test]
    fn test_decompress_string_emoji() {
        let original = "Hello 👋 World 🌍";
        let result = round_trip(original, "UTF8");

        assert_eq!(result, original, "Emoji should round-trip correctly");

        let original_bytes = original.as_bytes();
        let result_bytes = result.as_bytes();
        assert_eq!(result_bytes, original_bytes, "Bytes should match exactly");
    }
}
