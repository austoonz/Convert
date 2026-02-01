//! Helper functions for encoding operations

/// Sets output length to zero if pointer is non-null.
///
/// Used in error paths to ensure consistent behavior.
#[inline]
pub(crate) fn set_output_length_zero(out_length: *mut usize) {
    if !out_length.is_null() {
        unsafe {
            *out_length = 0;
        }
    }
}
