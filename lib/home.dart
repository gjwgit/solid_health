/// Home screen for the health data app.
///
// Time-stamp: <Tuesday 2025-01-07 14:12:37 +1100 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';
import 'package:healthpod/features/file/footer.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/utils/fetch_web_id.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/dialogs/show_about.dart';
import 'package:healthpod/utils/handle_logout.dart';
import 'package:healthpod/widgets/icon_grid_page.dart';

class HealthPodHome extends StatefulWidget {
  const HealthPodHome({super.key});

  @override
  HealthPodHomeState createState() => HealthPodHomeState();
}

class HealthPodHomeState extends State<HealthPodHome> {
  String? _webId;
  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();
    _initialiseFooterData();
  }

  Future<void> _initialiseFooterData() async {
    final webId = await fetchWebId();
    final isKeySaved = await fetchKeySavedStatus();

    setState(() {
      _webId = webId;
      _isKeySaved = isKeySaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health - Your Data - You Decide ... '),
        backgroundColor: titleBackgroundColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => handleLogout(context),
          ),
          MarkdownTooltip(
            message: '''
            **About:** Tap here to view information about the Rattle
            project. This includes a list of those who have contributed to the
            latest version of the software, *Version 6.* It also includes the
            extensive list of open-source packages that Rattle is built on and
            their licenses.
            ''',
            child: IconButton(
              onPressed: () {
                showAbout(context);
              },
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: titleBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: IconGridPage(),
          ),
           Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FooterWidget(
                webId: _webId,
                isKeySaved: _isKeySaved,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
