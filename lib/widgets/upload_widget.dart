import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadWidget extends StatelessWidget {
  final void Function(PlatformFile) onUpload;

  const UploadWidget({Key? key, required this.onUpload}) : super(key: key);

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      onUpload(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: const Text("Upload File"),
        onPressed: pickFile,
      ),
    );
  }
}
