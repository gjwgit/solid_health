/// A key-value editor.
///
// Time-stamp: <Thursday 2024-07-25 20:21:43 +1000 Graham Williams>
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
// You should have received a copy of the GNU General Public License along withk
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Kevin Wang, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/dialogs/show_my_about.dart.~1~';
import 'package:healthpod/main.dart';
import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/utils/rdf.dart';

class KeyValueEditor extends StatefulWidget {
  const KeyValueEditor({
    required this.title,
    required this.fileName,
    required this.child,
    super.key,
    this.keyValuePairs,
    this.webId,
  });
  final String title;
  final String fileName;
  final Widget child;
  final List<Map<String, dynamic>>? keyValuePairs;
  final String? webId;

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  // Loading indicator for data submission.

  bool _isLoading = false;
  Map<int, Map<String, dynamic>> dataMap = {};
  // Track if data has been modified.

  bool _isDataModified = false;

  final keyStr = 'key';
  final valStr = 'value';
  final regExp = RegExp(r'\s+');

  // Map to hold the TextEditingController for each key and value.
  Map<int, TextEditingController> keyControllers = {};
  Map<int, TextEditingController> valueControllers = {};
  Map<int, Map<String, dynamic>>? initialDataMap;
  @override
  void initState() {
    super.initState();
    if (widget.keyValuePairs != null) {
      var i = 0;
      for (final pair in widget.keyValuePairs!) {
        final keyController =
            TextEditingController(text: pair[keyStr] as String);
        final valueController =
            TextEditingController(text: pair[valStr] as String);
        keyControllers[i] = keyController;
        valueControllers[i] = valueController;
        dataMap[i++] = {keyStr: pair[keyStr], valStr: pair[valStr]};
      }
      // Store the initial dataMap value.
      initialDataMap = Map<int, Map<String, dynamic>>.from(dataMap);
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed.
    keyControllers.forEach((key, controller) {
      controller.dispose();
    });
    valueControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      final newIndex = dataMap.length;
      dataMap[newIndex] = {keyStr: '', valStr: ''};
      keyControllers[newIndex] = TextEditingController();
      valueControllers[newIndex] = TextEditingController();
    });
  }

  void _updateRowKey(int index, String newKey) {
    if (dataMap[index]![keyStr] != newKey) {
      setState(() {
        dataMap[index]![keyStr] = newKey;
        _isDataModified = true;
      });
    }
  }

  void _updateRowValue(int index, String newValue) {
    if (dataMap[index]![valStr] != newValue) {
      setState(() {
        dataMap[index]![valStr] = newValue;
        _isDataModified = true;
      });
    }
  }

  void _deleteRow(int index) {
    setState(() {
      dataMap.remove(index);
      keyControllers[index]?.dispose();
      valueControllers[index]?.dispose();
      keyControllers.remove(index);
      valueControllers.remove(index);

      // Check if the initial dataMap is null or if the initial dataMap and
      // the current dataMap are not equal.
      _isDataModified =
          initialDataMap == null || !_areMapsEqual(initialDataMap!, dataMap);
    });
  }

  /// Compares two maps of type `Map<String, String>` for equality.

  bool _areMapsEqual(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length) return false;

    for (var key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }

    return true;
  }

  Widget buildDataTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Key')),
        DataColumn(label: Text('Value')),
        DataColumn(label: Text('Actions')),
      ],
      rows: dataMap.keys.map((index) {
        return DataRow(
          cells: [
            DataCell(
              TextField(
                controller: keyControllers[index],
                onChanged: (newKey) => _updateRowKey(index, newKey),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            DataCell(
              TextField(
                controller: valueControllers[index],
                onChanged: (newValue) => _updateRowValue(index, newValue),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            DataCell(_actionCell(index)),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _alert(String msg) async => alert(context, msg);

  // Function to convert Map<int, Map<String, dynamic>> to List<KeyValuePair>
  Future<List<({String key, dynamic value})>?>
      _convertDataMapToListOfPairs() async {
    final rowInd = dataMap.keys.toList()..sort();
    final keys = <String>{};
    final pairs = <({String key, dynamic value})>[];
    for (final i in rowInd) {
      final k = (dataMap[i]![keyStr] as String).trim();
      if (k.isEmpty) {
        await _alert('Invalide key: "$k"');
        return null;
      }
      if (keys.contains(k)) {
        await _alert('Duplicate key: "$k"');
        return null;
      }
      if (regExp.hasMatch(k)) {
        await _alert('Invalided key: Whitespace found in key "$k"');
        return null;
      }
      keys.add(k);
      final v = dataMap[i]![valStr];
      pairs.add((key: k, value: v));
    }
    return pairs;
  }

  // Save data to PODs
  Future<bool> _saveToPod(BuildContext context) async {
    setState(() {
      // Begin loading.

      _isLoading = true;
    });

    final pairs = await _convertDataMapToListOfPairs();

    if (pairs == null) {
      return false;
    }

    try {
      // Generate TTL str with dataMap.

      final ttlStr = await genTTLStr(pairs);

      // Write to POD.

      if (context.mounted) {
        await writePod(widget.fileName, ttlStr, context, widget.child);
      }

      await _alert('Successfully saved ${dataMap.length} key-value pairs'
          ' to "${widget.fileName}" in PODs');
      return true;
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
    const smallGapH = SizedBox(width: 10);
    const medGapV = SizedBox(height: 20);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: titleBackgroundColor,
        // Instruct flutter to not put a leading widget automatically
        // see https://api.flutter.dev/flutter/material/AppBar/leading.html
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_card,
              color: iconColor,
            ),
            tooltip: 'Add a new row to the table of key-value pairs.',
            onPressed: _addNewRow,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save the key-value pairs to your Solid Pod.',
            onPressed: _isDataModified
                ? () async {
                    setState(() {
                      // Start loading.

                      _isLoading = true;
                    });
                    final saved = await _saveToPod(context);
                    if (saved) {
                      setState(() {
                        // Reset modification flag.

                        _isDataModified = false;
                      });
                    }
                    setState(() {
                      // Stop loading.

                      _isLoading = false;
                    });
                  }
                : null,
            style: activeButtonStyle(
              context,
            ), // Disable button if data is not modified
            // child: const Text('Save',
            //     style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: iconColor,
            ),
            tooltip: 'Configure your Solid Pod sharing.',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GrantPermissionUi(
                  backgroundColor: titleBackgroundColor,
                  child: KeyValueEditor(
                    title: widget.title,
                    fileName: widget.fileName,
                    keyValuePairs: widget.keyValuePairs,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.logout_sharp,
              color: iconColor,
            ),
            tooltip: 'Logout of your Solid Pod.',
            onPressed: () async => logoutPopup(context, const HealthPod()),
          ),
          IconButton(
            icon: const Icon(
              Icons.info,
              color: iconColor,
            ),
            tooltip: 'Popup the app About dialog.',
            onPressed: () async => showMyAbout(context, webId: widget.webId),
          ),
          smallGapH,
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  medGapV,
                  Text('Saving in Progress', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : Center(
              child: Container(
                // 3/4 of screen width.

                width: MediaQuery.of(context).size.width * 0.75,
                // Light grey thicker border.

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2.0),
                  // Rounded corners.

                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: buildDataTable(),
                  ),
                ),
              ),
            ),
    );
  }

  ButtonStyle activeButtonStyle(BuildContext context) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.disabled)) {
            // Text color when disabled.

            return Colors.grey.shade400;
          }

          // Text color when enabled.

          return iconColor;
        },
      ),
    );
  }

  Widget _actionCell(int index) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: iconColor),
          onPressed: () => _deleteRow(index),
        ),
      ],
    );
  }
}
