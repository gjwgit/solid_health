/// A template app to begin a Solid Pod project.
//
// Time-stamp: <Thursday 2024-07-25 19:44:49 +1000 Graham Williams>
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:healthpod/home.dart';
import 'package:healthpod/utils/is_desktop.dart';

void main() async {
  // This is the main entry point for the app. The [async] is required because
  // we asynchronously [await] the window manager below. Often, `main()` will
  // simply include just [runApp].

  if (isDesktop(PlatformWrapper())) {
    // Suport [windowManager] options for the desktop. We do this here before
    // running the app. If there is no [windowManager] options we probably don't
    // need this whole section.

    // Enusre things are set up properly since we haven't yet initialised the
    // app with [runApp].

    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      // We can set various desktop window options here.

      // Setting [alwaysOnTop] here will ensure the app starts on top of other
      // apps on the desktop so that it is visible (otherwise, Ubuuntu with
      // GNOME it is often lost below other windows on startup which can be a
      // little disconcerting). We later turn it off as we don't want to force
      // it always on top.

      alwaysOnTop: true,

      // The [title] is used for the window manager's window title.

      title: 'HealthPod - Private Solid Pod for Storing Key-Value Pairs',
    );

    // Once the window manager is ready we recofigure it a little.

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  // Ready to run the app.

  runApp(const HealthPod());
}

// The main widget could be in a separate file, but handy having it in main and
// the file is not too large. The widget essentially orchestrates the building
// of other widgets. Generically we set up to build a `Home()` widget containing
// the App. For SolidPod we wrap the `Home()` widget within the `SolidLogin()`
// widget so we start with a login screen, though this is optional.

class HealthPod extends StatelessWidget {
  const HealthPod({super.key});

  // This StatelessWidget is the root of our application.

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Solid Key Pod',
      home: SelectionArea(
        // Wrap the whole app inside a SelectionArea to ensure we get selectable
        // text, for text that can be selected, as a default.

        child: SolidLogin(
          // Wrap the actual home widget within a [SolidLogin].

          // If the app has functionality that does not require access to Pod
          // data then [required] can be `false`. If the user connects to their
          // Pod then their session information will be saved to save having to
          // log in everytime. The login token and the security key are (optionally)
          // cached so that the login information is not required every time.
          //
          // In this demo app we allow the CONTINUE button so as to demonstrate
          // the use of [SolidLoginPopup] during the app session. If we want to
          // save the data to the Pod or view data from the Pod, then if the
          // user did not log in during startup we can call [SolidLoginPopup] to
          // establish the connection at that time.

          required: false,

          title: 'HEALTH POD',
          image: AssetImage('assets/images/healthpod_image.png'),
          logo: AssetImage('assets/images/healthpod_logo.png'),
          link: 'https://github.com/anusii/healthpod/blob/main/README.md',
          infoButtonStyle: InfoButtonStyle(
            tooltip: 'Visit the HealthPod documentation.',
          ),
          loginButtonStyle: LoginButtonStyle(
            background: Colors.lightGreenAccent,
          ),
          child: HealthPodHome(),
        ),
      ),
    );
  }
}
