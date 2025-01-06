import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';
import 'package:healthpod/home.dart';

/// Creates a SolidLogin widget with consistent configuration
Widget createSolidLogin(BuildContext context) {
  return const SolidLogin(
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
    child: HealthPodHome(),
  );
}
