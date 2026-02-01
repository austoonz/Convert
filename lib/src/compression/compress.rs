//! String compression functions

use flate2::Compression;
use flate2::write::GzEncoder;
use std::ffi::CStr;
use std::io::Write;
use std::os::raw::c_char;

/// Compress a string using Gzip compression
///
/// Converts the input string to bytes using the specified encoding, then compresses
/// the bytes using Gzip compression. The compressed data is returned as a byte array
/// with metadata header for proper deallocation.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - `out_length` is a valid pointer to a usize
/// - The returned pointer must be freed using `free_bytes`
#[unsafe(no_mangle)]
pub unsafe extern "C" fn compress_string(
    input: *const c_char,
    encoding: *const c_char,
    out_length: *mut usize,
) -> *mut u8 {
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
        if !out_length.is_null() {
            unsafe {
                *out_length = 0;
            }
        }
        return std::ptr::null_mut();
    }

    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        if !out_length.is_null() {
            unsafe {
                *out_length = 0;
            }
        }
        return std::ptr::null_mut();
    }

    let input_str = match unsafe { CStr::from_ptr(input).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in input string".to_string());
            if !out_length.is_null() {
                unsafe {
                    *out_length = 0;
                }
            }
            return std::ptr::null_mut();
        }
    };

    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            if !out_length.is_null() {
                unsafe {
                    *out_length = 0;
                }
            }
            return std::ptr::null_mut();
        }
    };

    let bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            if !out_length.is_null() {
                unsafe {
                    *out_length = 0;
                }
            }
            return std::ptr::null_mut();
        }
    };

    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    if let Err(e) = encoder.write_all(&bytes) {
        crate::error::set_error(format!("Compression write failed: {}", e));
        if !out_length.is_null() {
            unsafe {
                *out_length = 0;
            }
        }
        return std::ptr::null_mut();
    }

    let compressed = match encoder.finish() {
        Ok(data) => data,
        Err(e) => {
            crate::error::set_error(format!("Compression finish failed: {}", e));
            if !out_length.is_null() {
                unsafe {
                    *out_length = 0;
                }
            }
            return std::ptr::null_mut();
        }
    };

    let length = compressed.len();
    if !out_length.is_null() {
        unsafe {
            *out_length = length;
        }
    }

    crate::error::clear_error();
    crate::memory::allocate_byte_array(compressed)
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

        fn is_null(&self) -> bool {
            self.ptr.is_null()
        }

        fn len(&self) -> usize {
            self.length
        }

        fn as_ptr(&self) -> *const u8 {
            self.ptr
        }
    }

    impl Drop for CompressedBytes {
        fn drop(&mut self) {
            if !self.ptr.is_null() {
                unsafe { crate::memory::free_bytes(self.ptr) };
            }
        }
    }

    fn compress_with_encoding(input: &str, encoding: &str) -> CompressedBytes {
        let input_cstr = CString::new(input).unwrap();
        let encoding_cstr = CString::new(encoding).unwrap();
        let mut out_length: usize = 0;

        let ptr = unsafe {
            compress_string(
                input_cstr.as_ptr(),
                encoding_cstr.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        CompressedBytes::new(ptr, out_length)
    }

    #[test]
    fn test_compress_string_happy_path_utf8() {
        let compressed = compress_with_encoding("test string", "UTF8");

        assert!(
            !compressed.is_null(),
            "Result should not be null for valid input"
        );
        assert!(
            compressed.len() > 0,
            "Output length should be greater than 0"
        );

        let compressed_data =
            unsafe { std::slice::from_raw_parts(compressed.as_ptr(), compressed.len()) };
        assert!(
            !compressed_data.is_empty(),
            "Compressed data should not be empty"
        );
    }

    #[test]
    fn test_compress_string_null_input_pointer() {
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            compress_string(
                std::ptr::null(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            result.is_null(),
            "Result should be null for null input pointer"
        );
        assert_eq!(out_length, 0, "Output length should be 0 for null input");
    }

    #[test]
    fn test_compress_string_null_encoding_pointer() {
        let input = CString::new("test string").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            compress_string(
                input.as_ptr(),
                std::ptr::null(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            result.is_null(),
            "Result should be null for null encoding pointer"
        );
        assert_eq!(out_length, 0, "Output length should be 0 for null encoding");
    }

    #[test]
    fn test_compress_string_invalid_encoding() {
        let input = CString::new("test string").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();
        let mut out_length: usize = 0;

        let result = unsafe {
            compress_string(
                input.as_ptr(),
                encoding.as_ptr(),
                &mut out_length as *mut usize,
            )
        };

        assert!(
            result.is_null(),
            "Result should be null for invalid encoding"
        );
        assert_eq!(
            out_length, 0,
            "Output length should be 0 for invalid encoding"
        );
    }

    #[test]
    fn test_compress_string_empty_string() {
        let compressed = compress_with_encoding("", "UTF8");

        assert!(
            !compressed.is_null(),
            "Result should not be null for empty string"
        );
        assert!(
            compressed.len() > 0,
            "Gzip header should produce non-zero output even for empty input"
        );
    }

    #[test]
    fn test_compress_string_large_string_1mb() {
        let large_string = "A".repeat(1024 * 1024);
        let compressed = compress_with_encoding(&large_string, "UTF8");

        assert!(
            !compressed.is_null(),
            "Result should not be null for large string"
        );
        assert!(
            compressed.len() > 0,
            "Output length should be greater than 0"
        );
    }

    #[test]
    fn test_compress_string_output_smaller_than_input() {
        let repetitive_string = "AAAAAAAAAA".repeat(1000);
        let original_size = repetitive_string.len();
        let compressed = compress_with_encoding(&repetitive_string, "UTF8");

        assert!(!compressed.is_null(), "Result should not be null");

        assert!(
            compressed.len() < original_size,
            "Compressed size ({}) should be smaller than original size ({})",
            compressed.len(),
            original_size
        );

        assert!(
            compressed.len() < original_size / 10,
            "Compressed size ({}) should be less than 10% of original size ({})",
            compressed.len(),
            original_size
        );
    }

    #[test]
    fn test_compress_string_various_encodings() {
        let test_string = "Hello World";
        let encodings = vec!["UTF8", "ASCII", "Unicode"];

        for encoding_name in encodings {
            let compressed = compress_with_encoding(test_string, encoding_name);

            assert!(
                !compressed.is_null(),
                "Result should not be null for encoding: {}",
                encoding_name
            );
            assert!(
                compressed.len() > 0,
                "Output length should be greater than 0 for encoding: {}",
                encoding_name
            );
        }
    }
}
