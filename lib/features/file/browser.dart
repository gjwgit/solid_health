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
  bool isLoading = true;
  String? selectedFile;

  @override
  void initState() {
    super.initState();
    refreshFiles();
  }

  Future<void> refreshFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the base data directory path and URL
      final baseDir = await getDataDirPath();
      final dataDir = await getDirUrl(baseDir);
      debugPrint('Data directory URL: $dataDir');
      
      // Get list of resources in the container
      final resources = await getResourcesInContainer(dataDir);
      final fileList = resources.files;
      debugPrint('Found files: $fileList');
      
      if (!mounted) return;

      // Process and filter files
      final processedFiles = <FileItem>[];
      
      for (var fileName in fileList) {
        // Skip non-.enc.ttl files
        if (!fileName.endsWith('.enc.ttl')) {
          continue;
        }
        
        // Get clean filename without .enc.ttl
        final cleanName = fileName.replaceAll(RegExp(r'\.enc\.ttl$'), '');
        
        // Only add if we haven't already added this file
        if (!processedFiles.any((f) => f.name == cleanName)) {
          // Construct the relative path from the data directory
          final relativePath = 'healthpod/data/$fileName';
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
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: refreshFiles,
                tooltip: 'Refresh file list',
              ),
            ],
          ),
        ),
        
        // File list
        Expanded(
          child: files.isEmpty
              ? const Center(
                  child: Text('No files found in your POD'),
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isSelected = selectedFile == file.name;
                    
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.name),
                      subtitle: Text(
                        'Modified: ${file.dateModified.toString().split('.')[0]}',
                      ),
                      selected: isSelected,
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
                    );
                  },
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