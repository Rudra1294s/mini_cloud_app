// lib/services/file_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class FileService {
  final String baseUrl;
  final String token;
  final Duration timeout;

  FileService({required this.baseUrl, required this.token, this.timeout = const Duration(minutes: 2)});

  Future<bool> uploadFile(PlatformFile file) async {
    try {
      final uri = Uri.parse('$baseUrl/upload'); // <- ensure backend endpoint is /upload
      final request = http.MultipartRequest('POST', uri);

      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Build multipart file either from path or from bytes (web / SAF safe)
      if (file.path != null && file.path!.isNotEmpty) {
        // prefer fromPath when available
        request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
      } else if (file.bytes != null) {
        final bytes = file.bytes!;
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
      } else {
        print('Upload Error: file has no path and no bytes.');
        return false;
      }

      // Optional extra fields (if backend expects)
      request.fields['uploaded_by'] = request.fields['uploaded_by'] ?? 'flutter_user';

      // send request with timeout and read full response body for debugging
      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      print('UPLOAD -> status: ${response.statusCode}');
      print('UPLOAD -> body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        // try to decode JSON error if any
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          print('Upload failed response json: $data');
        } catch (_) {
          print('Upload failed response (non-json): ${response.body}');
        }
        return false;
      }
    } on http.ClientException catch (e) {
      print('Upload ClientException: $e');
      return false;
    } on IOException catch (e) {
      print('Upload IO Error: $e');
      return false;
    } on TimeoutException catch (e) {
      print('Upload Timeout: $e');
      return false;
    } catch (e) {
      print('Upload Unexpected Error: $e');
      return false;
    }
  }

  Future<File?> downloadFile(String fileName) async {
    try {
      final url = Uri.parse('$baseUrl/download_chunk/$fileName'); // keep as your backend route
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'}).timeout(timeout);

      print('DOWNLOAD -> status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final saved = File('${dir.path}/$fileName');
        await saved.writeAsBytes(response.bodyBytes);
        return saved;
      } else {
        print('Download failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Download Error: $e');
      return null;
    }
  }

  Future<List<String>> listFiles() async {
    try {
      final url = Uri.parse('$baseUrl/recent_files/');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'}).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> files = jsonData["files"] ?? [];
        return files.map((f) => f.toString()).toList();
      } else {
        print('List files failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('List Error: $e');
      return [];
    }
  }
}
