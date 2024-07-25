/// A simple key value table for the home screen.
///
// Time-stamp: <Thursday 2024-07-25 20:22:00 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams

// TODO 20240526 gjw EITHER REPAIR ALL CONTEXT ISSUES OR EXPLAIN WHY NOT?

// REMOVE ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:path/path.dart' as path;

import 'package:healthpod/main.dart';
import 'package:healthpod/features/key_value_editor.dart.~1~';
import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/utils/rdf.dart';

class HealthPodHome extends StatefulWidget {
  /// Constructor for the home screen.

  const HealthPodHome({super.key});

  @override
  HealthPodHomeState createState() => HealthPodHomeState();
}

class HealthPodHomeState extends State<HealthPodHome> {
  // Track if the data is loading.

  bool _isLoading = false;

  // TODO 20240710 gjw CONSIDER REPLACING ALL THIS WITH A BUTTON
  //
  // Always be presented with a button and we press the button to load the data
  // from the Pod.

  Future<void> _loadData(BuildContext context) async {
    // TODO 20240708 gjw PLEASE DESCRIBE WHAT THIS FUNCTION DOES

    const fileName = 'key-value.ttl';

    try {
      setState(() {
        // Show the loading indicator.

        _isLoading = true;
      });

      // TODO dc: PLEASE EXPLAIN THIS SIMULATION, WHY IS IT NECESSARY?
      //
      // Simulate a network call.

      // await Future.delayed(const Duration(seconds: 2));

      // Navigate or perform additional actions after loading.

      final dataDirPath = await getDataDirPath();
      final filePath = path.join(dataDirPath, fileName);

      // The build context and the app widget are passed through to the
      // readPod() on the chance that it is required when the user CANCEL's the
      // secret key dialog.
      //
      // TODO 20240710 gjw CANCEL OF SECRET KEY SHOULD GO BACK TO PARENT?
      //
      // The parent is the HealthPodApp() - should that be implemented as the
      // default? Ideally the call is readPod(filePath) or eventually pod.read(filePath).

      if (context.mounted) {
        // Need to ensure the context is mounted to avoid async gaps.

        final webId = await getWebId();

        final fileContent = await readPod(filePath, context, const HealthPod());

        final pairs = fileContent == null
            ? null
            : await parseTTLStr(fileContent.toString());

        // Convert each tuple to a map.

        final keyValuePairs = pairs?.map((pair) {
          return {'key': pair.key, 'value': pair.value};
        }).toList();

        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KeyValueEditor(
                title: 'Key Value Pair Editor',
                fileName: fileName,
                keyValuePairs: keyValuePairs,
                webId: webId,
                child: const HealthPodHome(),
              ),
            ),
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (context.mounted) {
        setState(() {
          // Hide the loading indicator.

          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 20),
        Expanded(child: Container()),
      ],
    );
  }

  // TODO 20240708 gjw EXPLAIN WHY THIS INIT IS REQUIRED
  //
  // WORK WITH KEVIN TO RE-ENGINEER FOR THE NEW HealthPodApp BUTTON PAGE

  @override
  void initState() {
    super.initState();

    // Automatically press the KEYPODS button when the screen loads. WHAT
    // KEYPODS BUTTON?

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Key Value Pairs... '),
        backgroundColor: titleBackgroundColor,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: titleBackgroundColor,
      body: Stack(
        children: <Widget>[
          _buildMainContent(),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
