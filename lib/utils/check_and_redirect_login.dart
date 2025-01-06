import 'package:flutter/material.dart';
import 'package:healthpod/home.dart';
import 'package:solidpod/solidpod.dart' show SolidLogin, getWebId;
import 'package:healthpod/utils/create_solid_login.dart';

/// Checks if the user is logged in and navigates appropriately
Future<void> checkAndRedirectLogin(BuildContext context) async {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final webId = await getWebId();
      if (webId == null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => createSolidLogin(context)),
        );
      }
    } catch (e) {
      debugPrint('Error in checkAndRedirectLogin: $e');
    }
  });
}