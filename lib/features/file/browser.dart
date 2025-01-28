/// File browser widget.
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

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/file/item.dart';

/// File Browser Widget.
///
/// Interacts with files and directories in user's POD.
/// Handles displaying files and directories, and allows for navigation and file operations.

/// `FileBrowser` is a StatefulWidget as it needs to change its contents
/// based on user's actions, such as navigating directories or refreshing the view.
/// A few key callbacks are provided to allow for interaction outside this widget,
/// such as selecting a file, downloading a file, and deleting a file.

class FileBrowser extends StatefulWidget {
  final Function(String, String) onFileSelected;
  final Function(String, String) onFileDownload;
  final Function(String, String) onFileDelete;
  final Function(String) onDirectoryChanged;
  final Function(String, String)
      onImportCsv; // Callback for handling CSV file imports.
  final GlobalKey<FileBrowserState> browserKey;

  const FileBrowser({
    super.key,
    required this.onFileSelected,
    required this.onFileDownload,
    required this.onFileDelete,
    required this.browserKey,
    required this.onImportCsv,
    required this.onDirectoryChanged,
  });

  @override
  State<FileBrowser> createState() => FileBrowserState();
}

class FileBrowserState extends State<FileBrowser> {
  // State variables.

  List<FileItem> files = [];
  List<String> directories = [];
  bool isLoading = true;
  String? selectedFile;
  String currentPath = 'healthpod/data';
  List<String> pathHistory = ['healthpod/data'];

  final smallGapH = const SizedBox(width: 10);

  // As the widget initialises, we fetch the file list.

  @override
  void initState() {
    super.initState();
    refreshFiles();
  }

  // When a user clicks a directory, we navigate deeper into it.

  Future<void> navigateToDirectory(String dirName) async {
    setState(() {
      currentPath = '$currentPath/$dirName';
      pathHistory.add(currentPath);
    });
    await refreshFiles();

    // Notify parent about directory change.

    widget.onDirectoryChanged.call(currentPath);
  }

  // Users can navigate up by removing the last directory from the path history.

  Future<void> navigateUp() async {
    if (pathHistory.length > 1) {
      pathHistory.removeLast();
      setState(() {
        currentPath = pathHistory.last;

        // Notify parent about directory change.

        widget.onDirectoryChanged.call(currentPath);
      });
      await refreshFiles();
    }
  }

  // This is the core of the file browser.
  // We fetch the list of directories and files, processing each file for metadata.

  Future<void> refreshFiles() async {
    // Set loading state to show progress indicator.

    setState(() {
      isLoading = true;
    });

    try {
      // Get current directory URL and its resources.

      final dirUrl = await getDirUrl(currentPath);
      final resources = await getResourcesInContainer(dirUrl);

      if (!mounted) return;

      // Update directories list immediately.

      setState(() {
        directories = resources.subDirs;
      });

      // Process and validate files.

      final processedFiles = <FileItem>[];

      for (var fileName in resources.files) {
        // Filter for .enc.ttl files while preserving the full extension.
        // This ensures we only show encrypted turtle files that our app can handle.

        if (!fileName.endsWith('.enc.ttl')) {
          continue;
        }

        // Construct the full path for the file.

        final relativePath = '$currentPath/$fileName';

        // Validate file accessibility and metadata.
        // This step ensures we only display files that are properly formatted
        // and accessible to the current user.

        final metadata = await readPod(
          relativePath,
          context,
          const Text('Reading file info'),
        );

        // Only add files that pass validation.
        // This prevents displaying corrupt or inaccessible files.

        if (metadata != SolidFunctionCallStatus.fail &&
            metadata != SolidFunctionCallStatus.notLoggedIn) {
          processedFiles.add(FileItem(
            name: fileName, // Use complete filename with extension
            path: relativePath,
            dateModified: DateTime.now(),
          ));
        }
      }

      // Update UI with processed files.

      setState(() {
        files = processedFiles;
        isLoading = false;
      });
    } catch (e) {
      // Handle any errors during the refresh process.

      debugPrint('Error loading files: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Build the UI that will be displayed to the user.

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              100, // Account for padding/margins
          maxHeight: MediaQuery.of(context).size.height - 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Path bar: display current directory and allow user to go up.

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withAlpha(10),
                ),
              ),
              child: Row(
                children: [
                  if (pathHistory.length > 1)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: navigateUp,
                      tooltip: 'Go up',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withAlpha(10),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentPath,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  // Add Spacer to push the refresh icon to the far right.

                  const Spacer(),

                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: refreshFiles,
                    tooltip: 'Refresh',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withAlpha(10),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Content: display directories and files, or loading indicators when necessary.

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : directories.isEmpty && files.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(50),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'This folder is empty',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            if (directories.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Folders',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              // Display directories as a list.

                              ...directories.map((dir) => ListTile(
                                    leading: Icon(
                                      Icons.folder,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text(
                                      dir,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onTap: () => navigateToDirectory(dir),
                                  )),
                              if (files.isNotEmpty)
                                Divider(
                                  height: 24,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withAlpha(20),
                                ),
                            ],
                            if (files.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Files',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              // Display files with additional actions (select, download, delete).

                              ...files.map((file) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        const minWidthForButtons = 200;
                                        final showButtons =
                                            constraints.maxWidth >=
                                                minWidthForButtons;

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedFile = file.name;
                                            });
                                            widget.onFileSelected.call(
                                                file.name,
                                                currentPath); // Maintain path context for selection.
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: selectedFile == file.name
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer
                                                      .withAlpha(10)
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: constraints.maxWidth <
                                                      50
                                                  ? 4
                                                  : 12, // Reduce padding when very small
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize
                                                  .min, // Changed from max to min
                                              children: [
                                                // File icon and title.

                                                if (constraints.maxWidth > 40)
                                                  Icon(
                                                    Icons.insert_drive_file,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                    size: 20,
                                                  ),
                                                if (constraints.maxWidth > 40)
                                                  SizedBox(
                                                      width:
                                                          constraints.maxWidth <
                                                                  100
                                                              ? 4
                                                              : 12),

                                                // Title and date modified.

                                                Expanded(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        file.name,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (constraints.maxWidth >
                                                          150)
                                                        Text(
                                                          'Modified: ${file.dateModified.toString().split('.')[0]}',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 12,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                                // Action buttons (download, delete).

                                                if (showButtons) ...[
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    icon: Icon(
                                                      Icons.download,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    onPressed: () => widget
                                                        .onFileDownload
                                                        .call(file.name,
                                                            currentPath), // Maintain path context for download.
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withAlpha(10),
                                                      padding: EdgeInsets.zero,
                                                      minimumSize:
                                                          const Size(35, 35),
                                                    ),
                                                  ),
                                                  smallGapH,
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                    ),
                                                    onPressed: () => widget
                                                        .onFileDelete
                                                        .call(file.name,
                                                            currentPath), // Maintain path context for deletion.
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .error
                                                              .withAlpha(10),
                                                      padding: EdgeInsets.zero,
                                                      minimumSize:
                                                          const Size(35, 35),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
