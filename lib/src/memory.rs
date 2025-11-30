//! Memory management functions for freeing allocated strings and byte arrays

use std::os::raw::c_char;

/// Copy a UTF-8 string pointer to a byte array for PowerShell 5.1 compatibility
///
/// This function copies a UTF-8 string to a byte array that PowerShell can read
/// using Marshal.Copy, avoiding the PtrToStringUTF8 compatibility issue.
///
/// # Safety
/// This function is unsafe because it dereferences a raw pointer.
/// The caller must ensure that:
/// - `ptr` points to a valid null-terminated UTF-8 string
/// - `out_length` is a valid pointer to write the length
///
/// # Arguments
/// * `ptr` - A pointer to a null-terminated UTF-8 string
/// * `out_length` - Output parameter for the byte length (excluding null terminator)
///
/// # Returns
/// A pointer to a byte array containing the UTF-8 bytes (without null terminator),
/// or null if the input pointer is null. The caller must free this with `free_bytes`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn string_to_bytes_copy(
    ptr: *const c_char,
    out_length: *mut usize,
) -> *mut u8 {
    if ptr.is_null() || out_length.is_null() {
        return std::ptr::null_mut();
    }

    unsafe {
        // Convert C string to Rust string slice
        let c_str = std::ffi::CStr::from_ptr(ptr);
        let bytes = c_str.to_bytes(); // UTF-8 bytes without null terminator

        // Write the length
        *out_length = bytes.len();

        // Allocate and copy the bytes
        allocate_byte_array(bytes.to_vec())
    }
}

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
        // SAFETY: ptr was allocated by CString::into_raw() and is only freed once
        unsafe {
            let _ = std::ffi::CString::from_raw(ptr);
        }
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
/// This function reads metadata (length and total size) stored in a header
/// before the actual data pointer. The header is created by `allocate_byte_array`.
/// Uses `std::alloc::dealloc` with proper alignment for safe cross-platform operation.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn free_bytes(ptr: *mut u8) {
    use std::alloc::{Layout, dealloc};

    if ptr.is_null() {
        return;
    }

    // SAFETY: All operations are unsafe but guaranteed safe by contract:
    // - ptr was allocated by allocate_byte_array with proper alignment
    // - ptr is only freed once
    // - metadata is at a known offset with proper alignment
    unsafe {
        // Read the metadata header stored before the data
        // Layout: [data_length: usize][total_size: usize][data...]
        //                                                  ^ ptr points here

        let header_size = std::mem::size_of::<usize>() * 2;
        let header_ptr = ptr.sub(header_size);

        // Read metadata (now guaranteed aligned for usize access)
        let metadata_ptr = header_ptr as *const usize;
        let total_size = *metadata_ptr.add(1); // Total allocation size

        // Create the same layout used for allocation
        let layout = Layout::from_size_align_unchecked(total_size, std::mem::align_of::<usize>());

        // Deallocate the memory
        dealloc(header_ptr, layout);
    }
}

