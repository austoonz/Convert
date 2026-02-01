//! Compression and decompression functions using Gzip

mod base64_decompress;
mod compress;
mod decompress;

pub use base64_decompress::{base64_to_decompressed_string, base64_to_decompressed_string_lenient};
pub use compress::compress_string;
pub use decompress::{decompress_string, decompress_string_lenient};
