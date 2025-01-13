/// Footer widget to display server information, login status, and security key status.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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

/// Footer widget to display server information, login status, and security key status.

class Footer extends StatelessWidget {
  final String? webId;
  final bool isKeySaved;

  const Footer({
    super.key,
    required this.webId,
    required this.isKeySaved,
  });

  Widget _buildTextRow(String label, String value, {Color? valueColor}) {
    return Text(
      '$label: $value',
      style: TextStyle(fontSize: 14, color: valueColor ?? Colors.black),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNarrowLayout(String serverUri, String loginStatus,
      Color loginStatusColor, String securityKeyStatus) {
    return Container(
      color: Colors.grey[200],
      height: 90.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextRow('Server', serverUri),
            const SizedBox(height: 2),
            _buildTextRow('Login Status', loginStatus,
                valueColor: loginStatusColor),
            const SizedBox(height: 2),
            _buildTextRow('Security Key', securityKeyStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildMediumLayout(String serverUri, String loginStatus,
      Color loginStatusColor, String securityKeyStatus) {
    return Container(
      color: Colors.grey[200],
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextRow('Server', serverUri),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextRow('Login Status', loginStatus,
                      valueColor: loginStatusColor),
                  const SizedBox(width: 16),
                  _buildTextRow('Security Key', securityKeyStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(String serverUri, String loginStatus,
      Color loginStatusColor, String securityKeyStatus) {
    return Container(
      color: Colors.grey[200],
      height: 50.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTextRow('Server', serverUri),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextRow('Login Status', loginStatus,
                  valueColor: loginStatusColor),
              const SizedBox(width: 16),
              _buildTextRow('Security Key', securityKeyStatus),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverUri = webId?.split('/profile')[0] ?? 'Not connected';
    final loginStatus = webId == null ? "Not Logged In" : "Logged In";
    final loginStatusColor = webId == null ? Colors.red : Colors.green;
    final securityKeyStatus = isKeySaved ? "Saved" : "Not Saved";

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return _buildNarrowLayout(
              serverUri, loginStatus, loginStatusColor, securityKeyStatus);
        } else if (constraints.maxWidth < 600) {
          return _buildMediumLayout(
              serverUri, loginStatus, loginStatusColor, securityKeyStatus);
        } else {
          return _buildWideLayout(
              serverUri, loginStatus, loginStatusColor, securityKeyStatus);
        }
      },
    );
  }
}
