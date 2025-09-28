import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';

class HomeScreen extends StatefulWidget {
  final String baseUrl;
  final String token;

  const HomeScreen({super.key, required this.baseUrl, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService apiService;
  late FileService fileService;
  List<String> files = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: widget.baseUrl, token: widget.token);
    fileService = FileService(apiService: apiService);
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    setState(() => loading = true);
    files = await fileService.getFiles();
    setState(() => loading = false);
  }

  Future<void> pickAndUpload() async {
    await fileService.pickAndUpload();
    fetchFiles();
  }

  Future<void> downloadFile(String filename) async {
    await fileService.download(filename);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$filename downloaded")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mini Cloud")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (_, index) {
          final file = files[index];
          return ListTile(
            title: Text(file),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => downloadFile(file),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.upload),
        onPressed: pickAndUpload,
      ),
    );
  }
}
