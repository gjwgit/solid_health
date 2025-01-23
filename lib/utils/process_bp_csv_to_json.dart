/// Process blood pressure CSV to JSON.
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

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';

/// Process BP CSV file import, creating individual JSON files for each row.
///
/// Each row is saved as a separate JSON file with timestamp and responses.
/// Files are saved in the specified directory with timestamps in filenames.

Future<bool> processBpCsvToJson(
  String filePath,
  String dirPath,
  BuildContext context,
) async {
  try {
    // Read the CSV file.

    final file = File(filePath);
    final input = file.openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (fields.isEmpty) {
      throw Exception('CSV file is empty');
    }

    // Extract headers and validate required columns.

    final headers = List<String>.from(fields[0]);

    // Verify timestamp column exists.

    if (!headers.contains('timestamp')) {
      throw Exception('CSV must contain a timestamp column');
    }

    // Process each row and create individual JSON files.

    bool allSuccess = true;
    for (var i = 1; i < fields.length; i++) {
      try {
        final row = fields[i];
        if (row.length != headers.length) continue; // Skip malformed rows.

        // Create the JSON structure for this row.

        final Map<String, dynamic> jsonData = {
          'timestamp': '',
          'responses': <String, dynamic>{},
        };

        // Process each column.

        for (var j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = row[j];

          if (header == 'timestamp') {
            jsonData['timestamp'] = value;
          } else {
            // Try to parse numbers if possible.

            if (value is num) {
              jsonData['responses'][header] = value;
            } else if (value is String && double.tryParse(value) != null) {
              jsonData['responses'][header] = double.parse(value);
            } else {
              jsonData['responses'][header] = value;
            }
          }
        }

        // Generate filename using current timestamp.

        final timestamp =
            DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]+'), '-');
        final outputFileName = 'blood_pressure_$timestamp.json.enc.ttl';

        // Construct the full path for saving.

        final savePath =
            '${dirPath.replaceFirst('healthpod/data/', '')}/$outputFileName';

        debugPrint('Saving row $i to path: $savePath');

        if (!context.mounted) {
          debugPrint('Widget is no longer mounted, skipping upload.');
          return false;
        }

        // Write the encrypted JSON file to POD.

        final result = await writePod(
          savePath,
          json.encode(jsonData),
          context,
          Text('Converting row $i'),
          encrypted: true,
        );

        if (result != SolidFunctionCallStatus.success) {
          allSuccess = false;
          debugPrint('Failed to save row $i');
        }
      } catch (rowError) {
        debugPrint('Error processing row $i: $rowError');
        allSuccess = false;
      }
    }

    return allSuccess;
  } catch (e) {
    debugPrint('Import error: $e');
    return false;
  }
}
