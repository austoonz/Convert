//! Encoding conversion helper functions

/// Convert a Rust string to bytes using the specified encoding
pub(crate) fn convert_string_to_bytes(input: &str, encoding: &str) -> Result<Vec<u8>, String> {
    // Use eq_ignore_ascii_case to avoid allocating with to_uppercase()
    if encoding.eq_ignore_ascii_case("UTF8") || encoding.eq_ignore_ascii_case("UTF-8") {
        Ok(input.as_bytes().to_vec())
    } else if encoding.eq_ignore_ascii_case("ASCII") {
        // Validate that all characters are ASCII
        if input.is_ascii() {
            Ok(input.as_bytes().to_vec())
        } else {
            Err("String contains non-ASCII characters".to_string())
        }
    } else if encoding.eq_ignore_ascii_case("UNICODE")
        || encoding.eq_ignore_ascii_case("UTF16")
        || encoding.eq_ignore_ascii_case("UTF-16")
    {
        // Unicode in .NET typically means UTF-16LE
        let utf16: Vec<u16> = input.encode_utf16().collect();
        let mut bytes = Vec::with_capacity(utf16.len() * 2);
        for word in utf16 {
            bytes.push((word & 0xFF) as u8);
            bytes.push((word >> 8) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("UTF32") || encoding.eq_ignore_ascii_case("UTF-32") {
        // UTF-32LE encoding
        let mut bytes = Vec::with_capacity(input.chars().count() * 4);
        for ch in input.chars() {
            let code_point = ch as u32;
            bytes.push((code_point & 0xFF) as u8);
            bytes.push(((code_point >> 8) & 0xFF) as u8);
            bytes.push(((code_point >> 16) & 0xFF) as u8);
            bytes.push(((code_point >> 24) & 0xFF) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("BIGENDIANUNICODE")
        || encoding.eq_ignore_ascii_case("UTF16BE")
        || encoding.eq_ignore_ascii_case("UTF-16BE")
    {
        // UTF-16BE encoding
        let utf16: Vec<u16> = input.encode_utf16().collect();
        let mut bytes = Vec::with_capacity(utf16.len() * 2);
        for word in utf16 {
            bytes.push((word >> 8) as u8);
            bytes.push((word & 0xFF) as u8);
        }
        Ok(bytes)
    } else if encoding.eq_ignore_ascii_case("DEFAULT") {
        // Default encoding is UTF-8
        Ok(input.as_bytes().to_vec())
    } else {
        Err(format!("Unsupported encoding: {}", encoding))
    }
}

/// Convert bytes to a Rust string using the specified encoding
pub(crate) fn convert_bytes_to_string(bytes: &[u8], encoding: &str) -> Result<String, String> {
    // Use eq_ignore_ascii_case to avoid allocating with to_uppercase()
    if encoding.eq_ignore_ascii_case("UTF8") || encoding.eq_ignore_ascii_case("UTF-8") {
        String::from_utf8(bytes.to_vec()).map_err(|e| format!("Invalid UTF-8 bytes: {}", e))
    } else if encoding.eq_ignore_ascii_case("ASCII") {
        // Validate that all bytes are ASCII
        if bytes.iter().all(|&b| b < 128) {
            String::from_utf8(bytes.to_vec()).map_err(|e| format!("Invalid ASCII bytes: {}", e))
        } else {
            Err("Bytes contain non-ASCII values".to_string())
        }
    } else if encoding.eq_ignore_ascii_case("UNICODE")
        || encoding.eq_ignore_ascii_case("UTF16")
        || encoding.eq_ignore_ascii_case("UTF-16")
    {
        // Unicode in .NET typically means UTF-16LE
        if !bytes.len().is_multiple_of(2) {
            return Err("Invalid UTF-16 byte length (must be even)".to_string());
        }

        let mut utf16_chars = Vec::with_capacity(bytes.len() / 2);
        for chunk in bytes.chunks_exact(2) {
            let word = u16::from_le_bytes([chunk[0], chunk[1]]);
            utf16_chars.push(word);
        }

        String::from_utf16(&utf16_chars).map_err(|e| format!("Invalid UTF-16 bytes: {}", e))
    } else if encoding.eq_ignore_ascii_case("UTF32") || encoding.eq_ignore_ascii_case("UTF-32") {
        // UTF-32LE encoding
        if !bytes.len().is_multiple_of(4) {
            return Err("Invalid UTF-32 byte length (must be multiple of 4)".to_string());
        }

        let mut result = String::new();
        for chunk in bytes.chunks_exact(4) {
            let code_point = u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
            match char::from_u32(code_point) {
                Some(ch) => result.push(ch),
                None => return Err(format!("Invalid UTF-32 code point: {}", code_point)),
            }
        }
        Ok(result)
    } else if encoding.eq_ignore_ascii_case("BIGENDIANUNICODE")
        || encoding.eq_ignore_ascii_case("UTF16BE")
        || encoding.eq_ignore_ascii_case("UTF-16BE")
    {
        // UTF-16BE encoding
        if !bytes.len().is_multiple_of(2) {
            return Err("Invalid UTF-16BE byte length (must be even)".to_string());
        }

        let mut utf16_chars = Vec::with_capacity(bytes.len() / 2);
        for chunk in bytes.chunks_exact(2) {
            let word = u16::from_be_bytes([chunk[0], chunk[1]]);
            utf16_chars.push(word);
        }

        String::from_utf16(&utf16_chars).map_err(|e| format!("Invalid UTF-16BE bytes: {}", e))
    } else if encoding.eq_ignore_ascii_case("DEFAULT") {
        // Default encoding is UTF-8
        String::from_utf8(bytes.to_vec()).map_err(|e| format!("Invalid UTF-8 bytes: {}", e))
    } else if encoding.eq_ignore_ascii_case("ISO-8859-1")
        || encoding.eq_ignore_ascii_case("LATIN1")
        || encoding.eq_ignore_ascii_case("LATIN-1")
    {
        // Latin-1 (ISO-8859-1) - each byte maps directly to a Unicode code point
        // This encoding can represent any byte value (0x00-0xFF)
        // Note: Null bytes (0x00) are replaced with Unicode replacement character (U+FFFD)
        // to ensure the result can be safely passed through C string interfaces
        Ok(bytes
            .iter()
            .map(|&b| if b == 0 { '\u{FFFD}' } else { b as char })
            .collect())
    } else {
        Err(format!("Unsupported encoding: {}", encoding))
    }
}

/// Convert bytes to a Rust string with automatic fallback to Latin-1 for binary data
///
/// This function first attempts to decode using the specified encoding. If that fails
/// due to invalid byte sequences (common with binary data like certificates), it
/// automatically falls back to Latin-1 (ISO-8859-1) which can represent any byte value.
///
/// Note: Null bytes (0x00) are replaced with the Unicode replacement character (U+FFFD)
/// to ensure the result can be safely passed through C string interfaces.
pub(crate) fn convert_bytes_to_string_with_fallback(
    bytes: &[u8],
    encoding: &str,
) -> Result<String, String> {
    match convert_bytes_to_string(bytes, encoding) {
        Ok(s) => Ok(s),
        Err(e) => {
            // Check if this is an encoding error that Latin-1 fallback can handle
            if e.contains("Invalid UTF-8")
                || e.contains("Invalid ASCII")
                || e.contains("Invalid UTF-16")
                || e.contains("Invalid UTF-32")
                || e.contains("non-ASCII values")
            {
                // Fall back to Latin-1 which can represent any byte
                // Replace null bytes with replacement character for C string safety
                Ok(bytes
                    .iter()
                    .map(|&b| if b == 0 { '\u{FFFD}' } else { b as char })
                    .collect())
            } else {
                // Other errors (unsupported encoding, wrong byte length) should propagate
                Err(e)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_latin1_encoding_direct() {
        let all_bytes: Vec<u8> = (0..=255).collect();
        let result = convert_bytes_to_string(&all_bytes, "ISO-8859-1");

        assert!(result.is_ok(), "Latin-1 should accept any byte value");
        let s = result.unwrap();

        assert_eq!(s.chars().count(), 256, "Result should have 256 characters");

        for (i, ch) in s.chars().enumerate() {
            if i == 0 {
                assert_eq!(
                    ch, '\u{FFFD}',
                    "Null byte should map to replacement character"
                );
            } else {
                assert_eq!(
                    ch as u32, i as u32,
                    "Byte {} should map to Unicode code point {}",
                    i, i
                );
            }
        }
    }

    #[test]
    fn test_latin1_encoding_variants() {
        let test_bytes: Vec<u8> = vec![0xA1, 0xC0, 0xFF];
        let variants = vec!["ISO-8859-1", "LATIN1", "Latin-1", "latin1", "iso-8859-1"];

        for variant in variants {
            let result = convert_bytes_to_string(&test_bytes, variant);
            assert!(
                result.is_ok(),
                "Latin-1 variant '{}' should be recognized",
                variant
            );
        }
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_utf8_success() {
        let utf8_bytes = "Hello".as_bytes().to_vec();
        let result = convert_bytes_to_string_with_fallback(&utf8_bytes, "UTF8");

        assert!(result.is_ok(), "Valid UTF-8 should succeed");
        assert_eq!(result.unwrap(), "Hello");
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_invalid_utf8() {
        let invalid_utf8: Vec<u8> = vec![0xA1, 0x59, 0xC0, 0xA5, 0xE4, 0x94, 0xFF, 0x80];
        let result = convert_bytes_to_string_with_fallback(&invalid_utf8, "UTF8");

        assert!(
            result.is_ok(),
            "Invalid UTF-8 should fall back to Latin-1 and succeed"
        );
        let s = result.unwrap();

        let round_trip: Vec<u8> = s.chars().map(|c| c as u8).collect();
        assert_eq!(
            round_trip, invalid_utf8,
            "Latin-1 fallback should preserve original bytes"
        );
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_non_ascii() {
        let non_ascii: Vec<u8> = vec![72, 200, 111];
        let result = convert_bytes_to_string_with_fallback(&non_ascii, "ASCII");

        assert!(
            result.is_ok(),
            "Non-ASCII bytes should fall back to Latin-1"
        );
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_structural_errors_fallback() {
        let odd_bytes: Vec<u8> = vec![72, 65, 101];
        let result = convert_bytes_to_string_with_fallback(&odd_bytes, "Unicode");

        assert!(
            result.is_ok(),
            "Odd-length bytes should fall back to Latin-1 for UTF-16"
        );

        let s = result.unwrap();
        let round_trip: Vec<u8> = s.chars().map(|c| c as u8).collect();
        assert_eq!(
            round_trip, odd_bytes,
            "Should preserve original bytes via Latin-1"
        );
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_unsupported_encoding() {
        let bytes: Vec<u8> = vec![72, 101, 108, 108, 111];
        let result = convert_bytes_to_string_with_fallback(&bytes, "INVALID_ENCODING");

        assert!(
            result.is_err(),
            "Unsupported encoding should propagate error"
        );
        assert!(
            result.unwrap_err().contains("Unsupported encoding"),
            "Error should mention unsupported encoding"
        );
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_binary_data_round_trip() {
        let binary_data: Vec<u8> = vec![
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFF, 0xFE, 0x80,
        ];

        let result = convert_bytes_to_string_with_fallback(&binary_data, "UTF8");
        assert!(
            result.is_ok(),
            "Binary data should succeed via Latin-1 fallback"
        );

        let s = result.unwrap();
        let round_trip: Vec<u8> = s.chars().map(|c| c as u8).collect();
        assert_eq!(
            round_trip, binary_data,
            "Binary data should round-trip correctly"
        );
    }

    #[test]
    fn test_convert_bytes_to_string_with_fallback_null_bytes_replaced() {
        let data_with_null: Vec<u8> = vec![0xA1, 0x00, 0xC0];

        let result = convert_bytes_to_string_with_fallback(&data_with_null, "UTF8");
        assert!(result.is_ok(), "Data with null should succeed");

        let s = result.unwrap();
        assert_eq!(s.chars().count(), 3, "Should have 3 characters");
        assert_eq!(
            s.chars().next().unwrap(),
            '\u{00A1}',
            "First char should be Latin-1 0xA1"
        );
        assert_eq!(
            s.chars().nth(1).unwrap(),
            '\u{FFFD}',
            "Null byte should be replacement char"
        );
        assert_eq!(
            s.chars().nth(2).unwrap(),
            '\u{00C0}',
            "Third char should be Latin-1 0xC0"
        );
    }
}
