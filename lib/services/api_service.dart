// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileItem {
  final String name;
  final String id;
  final int size;

  FileItem({required this.name, required this.id, required this.size});

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
    );
  }
}

class ApiService {
  final String baseUrl;
  final String token;
  final Duration timeout;

  ApiService({required this.baseUrl, required this.token, this.timeout = const Duration(minutes: 2)});

  // ------------------ GET FILES ------------------
  Future<List<FileItem>> getFiles() async {
    try {
      final url = Uri.parse('$baseUrl/recent_files/');
      final resp = await http.get(url, headers: _authHeader()).timeout(timeout);
      print('GET FILES -> status: ${resp.statusCode}, body: ${resp.body}');

      if (resp.statusCode == 200) {
        final jsonData = jsonDecode(resp.body);
        final List<dynamic> filesData = jsonData["files"] ?? [];
        // If API returns objects, try parsing; if it returns list of names, handle that too
        return filesData.map<FileItem>((f) {
          if (f is Map<String, dynamic>) return FileItem.fromJson(f);
          return FileItem(id: f.toString(), name: f.toString(), size: 0);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get files error: $e');
      return [];
    }
  }

  // ------------------ UPLOAD FILE ------------------
  Future<bool> uploadFile(PlatformFile file) async {
    try {
      final uri = Uri.parse('$baseUrl/upload'); // adjust if backend uses /upload_chunk/
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeader());

      // add file either from path or bytes
      if (file.path != null && file.path!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
      } else if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      } else {
        print('Upload Error: no file path and no bytes available');
        return false;
      }

      // optional additional fields
      request.fields['uploaded_by'] = request.fields['uploaded_by'] ?? 'flutter_user';

      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      print('UPLOAD -> status: ${response.statusCode}, body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } on TimeoutException catch (e) {
      print('Upload Timeout: $e');
      return false;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  // ------------------ DOWNLOAD FILE ------------------
  Future<File?> downloadFile(String fileName) async {
    try {
      final url = Uri.parse('$baseUrl/download_chunk/$fileName'); // adjust if needed
      final resp = await http.get(url, headers: _authHeader()).timeout(timeout);
      print('DOWNLOAD -> status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(resp.bodyBytes);
        return file;
      } else {
        print('Download failed: ${resp.statusCode} ${resp.body}');
        return null;
      }
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  Map<String, String> _authHeader() {
    if (token.isNotEmpty) return {'Authorization': 'Bearer $token'};
    return {};
  }
}
