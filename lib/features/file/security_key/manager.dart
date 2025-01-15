/// Security key manager.
///
// Time-stamp: <Friday 2024-06-28 13:35:54 +1000 Graham Williams>
///
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart'
    show
        AppInfo,
        KeyManager,
        SolidFunctionCallStatus,
        changeKeyPopup,
        getEncKeyPath,
        getWebId,
        readPod;

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/file/security_key/view_keys.dart';

/// Security Key Manager.
/// 
/// This class represents a dialog interface for managing local security keys.
/// It provides features like showing the current securtiy key, changing the key,
/// and forgetting the key locally altogether. 

/// Main widget for managing security keys.

class SecurityKeyManager extends StatefulWidget {
  const SecurityKeyManager({super.key});

  @override
  SecurityKeyManagerState createState() => SecurityKeyManagerState();
}

/// State class that powers `SecurityKeyManager` widget.
/// It encapsulates all logic and UI rendering for the dialog.

class SecurityKeyManagerState extends State<SecurityKeyManager>
    with SingleTickerProviderStateMixin {
  
  // A boolean flag to indicate when an operation is in progress.

  bool _isLoading = false;

  /// Retrieves and displays private security key data when the user requests it.

  Future<void> _showPrivateData(String title, BuildContext context) async {

    // The user inititaes an action. Start by indicating that a process is ongoing.

    setState(() {
      _isLoading = true;
    });

    try {
      // Find where the encryption key is stored.

      final filePath = await getEncKeyPath();
      if (!context.mounted) return;

      // Retrieve the security key from the specified file.

      final fileContent = await readPod(
        filePath,
        context,
        const SecurityKeyManager(),
      );
      if (!context.mounted) return;

      // If the file content is valid and the user is logged in, navigate to view the key details.

      if (![SolidFunctionCallStatus.notLoggedIn, SolidFunctionCallStatus.fail]
          .contains(fileContent)) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewKeys(
              keyInfo: fileContent!,
              title: title,
            ),
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('Exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Retries app information for the title.

  Future<({String name, String? webId})> _getInfo() async =>
      (name: await AppInfo.name, webId: await getWebId());

  /// Builds the content of the dialog.
  /// 
  /// The user is presented with options to view, change or forget the security key.

  Widget _buildDialogContent(BuildContext context, String title) {
    const smallGapV = SizedBox(height: 20.0);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Introduction to the dialog's purpose.

            Container(
              color: titleBackgroundColor,
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: const Row(
                children: [
                  Text(
                    'Local Security Key Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Interactive options for the user.

            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await _showPrivateData(title, context);
                            },
                            child: const Text('Show Security Key'),
                          ),
                        ),
                        smallGapV,
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              changeKeyPopup(context, widget);
                            },
                            child: const Text('Change Key'),
                          ),
                        ),
                        smallGapV,
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              late String msg;
                              try {
                                await KeyManager.forgetSecurityKey();
                                msg = 'Successfully forgot local security key.';
                              } on Exception catch (e) {
                                msg = 'Failed to forget local security key: $e';
                              }
                              if (context.mounted) {
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: const Text('Notice'),
                                    content: Text(msg),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: const Text('Forget Security Key'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the dialog widget.
  /// 
  /// It uses a FutureBuilder to fetch app information and display the dialog content.

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: FutureBuilder<({String name, String? webId})>(
        future: _getInfo(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final appName = snapshot.data?.name;
            final title =
                'Security Key Management - ${appName!.isNotEmpty ? appName[0].toUpperCase() + appName.substring(1) : ""}';
            return _buildDialogContent(context, title);
          } else {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24.0),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