/// Helper function to allocate a byte array with metadata header
///
/// This function allocates memory for a byte array with a header containing
/// length and total allocation size information. This allows `free_bytes` to properly
/// deallocate the memory later.
///
/// Uses `std::alloc` with explicit alignment to ensure safe metadata access on all platforms.
/// All operations complete atomically to prevent memory leaks on panic.
///
/// # Arguments
/// * `data` - The byte vector to allocate
///
/// # Returns
/// A pointer to the data portion (after the header)
pub fn allocate_byte_array(data: Vec<u8>) -> *mut u8 {
    use std::alloc::{Layout, alloc};

    let data_length = data.len();
    let header_size = std::mem::size_of::<usize>() * 2;
    let total_size = header_size + data_length;

    // Create layout with usize alignment for the entire allocation
    // This ensures the header can be safely read as usize values
    let layout =
        Layout::from_size_align(total_size, std::mem::align_of::<usize>()).expect("Invalid layout");

    unsafe {
        // Allocate memory with proper alignment
        let ptr = alloc(layout);
        if ptr.is_null() {
            panic!("Allocation failed");
        }

        // Write metadata header (guaranteed aligned for usize access)
        let header_ptr = ptr as *mut usize;
        *header_ptr = data_length; // Store data length
        *header_ptr.add(1) = total_size; // Store total allocation size

        // Copy data to the allocated memory
        let data_ptr = ptr.add(header_size);
        std::ptr::copy_nonoverlapping(data.as_ptr(), data_ptr, data_length);

        // Return pointer to data portion (after header)
        data_ptr
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    // ===== Tests for free_string =====

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
        let special_string = CString::new("Hello\n\t\r\0World")
            .unwrap_or_else(|_| CString::new("Hello World").unwrap());
        let ptr = special_string.into_raw();

        unsafe { free_string(ptr) };

        // If we reach here without panic, the test passes
    }

    // ===== Tests for free_bytes =====

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
        assert_eq!(
            ptr_addr % alignment,
            0,
            "Data pointer should be aligned to {} bytes, but got address 0x{:x}",
            alignment,
            ptr_addr
        );

        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_allocate_byte_array_metadata_integrity() {
        // Test: metadata should be correctly stored and retrievable
        let test_sizes = vec![0, 1, 7, 8, 15, 16, 100, 1000, 10000];

        for size in test_sizes {
            let test_data = vec![0xABu8; size];
            let ptr = allocate_byte_array(test_data.clone());

            // Read back the metadata using the same method as free_bytes()
            let header_size = std::mem::size_of::<usize>() * 2;
            let header_ptr = unsafe { ptr.sub(header_size) };

            // Read metadata (now safe because allocation is properly aligned)
            let metadata_ptr = header_ptr as *const usize;
            let stored_length = unsafe { *metadata_ptr };
            let stored_total_size = unsafe { *metadata_ptr.add(1) };

            // Verify metadata matches expectations
            assert_eq!(
                stored_length, size,
                "Stored length {} should match actual size {} for test data",
                stored_length, size
            );

            assert_eq!(
                stored_total_size,
                header_size + size,
                "Stored total size {} should equal header_size + data_length ({} + {})",
                stored_total_size,
                header_size,
                size
            );

            // Verify data integrity
            let data_slice = unsafe { std::slice::from_raw_parts(ptr, size) };
            assert_eq!(
                data_slice,
                &test_data[..],
                "Data should be intact after allocation"
            );

            unsafe { free_bytes(ptr) };
        }
    }

    #[test]
    fn test_allocate_byte_array_total_size_tracking() {
        // Test: verify that total size is tracked correctly
        let data = vec![42u8; 100];
        let ptr = allocate_byte_array(data);

        // Read back the stored total size
        let header_size = std::mem::size_of::<usize>() * 2;
        let header_ptr = unsafe { ptr.sub(header_size) as *const usize };
        let stored_total_size = unsafe { *header_ptr.add(1) };

        // The stored total size should be exactly header_size + data_length
        assert_eq!(
            stored_total_size,
            header_size + 100,
            "Stored total size {} should equal header_size + data_length",
            stored_total_size
        );

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
            assert_eq!(
                read_data,
                &data[..],
                "Data integrity check failed at iteration {}",
                i
            );

            unsafe { free_bytes(ptr) };
        }
    }

    #[test]
    fn test_allocate_byte_array_zero_capacity_vec() {
        // Test: handle Vec with zero capacity (edge case)
        let data = vec![42u8];
        // data now has len=1 but capacity might be small

        let ptr = allocate_byte_array(data);

        // Should still work correctly
        let read_data = unsafe { std::slice::from_raw_parts(ptr, 1) };
        assert_eq!(read_data[0], 42);

        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_metadata_native_endianness() {
        // Test: verify metadata is stored in native endianness (platform-specific)
        // This is safe because we never serialize the metadata across platforms
        let data = vec![1u8, 2, 3, 4];
        let ptr = allocate_byte_array(data);

        let header_size = std::mem::size_of::<usize>() * 2;
        let header_ptr = unsafe { ptr.sub(header_size) };

        // Read as native usize (now safe due to proper alignment)
        let metadata_ptr = header_ptr as *const usize;
        let stored_length = unsafe { *metadata_ptr };
        let stored_total_size = unsafe { *metadata_ptr.add(1) };

        assert_eq!(stored_length, 4, "Length should be 4");
        assert_eq!(
            stored_total_size,
            header_size + 4,
            "Total size should be header + data"
        );

        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_allocation_uses_proper_alignment() {
        // Test: verify that allocations use proper alignment for usize
        let data = vec![1u8, 2, 3, 4, 5];
        let ptr = allocate_byte_array(data);

        // The header should be aligned for usize access
        let header_size = std::mem::size_of::<usize>() * 2;
        let header_ptr = unsafe { ptr.sub(header_size) };
        let header_addr = header_ptr as usize;
        let required_alignment = std::mem::align_of::<usize>();

        assert_eq!(
            header_addr % required_alignment,
            0,
            "Header pointer must be aligned to {} bytes for safe usize access, got address 0x{:x}",
            required_alignment,
            header_addr
        );

        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_free_bytes_uses_aligned_reads() {
        // Test: verify that free_bytes can safely read metadata with various sizes
        for size in [1, 3, 5, 7, 9, 11, 13, 15, 17, 100, 1000] {
            let data = vec![0xABu8; size];
            let ptr = allocate_byte_array(data);

            // This should not panic or cause UB even with odd sizes
            // If alignment is wrong, this will fail on ARM/SPARC
            unsafe { free_bytes(ptr) };
        }
    }

    #[test]
    fn test_allocate_byte_array_panic_safety() {
        // Test: verify no memory leak if operations panic
        // This is hard to test directly, but we can verify the order of operations

        // If this doesn't panic, the implementation is safe
        let data = vec![1u8; 1000];
        let ptr = allocate_byte_array(data);

        // Verify we can read the data
        let read_data = unsafe { std::slice::from_raw_parts(ptr, 1000) };
        assert_eq!(read_data.len(), 1000);

        unsafe { free_bytes(ptr) };
    }

    #[test]
    fn test_concurrent_allocations() {
        use std::thread;

        // Test: multiple threads allocating and freeing concurrently
        let handles: Vec<_> = (0..10)
            .map(|i| {
                thread::spawn(move || {
                    for j in 0..100 {
                        let size = (i * 100 + j) % 256 + 1;
                        let data = vec![i as u8; size];
                        let ptr = allocate_byte_array(data.clone());

                        // Verify data integrity
                        let read_data = unsafe { std::slice::from_raw_parts(ptr, size) };
                        assert_eq!(read_data, &data[..]);

                        unsafe { free_bytes(ptr) };
                    }
                })
            })
            .collect();

        for handle in handles {
            handle.join().unwrap();
        }
    }

    #[test]
    fn test_allocate_byte_array_preserves_data_exactly() {
        // Test: verify that all byte values are preserved correctly
        // This exposes any data corruption during allocation
        let all_bytes: Vec<u8> = (0..=255).collect();
        let ptr = allocate_byte_array(all_bytes.clone());

        let read_data = unsafe { std::slice::from_raw_parts(ptr, 256) };

        for (i, &byte) in read_data.iter().enumerate() {
            assert_eq!(
                byte, i as u8,
                "Byte at index {} should be {}, but got {}",
                i, i, byte
            );
        }

        unsafe { free_bytes(ptr) };
    }
}
