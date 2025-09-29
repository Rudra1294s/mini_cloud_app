import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  final String baseUrl;
  final String token;

  FileService({required this.baseUrl, required this.token});

  Future<bool> uploadFile(PlatformFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_chunk/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Upload Error: $e");
      return false;
    }
  }

  Future<File?> downloadFile(String fileName) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/download_chunk/$fileName'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        Directory dir = await getApplicationDocumentsDirectory();
        File file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      print("Download failed: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Download Error: $e");
      return null;
    }
  }

  Future<List<String>> listFiles() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/recent_files/'), headers: {'Authorization': 'Bearer $token'}); // ✅ updated
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> files = jsonData["files"] ?? [];
        return files.map((f) => f.toString()).toList();
      }
      print("List files failed: ${response.statusCode}");
      return [];
    } catch (e) {
      print("List Error: $e");
      return [];
    }
  }
}
