//! Convert Core Library
//!
//! High-performance conversion functions for the PowerShell Convert module.
//! This library provides C ABI exports for Base64 encoding/decoding, cryptographic
//! hashing, compression, URL encoding, and time/temperature conversions.

// Module declarations
mod base64;
mod compression;
mod encoding;
mod error;
mod hash;
mod memory;
mod temperature;
mod time;
mod url;

// Re-export public functions from modules
pub use base64::*;
pub use compression::*;
pub use encoding::*;
pub use error::*;
pub use hash::*;
pub use memory::*;
pub use temperature::*;
pub use time::*;
pub use url::*;
