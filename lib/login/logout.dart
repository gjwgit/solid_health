/// Logout screen for the health data app.
//
// Time-stamp: <Thursday 2024-12-19 13:39:36 +1100 Graham Williams>
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


import 'package:flutter/material.dart';
import 'package:healthpod/login/login_screen.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> logout(BuildContext context, String logoutUrl) async {
  try {
    if (await canLaunchUrl(Uri.parse(logoutUrl))) {
      await launchUrl(
        Uri.parse(logoutUrl),
        mode: LaunchMode.inAppWebView,
      );
    } else {
      throw 'Could not launch $logoutUrl';
    }

    await Future.delayed(const Duration(seconds: 4));

    if (currPlatform.isWeb()) {
      // Replace this with your specific web logout logic
      authManager.userLogout(logoutUrl);
    }

    // Navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );

    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logout failed: $e')),
    );
    return false;
  }
}
