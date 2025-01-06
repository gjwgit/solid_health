/// Your health data in your POD
//
// Time-stamp: <Thursday 2024-12-19 13:33:52 +1100 Graham Williams>
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

library;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:healthpod/home.dart';
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
    checkAndRedirectLogin(context); // Use the utility function.
    return const MaterialApp(
      title: 'Solid Health Pod',
      home: SelectionArea(
        child: HealthPodHome(),
      ),
    );
  }
}
