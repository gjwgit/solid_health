/// Data visualisation viewer.
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

import 'package:healthpod/features/data/visualisation.dart';

/// HealthDataViewer brings health survey data to life so to speak.
///
/// It fetches JSON survey files from a directory, processes them,
/// and uses a visualisation widget to display the data.

class HealthDataViewer extends StatelessWidget {
  // Path to directory containing survey data files.

  final String directoryPath;

  const HealthDataViewer({
    super.key,
    required this.directoryPath,
  });

  /// Loads and parses survey data from JSON files in directory.

  Future<List<Map<String, dynamic>>> _loadSurveyData() async {
    final directory = Directory(directoryPath);
    final List<Map<String, dynamic>> allData = [];

    // Check if directory exists and process each file.

    if (await directory.exists()) {
      await for (final file in directory.list()) {
        if (file.path.endsWith('.json')) {
          // Read and decode JSON file contents.

          final contents = await File(file.path).readAsString();
          final data = json.decode(contents);
          allData.add(data);
        }
      }
    }

    // Sort data by timestamp for chronological display.

    allData.sort((a, b) => DateTime.parse(a['timestamp'])
        .compareTo(DateTime.parse(b['timestamp'])));

    return allData;
  }

  @override
  Widget build(BuildContext context) {
    // Asynchronously fetch data and update UI based on state.

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadSurveyData(),
      builder: (context, snapshot) {
        // Show a loading spinner while waiting for data.

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors during data loading.

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading data: ${snapshot.error}'),
          );
        }

        // Handle case where no data is available.

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No survey data available'),
          );
        }

        // Render visualisation widget with loaded data.

        return HealthDataVisualisation(surveyData: snapshot.data!);
      },
    );
  }
}
