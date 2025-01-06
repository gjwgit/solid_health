import 'package:flutter/material.dart';
import 'package:healthpod/home.dart';
import 'package:healthpod/utils/create_solid_login.dart';
import 'package:solidpod/solidpod.dart' show logoutPopup, getWebId;

/// Handles logout and navigates to the login screen
Future<void> handleLogout(BuildContext context) async {
  await logoutPopup(context, const HealthPodHome());

  // Check login status using getWebId
  final webId = await getWebId();
  if (webId == null && context.mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => createSolidLogin(context)),
    );
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout failed. Please try again.')),
    );
  }
}
