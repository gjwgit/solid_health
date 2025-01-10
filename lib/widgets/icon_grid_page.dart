/// Icon grid page.
//
// Time-stamp: <Saturday 2025-01-11 08:05:49 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/dialogs/show_coming_soon.dart';
import 'package:healthpod/features/file/service.dart';

class IconGridPage extends StatelessWidget {
  final List<IconData> icons = [
    Icons.home,
    Icons.folder,
    Icons.lightbulb,
    Icons.map,
    Icons.work,
    Icons.alarm,
  ];

  IconGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What would you like to do today ...'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10.0, // Space between icons horizontally
          runSpacing: 10.0, // Space between icons vertically
          children: icons.map((icon) {
            final iconContainer = Container(
              width: 80.0, // Fixed width for each icon container
              height: 80.0, // Fixed height for each icon container
              decoration: BoxDecoration(
                color: {Icons.lightbulb, Icons.folder}.contains(icon)
                    ? Colors.blue
                    : Colors.grey,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 50.0,
              ),
            );

            final gestureDetector = GestureDetector(
              onTap: () {
                if (icon == Icons.folder) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FileService()),
                  );
                } else if (icon == Icons.lightbulb) {
                  alert(context,
                      'Using the alert dialog to avoid a lint message for now.');
                } else {
                  showComingSoon(context); // For other icons.
                }
              },
              child: iconContainer,
            );

            // Add tooltips for the folder icons.

            return switch (icon) {
              Icons.folder => MarkdownTooltip(
                  message: '''

                **File Management:** Tap here to access file management features.
                This allows you to:

                - Upload large files to your POD storage

                - Download files from your POD

                - Delete files from your POD

                ''',
                  child: gestureDetector,
                ),
              Icons.lightbulb => MarkdownTooltip(
                  message: 'Placeholder',
                  child: gestureDetector,
                ),
              _ => gestureDetector,
            };
          }).toList(),
        ),
      ),
    );
  }
}
