import 'package:file_picker/file_picker.dart';
import 'api_service.dart';

class FileService {
  final ApiService apiService;

  FileService({required this.apiService});

  Future<void> pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      bool success = await apiService.uploadFile(result.files.first);
      print(success ? "Upload successful" : "Upload failed");
    }
  }

  Future<void> download(String filename) async {
    await apiService.downloadFile(filename);
  }

  Future<List<String>> getFiles() async {
    return await apiService.getFiles();
  }
}
