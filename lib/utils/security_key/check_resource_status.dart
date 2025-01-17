import 'package:flutter/material.dart';
import 'package:healthpod/constants/link.dart';
import 'package:healthpod/constants/resource_content_type.dart';
import 'package:healthpod/constants/resource_status.dart';
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