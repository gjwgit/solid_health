import 'package:flutter/material.dart';
import 'package:healthpod/home.dart';
import 'package:solidpod/solidpod.dart' show SolidLogin, getWebId, logoutPopup;

/// Handles logout and navigates to the login screen
Future<void> handleLogout(BuildContext context) async {
  await logoutPopup(context, const HealthPodHome()); 

  // Check login status using getWebId
  final webId = await getWebId();
  if (webId == null && context.mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SolidLogin(
          required: false,
          title: 'HEALTH POD',
          image: AssetImage('assets/images/healthpod_image.png'),
          logo: AssetImage('assets/images/healthpod_logo.png'),
          link: 'https://github.com/anusii/healthpod/blob/main/README.md',
          child: HealthPodHome(), 
        ),
      ),
    );
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout failed. Please try again.')),
    );
  }
}

/// Checks if the user is logged in and navigates appropriately
Future<void> checkAndRedirectLogin(BuildContext context) async {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final webId = await getWebId();
      if (webId == null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SolidLogin(
              required: false,
              title: 'HEALTH POD',
              image: AssetImage('assets/images/healthpod_image.png'),
              logo: AssetImage('assets/images/healthpod_logo.png'),
              link: 'https://github.com/anusii/healthpod/blob/main/README.md',
              child: HealthPodHome(), 
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in checkAndRedirectLogin: $e');
    }
  });
}
