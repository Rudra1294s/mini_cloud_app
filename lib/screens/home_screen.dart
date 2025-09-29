import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../widgets/file_list_widget.dart';
import '../widgets/upload_widget.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  final String baseUrl;
  final String token;

  const HomeScreen({super.key, required this.baseUrl, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FileService fileService;
  List<String> files = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fileService = FileService(baseUrl: widget.baseUrl, token: widget.token);
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    setState(() => loading = true);
    files = await fileService.listFiles();
    setState(() => loading = false);
  }

  void uploadFile(PlatformFile file) async {
    bool success = await fileService.uploadFile(file);
    if (success) fetchFiles();
  }

  void downloadFile(String fileName) async {
    File? file = await fileService.downloadFile(fileName);
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.path} downloaded")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mini Cloud")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          UploadWidget(onUpload: uploadFile),
          Expanded(child: FileListWidget(files: files, onDownload: downloadFile)),
        ],
      ),
    );
  }
}
