//! Compression and decompression functions using Gzip

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use flate2::write::GzEncoder;
use flate2::read::GzDecoder;
use flate2::Compression;
use std::io::{Write, Read};

/// Compress a string using Gzip compression
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `input` is a valid null-terminated C string or null
/// - `encoding` is a valid null-terminated C string or null
/// - `out_length` is a valid pointer to a usize
/// - The returned pointer must be freed using `free_bytes`
/// 
/// # Arguments
/// * `input` - The string to compress
/// * `encoding` - The character encoding to use (UTF8, ASCII, Unicode, etc.)
/// * `out_length` - Pointer to store the length of compressed data
/// 
/// # Returns
/// Pointer to compressed byte array, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn compress_string(
    input: *const c_char,
    encoding: *const c_char,
    out_length: *mut usize,
) -> *mut u8 {
    // Validate null pointers
    if input.is_null() {
        crate::error::set_error("Input pointer is null".to_string());
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        return std::ptr::null_mut();
    }
    
    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        return std::ptr::null_mut();
    }
    
    // Convert C strings to Rust strings
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
    
    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            if !out_length.is_null() {
                unsafe { *out_length = 0; }
            }
            return std::ptr::null_mut();
        }
    };
    
    // Convert string to bytes based on encoding
    let bytes = match crate::base64::convert_string_to_bytes(input_str, encoding_str) {
        Ok(b) => b,
        Err(e) => {
            crate::error::set_error(e);
            if !out_length.is_null() {
                unsafe { *out_length = 0; }
            }
            return std::ptr::null_mut();
        }
    };
    
    // Compress using Gzip
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    if let Err(e) = encoder.write_all(&bytes) {
        crate::error::set_error(format!("Compression write failed: {}", e));
        if !out_length.is_null() {
            unsafe { *out_length = 0; }
        }
        return std::ptr::null_mut();
    }
    
    let compressed = match encoder.finish() {
        Ok(data) => data,
        Err(e) => {
            crate::error::set_error(format!("Compression finish failed: {}", e));
            if !out_length.is_null() {
                unsafe { *out_length = 0; }
            }
            return std::ptr::null_mut();
        }
    };
    
    // Set output length
    let length = compressed.len();
    if !out_length.is_null() {
        unsafe { *out_length = length; }
    }
    
    // Allocate byte array with metadata header for proper deallocation
    crate::error::clear_error();
    crate::memory::allocate_byte_array(compressed)
}

