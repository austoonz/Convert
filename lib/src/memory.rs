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
