import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html; // Only for Web

class ApiService {
  final String baseUrl;
  final String token;

  ApiService({required this.baseUrl, required this.token});

  Future<bool> uploadFile(PlatformFile file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_chunk'),
      );

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      } else {
        request.files.add(http.MultipartFile.fromBytes('file', File(file.path!).readAsBytesSync(), filename: file.name));
      }

      request.headers['Authorization'] = 'Bearer $token';
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  Future<List<String>> getFiles() async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/files'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching files: $e');
      return [];
    }
  }

  Future<void> downloadFile(String filename) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/download_chunk/$filename'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)..setAttribute("download", filename)..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final dir = Directory.current.path;
          File file = File('$dir/$filename');
          await file.writeAsBytes(response.bodyBytes);
        }
      } else {
        print('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Download error: $e');
    }
  }
}
