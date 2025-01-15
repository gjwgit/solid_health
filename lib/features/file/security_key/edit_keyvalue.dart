/// A widget to edit key/value pairs and save them in a POD.
///
// Time-stamp: <Friday 2024-06-28 13:35:54 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
/// Authors: Dawei Chen, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:editable/editable.dart';

import 'package:solidpod/solidpod.dart'
    show SolidFunctionCallStatus, loginIfRequired, writePod;

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/utils/rdf.dart';

/// A widget to edit and manage key-value pairs, and save them to Solid PODs.

class KeyValueEdit extends StatefulWidget {
  const KeyValueEdit(
      {required this.title,
      required this.fileName,
      required this.child,
      this.encrypted = true,
      this.keyValuePairs,
      super.key});

  // Title of the page.

  final String title;

  // File name to be saved in PODs.

  final String fileName; 

  // The widget to navigate to after saving.
  
  final Widget child;

  // Whether the data should be encrypted.
  
  final bool encrypted;

  // Initial key-value pairs to populate the table.
  
  final List<({String key, dynamic value})>?
      keyValuePairs; // initial key value pairs

  @override
  State<KeyValueEdit> createState() => _KeyValueEditState();
}

class _KeyValueEditState extends State<KeyValueEdit> {
  // Create a Key for EditableState.
  
  final _editableKey = GlobalKey<EditableState>();

  // Regular expression to validate keys (e.g. no spaces allowed).
  
  final regExp = RegExp(r'\s+');
  static const rowKey = 'row'; // key of row index in editedRows
  static const keyStr = 'key';
  static const valStr = 'value';

  // Rows of data to display in the editable table.
  
  final List<dynamic> rows = [];

  // Definitions of table columns.

  final List<dynamic> cols = [
    {'title': 'Key', 'key': keyStr},
    {'title': 'Value', 'key': valStr},
  ];

  // A map to track the edited data.

  final dataMap = <int, ({String key, dynamic value})>{};

  bool _isLoading = false; // Loading indicator for data submission

  @override
  void initState() {
    super.initState();

    // A column is a {'title': TITLE, 'key': KEY}
    // A row is a {KEY: VALUE}

    // Initialise the rows.

    if (widget.keyValuePairs != null) {
      for (final (:key, :value) in widget.keyValuePairs!) {
        rows.add({keyStr: key, valStr: value});
      }
    }

    // Save initial data.

    for (var i = 0; i < rows.length; i++) {
      dataMap[i] = (key: rows[i][keyStr], value: rows[i][valStr]);
    }
  }

  // Add a new row using the global key assigined to the Editable widget
  // to access its current state.

  void _addNewRow() {
    setState(() {
      _editableKey.currentState?.createRow();
    });
  }

  void _saveEditedRows() {
    final editedRows = _editableKey.currentState?.editedRows as List;
    if (editedRows.isEmpty) {
      return;
    }
    for (final r in editedRows) {
      final rowInd = r[rowKey] as int;
      dataMap[rowInd] = (key: r[keyStr] as String, value: r[valStr]);
      rows[rowInd] = {keyStr: r[keyStr], valStr: r[valStr]};
    }
  }

  // Show an alert with the provided message.

  Future<void> _alert(String msg) async => alert(context, msg);

  // Retrieve and validate the key-value pairs for saving.

  Future<List<({String key, dynamic value})>?> _getKeyValuePairs() async {
    final rowInd = dataMap.keys.toList()..sort();
    final keys = <String>{};
    final pairs = <({String key, dynamic value})>[];
    for (final i in rowInd) {
      final k = dataMap[i]!.key.trim();
      if (k.isEmpty) {
        await _alert('Invalide key: "$k"');
        return null;
      }
      if (keys.contains(k)) {
        await _alert('Invalide key: Duplicate key "$k"');
        return null;
      }
      if (regExp.hasMatch(k)) {
        await _alert('Invalided key: Whitespace found in key "$k"');
        return null;
      }
      keys.add(k);
      final v = dataMap[i]!.value;
      pairs.add((key: k, value: v));
    }
    return pairs;
  }

  // Save data to PODs.

  Future<bool> _saveToPod(BuildContext context) async {
    _saveEditedRows();

    final pairs = await _getKeyValuePairs();
    if (dataMap.isEmpty) {
      await _alert('No data to submit');
      return false;
    }

    setState(() {
      // Begin loading.

      _isLoading = true;
    });

    try {
      // Write to POD.

      if (context.mounted) {
        final loggedIn = await loginIfRequired(context);
        // Generate TTL str with dataMap.

        if (loggedIn) {
          final ttlStr = await genTTLStr(pairs!);
          if (context.mounted) {
            final result = await writePod(
                widget.fileName, ttlStr, context, widget.child,
                encrypted: widget.encrypted);

            if (result == SolidFunctionCallStatus.success) {
              await _alert(
                  'Successfully saved ${dataMap.length} key-value pairs'
                  ' to "${widget.fileName}" in PODs');
              return true;
            } else {
              await _alert('Something went wrong. Please try again!');
              return false;
            }
          }
        } else {
          await _alert('Please login to write data to your POD');
          return false;
        }
      }
    } on Exception catch (e) {
      debugPrint('Exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          // End loading.

          _isLoading = false;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: titleBackgroundColor,
          leadingWidth: 100,
          actions: [
            Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Button to add a new row.

                  TextButton.icon(
                    onPressed: _addNewRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),

                  // Button to save the data to PODs.
                  
                  ElevatedButton(
                      onPressed: () async {
                        final saved = await _saveToPod(context);
                        if (saved) {
                          if (!context.mounted) return;
                          await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => widget.child));
                        }
                      },
                      child: const Text('Submit',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ])),
          ],
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator
              : Editable(
                  key: _editableKey,
                  columns: cols,
                  rows: rows,
                  onRowSaved: print,
                  onSubmitted: print,
                  borderColor: Colors.blueGrey,
                  tdStyle: const TextStyle(fontWeight: FontWeight.bold),
                  trHeight: 20,
                  thStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  thAlignment: TextAlign.center,
                  thVertAlignment: CrossAxisAlignment.end,
                  thPaddingBottom: 3,
                  tdAlignment: TextAlign.left,
                  tdEditableMaxLines: 100, // don't limit and allow data to wrap
                  tdPaddingTop: 5,
                  tdPaddingBottom: 5,
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.zero),
                ),
        ));
  }
}
