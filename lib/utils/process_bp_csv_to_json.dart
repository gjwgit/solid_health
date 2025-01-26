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

import 'package:healthpod/utils/show_alert.dart';

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
    final file = File(filePath);
    final input = file.openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (fields.isEmpty) {
      throw Exception('CSV file is empty');
    }

    final headers = List<String>.from(fields[0]);
    
    // Validate required columns
    final requiredColumns = ['timestamp', 'systolic', 'diastolic', 'heart_rate'];
    final missingColumns = requiredColumns.where(
      (col) => !headers.map((h) => h.trim().toLowerCase()).contains(col.toLowerCase())
    ).toList();
    
    if (missingColumns.isNotEmpty) {
      if (!context.mounted) return false;
      const requiredColumnMessage = '''

        Your CSV file must contain these required columns:

        - timestamp (e.g. 2025-01-21T23:05:42)
        - systolic (e.g. 120)
        - diastolic (e.g. 80)
        - heart_rate (e.g. 72)

        Optional columns:

        - feeling (e.g. Good)
        - notes (e.g. After exercise)

        ''';

        showAlert(context, requiredColumnMessage);

      return false;
    }

    bool allSuccess = true;
    for (var i = 1; i < fields.length; i++) {
      try {
        final row = fields[i];
        if (row.length != headers.length) continue;

        // Create standardized response structure
        final Map<String, dynamic> responses = {
          "What's your systolic blood pressure?": 0,
          "What's your diastolic measurement?": 0,
          "What's your heart rate?": 0,
          "How are you feeling?": "",
          "Any additional notes about your health?": "",
        };
        
        String timestamp = "";

        // Map CSV columns to response structure
        for (var j = 0; j < headers.length; j++) {
          final header = headers[j].trim().toLowerCase();
          final value = row[j];

          switch (header) {
            case 'timestamp':
              timestamp = value.toString();
            case 'systolic':
              responses["What's your systolic blood pressure?"] = int.parse(value.toString());
            case 'diastolic':
              responses["What's your diastolic measurement?"] = int.parse(value.toString());
            case 'heart_rate':
              responses["What's your heart rate?"] = int.parse(value.toString());
            case 'feeling':
              responses["How are you feeling?"] = value.toString();
            case 'notes':
              responses["Any additional notes about your health?"] = value.toString();
          }
        }

        final jsonData = {
          'timestamp': timestamp,
          'responses': responses,
        };

       timestamp =
            timestamp.replaceAll(RegExp(r'[:.]+'), '-');
        final outputFileName = 'blood_pressure_$timestamp.json.enc.ttl';

        // Construct the full path for saving.

        final savePath =
            '${dirPath.replaceFirst('healthpod/data/', '')}/$outputFileName';

        if (!context.mounted) return false;

        final result = await writePod(
          savePath,
          json.encode(jsonData),
          context,
          Text('Converting row $i'),
          encrypted: true,
        );

        if (result != SolidFunctionCallStatus.success) {
          allSuccess = false;
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