/// Decompress a Gzip-compressed byte array to a string
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `bytes` is a valid pointer to a byte array or null
/// - `length` accurately represents the number of bytes to read
/// - `encoding` is a valid null-terminated C string or null
/// - The returned pointer must be freed using `free_string`
/// 
/// # Arguments
/// * `bytes` - Pointer to compressed byte array
/// * `length` - Length of compressed data
/// * `encoding` - The character encoding to use for the output string
/// 
/// # Returns
/// Pointer to decompressed string, or null on error
#[unsafe(no_mangle)]
pub extern "C" fn decompress_string(
    bytes: *const u8,
    length: usize,
    encoding: *const c_char,
) -> *mut c_char {
    // Validate null pointers
    if bytes.is_null() {
        crate::error::set_error("Byte array pointer is null".to_string());
        return std::ptr::null_mut();
    }
    
    if encoding.is_null() {
        crate::error::set_error("Encoding pointer is null".to_string());
        return std::ptr::null_mut();
    }
    
    // Convert encoding C string to Rust string
    let encoding_str = match unsafe { CStr::from_ptr(encoding).to_str() } {
        Ok(s) => s,
        Err(_) => {
            crate::error::set_error("Invalid UTF-8 in encoding string".to_string());
            return std::ptr::null_mut();
        }
    };
    
    // Create a slice from the raw pointer
    let compressed_slice = unsafe {
        std::slice::from_raw_parts(bytes, length)
    };
    
    // Decompress using Gzip
    let mut decoder = GzDecoder::new(compressed_slice);
    let mut decompressed = Vec::new();
    
    if let Err(e) = decoder.read_to_end(&mut decompressed) {
        crate::error::set_error(format!("Decompression failed: {}", e));
        return std::ptr::null_mut();
    }
    
    // Convert bytes to string based on encoding
    let result_string = match crate::base64::convert_bytes_to_string(&decompressed, encoding_str) {
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
            crate::error::set_error("Failed to create C string from decompressed result".to_string());
            std::ptr::null_mut()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    // ===== Test Helpers =====

    /// RAII guard for automatic cleanup of compressed byte arrays
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

    /// RAII guard for automatic cleanup of decompressed strings
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

    /// Helper to compress a string with automatic cleanup
    fn compress_with_encoding(input: &str, encoding: &str) -> CompressedBytes {
        let input_cstr = CString::new(input).unwrap();
        let encoding_cstr = CString::new(encoding).unwrap();
        let mut out_length: usize = 0;

        let ptr = compress_string(
            input_cstr.as_ptr(),
            encoding_cstr.as_ptr(),
            &mut out_length as *mut usize,
        );

        CompressedBytes::new(ptr, out_length)
    }

    /// Helper to decompress bytes with automatic cleanup
    fn decompress_with_encoding(bytes: &CompressedBytes, encoding: &str) -> DecompressedString {
        let encoding_cstr = CString::new(encoding).unwrap();

        let ptr = decompress_string(
            bytes.as_ptr(),
            bytes.len(),
            encoding_cstr.as_ptr(),
        );

        DecompressedString::new(ptr)
    }

    /// Helper to perform a full round-trip compression/decompression
    fn round_trip(input: &str, encoding: &str) -> String {
        let compressed = compress_with_encoding(input, encoding);
        assert!(!compressed.is_null(), "Compression failed for: {}", input);

        let decompressed = decompress_with_encoding(&compressed, encoding);
        assert!(!decompressed.is_null(), "Decompression failed for: {}", input);

        decompressed.to_str().unwrap().to_string()
    }

    // ===== Tests for compress_string =====

    #[test]
    fn test_compress_string_happy_path_utf8() {
        // Test: compress "test string" with UTF8 encoding
        let compressed = compress_with_encoding("test string", "UTF8");
        
        assert!(!compressed.is_null(), "Result should not be null for valid input");
        assert!(compressed.len() > 0, "Output length should be greater than 0");
        
        // Verify we can read the compressed data
        let compressed_data = unsafe { std::slice::from_raw_parts(compressed.as_ptr(), compressed.len()) };
        assert!(!compressed_data.is_empty(), "Compressed data should not be empty");
    }

    #[test]
    fn test_compress_string_null_input_pointer() {
        // Test: null input pointer should return null
        let encoding = CString::new("UTF8").unwrap();
        let mut out_length: usize = 0;
        
        let result = compress_string(
            std::ptr::null(),
            encoding.as_ptr(),
            &mut out_length as *mut usize,
        );
        
        assert!(result.is_null(), "Result should be null for null input pointer");
        assert_eq!(out_length, 0, "Output length should be 0 for null input");
    }

    #[test]
    fn test_compress_string_null_encoding_pointer() {
        // Test: null encoding pointer should return null
        let input = CString::new("test string").unwrap();
        let mut out_length: usize = 0;
        
        let result = compress_string(
            input.as_ptr(),
            std::ptr::null(),
            &mut out_length as *mut usize,
        );
        
        assert!(result.is_null(), "Result should be null for null encoding pointer");
        assert_eq!(out_length, 0, "Output length should be 0 for null encoding");
    }

    #[test]
    fn test_compress_string_invalid_encoding() {
        // Test: invalid encoding should return null
        let input = CString::new("test string").unwrap();
        let encoding = CString::new("INVALID_ENCODING").unwrap();
        let mut out_length: usize = 0;
        
        let result = compress_string(
            input.as_ptr(),
            encoding.as_ptr(),
            &mut out_length as *mut usize,
        );
        
        assert!(result.is_null(), "Result should be null for invalid encoding");
        assert_eq!(out_length, 0, "Output length should be 0 for invalid encoding");
    }

    #[test]
    fn test_compress_string_empty_string() {
        // Test: empty string should compress successfully
        let compressed = compress_with_encoding("", "UTF8");
        
        assert!(!compressed.is_null(), "Result should not be null for empty string");
        assert!(compressed.len() > 0, "Gzip header should produce non-zero output even for empty input");
    }

    #[test]
    fn test_compress_string_large_string_1mb() {
        // Test: large string (1MB) should compress successfully
        let large_string = "A".repeat(1024 * 1024);
        let compressed = compress_with_encoding(&large_string, "UTF8");
        
        assert!(!compressed.is_null(), "Result should not be null for large string");
        assert!(compressed.len() > 0, "Output length should be greater than 0");
    }

    #[test]
    fn test_compress_string_output_smaller_than_input() {
        // Test: verify compressed output is smaller than input for repetitive data
        let repetitive_string = "AAAAAAAAAA".repeat(1000); // 10,000 bytes of 'A'
        let original_size = repetitive_string.len();
        let compressed = compress_with_encoding(&repetitive_string, "UTF8");
        
        assert!(!compressed.is_null(), "Result should not be null");
        
        // Compressed size should be significantly smaller than original
        assert!(compressed.len() < original_size, 
            "Compressed size ({}) should be smaller than original size ({})", 
            compressed.len(), original_size);
        
        // For highly repetitive data, compression should be very effective
        assert!(compressed.len() < original_size / 10, 
            "Compressed size ({}) should be less than 10% of original size ({})", 
            compressed.len(), original_size);
    }

    #[test]
    fn test_compress_string_various_encodings() {
        // Test: compress with various supported encodings
        let test_string = "Hello World";
        let encodings = vec!["UTF8", "ASCII", "Unicode"];
        
        for encoding_name in encodings {
            let compressed = compress_with_encoding(test_string, encoding_name);
            
            assert!(!compressed.is_null(), 
                "Result should not be null for encoding: {}", encoding_name);
            assert!(compressed.len() > 0, 
                "Output length should be greater than 0 for encoding: {}", encoding_name);
        }
    }

    // ===== Tests for decompress_string =====

    #[test]
    fn test_decompress_string_happy_path() {
        // Test: decompress to original string
        let original = "test string for decompression";
        let result = round_trip(original, "UTF8");
        
        assert_eq!(result, original, "Decompressed string should match original");
    }

    #[test]
    fn test_decompress_string_round_trip() {
        // Test: compress/decompress round-trip preserves data
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
            assert_eq!(result, original, "Round-trip should preserve data for: {}", original);
        }
    }

    #[test]
    fn test_decompress_string_null_pointer() {
        // Test: null pointer should return null
        let encoding = CString::new("UTF8").unwrap();
        
        let result = decompress_string(
            std::ptr::null(),
            0,
            encoding.as_ptr(),
        );
        
        assert!(result.is_null(), "Result should be null for null pointer");
    }

    #[test]
    fn test_decompress_string_invalid_compressed_data() {
        // Test: invalid compressed data should return null
        let invalid_data = vec![0xFF, 0xFE, 0xFD, 0xFC]; // Not valid Gzip data
        let encoding = CString::new("UTF8").unwrap();
        
        let result = decompress_string(
            invalid_data.as_ptr(),
            invalid_data.len(),
            encoding.as_ptr(),
        );
        
        assert!(result.is_null(), "Result should be null for invalid compressed data");
    }

    #[test]
    fn test_decompress_string_various_encodings() {
        // Test: decompress with various encodings
        let original = "Test String";
        let encodings = vec!["UTF8", "ASCII"];
        
        for encoding_name in encodings {
            let result = round_trip(original, encoding_name);
            assert_eq!(result, original, 
                "Round-trip should preserve data for encoding: {}", encoding_name);
        }
    }

    #[test]
    fn test_decompress_string_null_encoding_pointer() {
        // Test: null encoding pointer should return null
        let data = vec![0x1F, 0x8B]; // Gzip magic number
        
        let result = decompress_string(
            data.as_ptr(),
            data.len(),
            std::ptr::null(),
        );
        
        assert!(result.is_null(), "Result should be null for null encoding pointer");
    }

    #[test]
    fn test_decompress_string_empty_compressed_data() {
        // Test: empty compressed data should return null or handle gracefully
        let encoding = CString::new("UTF8").unwrap();
        
        let result = decompress_string(
            std::ptr::null(),
            0,
            encoding.as_ptr(),
        );
        
        assert!(result.is_null(), "Result should be null for empty compressed data");
    }

    #[test]
    fn test_decompress_string_emoji() {
        // Test: emoji characters should round-trip correctly
        let original = "Hello 👋 World 🌍";
        let result = round_trip(original, "UTF8");
        
        assert_eq!(result, original, "Emoji should round-trip correctly");
        
        // Verify the bytes are correct
        let original_bytes = original.as_bytes();
        let result_bytes = result.as_bytes();
        assert_eq!(result_bytes, original_bytes, "Bytes should match exactly");
    }
}
