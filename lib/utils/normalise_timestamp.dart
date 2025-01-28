/// Normalise timestamp.
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

/// Normalises a timestamp string to ensure it contains the 'T' separator.
///
/// Accepts timestamps in either format:
/// - With 'T': "2025-01-21T23:05:42"
/// - Without 'T': "2025-01-21 23:05:42"
///
/// Always returns timestamp with 'T' separator for internal storage.

String normaliseTimestamp(String timestamp) {
  // If timestamp already has 'T', return as is.

  if (timestamp.contains('T')) {
    return timestamp;
  }

  // Replace space with 'T' between date and time.
  // This regex matches a space between date and time components.

  return timestamp.replaceFirst(RegExp(r' (?=\d{2}:\d{2}:\d{2})'), 'T');
}
