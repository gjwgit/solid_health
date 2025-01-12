/// A widget to demonstrate the upload, download, and delete large files.
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
/// Authors: Dawei Chen

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/dialogs/alert.dart';


class FileService extends StatefulWidget {
  const FileService({super.key});

  @override
  State<FileService> createState() => _FileServiceState();
}

class _FileServiceState extends State<FileService> {
  // File state.

  String? uploadFile;
  String? downloadFile;
  String? remoteFileName = 'remoteFileName';
  String? remoteFileUrl;

  // Operation states.

  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool deleteInProgress = false;
  bool uploadDone = false;
  bool downloadDone = false;
  bool deleteDone = false;

  // UI Constants.

  final smallGapH = const SizedBox(width: 10);
  final smallGapV = const SizedBox(height: 10);
  final largeGapV = const SizedBox(height: 50);

  // File type detection.

  final textFileExtensions = ['.txt', '.md', '.json', '.xml', '.csv', '.html', 
                            '.css', '.js', '.dart', '.yaml', '.yml'];

  bool isTextFile(String filePath) {
    return textFileExtensions.contains(path.extension(filePath).toLowerCase());
  }

  Future<void> handleUpload() async {
    if (uploadFile == null) return;

    try {
      setState(() {
        uploadInProgress = true;
        uploadDone = false;
      });

      final file = File(uploadFile!);
      String fileContent;

      // Read file content.

      if (isTextFile(uploadFile!)) {
        fileContent = await file.readAsString();
      } else {
        final bytes = await file.readAsBytes();
        fileContent = base64Encode(bytes);
      }

      // Use original filename but remove special characters
      // Add .enc.ttl suffix for encrypted files.

      remoteFileName = '${path.basename(uploadFile!)
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'\.enc\.ttl$'), '')}.enc.ttl';

      if (context.mounted) {
        // Upload with encryption.
      
        final result = await writePod(
          remoteFileName!,
          fileContent,
          context,
          const Text('Upload'),
          encrypted: true,
        );

        setState(() {
          uploadDone = result == SolidFunctionCallStatus.success;
        });

        if (result != SolidFunctionCallStatus.success) {
          if (context.mounted) {
            alert(context, 'Upload failed - please check your connection and permissions.');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        alert(context, 'Upload error: ${e.toString()}');
      }
      debugPrint('Upload error: $e');
    } finally {
      setState(() {
        uploadInProgress = false;
      });
    }
  }

  Future<void> handleDownload() async {
    if (downloadFile == null || remoteFileName == null) return;

    try {
      setState(() {
        downloadInProgress = true;
        downloadDone = false;
      });

      final dataDir = await getDataDirPath();
      // Use .enc.ttl suffix for encrypted files.

      final filePath = '$dataDir/$remoteFileName';

      if (context.mounted) {
        final fileContent = await readPod(
          filePath,
          context,
          const Text('Downloading'),
        );

        if (fileContent == SolidFunctionCallStatus.fail || 
            fileContent == SolidFunctionCallStatus.notLoggedIn) {
          throw Exception('Download failed - please check your connection and permissions');
        }

        // Extract original filename without .enc.ttl suffix for saving.

        final saveFileName = downloadFile!.replaceAll(RegExp(r'\.enc\.ttl$'), '');
        final file = File(saveFileName);
        
        try {
          if (isTextFile(remoteFileName!.replaceAll(RegExp(r'\.enc\.ttl$'), ''))) {
            await file.writeAsString(fileContent.toString());
          } else {
            try {
              final bytes = base64Decode(fileContent.toString());
              await file.writeAsBytes(bytes);
            } catch (e) {
              await file.writeAsString(fileContent.toString());
            }
          }
          setState(() {
            downloadDone = true;
          });
        } catch (e) {
          throw Exception('Failed to save file: ${e.toString()}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        alert(context, e.toString().replaceAll('Exception: ', ''));
      }
      debugPrint('Download error: $e');
    } finally {
      setState(() {
        downloadInProgress = false;
      });
    }
  }

  Future<void> handleDelete() async {
    try {
      setState(() {
        deleteInProgress = true;
        deleteDone = false;
      });

      if (remoteFileName == null) return;
      
      final dataDir = await getDataDirPath();
      final basePath = '$dataDir/$remoteFileName';
      
      if (context.mounted) {
        bool mainFileDeleted = false;
        
        try {
          // Delete main encrypted file first.
          
          await deleteFile(basePath);
          mainFileDeleted = true;
          debugPrint('Successfully deleted main file: $basePath');
        } catch (e) {
          debugPrint('Error deleting main file: $e');
          // Only rethrow if it's not a "not found" error.

          if (!e.toString().contains('404') && 
              !e.toString().contains('NotFoundHttpError')) {
            rethrow;
          }
        }

        // Only try to delete ACL file if main file was deleted
        // Note: We don't try to delete .meta files as they're managed by the server.

        if (mainFileDeleted) {
          try {
            await deleteFile('$basePath.acl');
            debugPrint('Successfully deleted ACL file');
          } catch (e) {
            // Ignore 404 errors for ACL file
            if (e.toString().contains('404') || 
                e.toString().contains('NotFoundHttpError')) {
              debugPrint('ACL file not found (safe to ignore)');
            } else {
              debugPrint('Error deleting ACL file: ${e.toString()}');
            }
          }
          
          setState(() {
            deleteDone = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        deleteDone = false;
      });
      if (context.mounted) {
        if (e.toString().contains('404') || 
            e.toString().contains('NotFoundHttpError')) {
          alert(context, 'File not found or already deleted');
        } else {
          alert(context, 'Delete failed: ${e.toString()}');
        }
      }
      debugPrint('Delete error: $e');
    } finally {
      setState(() {
        deleteInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final browseButton = ElevatedButton(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles();
        if (result != null) {
          setState(() {
            uploadFile = result.files.single.path!;
            uploadDone = false;
          });
        }
      },
      child: const Text('Browse'),
    );

    final uploadButton = ElevatedButton(
      onPressed: (uploadFile == null ||
              uploadInProgress ||
              downloadInProgress ||
              deleteInProgress)
          ? null
          : handleUpload,
      child: const Text('Upload'),
    );

    final downloadButton = ElevatedButton(
      onPressed: (uploadInProgress || downloadInProgress || deleteInProgress)
          ? null
          : () async {
              String? outputFile = await FilePicker.platform.saveFile(
                dialogTitle: 'Please set the output file:',
                fileName: remoteFileName, // Suggest the original filename
              );
              if (outputFile != null) {
                setState(() {
                  downloadFile = outputFile;
                });
                await handleDownload();
              } else {
                debugPrint('Download is cancelled');
              }
            },
      child: const Text('Download'),
    );

    final deleteButton = ElevatedButton(
      onPressed: (uploadInProgress || downloadInProgress || deleteInProgress)
          ? null
          : handleDelete,
      child: const Text('Delete'),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                largeGapV,
                largeGapV,

                // Upload section.

                Text(
                  'Upload a file and save it as "$remoteFileName" in POD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                smallGapV,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('Upload file'),
                    smallGapH,
                    Text(
                      uploadFile ?? 'Click the Browse button to choose a file',
                      style: TextStyle(
                        color: uploadFile == null ? Colors.red : Colors.blue,
                      ),
                    ),
                    smallGapH,
                    if (uploadDone) const Icon(Icons.done, color: Colors.green),
                  ],
                ),
                smallGapV,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    browseButton,
                    smallGapH,
                    uploadButton,
                  ],
                ),

                largeGapV,

                // Download section.

                Text(
                  'Download "$remoteFileName" from POD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                smallGapV,
                if (downloadFile != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('Save file'),
                      smallGapH,
                      Text(
                        downloadFile!,
                        style: const TextStyle(color: Colors.blue),
                      ),
                      smallGapH,
                      if (downloadDone)
                        const Icon(Icons.done, color: Colors.green),
                    ],
                  ),
                smallGapV,
                downloadButton,

                largeGapV,

                // Delete section.

                Text(
                  'Delete "$remoteFileName" from POD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                smallGapV,
                if (deleteInProgress || deleteDone)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Delete file'),
                      smallGapH,
                      Text('$remoteFileName', style: const TextStyle(color: Colors.red)),
                      smallGapH,
                      Text(
                        remoteFileUrl ?? '',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      smallGapH,
                      if (deleteDone)
                        const Icon(Icons.done, color: Colors.green),
                    ],
                  ),
                smallGapV,
                deleteButton,
              ],
            ),

            // Operation indicators.

            if (uploadInProgress || downloadInProgress || deleteInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      smallGapV,
                      Text(
                        uploadInProgress
                            ? 'Uploading...'
                            : downloadInProgress
                                ? 'Downloading...'
                                : 'Deleting...',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Back button.

            Positioned(
              top: 10,
              left: 10,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}