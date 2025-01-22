/// Process CSV file import.
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

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

/// Processes a CSV file and converts it to JSON format.

Future<bool> processCsvToJson(
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

    // Extract headers and data.

    final headers = List<String>.from(fields[0]);
    final data = <Map<String, dynamic>>[];

    // Convert rows to maps with proper headers.

    for (var i = 1; i < fields.length; i++) {
      final row = <String, dynamic>{};
      for (var j = 0; j < headers.length; j++) {
        if (j < fields[i].length) {
          final value = fields[i][j];
          // Try to parse numbers if possible
          if (value is num) {
            row[headers[j]] = value;
          } else if (value is String && double.tryParse(value) != null) {
            row[headers[j]] = double.parse(value);
          } else {
            row[headers[j]] = value;
          }
        }
      }
      data.add(row);
    }

    // Convert to JSON.

    final jsonData = json.encode(data);

    // Generate output filename.

    final inputFileName = path.basename(filePath);
    final baseFileName = inputFileName.replaceAll(RegExp(r'\.csv$'), '');
    final outputFileName = '$baseFileName.json.enc.ttl';

    // Construct the full path for saving.

    final savePath = dirPath == 'healthpod/data'
        ? outputFileName
        : '${dirPath.replaceFirst('healthpod/data/', '')}/$outputFileName';

    debugPrint('Saving to path: $savePath');

    // Write the encrypted JSON file to POD.

    final result = await writePod(
      savePath,
      jsonData,
      context,
      const Text('Converting and saving CSV as JSON'),
      encrypted: true,
    );

    return result == SolidFunctionCallStatus.success;
  } catch (e) {
    debugPrint('Import error: $e');
    return false;
  }
}
