//! Core hash and HMAC algorithm implementations

use hmac::{Hmac, Mac};
use md5::Md5;
use sha1::Sha1;
use sha2::{Digest, Sha256, Sha384, Sha512};

/// Computes hash for the given bytes using the specified algorithm.
///
/// Returns uppercase hexadecimal string for .NET compatibility.
pub(crate) fn compute_hash_bytes(bytes: &[u8], algorithm: &str) -> Result<String, String> {
    match algorithm.to_uppercase().as_str() {
        "MD5" => {
            let mut hasher = Md5::new();
            hasher.update(bytes);
            Ok(format!("{:X}", hasher.finalize()))
        }
        "SHA1" => {
            let mut hasher = Sha1::new();
            hasher.update(bytes);
            Ok(format!("{:X}", hasher.finalize()))
        }
        "SHA256" => {
            let mut hasher = Sha256::new();
            hasher.update(bytes);
            Ok(format!("{:X}", hasher.finalize()))
        }
        "SHA384" => {
            let mut hasher = Sha384::new();
            hasher.update(bytes);
            Ok(format!("{:X}", hasher.finalize()))
        }
        "SHA512" => {
            let mut hasher = Sha512::new();
            hasher.update(bytes);
            Ok(format!("{:X}", hasher.finalize()))
        }
        _ => Err(format!(
            "Unsupported algorithm: {}. Supported: MD5, SHA1, SHA256, SHA384, SHA512",
            algorithm
        )),
    }
}

/// Computes HMAC using the specified algorithm.
///
/// Returns uppercase hexadecimal string for .NET compatibility.
pub(crate) fn compute_hmac_internal(
    algorithm: &str,
    key: &[u8],
    input: &[u8],
) -> Result<String, String> {
    match algorithm.to_uppercase().as_str() {
        "MD5" => compute_hmac_md5(key, input),
        "SHA1" => compute_hmac_sha1(key, input),
        "SHA256" => compute_hmac_sha256(key, input),
        "SHA384" => compute_hmac_sha384(key, input),
        "SHA512" => compute_hmac_sha512(key, input),
        _ => Err(format!(
            "Unsupported algorithm: {}. Supported: MD5, SHA1, SHA256, SHA384, SHA512",
            algorithm
        )),
    }
}

/// Compute HMAC-MD5
#[inline]
fn compute_hmac_md5(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacMd5 = Hmac<Md5>;
    let mut mac = HmacMd5::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-MD5 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA1
#[inline]
fn compute_hmac_sha1(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha1 = Hmac<Sha1>;
    let mut mac = HmacSha1::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA1 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA256
#[inline]
fn compute_hmac_sha256(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha256 = Hmac<Sha256>;
    let mut mac = HmacSha256::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA256 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA384
#[inline]
fn compute_hmac_sha384(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha384 = Hmac<Sha384>;
    let mut mac = HmacSha384::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA384 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}

/// Compute HMAC-SHA512
#[inline]
fn compute_hmac_sha512(key: &[u8], input: &[u8]) -> Result<String, String> {
    type HmacSha512 = Hmac<Sha512>;
    let mut mac = HmacSha512::new_from_slice(key)
        .map_err(|_| "Failed to create HMAC-SHA512 instance".to_string())?;
    mac.update(input);
    Ok(format!("{:X}", mac.finalize().into_bytes()))
}
