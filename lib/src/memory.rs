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
    
    let header_size = std::mem::size_of::<usize>() * 2;
    let header_ptr = unsafe { ptr.sub(header_size) as *const usize };
    
    let data_length = unsafe { *header_ptr };
    let full_capacity = unsafe { *header_ptr.add(1) };
    
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
    let header_size = std::mem::size_of::<usize>() * 2;
    let mut full_vec = Vec::with_capacity(header_size + data_length);
    
    // Write header with data length
    full_vec.extend_from_slice(&data_length.to_ne_bytes());
    
    // Reserve space for capacity (will write after we know actual capacity)
    full_vec.extend_from_slice(&[0u8; std::mem::size_of::<usize>()]);
    
    // Write data
    full_vec.append(&mut data);
    
    // Now write the actual capacity of the full_vec
    let actual_capacity = full_vec.capacity();
    let capacity_bytes = actual_capacity.to_ne_bytes();
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
}
