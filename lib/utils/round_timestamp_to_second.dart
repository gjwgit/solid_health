/// Round timestamp to nearest second.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

/// Rounds a timestamp string to the nearest second by removing subsecond precision.
///
/// Takes an ISO 8601 formatted [timestamp] string and returns it truncated to seconds.
/// If parsing fails, returns the original [timestamp] string unchanged.

String roundTimestampToSecond(String timestamp) {
  try {
    final DateTime dt = DateTime.parse(timestamp);
    return dt.toIso8601String().split('.')[0];
  } catch (e) {
    return timestamp;
  }
}
