/// Preview Dialog.
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

import 'package:path/path.dart' as path;

class PreviewDialog extends StatelessWidget {
  final String? uploadFile;
  final String? filePreview;
  final VoidCallback onClose;

  const PreviewDialog({
    super.key,
    required this.uploadFile,
    required this.filePreview,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,  // 80% of screen height
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,  
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(  
                    child: Text(
                      'Preview: ${path.basename(uploadFile ?? '')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,  // Handles long filenames
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,  
                    onPressed: onClose,
                  ),
                ],
              ),
              const Divider(height: 16), 
              Flexible(  
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,  
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(  
                      filePreview ?? 'No preview available',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}