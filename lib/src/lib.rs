//! Convert Core Library
//!
//! High-performance conversion functions for the PowerShell Convert module.
//! This library provides C ABI exports for Base64 encoding/decoding, cryptographic
//! hashing, compression, URL encoding, and time/temperature conversions.


// Module declarations
mod base64;
mod hash;
mod compression;
mod url;
mod time;
mod temperature;
mod memory;
mod error;
mod encoding;

// Re-export public functions from modules
pub use base64::*;
pub use hash::*;
pub use compression::*;
pub use url::*;
pub use time::*;
pub use temperature::*;
pub use memory::*;
pub use error::*;
pub use encoding::*;
