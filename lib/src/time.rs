//! Unix time conversion functions

/// Convert a date/time to Unix timestamp
///
/// # Arguments
/// * `year` - Year (e.g., 2000)
/// * `month` - Month (1-12)
/// * `day` - Day (1-31)
/// * `hour` - Hour (0-23)
/// * `minute` - Minute (0-59)
/// * `second` - Second (0-59)
/// * `milliseconds` - If true, return milliseconds; if false, return seconds
///
/// # Returns
/// Unix timestamp as i64 (seconds or milliseconds since 1970-01-01 00:00:00 UTC)
///
/// # Safety
/// This function performs date calculations and has no unsafe operations.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn to_unix_time(
    year: i32,
    month: u32,
    day: u32,
    hour: u32,
    minute: u32,
    second: u32,
    milliseconds: bool,
) -> i64 {
    // Calculate days since Unix epoch (1970-01-01)
    let mut days = 0i64;

    // Add days for complete years
    for y in 1970..year {
        days += if is_leap_year(y) { 366 } else { 365 };
    }

    // Add days for complete months in current year
    let days_in_month = [
        31,
        if is_leap_year(year) { 29 } else { 28 },
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ];
    for m in 1..month {
        days += days_in_month[(m - 1) as usize] as i64;
    }

    // Add remaining days
    days += (day - 1) as i64;

    // Convert to seconds
    let total_seconds =
        days * 86400 + (hour as i64) * 3600 + (minute as i64) * 60 + (second as i64);

    if milliseconds {
        total_seconds * 1000
    } else {
        total_seconds
    }
}

fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

/// Convert Unix timestamp to date/time components
///
/// # Arguments
/// * `timestamp` - Unix timestamp (seconds or milliseconds since 1970-01-01 00:00:00 UTC)
/// * `milliseconds` - If true, timestamp is in milliseconds; if false, in seconds
///
/// # Returns
/// Tuple of (year, month, day, hour, minute, second)
pub fn from_unix_time(timestamp: i64, milliseconds: bool) -> (i32, u32, u32, u32, u32, u32) {
    let total_seconds = if milliseconds {
        timestamp / 1000
    } else {
        timestamp
    };

    let mut remaining_seconds = total_seconds;

    // Extract time components
    let second = (remaining_seconds % 60) as u32;
    remaining_seconds /= 60;
    let minute = (remaining_seconds % 60) as u32;
    remaining_seconds /= 60;
    let hour = (remaining_seconds % 24) as u32;
    let mut days = remaining_seconds / 24;

    // Calculate year
    let mut year = 1970;
    loop {
        let days_in_year = if is_leap_year(year) { 366 } else { 365 };
        if days < days_in_year {
            break;
        }
        days -= days_in_year;
        year += 1;
    }

    // Calculate month and day
    let days_in_month = [
        31,
        if is_leap_year(year) { 29 } else { 28 },
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ];
    let mut month = 1;
    for &dim in &days_in_month {
        if days < dim {
            break;
        }
        days -= dim;
        month += 1;
    }
    let day = days as u32 + 1;

    (year, month, day, hour, minute, second)
}

