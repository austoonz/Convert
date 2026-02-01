//! Base64 encoding and decoding functions

mod bytes_ops;
mod encoding;
mod string_ops;

// Re-export public FFI functions
pub use bytes_ops::{base64_to_bytes, bytes_to_base64};
pub use string_ops::{base64_to_string, base64_to_string_lenient, string_to_base64};

// Re-export encoding helpers for use by other modules
pub(crate) use encoding::{
    convert_bytes_to_string, convert_bytes_to_string_with_fallback, convert_string_to_bytes,
};
