// lib/screens/home_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  double uploadProgress = 0.0;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    fileService = FileService(baseUrl: widget.baseUrl, token: widget.token);
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    setState(() => loading = true);
    try {
      final list = await fileService.listFiles();
      setState(() => files = list);
    } catch (e) {
      debugPrint('fetchFiles error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load files')));
    } finally {
      setState(() => loading = false);
    }
  }

  // called by UploadWidget
  void uploadFile(PlatformFile file) async {
    setState(() {
      uploading = true;
      uploadProgress = 0.0;
    });

    final success = await fileService.uploadFile(file, onProgress: (sent, total) {
      if (total != 0) {
        setState(() => uploadProgress = sent / total);
      }
    });

    setState(() {
      uploading = false;
      uploadProgress = 0.0;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload succeeded')));
      await fetchFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  void downloadFile(String fileName) async {
    // universal FileService.downloadFile handles web vs io internally
    try {
      await fileService.downloadFile(fileName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fileName download started/completed')));
    } catch (e) {
      debugPrint('downloadFile error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mini Cloud")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Upload button + progress
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                UploadWidget(onUpload: uploadFile),
                if (uploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(value: uploadProgress),
                  ),
              ],
            ),
          ),
          const Divider(),
          // File list
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchFiles,
              child: files.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No files found. Pull to refresh.')),
                ],
              )
                  : FileListWidget(
                files: files,
                onDownload: downloadFile,
              ),
            ),
          ),
        ],
      ),
    );
  }
}