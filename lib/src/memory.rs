//! Memory management functions for freeing allocated strings and byte arrays

use std::os::raw::c_char;

/// Free a string allocated by Rust and returned to the caller
/// 
/// # Safety
/// This function is unsafe because it takes ownership of a raw pointer.
/// The caller must ensure that:
/// - `ptr` was allocated by a Rust function using CString::into_raw()
/// - `ptr` is not used after calling this function
/// - `ptr` is only freed once
/// 
/// # Arguments
/// * `ptr` - A pointer to a C string allocated by Rust. Can be null (no-op).
/// 
/// # Examples
/// ```
/// use std::ffi::CString;
/// let s = CString::new("test").unwrap();
/// let ptr = s.into_raw();
/// unsafe { free_string(ptr); }
/// ```
#[unsafe(no_mangle)]
pub unsafe extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        // Reconstruct the CString and let it drop, which deallocates the memory
        let _ = unsafe { std::ffi::CString::from_raw(ptr) };
    }
}

/// Free a byte array allocated by Rust and returned to the caller
/// 
/// # Safety
/// This function is unsafe because it takes ownership of a raw pointer.
/// The caller must ensure that:
/// - `ptr` was allocated by a Rust function that used `allocate_byte_array`
/// - `ptr` is not used after calling this function
/// - `ptr` is only freed once
/// 
/// # Arguments
/// * `ptr` - A pointer to a byte array allocated by Rust. Can be null (no-op).
/// 
/// # Implementation Note
/// This function reads metadata (length and capacity) stored in a header
/// before the actual data pointer. The header is created by `allocate_byte_array`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn free_bytes(ptr: *mut u8) {
    if ptr.is_null() {
        return;
    }
    
    // Read the metadata header stored before the data
    // Layout: [data_length: usize][full_capacity: usize][data...]
    //                                                     ^ ptr points here
    // Metadata is stored in little-endian for portability
    
    let header_size = std::mem::size_of::<usize>() * 2;
    let header_ptr = unsafe { ptr.sub(header_size) };
    
    // Read length (little-endian)
    let length_bytes = unsafe { 
        std::slice::from_raw_parts(header_ptr, std::mem::size_of::<usize>()) 
    };
    let data_length = usize::from_le_bytes(
        length_bytes.try_into().expect("Invalid length bytes")
    );
    
    // Read capacity (little-endian)
    let capacity_ptr = unsafe { header_ptr.add(std::mem::size_of::<usize>()) };
    let capacity_bytes = unsafe { 
        std::slice::from_raw_parts(capacity_ptr, std::mem::size_of::<usize>()) 
    };
    let full_capacity = usize::from_le_bytes(
        capacity_bytes.try_into().expect("Invalid capacity bytes")
    );
    
    // Reconstruct the Vec from raw parts (this includes the header + data)
    // The length is header_size + data_length
    // The capacity is what we stored (the actual allocated capacity)
    let full_length = header_size + data_length;
    let full_vec = unsafe { Vec::from_raw_parts(header_ptr as *mut u8, full_length, full_capacity) };
    
    // Vec will be dropped here, deallocating the memory
    drop(full_vec);
}

