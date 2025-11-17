//! Memory management functions for freeing allocated strings and byte arrays

use std::os::raw::c_char;

/// Free a string allocated by Rust and returned to the caller
/// 
/// # Safety
/// This function is unsafe because it takes ownership of a raw pointer.
/// The caller must ensure that:
/// - `ptr` was allocated by a Rust function using CString::into_raw()
/// - `ptr` is not used after calling this function
/// - `ptr` is not null
#[unsafe(no_mangle)]
pub unsafe extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        // Reconstruct the CString and let it drop
        let _ = unsafe { std::ffi::CString::from_raw(ptr) };
    }
}

/// Free a byte array allocated by Rust and returned to the caller
/// 
/// # Safety
/// This function is unsafe because it takes ownership of a raw pointer.
/// The caller must ensure that:
/// - `ptr` was allocated by a Rust function using Vec::into_raw_parts()
/// - `ptr` is not used after calling this function
/// - `ptr` is not null
/// 
/// Note: This is a stub implementation for testing. Full implementation in task 3.2.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn free_bytes(ptr: *mut u8) {
    if !ptr.is_null() {
        // TODO: Implement proper deallocation in task 3.2
        // For now, this is a stub to allow tests to compile
        // The proper implementation will need to know the length and capacity
    }
}
