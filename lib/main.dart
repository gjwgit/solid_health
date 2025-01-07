/// Your health data in your POD
//
// Time-stamp: <Tuesday 2025-01-07 14:10:07 +1100 Graham Williams>
//
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
/// Authors: Graham Williams, Ashley Tang
/// Authors: Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

import 'package:healthpod/utils/create_solid_login.dart';
import 'package:healthpod/utils/is_desktop.dart';
import 'package:healthpod/utils/session_utils.dart'; 



void main() async {
  if (isDesktop(PlatformWrapper())) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      alwaysOnTop: true,
      title: 'HealthPod - Private Solid Pod for Storing Key-Value Pairs',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  runApp(const HealthPod());
}

class HealthPod extends StatelessWidget {
  const HealthPod({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solid Health Pod',
      home: SelectionArea(
        // Wrap the whole app inside a SelectionArea to ensure we get selectable
        // text, for text that can be selected, as a default.
        child: createSolidLogin(context),
      ),
    );
  }
}
