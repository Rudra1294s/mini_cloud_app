import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class FileItem {
  final String name;
  final String id;
  final int size;

  FileItem({required this.name, required this.id, required this.size});

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed',
      size: json['size'] ?? 0,
    );
  }
}

class ApiService {
  final String baseUrl;
  final String token;

  ApiService({required this.baseUrl, required this.token});

  // ------------------ GET FILES ------------------
  Future<List<FileItem>> getFiles() async {
    try {
      final url = Uri.parse('$baseUrl/recent_files/'); // ✅ Update endpoint
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> filesData = jsonData["files"] ?? [];
        return filesData.map((f) => FileItem(id: f, name: f, size: 0)).toList(); // filenames only
      } else if (response.statusCode == 404) {
        print("Endpoint not found: $url");
        return [];
      } else {
        print("Server error ${response.statusCode}: ${response.reasonPhrase}");
        return [];
      }
    } catch (e) {
      print("Get files error: $e");
      return [];
    }
  }


  // ------------------ UPLOAD FILE ------------------
  Future<bool> uploadFile(PlatformFile file) async {
    try {
      final url = Uri.parse('$baseUrl/upload_chunk/');
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', file.path!));

      var response = await request.send();

      if (response.statusCode == 200) {
        print("File uploaded successfully: ${file.name}");
        return true;
      } else {
        print("Upload failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }

  // ------------------ DOWNLOAD FILE ------------------
  Future<bool> downloadFile(String fileName, String savePath) async {
    try {
      final url = Uri.parse('$baseUrl/download_chunk/$fileName'); // ✅ updated endpoint
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        print("File downloaded: $savePath");
        return true;
      } else {
        print("Download failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Download error: $e");
      return false;
    }
  }

}
