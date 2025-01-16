import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

class FileBrowser extends StatefulWidget {
  final Function(String)? onFileSelected;
  final Function(String)? onFileDownload;
  final Function(String)? onFileDelete;
  
  const FileBrowser({
    super.key, 
    this.onFileSelected,
    this.onFileDownload,
    this.onFileDelete,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  List<FileItem> files = [];
  List<String> directories = [];
  bool isLoading = true;
  String? selectedFile;
  String currentPath = 'healthpod/data';
  List<String> pathHistory = ['healthpod/data'];

  @override
  void initState() {
    super.initState();
    refreshFiles();
  }

  Future<void> navigateToDirectory(String dirName) async {
    setState(() {
      currentPath = '$currentPath/$dirName';
      pathHistory.add(currentPath);
    });
    await refreshFiles();
  }

  Future<void> navigateUp() async {
    if (pathHistory.length > 1) {
      pathHistory.removeLast();
      setState(() {
        currentPath = pathHistory.last;
      });
      await refreshFiles();
    }
  }

  Future<void> refreshFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get URL for current directory
      final dirUrl = await getDirUrl(currentPath);
      debugPrint('Current directory URL: $dirUrl');
      
      // Get list of resources in the container
      final resources = await getResourcesInContainer(dirUrl);
      debugPrint('Subdirectories: ${resources.subDirs}');
      debugPrint('Files: ${resources.files}');
      
      if (!mounted) return;

      // Process directories
      setState(() {
        directories = resources.subDirs;
      });

      // Process and filter files
      final processedFiles = <FileItem>[];
      
      for (var fileName in resources.files) {
        // Skip non-.enc.ttl files
        if (!fileName.endsWith('.enc.ttl')) {
          continue;
        }
        
        // Get clean filename without .enc.ttl
        final cleanName = fileName.replaceAll(RegExp(r'\.enc\.ttl$'), '');
        
        // Only add if we haven't already added this file
        if (!processedFiles.any((f) => f.name == cleanName)) {
          // Construct the relative path from the current directory
          final relativePath = '$currentPath/$fileName';
          debugPrint('Reading file with relative path: $relativePath');
          
          // Read file metadata using readPod with relative path
          final metadata = await readPod(
            relativePath,
            context,
            const Text('Reading file info'),
          );

          if (metadata != SolidFunctionCallStatus.fail && 
              metadata != SolidFunctionCallStatus.notLoggedIn) {
            processedFiles.add(FileItem(
              name: cleanName,
              path: relativePath,
              dateModified: DateTime.now(), // Could be extracted from metadata if available
            ));
          }
        }
      }

      setState(() {
        files = processedFiles;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Navigation bar
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            children: [
              if (pathHistory.length > 1)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: navigateUp,
                  tooltip: 'Go up',
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentPath,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: refreshFiles,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // Directory and file list
        Expanded(
          child: directories.isEmpty && files.isEmpty
              ? const Center(
                  child: Text('This folder is empty'),
                )
              : ListView(
                  children: [
                    // Directories section
                    if (directories.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Folders',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...directories.map((dir) => ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(dir),
                        onTap: () => navigateToDirectory(dir),
                      )),
                      const Divider(),
                    ],
                    
                    // Files section
                    if (files.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Files',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...files.map((file) => ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.name),
                        subtitle: Text(
                          'Modified: ${file.dateModified.toString().split('.')[0]}',
                        ),
                        selected: selectedFile == file.name,
                        onTap: () {
                          setState(() {
                            selectedFile = file.name;
                          });
                          widget.onFileSelected?.call(file.name);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => widget.onFileDownload?.call(file.name),
                              tooltip: 'Download file',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => widget.onFileDelete?.call(file.name),
                              tooltip: 'Delete file',
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class FileItem {
  final String name;
  final String path;
  final DateTime dateModified;

  FileItem({
    required this.name,
    required this.path,
    required this.dateModified,
  });
}