//! Error reporting mechanism with thread-local storage

use std::cell::RefCell;
use std::ffi::CString;
use std::os::raw::c_char;

thread_local! {
    static LAST_ERROR: RefCell<Option<String>> = RefCell::new(None);
}

/// Set the last error message
pub fn set_error(message: String) {
    LAST_ERROR.with(|e| {
        *e.borrow_mut() = Some(message);
    });
}

/// Clear the last error message
pub fn clear_error() {
    LAST_ERROR.with(|e| {
        *e.borrow_mut() = None;
    });
}

/// Get the last error message as a C string
/// Returns null if no error
/// Caller must free the returned string with free_string
#[unsafe(no_mangle)]
pub extern "C" fn get_last_error() -> *mut c_char {
    LAST_ERROR.with(|e| {
        match e.borrow().as_ref() {
            Some(err) => {
                match CString::new(err.clone()) {
                    Ok(c_str) => c_str.into_raw(),
                    Err(_) => std::ptr::null_mut(),
                }
            }
            None => std::ptr::null_mut(),
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    #[test]
    fn test_error_handling() {
        clear_error();
        let ptr = get_last_error();
        assert!(ptr.is_null());

        set_error("Test error".to_string());
        let ptr = get_last_error();
        assert!(!ptr.is_null());

        unsafe {
            let c_str = CStr::from_ptr(ptr);
            assert_eq!(c_str.to_str().unwrap(), "Test error");
            // Free the string
            let _ = CString::from_raw(ptr);
        }
    }
}
