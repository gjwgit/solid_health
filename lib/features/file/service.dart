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
import 'package:healthpod/widgets/preview.dart';
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
  String? filePreview;

  // Operation states.

  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool deleteInProgress = false;
  bool uploadDone = false;
  bool downloadDone = false;
  bool deleteDone = false;
  bool showPreview = false;

  // UI Constants.

  final smallGapH = const SizedBox(width: 10);
  final smallGapV = const SizedBox(height: 10);
  final largeGapV = const SizedBox(height: 50);

  // File type detection.

  final textFileExtensions = [
    '.txt',
    '.md',
    '.json',
    '.xml',
    '.csv',
    '.html',
    '.css',
    '.js',
    '.dart',
    '.yaml',
    '.yml'
  ];

  bool isTextFile(String filePath) {
    return textFileExtensions.contains(path.extension(filePath).toLowerCase());
  }

  // Helper method to show alerts safely.

  void _showAlert(BuildContext context, String message) {
    if (context.mounted) {
      alert(context, message);
    }
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

      remoteFileName =
          '${path.basename(uploadFile!).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_').replaceAll(RegExp(r'\.enc\.ttl$'), '')}.enc.ttl';

      if (!mounted) return;

      // Upload with encryption.

      final result = await writePod(
        remoteFileName!,
        fileContent,
        context,
        const Text('Upload'),
        encrypted: true,
      );

      if (!mounted) return;

      setState(() {
        uploadDone = result == SolidFunctionCallStatus.success;
      });

      if (result != SolidFunctionCallStatus.success && mounted) {
        _showAlert(context,
            'Upload failed - please check your connection and permissions.');
      }
    } catch (e) {
      if (!mounted) return;
      _showAlert(context, 'Upload error: ${e.toString()}');
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          uploadInProgress = false;
        });
      }
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
      final filePath = '$dataDir/$remoteFileName';

      if (!mounted) return;

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Downloading'),
      );

      if (!mounted) return;

      if (fileContent == SolidFunctionCallStatus.fail ||
          fileContent == SolidFunctionCallStatus.notLoggedIn) {
        throw Exception(
            'Download failed - please check your connection and permissions');
      }

      final saveFileName = downloadFile!.replaceAll(RegExp(r'\.enc\.ttl$'), '');
      final file = File(saveFileName);

      try {
        if (isTextFile(
            remoteFileName!.replaceAll(RegExp(r'\.enc\.ttl$'), ''))) {
          await file.writeAsString(fileContent.toString());
        } else {
          try {
            final bytes = base64Decode(fileContent.toString());
            await file.writeAsBytes(bytes);
          } catch (e) {
            await file.writeAsString(fileContent.toString());
          }
        }

        if (!mounted) return;
        setState(() {
          downloadDone = true;
        });
      } catch (e) {
        throw Exception('Failed to save file: ${e.toString()}');
      }
    } catch (e) {
      if (!mounted) return;
      _showAlert(context, e.toString().replaceAll('Exception: ', ''));
      debugPrint('Download error: $e');
    } finally {
      if (mounted) {
        setState(() {
          downloadInProgress = false;
        });
      }
    }
  }

  Future<void> handlePreview() async {
    if (uploadFile == null) return;

    try {
      final file = File(uploadFile!);
      String content;

      if (isTextFile(uploadFile!)) {
        // For text files, read first few lines.

        content = await file.readAsString();

        // Take first 500 characters or less.
        content =
            content.length > 500 ? '${content.substring(0, 500)}...' : content;
      } else {
        // For binary files, show basic info.

        final bytes = await file.readAsBytes();
        content =
            'Binary file\nSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(uploadFile!)}';
      }

      if (!mounted) return;
      setState(() {
        filePreview = content;
        showPreview = true;
      });
    } catch (e) {
      if (!mounted) return;
      _showAlert(context, 'Failed to preview file: ${e.toString()}');
      debugPrint('Preview error: $e');
    }
  }

  Future<void> handleDelete() async {
    if (remoteFileName == null) return;

    try {
      setState(() {
        deleteInProgress = true;
        deleteDone = false;
      });

      final dataDir = await getDataDirPath();
      final basePath = '$dataDir/$remoteFileName';

      if (!mounted) return;

      bool mainFileDeleted = false;
      try {
        await deleteFile(basePath);
        mainFileDeleted = true;
        debugPrint('Successfully deleted main file: $basePath');
      } catch (e) {
        debugPrint('Error deleting main file: $e');
        if (!e.toString().contains('404') &&
            !e.toString().contains('NotFoundHttpError')) {
          rethrow;
        }
      }

      if (!mounted) return;

      if (mainFileDeleted) {
        try {
          await deleteFile('$basePath.acl');
          debugPrint('Successfully deleted ACL file');
        } catch (e) {
          if (e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')) {
            debugPrint('ACL file not found (safe to ignore)');
          } else {
            debugPrint('Error deleting ACL file: ${e.toString()}');
          }
        }

        if (!mounted) return;
        setState(() {
          deleteDone = true;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deleteDone = false;
      });

      final message = e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')
          ? 'File not found or already deleted'
          : 'Delete failed: ${e.toString()}';

      _showAlert(context, message);
      debugPrint('Delete error: $e');
    } finally {
      if (mounted) {
        setState(() {
          deleteInProgress = false;
        });
      }
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
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(100, 40),
      ),
      child: const Text('Browse'),
    );

    final uploadButton = ElevatedButton(
      onPressed: (uploadFile == null ||
              uploadInProgress ||
              downloadInProgress ||
              deleteInProgress)
          ? null
          : handleUpload,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(100, 40),
      ),
      child: const Text('Upload'),
    );

    final previewButton = ElevatedButton(
      onPressed: (uploadFile == null ||
              uploadInProgress ||
              downloadInProgress ||
              deleteInProgress)
          ? null
          : handlePreview,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(100, 40),
      ),
      child: const Text('Preview'),
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
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(100, 40),
      ),
      child: const Text('Download'),
    );

    final deleteButton = ElevatedButton(
      onPressed: (uploadInProgress || downloadInProgress || deleteInProgress)
          ? null
          : handleDelete,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(100, 40),
      ),
      child: const Text('Delete'),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
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
                        uploadFile ??
                            'Click the Browse button to choose a file',
                        style: TextStyle(
                          color: uploadFile == null ? Colors.red : Colors.blue,
                        ),
                      ),
                      smallGapH,
                      if (uploadDone)
                        const Icon(Icons.done, color: Colors.green),
                    ],
                  ),
                  smallGapV,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      browseButton,
                      smallGapH,
                      previewButton,
                      smallGapH,
                      uploadButton,
                    ],
                  ),

                  largeGapV,

                  // Preview section.

                  if (showPreview)
                    PreviewDialog(
                      uploadFile: uploadFile,
                      filePreview: filePreview,
                      onClose: () {
                        setState(() {
                          showPreview = false;
                        });
                      },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      downloadButton,
                      smallGapH,
                      previewButton,
                    ],
                  ),

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
                        Text('$remoteFileName',
                            style: const TextStyle(color: Colors.red)),
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
