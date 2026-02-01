//! Cryptographic hash functions (MD5, SHA1, SHA256, SHA384, SHA512, HMAC)

mod algorithms;
mod hash_ops;
mod hmac_ops;

// Re-export public FFI functions
pub use hash_ops::compute_hash;
pub use hmac_ops::{compute_hmac_bytes, compute_hmac_with_encoding};
