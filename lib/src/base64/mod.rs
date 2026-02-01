//! Base64 encoding and decoding functions

mod encoding;
mod string_ops;
mod bytes_ops;

// Re-export public FFI functions
pub use string_ops::{string_to_base64, base64_to_string, base64_to_string_lenient};
pub use bytes_ops::{bytes_to_base64, base64_to_bytes};

// Re-export encoding helpers for use by other modules
pub(crate) use encoding::{
    convert_string_to_bytes,
    convert_bytes_to_string,
    convert_bytes_to_string_with_fallback,
};
