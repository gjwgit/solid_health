import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';
import 'package:csv/csv.dart';

/// Processes a CSV file and converts it to JSON format
Future<bool> processCsvToJson(
  String filePath,
  String dirPath,
  BuildContext context,
) async {
  try {
    // Read the CSV file
    final file = File(filePath);
    final input = file.openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (fields.isEmpty) {
      throw Exception('CSV file is empty');
    }

    // Extract headers and data
    final headers = List<String>.from(fields[0]);
    final data = <Map<String, dynamic>>[];

    // Convert rows to maps with proper headers
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

    // Convert to JSON
    final jsonData = json.encode(data);

    // Generate output filename
    final inputFileName = path.basename(filePath);
    final baseFileName = inputFileName.replaceAll(RegExp(r'\.csv$'), '');
    final outputFileName = '$baseFileName.json.enc.ttl';

    // Construct the full path for saving
    final savePath = dirPath == 'healthpod/data'
        ? outputFileName
        : '${dirPath.replaceFirst('healthpod/data/', '')}/$outputFileName';

    debugPrint('Saving to path: $savePath');

    // Write the encrypted JSON file to POD
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