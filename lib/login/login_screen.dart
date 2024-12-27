/// Login screen for the health data app.
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
library;


import 'package:flutter/material.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:healthpod/home.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController webIdController = TextEditingController()
    ..text = 'https://pods.solidcommunity.au';

  LoginScreen({super.key}); // Default WebID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/healthpod_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/healthpod_logo.png',
                        width: 200,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'LOGIN WITH YOUR POD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: webIdController,
                        decoration: InputDecoration(
                          labelText: 'Enter your POD URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final webId = webIdController.text;
                          
                          if (webId.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('WebID cannot be empty'),
                              ),
                            );
                            return;
                          }

                          try {
                            await authenticate(
                              Uri.parse(webId),
                              ['openid', 'profile', 'offline_access'],
                              context,
                            );

                            navigator.pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(webId: webId),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Login failed: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          // Navigate to a page to get a POD (optional)
                        },
                        child: const Text(
                          'Don’t have a POD? Get one here',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