/// Helper function to allocate a byte array with metadata header
/// 
/// This function allocates memory for a byte array with a header containing
/// length and capacity information. This allows `free_bytes` to properly
/// deallocate the memory later.
/// 
/// # Arguments
/// * `data` - The byte vector to allocate
/// 
/// # Returns
/// A pointer to the data portion (after the header)
pub fn allocate_byte_array(mut data: Vec<u8>) -> *mut u8 {
    let data_length = data.len();
    
    // Create a new Vec with header: [data_length][full_capacity][data...]
    // Use little-endian for explicit, portable byte order
    let header_size = std::mem::size_of::<usize>() * 2;
    let mut full_vec = Vec::with_capacity(header_size + data_length);
    
    // Write header with data length (little-endian for portability)
    full_vec.extend_from_slice(&data_length.to_le_bytes());
    
    // Reserve space for capacity (will write after we know actual capacity)
    full_vec.extend_from_slice(&[0u8; std::mem::size_of::<usize>()]);
    
    // Write data
    full_vec.append(&mut data);
    
    // Now write the actual capacity of the full_vec (little-endian)
    let actual_capacity = full_vec.capacity();
    let capacity_bytes = actual_capacity.to_le_bytes();
    let capacity_offset = std::mem::size_of::<usize>();
    full_vec[capacity_offset..capacity_offset + std::mem::size_of::<usize>()]
        .copy_from_slice(&capacity_bytes);
    
    // Get pointer to data portion (skip header)
    let ptr = unsafe { full_vec.as_mut_ptr().add(header_size) };
    
    // Prevent deallocation - caller will free with free_bytes
    std::mem::forget(full_vec);
    
    ptr
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    // ===== Tests for free_string (Task 3.1) =====

    #[test]
    fn test_free_string_valid_pointer() {
        // Test: free_string should safely deallocate a valid C string pointer
        let test_string = CString::new("Hello, World!").unwrap();
        let ptr = test_string.into_raw();

        // This should not panic or cause memory issues
        unsafe { free_string(ptr) };
        
        // If we reach here without panic, the test passes
        // Note: We cannot verify deallocation directly, but valgrind/miri would catch issues
    }

    #[test]
    fn test_free_string_null_pointer() {
        // Test: free_string should handle null pointer gracefully (no-op)
        let null_ptr: *mut c_char = std::ptr::null_mut();

        // This should not panic
        unsafe { free_string(null_ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_string_empty_string() {
        // Test: free_string should handle empty string pointer
        let empty_string = CString::new("").unwrap();
        let ptr = empty_string.into_raw();

        unsafe { free_string(ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_string_large_string() {
        // Test: free_string should handle large string (1MB)
        let large_string = "A".repeat(1024 * 1024);
        let test_string = CString::new(large_string).unwrap();
        let ptr = test_string.into_raw();

        unsafe { free_string(ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_string_special_characters() {
        // Test: free_string should handle strings with special characters
        let special_string = CString::new("Hello\n\t\r\0World").unwrap_or_else(|_| {
            CString::new("Hello World").unwrap()
        });
        let ptr = special_string.into_raw();

        unsafe { free_string(ptr) };
        
        // If we reach here without panic, the test passes
    }

    // ===== Tests for free_bytes (Task 3.2) =====

    #[test]
    fn test_free_bytes_valid_pointer() {
        // Test: free_bytes should safely deallocate a valid byte array pointer
        let test_data = vec![1u8, 2, 3, 4, 5];
        let ptr = allocate_byte_array(test_data);

        // This should not panic or cause memory issues
        unsafe { free_bytes(ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_bytes_null_pointer() {
        // Test: free_bytes should handle null pointer gracefully (no-op)
        let null_ptr: *mut u8 = std::ptr::null_mut();

        // This should not panic
        unsafe { free_bytes(null_ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_bytes_empty_array() {
        // Test: free_bytes should handle empty byte array
        let empty_data = Vec::<u8>::new();
        let ptr = allocate_byte_array(empty_data);

        unsafe { free_bytes(ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_bytes_large_array() {
        // Test: free_bytes should handle large byte array (1MB)
        let large_data = vec![0u8; 1024 * 1024];
        let ptr = allocate_byte_array(large_data);

        unsafe { free_bytes(ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_allocate_and_free_bytes_round_trip() {
        // Test: allocate and free should work correctly for various sizes
        let test_data = vec![10u8, 20, 30, 40, 50, 60, 70, 80, 90, 100];
        let ptr = allocate_byte_array(test_data.clone());

        // Verify we can read the data back
        let read_data = unsafe { std::slice::from_raw_parts(ptr, test_data.len()) };
        assert_eq!(read_data, &test_data[..]);

        // Free the memory
        unsafe { free_bytes(ptr) };
        
        // If we reach here without panic, the test passes
    }

    #[test]
    fn test_free_bytes_multiple_allocations() {
        // Test: multiple allocations and frees should work correctly
        for size in [0, 1, 10, 100, 1000, 10000] {
            let data = vec![42u8; size];
            let ptr = allocate_byte_array(data);
            unsafe { free_bytes(ptr) };
        }
        
        // If we reach here without panic, the test passes
    }

    // ===== Tests to expose critical issues (RED phase) =====

    #[test]
    fn test_allocate_byte_array_alignment() {
        // Test: allocated pointer should be properly aligned for the data
        // This test exposes potential alignment issues in the header layout
        let test_data = vec![1u8, 2, 3, 4, 5, 6, 7, 8];
        let ptr = allocate_byte_array(test_data.clone());
        
        // Check that the pointer is aligned (at least to usize alignment)
        let ptr_addr = ptr as usize;
        let alignment = std::mem::align_of::<usize>();
        
        // The data pointer should ideally be aligned, though the current implementation
        // may not guarantee this if header_size isn't a multiple of alignment
        // This test documents the expected behavior
        assert_eq!(ptr_addr % alignment, 0, 
            "Data pointer should be aligned to {} bytes, but got address 0x{:x}", 
            alignment, ptr_addr);
        
        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_allocate_byte_array_metadata_integrity() {
        // Test: metadata should be correctly stored and retrievable
        // This test exposes issues with metadata corruption
        let test_sizes = vec![0, 1, 7, 8, 15, 16, 100, 1000, 10000];
        
        for size in test_sizes {
            let test_data = vec![0xABu8; size];
            let ptr = allocate_byte_array(test_data.clone());
            
            // Read back the metadata (this is what free_bytes does)
            let header_size = std::mem::size_of::<usize>() * 2;
            let header_ptr = unsafe { ptr.sub(header_size) as *const usize };
            
            let stored_length = unsafe { *header_ptr };
            let stored_capacity = unsafe { *header_ptr.add(1) };
            
            // Verify metadata matches expectations
            assert_eq!(stored_length, size, 
                "Stored length {} should match actual size {} for test data", 
                stored_length, size);
            
            assert!(stored_capacity >= header_size + size, 
                "Stored capacity {} should be at least header_size + data_length ({} + {})", 
                stored_capacity, header_size, size);
            
            // Verify data integrity
            let data_slice = unsafe { std::slice::from_raw_parts(ptr, size) };
            assert_eq!(data_slice, &test_data[..], 
                "Data should be intact after allocation");
            
            unsafe { free_bytes(ptr) };
        }
    }

    #[test]
    fn test_allocate_byte_array_capacity_reallocation() {
        // Test: verify that capacity is captured correctly even if Vec reallocates
        // This exposes the issue where we write capacity after the Vec is populated
        
        // Create a Vec that will likely reallocate during construction
        let mut data = Vec::with_capacity(10);
        for i in 0..100 {
            data.push(i as u8);
        }
        // At this point, data has reallocated and capacity > 10
        
        let original_capacity = data.capacity();
        let ptr = allocate_byte_array(data);
        
        // Read back the stored capacity
        let header_size = std::mem::size_of::<usize>() * 2;
        let header_ptr = unsafe { ptr.sub(header_size) as *const usize };
        let stored_capacity = unsafe { *header_ptr.add(1) };
        
        // The stored capacity should reflect the actual allocation size
        // This test will help verify the fix handles capacity correctly
        assert!(stored_capacity >= header_size + 100, 
            "Stored capacity {} should account for header and data", 
            stored_capacity);
        
        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_free_bytes_with_unaligned_access() {
        // Test: free_bytes should handle potentially unaligned metadata reads
        // This test exposes issues on platforms with strict alignment requirements
        
        // Allocate various sizes to test different alignment scenarios
        let test_sizes = vec![1, 3, 5, 7, 9, 11, 13, 15, 17];
        
        for size in test_sizes {
            let data = vec![0xFFu8; size];
            let ptr = allocate_byte_array(data);
            
            // Verify we can read the data
            let data_slice = unsafe { std::slice::from_raw_parts(ptr, size) };
            assert_eq!(data_slice.len(), size);
            
            // This should not panic or cause UB even with odd sizes
            unsafe { free_bytes(ptr) };
        }
    }

    #[test]
    fn test_allocate_free_stress_test() {
        // Test: stress test with many allocations and frees
        // This exposes memory leaks or corruption under load
        const ITERATIONS: usize = 1000;
        
        for i in 0..ITERATIONS {
            let size = (i % 100) + 1; // Vary size from 1 to 100
            let data = vec![(i % 256) as u8; size];
            let ptr = allocate_byte_array(data.clone());
            
            // Verify data integrity
            let read_data = unsafe { std::slice::from_raw_parts(ptr, size) };
            assert_eq!(read_data, &data[..], 
                "Data integrity check failed at iteration {}", i);
            
            unsafe { free_bytes(ptr) };
        }
    }

    #[test]
    fn test_allocate_byte_array_zero_capacity_vec() {
        // Test: handle Vec with zero capacity (edge case)
        let mut data = Vec::new();
        data.push(42u8);
        // data now has len=1 but capacity might be small
        
        let ptr = allocate_byte_array(data);
        
        // Should still work correctly
        let read_data = unsafe { std::slice::from_raw_parts(ptr, 1) };
        assert_eq!(read_data[0], 42);
        
        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_metadata_endianness_explicit_little_endian() {
        // Test: verify metadata is ALWAYS stored in little-endian format
        // This ensures cross-platform compatibility if metadata is ever serialized
        let data = vec![1u8, 2, 3, 4];
        let ptr = allocate_byte_array(data);
        
        let header_size = std::mem::size_of::<usize>() * 2;
        let header_ptr = unsafe { ptr.sub(header_size) };
        
        // Read raw bytes of the length field
        let length_bytes = unsafe { 
            std::slice::from_raw_parts(header_ptr, std::mem::size_of::<usize>()) 
        };
        
        // Metadata is ALWAYS little-endian, regardless of platform
        // length=4 should be [4, 0, 0, 0, 0, 0, 0, 0] (for 64-bit)
        // or [4, 0, 0, 0] (for 32-bit)
        assert_eq!(length_bytes[0], 4, 
            "First byte should be 4 (little-endian format)");
        
        // Verify we can read it back correctly
        let read_length = usize::from_le_bytes(
            length_bytes[..std::mem::size_of::<usize>()].try_into().unwrap()
        );
        assert_eq!(read_length, 4, "Should read back as 4");
        
        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_allocate_byte_array_preserves_data_exactly() {
        // Test: verify that all byte values are preserved correctly
        // This exposes any data corruption during allocation
        let all_bytes: Vec<u8> = (0..=255).collect();
        let ptr = allocate_byte_array(all_bytes.clone());
        
        let read_data = unsafe { std::slice::from_raw_parts(ptr, 256) };
        
        for (i, &byte) in read_data.iter().enumerate() {
            assert_eq!(byte, i as u8, 
                "Byte at index {} should be {}, but got {}", i, i, byte);
        }
        
        unsafe { free_bytes(ptr) };
    }
}
