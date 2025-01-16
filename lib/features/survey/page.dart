/// Health survey page.
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

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/features/survey/form.dart';
import 'package:healthpod/features/survey/question.dart';

/// A page for collecting health survey data.

class HealthSurveyPage extends StatelessWidget {
  final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: "What's your systolic blood pressure?",
      type: HealthDataType.number,
      unit: "mm Hg",
      min: 70,
      max: 200,
    ),
    HealthSurveyQuestion(
      question: "What's your diastolic measurement today?",
      type: HealthDataType.number,
      unit: "mm Hg",
      min: 40,
      max: 220,
    ),
    HealthSurveyQuestion(
      question: "What's your heart rate?",
      type: HealthDataType.number,
      unit: "bpm",
      min: 40,
      max: 220,
    ),
    HealthSurveyQuestion(
      question: "How are you feeling today?",
      type: HealthDataType.categorical,
      options: ["Excellent", "Good", "Fair", "Poor"],
    ),
    HealthSurveyQuestion(
      question: "Any additional notes about your health today?",
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];

  HealthSurveyPage({super.key});

  /// Saves the survey responses to a local file.

  Future<void> _saveResponsesLocally(
      BuildContext context, Map<String, dynamic> responses) async {
    try {
      // Add timestamp to responses.

      final responseData = {
        'timestamp': DateTime.now().toIso8601String(),
        'responses': responses,
      };

      // Convert to JSON string with proper formatting.

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(responseData);

      // Generate default filename.

      final timestamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]+'), '-');
      final defaultFileName = 'blood_pressure_$timestamp.json';

      // Show file picker for save location.

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Survey Response',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) {
        // User cancelled the save.

        if (context.mounted) {
          Navigator.of(context).pop(); // Return to previous screen
        }
        return;
      }

      // Ensure .json extension.

      if (!outputFile.toLowerCase().endsWith('.json')) {
        outputFile = '$outputFile.json';
      }

      // Save the file.

      final file = File(outputFile);
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Survey saved to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving survey: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Saves the survey responses to a POD.

  Future<void> _saveResponsesToPod(
      BuildContext context, Map<String, dynamic> responses) async {
    try {
      final responseData = {
        'timestamp': DateTime.now().toIso8601String(),
        'responses': responses,
      };

      final jsonString = jsonEncode(responseData);

      final timestamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]+'), '-');

      // Just use the filename without additional path.

      final fileName = 'blood_pressure_$timestamp.enc.ttl';

      if (!context.mounted) return;

      // Show saving indicator.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving to POD...'),
          duration: Duration(seconds: 1),
        ),
      );

      debugPrint('Attempting to save survey to POD: $fileName');
      final result = await writePod(
        fileName,
        jsonString,
        context,
        const Text('Saving survey'),
        encrypted: true,
      );

      debugPrint('POD save result: $result');

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to save survey responses (Status: $result)');
      }

      if (!context.mounted) return;

      // Wait briefly to ensure write completes.

      await Future.delayed(const Duration(seconds: 1));

      if (!context.mounted) return;

      // Verify the file exists by attempting to read it.

      final dataDir = await getDataDirPath();
      final filePath = '$dataDir/$fileName';

      debugPrint('Verifying file at path: $filePath');

      if (!context.mounted) return;

      final verifyResult = await readPod(
        filePath,
        context,
        const Text('Verifying save'),
      );

      if (verifyResult == SolidFunctionCallStatus.fail ||
          verifyResult == SolidFunctionCallStatus.notLoggedIn) {
        throw Exception('Failed to verify saved file');
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey saved to POD successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Return to previous screen
    } catch (e) {
      debugPrint('Error saving to POD: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to POD: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Handles the submission of the survey.

  Future<void> _handleSubmit(
      BuildContext context, Map<String, dynamic> responses) async {
    // First show submission success.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Survey submitted successfully!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Wait a moment for the success message to be visible.

    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;

    // Check login and security key status.

    final isKeySaved = await fetchKeySavedStatus();

    if (!context.mounted) return;

    // Then ask about saving.

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Survey Results'),
          content: const Text('Would you like to save your survey results?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text('No, Return Home'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close current dialog
                // Show save location options.

                if (!context.mounted) return;
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Choose Save Location'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Where would you like to save your results?'),
                          if (!isKeySaved) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Note: Saving to POD requires setting up your security key first.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            _saveResponsesLocally(context, responses);
                            Navigator.of(context).pop(); // Return home
                          },
                          child: const Text('Save Locally'),
                        ),
                        TextButton(
                          onPressed: isKeySaved
                              ? () {
                                  Navigator.of(context).pop(); // Close dialog
                                  _saveResponsesToPod(context, responses);
                                  Navigator.of(context).pop(); // Return home
                                }
                              : null, // Disable if key not set
                          child: Text(
                            'Save to POD',
                            style: TextStyle(
                              color: isKeySaved ? null : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Yes, Save Results'),
            ),
          ],
        );
      },
    );
  }

  /// Builds the health survey page.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Survey'),
        backgroundColor: titleBackgroundColor,
      ),
      body: HealthSurveyForm(
        questions: questions,
        onSubmit: (responses) => _handleSubmit(context, responses),
      ),
    );
  }
}
