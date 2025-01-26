/// Data editor widget.
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
/// Authors: Ashley Tang.

library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/data/record.dart';

/// Data Editor Page.
///
/// A widget that provides CRUD (Create, Read, Update, Delete) operations for blood pressure records.
/// Records are stored in encrypted format in the user's POD storage under the 'bp' directory.
/// Each record contains timestamp, systolic/diastolic pressure, heart rate, feeling, and notes.

class BPDataEditorPage extends StatefulWidget {
  const BPDataEditorPage({super.key});

  @override
  State<BPDataEditorPage> createState() => _BPDataEditorPageState();
}

class _BPDataEditorPageState extends State<BPDataEditorPage> {
  // List of blood pressure records loaded from POD.

  List<DataRecord> records = [];

  // Index of record currently being edited, null if no record is being edited.

  int? editingIndex;

  // Loading state for async operations.

  bool isLoading = true;

  // Error message if data loading fails.

  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Loads blood pressure records from POD storage.
  ///
  /// Fetches all .enc.ttl files from the bp directory, decrypts them,
  /// and parses them into DataRecord objects. Records are sorted by timestamp
  /// in descending order (newest first).

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final dirUrl = await getDirUrl('healthpod/data/bp');
      final resources = await getResourcesInContainer(dirUrl);

      final List<DataRecord> loadedRecords = [];
      for (final file in resources.files) {
        if (!file.endsWith('.enc.ttl')) continue;

        if (!mounted) break;

        final content = await readPod(
          'healthpod/data/bp/$file',
          context,
          const Text('Loading file'),
        );

        if (content != SolidFunctionCallStatus.fail &&
            content != SolidFunctionCallStatus.notLoggedIn &&
            content != null) {
          try {
            final data = json.decode(content.toString());
            loadedRecords.add(DataRecord.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing file $file: $e');
          }
        }
      }

      setState(() {
        records = loadedRecords
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  /// Saves a blood pressure record to POD storage.
  ///
  /// Creates or updates an encrypted file in the bp directory with the record data.
  /// File name is generated from the record's timestamp.

  Future<void> saveRecord(DataRecord record) async {
    try {
      final filename =
          'blood_pressure_${record.timestamp.toIso8601String().replaceAll(RegExp(r'[:.]+'), '-')}.json.enc.ttl';

      await writePod(
        'bp/$filename',
        json.encode(record.toJson()),
        context,
        const Text('Saving'),
        encrypted: true,
      );

      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        editingIndex = null;
      });

      await loadData();
    } catch (e) {
      if (mounted) {
        // Only use context when the widget is mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  /// Deletes a blood pressure record from POD storage.
  ///
  /// Removes the encrypted file corresponding to the record from the bp directory.

  Future<void> deleteRecord(DataRecord record) async {
    try {
      final filename =
          'blood_pressure_${record.timestamp.toIso8601String().replaceAll(RegExp(r'[:.]+'), '-')}.json.enc.ttl';

      await deleteFile('bp/$filename');

      if (!mounted) return;

      await loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  /// Creates a new blank blood pressure record.
  ///
  /// Inserts a new record at the beginning of the list and enters edit mode.

  void addNewRecord() {
    setState(() {
      records.insert(
          0,
          DataRecord(
            timestamp: DateTime.now(),
            systolic: 0,
            diastolic: 0,
            heartRate: 0,
            feeling: '',
            notes: '',
          ));
      editingIndex = 0;
    });
  }

  /// Builds a read-only display row for a blood pressure record.
  ///
  /// Displays formatted timestamp, systolic/diastolic pressure, heart rate,
  /// feeling, and notes as static text. Includes edit and delete action buttons.

  DataRow _buildDisplayRow(DataRecord record, int index) {
    return DataRow(
      cells: [
        DataCell(
            Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp))),
        DataCell(Text(record.systolic.toString())),
        DataCell(Text(record.diastolic.toString())),
        DataCell(Text(record.heartRate.toString())),
        DataCell(Text(record.feeling)),
        DataCell(Text(record.notes)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => editingIndex = index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteRecord(record),
            ),
          ],
        )),
      ],
    );
  }

  /// Builds an editable row for a blood pressure record.
  ///
  /// Creates text fields for timestamp, systolic/diastolic pressure, and heart rate,
  /// a dropdown for feeling selection, and a notes field. Each field has its own
  /// controller and updates the record on change.

  DataRow _buildEditingRow(DataRecord record, int index) {
    final timestampController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp),
    );
    final systolicController =
        TextEditingController(text: record.systolic.toString());
    final diastolicController =
        TextEditingController(text: record.diastolic.toString());
    final heartRateController =
        TextEditingController(text: record.heartRate.toString());
    final notesController = TextEditingController(text: record.notes);

    return DataRow(
      cells: [
        DataCell(TextField(
          controller: timestampController,
          onChanged: (value) {
            try {
              records[index] = record.copyWith(
                timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').parse(value),
              );
            } catch (_) {}
          },
        )),
        DataCell(TextField(
          controller: systolicController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            records[index] = record.copyWith(
              systolic: int.tryParse(value) ?? 0,
            );
          },
        )),
        DataCell(TextField(
          controller: diastolicController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            records[index] = record.copyWith(
              diastolic: int.tryParse(value) ?? 0,
            );
          },
        )),
        DataCell(TextField(
          controller: heartRateController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            records[index] = record.copyWith(
              heartRate: int.tryParse(value) ?? 0,
            );
          },
        )),
        DataCell(DropdownButton<String>(
          value: record.feeling.isEmpty ? null : record.feeling,
          items: ['Excellent', 'Good', 'Fair', 'Poor']
              .map((feeling) => DropdownMenuItem(
                    value: feeling,
                    child: Text(feeling),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              records[index] = record.copyWith(feeling: value ?? '');
            });
          },
        )),
        DataCell(TextField(
          controller: notesController,
          onChanged: (value) {
            records[index] = record.copyWith(notes: value);
          },
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => saveRecord(records[index]),
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => setState(() => editingIndex = null),
            ),
          ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Records'),
        backgroundColor: titleBackgroundColor,
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: addNewRecord,
              tooltip: 'Add New Reading',
            ),
        ],
      ),
      body: (() {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (error != null) {
          return Center(child: Text('Error: $error'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Systolic')),
                DataColumn(label: Text('Diastolic')),
                DataColumn(label: Text('Heart Rate')),
                DataColumn(label: Text('Feeling')),
                DataColumn(label: Text('Notes')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List<DataRow>.generate(
                records.length,
                (index) {
                  final record = records[index];
                  if (editingIndex == index) {
                    return _buildEditingRow(record, index);
                  }
                  return _buildDisplayRow(record, index);
                },
              ),
            ),
          ),
        );
      })(),
    );
  }
}
