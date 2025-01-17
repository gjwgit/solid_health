/// Check resource status.
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
import 'package:healthpod/constants/link.dart';
import 'package:healthpod/constants/resource/content_type.dart';
import 'package:healthpod/constants/resource/status.dart';
import 'package:solidpod/solidpod.dart';
import 'package:http/http.dart' as http;

/// Asynchronously checks whether a given resource exists on the server.
///
/// This function makes an HTTP GET request to the specified resource URL to determine if the resource exists.
/// It handles both files and directories (containers) by setting appropriate headers based on the [fileFlag].

Future<ResourceStatus> checkResourceStatus(
  String resUrl, {
  bool fileFlag = true,
}) async {
  final (:accessToken, :dPopToken) = await getTokensForResource(resUrl, 'GET');
  final response = await http.get(
    Uri.parse(resUrl),
    headers: <String, String>{
      'Content-Type': fileFlag
          ? ResourceContentType.any.value
          : ResourceContentType.directory.value,
      'Authorization': 'DPoP $accessToken',
      'Link': fileFlag ? fileTypeLink : dirTypeLink,
      'DPoP': dPopToken,
    },
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    return ResourceStatus.exist;
  } else if (response.statusCode == 404) {
    return ResourceStatus.notExist;
  } else {
    debugPrint('Failed to check resource status.\n'
        'URL: $resUrl\n'
        'ERR: ${response.body}');
    return ResourceStatus.unknown;
  }
}
