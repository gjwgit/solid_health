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

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/dialogs/alert.dart';

class FileService extends StatefulWidget {
  const FileService({super.key});

  @override
  State<FileService> createState() => _FileServiceState();
}

class _FileServiceState extends State<FileService> {
  String remoteFileName = 'large_file.bin';
  String? uploadFile;
  String? downloadFile;
  String? remoteFileUrl;

  double uploadPercent = 0.0;
  double downloadPercent = 0.0;
  double deletePercent = 0.0;

  bool uploadDone = false;
  bool downloadDone = false;
  bool deleteDone = false;

  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool deleteInProgress = false;

  final smallGapH = const SizedBox(width: 10);
  final smallGapV = const SizedBox(height: 10);
  final largeGapV = const SizedBox(height: 50);

  Future<String> getRemoteFileUrl() async =>
      getFileUrl([await getDataDirPath(), remoteFileName].join('/'));

  Widget getProgressBar(String message, bool isDone, double percent) {
    const textStyle = TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
    );

    final prefix = Text(message, style: textStyle);
    final suffix = Text('${(percent * 100).toInt()}%', style: textStyle);
    final progress = SizedBox(
      width: 300,
      height: 10,
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 2,
        backgroundColor: Colors.black12,
        color: Colors.greenAccent,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        prefix,
        smallGapH,
        progress,
        smallGapH,
        suffix,
      ],
    );
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
            uploadPercent = 0.0;
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
          : () async {
              try {
                remoteFileUrl ??= await getRemoteFileUrl();
                setState(() {
                  uploadInProgress = true;
                });
                await sendLargeFile(
                    localFilePath: uploadFile!,
                    remoteFileName: remoteFileName,
                    onProgress: (sent, total) {
                      setState(() {
                        uploadDone = sent == total;
                        uploadPercent = sent / total;
                      });
                    }, context: context, child: const Text('Upload'));
                if (uploadDone) {
                  setState(() {
                    uploadInProgress = false;
                  });
                }
              } on Object catch (e) {
                if (context.mounted) alert(context, 'Failed to send file.');
                debugPrint('$e');
              }
            },
      child: const Text('Upload'),
    );

    final downloadButton = ElevatedButton(
      onPressed: (uploadInProgress || downloadInProgress || deleteInProgress)
          ? null
          : () async {
              String? outputFile = await FilePicker.platform.saveFile(
                dialogTitle: 'Please set the output file:',
                // fileName: 'download.bin',
              );
              if (outputFile == null) {
                // User canceled the picker
                debugPrint('Download is cancelled');
              } else {
                setState(() {
                  downloadFile = outputFile;
                });
                try {
                  remoteFileUrl ??= await getRemoteFileUrl();
                  setState(() {
                    downloadInProgress = true;
                  });
                  await getLargeFile(
                      remoteFileName: remoteFileName,
                      localFilePath: outputFile,
                      onProgress: (received, total) {
                        setState(() {
                          downloadDone = received == total;
                          downloadPercent = received / total;
                        });
                      }, context: context, child: const Text('Download'));
                  if (downloadDone) {
                    setState(() {
                      downloadInProgress = false;
                    });
                  }
                } on Object catch (e) {
                  if (context.mounted) {
                    alert(context, 'Failed to download file.');
                  }
                  debugPrint('$e');
                }
              }
            },
      child: const Text('Download'),
    );

    final deleteButton = ElevatedButton(
      onPressed: (uploadInProgress || downloadInProgress || deleteInProgress)
          ? null
          : () async {
              try {
                remoteFileUrl ??= await getRemoteFileUrl();
                setState(() {
                  deleteInProgress = true;
                });
                await deleteLargeFile(
                    remoteFileName: remoteFileName,
                    onProgress: (deleted, total) {
                      setState(() {
                        deleteDone = deleted == total;
                        deletePercent = deleted / total;
                      });
                    }, context: context, child: const Text('Delete'));
                if (deleteDone) {
                  setState(() {
                    deleteInProgress = false;
                  });
                }
              } on Object catch (e) {
                if (context.mounted) {
                  alert(context, 'Failed to delete file.');
                }
                debugPrint('$e');
              }
            },
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

                // Upload

                Text(
                  'Upload a large file and save it as "$remoteFileName" in POD',
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
                        // fontStyle: FontStyle.italic,
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

                // Download

                Text(
                  'Download the "$remoteFileName" from POD',
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

                // Delete

                Text(
                  'Delete the "$remoteFileName" from POD',
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
                      const Text('Delete file'),
                      smallGapH,
                      Text(
                        remoteFileUrl!,
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

            // Uploading progress bar

            if (uploadInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: getProgressBar('Uploading:', uploadDone, uploadPercent),
              ),

            // Downloading progress bar

            if (downloadInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: getProgressBar(
                    'Downloading:', downloadDone, downloadPercent),
              ),

            // Deleting progress bar

            if (deleteInProgress)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: getProgressBar('Deleting:', deleteDone, deletePercent),
              ),

            // Navigate back to demo page
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
