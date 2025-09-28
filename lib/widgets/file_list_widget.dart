import 'package:flutter/material.dart';

class FileListWidget extends StatelessWidget {
  final List<String> files;
  final void Function(String) onDownload;

  const FileListWidget({Key? key, required this.files, required this.onDownload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(child: Text("No files available"));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            title: Text(file),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => onDownload(file),
            ),
          ),
        );
      },
    );
  }
}