/// Convert Unix timestamp to date/time components (FFI wrapper)
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that all out parameters are valid pointers.
///
/// # Arguments
/// * `timestamp` - Unix timestamp (seconds or milliseconds since 1970-01-01 00:00:00 UTC)
/// * `milliseconds` - If true, timestamp is in milliseconds; if false, in seconds
/// * `out_year` - Pointer to store year
/// * `out_month` - Pointer to store month (1-12)
/// * `out_day` - Pointer to store day (1-31)
/// * `out_hour` - Pointer to store hour (0-23)
/// * `out_minute` - Pointer to store minute (0-59)
/// * `out_second` - Pointer to store second (0-59)
///
/// # Returns
/// true on success, false if any out parameter is null
#[unsafe(no_mangle)]
pub unsafe extern "C" fn from_unix_time_ffi(
    timestamp: i64,
    milliseconds: bool,
    out_year: *mut i32,
    out_month: *mut u32,
    out_day: *mut u32,
    out_hour: *mut u32,
    out_minute: *mut u32,
    out_second: *mut u32,
) -> bool {
    if out_year.is_null()
        || out_month.is_null()
        || out_day.is_null()
        || out_hour.is_null()
        || out_minute.is_null()
        || out_second.is_null()
    {
        return false;
    }

    let (year, month, day, hour, minute, second) = from_unix_time(timestamp, milliseconds);

    // SAFETY: All pointers have been validated as non-null
    unsafe {
        *out_year = year;
        *out_month = month;
        *out_day = day;
        *out_hour = hour;
        *out_minute = minute;
        *out_second = second;
    }

    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_to_unix_time_epoch() {
        // Test: Unix epoch (1970-01-01 00:00:00) should return 0 seconds
        let result = unsafe { to_unix_time(1970, 1, 1, 0, 0, 0, false) };
        assert_eq!(result, 0, "Unix epoch should return 0 seconds");
    }

    #[test]
    fn test_to_unix_time_epoch_milliseconds() {
        // Test: Unix epoch (1970-01-01 00:00:00) should return 0 milliseconds
        let result = unsafe { to_unix_time(1970, 1, 1, 0, 0, 0, true) };
        assert_eq!(result, 0, "Unix epoch should return 0 milliseconds");
    }

    #[test]
    fn test_to_unix_time_year_2000() {
        // Test: 2000-01-01 00:00:00 = 946684800 seconds
        let result = unsafe { to_unix_time(2000, 1, 1, 0, 0, 0, false) };
        assert_eq!(
            result, 946684800,
            "2000-01-01 00:00:00 should return 946684800 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_year_2000_milliseconds() {
        // Test: 2000-01-01 00:00:00 = 946684800000 milliseconds
        let result = unsafe { to_unix_time(2000, 1, 1, 0, 0, 0, true) };
        assert_eq!(
            result, 946684800000,
            "2000-01-01 00:00:00 should return 946684800000 milliseconds"
        );
    }

    #[test]
    fn test_to_unix_time_with_time_components() {
        // Test: 2000-01-01 12:30:45 = 946684800 + 12*3600 + 30*60 + 45 = 946729845 seconds
        let result = unsafe { to_unix_time(2000, 1, 1, 12, 30, 45, false) };
        assert_eq!(
            result, 946729845,
            "2000-01-01 12:30:45 should return 946729845 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_with_time_components_milliseconds() {
        // Test: 2000-01-01 12:30:45 in milliseconds
        let result = unsafe { to_unix_time(2000, 1, 1, 12, 30, 45, true) };
        assert_eq!(
            result, 946729845000,
            "2000-01-01 12:30:45 should return 946729845000 milliseconds"
        );
    }

    #[test]
    fn test_to_unix_time_leap_year() {
        // Test: 2000-02-29 (leap year) 00:00:00 = 946684800 + 59*86400 = 951782400 seconds
        let result = unsafe { to_unix_time(2000, 2, 29, 0, 0, 0, false) };
        assert_eq!(
            result, 951782400,
            "2000-02-29 00:00:00 should return 951782400 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_end_of_month() {
        // Test: 2000-01-31 23:59:59 = 946684800 + 30*86400 + 23*3600 + 59*60 + 59 = 949363199 seconds
        let result = unsafe { to_unix_time(2000, 1, 31, 23, 59, 59, false) };
        assert_eq!(
            result, 949363199,
            "2000-01-31 23:59:59 should return 949363199 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_recent_date() {
        // Test: 2024-01-01 00:00:00 = 1704067200 seconds
        let result = unsafe { to_unix_time(2024, 1, 1, 0, 0, 0, false) };
        assert_eq!(
            result, 1704067200,
            "2024-01-01 00:00:00 should return 1704067200 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_recent_date_milliseconds() {
        // Test: 2024-01-01 00:00:00 in milliseconds
        let result = unsafe { to_unix_time(2024, 1, 1, 0, 0, 0, true) };
        assert_eq!(
            result, 1704067200000,
            "2024-01-01 00:00:00 should return 1704067200000 milliseconds"
        );
    }

    #[test]
    fn test_to_unix_time_different_months() {
        // Test: 2020-06-15 10:30:00 = 1592217000 seconds
        let result = unsafe { to_unix_time(2020, 6, 15, 10, 30, 0, false) };
        assert_eq!(
            result, 1592217000,
            "2020-06-15 10:30:00 should return 1592217000 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_end_of_year() {
        // Test: 2020-12-31 23:59:59 = 1609459199 seconds
        let result = unsafe { to_unix_time(2020, 12, 31, 23, 59, 59, false) };
        assert_eq!(
            result, 1609459199,
            "2020-12-31 23:59:59 should return 1609459199 seconds"
        );
    }

    #[test]
    fn test_to_unix_time_milliseconds_flag_difference() {
        // Test: Verify milliseconds flag produces value 1000x larger
        let seconds = unsafe { to_unix_time(2020, 6, 15, 10, 30, 0, false) };
        let milliseconds = unsafe { to_unix_time(2020, 6, 15, 10, 30, 0, true) };
        assert_eq!(
            milliseconds,
            seconds * 1000,
            "Milliseconds should be 1000x seconds"
        );
    }

    // ===== Tests for from_unix_time =====

    #[test]
    fn test_from_unix_time_epoch_seconds() {
        // Test: Unix timestamp 0 = 1970-01-01 00:00:00
        let (year, month, day, hour, minute, second) = from_unix_time(0, false);
        assert_eq!(year, 1970, "Epoch year should be 1970");
        assert_eq!(month, 1, "Epoch month should be 1");
        assert_eq!(day, 1, "Epoch day should be 1");
        assert_eq!(hour, 0, "Epoch hour should be 0");
        assert_eq!(minute, 0, "Epoch minute should be 0");
        assert_eq!(second, 0, "Epoch second should be 0");
    }

    #[test]
    fn test_from_unix_time_epoch_milliseconds() {
        // Test: Unix timestamp 0 milliseconds = 1970-01-01 00:00:00
        let (year, month, day, hour, minute, second) = from_unix_time(0, true);
        assert_eq!(year, 1970, "Epoch year should be 1970");
        assert_eq!(month, 1, "Epoch month should be 1");
        assert_eq!(day, 1, "Epoch day should be 1");
        assert_eq!(hour, 0, "Epoch hour should be 0");
        assert_eq!(minute, 0, "Epoch minute should be 0");
        assert_eq!(second, 0, "Epoch second should be 0");
    }

    #[test]
    fn test_from_unix_time_year_2000_seconds() {
        // Test: Unix timestamp 946684800 = 2000-01-01 00:00:00
        let (year, month, day, hour, minute, second) = from_unix_time(946684800, false);
        assert_eq!(year, 2000, "Year should be 2000");
        assert_eq!(month, 1, "Month should be 1");
        assert_eq!(day, 1, "Day should be 1");
        assert_eq!(hour, 0, "Hour should be 0");
        assert_eq!(minute, 0, "Minute should be 0");
        assert_eq!(second, 0, "Second should be 0");
    }

    #[test]
    fn test_from_unix_time_year_2000_milliseconds() {
        // Test: Unix timestamp 946684800000 milliseconds = 2000-01-01 00:00:00
        let (year, month, day, hour, minute, second) = from_unix_time(946684800000, true);
        assert_eq!(year, 2000, "Year should be 2000");
        assert_eq!(month, 1, "Month should be 1");
        assert_eq!(day, 1, "Day should be 1");
        assert_eq!(hour, 0, "Hour should be 0");
        assert_eq!(minute, 0, "Minute should be 0");
        assert_eq!(second, 0, "Second should be 0");
    }

    #[test]
    fn test_from_unix_time_milliseconds_flag_difference() {
        // Test: Same timestamp with different milliseconds flag
        let (y1, m1, d1, h1, min1, s1) = from_unix_time(946684800, false);
        let (y2, m2, d2, h2, min2, s2) = from_unix_time(946684800000, true);

        assert_eq!(y1, y2, "Years should match");
        assert_eq!(m1, m2, "Months should match");
        assert_eq!(d1, d2, "Days should match");
        assert_eq!(h1, h2, "Hours should match");
        assert_eq!(min1, min2, "Minutes should match");
        assert_eq!(s1, s2, "Seconds should match");
    }

    #[test]
    fn test_from_unix_time_round_trip_epoch() {
        // Test: Round-trip conversion for epoch
        let timestamp = unsafe { to_unix_time(1970, 1, 1, 0, 0, 0, false) };
        let (year, month, day, hour, minute, second) = from_unix_time(timestamp, false);

        assert_eq!(year, 1970, "Round-trip year should match");
        assert_eq!(month, 1, "Round-trip month should match");
        assert_eq!(day, 1, "Round-trip day should match");
        assert_eq!(hour, 0, "Round-trip hour should match");
        assert_eq!(minute, 0, "Round-trip minute should match");
        assert_eq!(second, 0, "Round-trip second should match");
    }

    #[test]
    fn test_from_unix_time_round_trip_year_2000() {
        // Test: Round-trip conversion for year 2000
        let timestamp = unsafe { to_unix_time(2000, 1, 1, 0, 0, 0, false) };
        let (year, month, day, hour, minute, second) = from_unix_time(timestamp, false);

        assert_eq!(year, 2000, "Round-trip year should match");
        assert_eq!(month, 1, "Round-trip month should match");
        assert_eq!(day, 1, "Round-trip day should match");
        assert_eq!(hour, 0, "Round-trip hour should match");
        assert_eq!(minute, 0, "Round-trip minute should match");
        assert_eq!(second, 0, "Round-trip second should match");
    }

    #[test]
    fn test_from_unix_time_round_trip_with_time() {
        // Test: Round-trip conversion with time components
        let timestamp = unsafe { to_unix_time(2024, 6, 15, 14, 30, 45, false) };
        let (year, month, day, hour, minute, second) = from_unix_time(timestamp, false);

        assert_eq!(year, 2024, "Round-trip year should match");
        assert_eq!(month, 6, "Round-trip month should match");
        assert_eq!(day, 15, "Round-trip day should match");
        assert_eq!(hour, 14, "Round-trip hour should match");
        assert_eq!(minute, 30, "Round-trip minute should match");
        assert_eq!(second, 45, "Round-trip second should match");
    }

    #[test]
    fn test_from_unix_time_round_trip_milliseconds() {
        // Test: Round-trip conversion with milliseconds
        let timestamp = unsafe { to_unix_time(2024, 6, 15, 14, 30, 45, true) };
        let (year, month, day, hour, minute, second) = from_unix_time(timestamp, true);

        assert_eq!(year, 2024, "Round-trip year should match");
        assert_eq!(month, 6, "Round-trip month should match");
        assert_eq!(day, 15, "Round-trip day should match");
        assert_eq!(hour, 14, "Round-trip hour should match");
        assert_eq!(minute, 30, "Round-trip minute should match");
        assert_eq!(second, 45, "Round-trip second should match");
    }

    // ===== Tests for from_unix_time_ffi =====

    #[test]
    fn test_from_unix_time_ffi_epoch() {
        // Test: FFI wrapper for epoch timestamp
        let mut year = 0i32;
        let mut month = 0u32;
        let mut day = 0u32;
        let mut hour = 0u32;
        let mut minute = 0u32;
        let mut second = 0u32;

        let result = unsafe {
            from_unix_time_ffi(
                0,
                false,
                &mut year,
                &mut month,
                &mut day,
                &mut hour,
                &mut minute,
                &mut second,
            )
        };

        assert!(result, "FFI call should succeed");
        assert_eq!(year, 1970, "Epoch year should be 1970");
        assert_eq!(month, 1, "Epoch month should be 1");
        assert_eq!(day, 1, "Epoch day should be 1");
        assert_eq!(hour, 0, "Epoch hour should be 0");
        assert_eq!(minute, 0, "Epoch minute should be 0");
        assert_eq!(second, 0, "Epoch second should be 0");
    }

    #[test]
    fn test_from_unix_time_ffi_year_2000() {
        // Test: FFI wrapper for year 2000
        let mut year = 0i32;
        let mut month = 0u32;
        let mut day = 0u32;
        let mut hour = 0u32;
        let mut minute = 0u32;
        let mut second = 0u32;

        let result = unsafe {
            from_unix_time_ffi(
                946684800,
                false,
                &mut year,
                &mut month,
                &mut day,
                &mut hour,
                &mut minute,
                &mut second,
            )
        };

        assert!(result, "FFI call should succeed");
        assert_eq!(year, 2000, "Year should be 2000");
        assert_eq!(month, 1, "Month should be 1");
        assert_eq!(day, 1, "Day should be 1");
    }

    #[test]
    fn test_from_unix_time_ffi_null_year() {
        // Test: FFI wrapper rejects null year pointer
        let mut month = 0u32;
        let mut day = 0u32;
        let mut hour = 0u32;
        let mut minute = 0u32;
        let mut second = 0u32;

        let result = unsafe {
            from_unix_time_ffi(
                0,
                false,
                std::ptr::null_mut(),
                &mut month,
                &mut day,
                &mut hour,
                &mut minute,
                &mut second,
            )
        };

        assert!(!result, "FFI call should fail with null year pointer");
    }

    #[test]
    fn test_from_unix_time_ffi_null_month() {
        // Test: FFI wrapper rejects null month pointer
        let mut year = 0i32;
        let mut day = 0u32;
        let mut hour = 0u32;
        let mut minute = 0u32;
        let mut second = 0u32;

        let result = unsafe {
            from_unix_time_ffi(
                0,
                false,
                &mut year,
                std::ptr::null_mut(),
                &mut day,
                &mut hour,
                &mut minute,
                &mut second,
            )
        };

        assert!(!result, "FFI call should fail with null month pointer");
    }

    #[test]
    fn test_from_unix_time_ffi_milliseconds() {
        // Test: FFI wrapper with milliseconds flag
        let mut year = 0i32;
        let mut month = 0u32;
        let mut day = 0u32;
        let mut hour = 0u32;
        let mut minute = 0u32;
        let mut second = 0u32;

        let result = unsafe {
            from_unix_time_ffi(
                946684800000,
                true,
                &mut year,
                &mut month,
                &mut day,
                &mut hour,
                &mut minute,
                &mut second,
            )
        };

        assert!(result, "FFI call should succeed");
        assert_eq!(year, 2000, "Year should be 2000");
        assert_eq!(month, 1, "Month should be 1");
        assert_eq!(day, 1, "Day should be 1");
    }
}
