// lib/services/file_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:io' as io;             // Only works on mobile/desktop
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:html' as html;         // Only works on web

class FileService {
  final String baseUrl;
  final String token;
  final Dio dio;

  FileService({required this.baseUrl, required this.token})
      : dio = Dio(BaseOptions(
    baseUrl: _normalizeBaseUrl(baseUrl),
    connectTimeout: const Duration(minutes: 2),
    receiveTimeout: const Duration(minutes: 2),
  )) {
    // Simple logging interceptor for debugging
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('→ REQUEST: ${options.method} ${options.uri}');
        print('  headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (r, handler) {
        print('← RESPONSE ${r.statusCode}: ${r.requestOptions.method} ${r.requestOptions.uri}');
        handler.next(r);
      },
      onError: (e, handler) {
        print('!! DIO ERROR (${e.type}) for ${e.requestOptions.method} ${e.requestOptions.uri}');
        if (e.response != null) {
          print('   status: ${e.response?.statusCode}');
          print('   data: ${e.response?.data}');
        } else {
          print('   no response (likely network/CORS/mixed-content)');
        }
        handler.next(e);
      },
    ));
  }

  // Ensure baseUrl includes scheme (helps catch mistakes)
  static String _normalizeBaseUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw ArgumentError.value(url, 'baseUrl', 'baseUrl must start with http:// or https://');
    }
    return url;
  }

  // ---------------- UPLOAD ----------------
  Future<bool> uploadFile(PlatformFile file,
      {void Function(int sent, int total)? onProgress}) async {
    try {
      MultipartFile mfile;

      // Web → use bytes
      if (kIsWeb) {
        if (file.bytes == null) {
          print("WEB ERROR: File bytes are NULL. Use FilePicker withData:true.");
          return false;
        }
        mfile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      }

      // Mobile/Desktop → use path if available
      else if (file.path != null && file.path!.isNotEmpty) {
        mfile = await MultipartFile.fromFile(file.path!, filename: file.name);
      }

      // Fallback → use bytes
      else if (file.bytes != null) {
        mfile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else {
        print("UPLOAD ERROR: No path + no bytes.");
        return false;
      }

      final form = FormData.fromMap({
        "file": mfile,
        "uploaded_by": "universal_user",
      });

      final resp = await dio.post(
        "/upload",
        data: form,
        options: Options(
          headers: token.isNotEmpty ? {"Authorization": "Bearer $token"} : null,
        ),
        onSendProgress: onProgress,
      );

      print("UPLOAD STATUS: ${resp.statusCode} | ${resp.data}");
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e, st) {
      print("UPLOAD ERROR: $e\n$st");
      return false;
    }
  }

  // ---------------- DOWNLOAD ----------------
  Future<void> downloadFile(String fileName) async {
    try {
      final resp = await dio.get<List<int>>(
        "/download_chunk/$fileName",
        options: Options(
          responseType: ResponseType.bytes,
          headers: token.isNotEmpty ? {"Authorization": "Bearer $token"} : null,
        ),
      );

      // WEB (browser download)
      if (kIsWeb) {
        // resp.data might be a List<int> / Uint8List — ensure it's accepted by Blob
        final data = resp.data ?? <int>[];
        final blob = html.Blob([data]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return;
      }

      // MOBILE + DESKTOP saving
      final dir = await path_provider.getApplicationDocumentsDirectory();
      final file = io.File("${dir.path}/$fileName");
      await file.writeAsBytes(resp.data ?? <int>[]);
      print("Saved to ${file.path}");
    } catch (e, st) {
      print("DOWNLOAD ERROR: $e\n$st");
    }
  }

  // ---------------- LIST FILES ----------------
  Future<List<String>> listFiles() async {
    try {
      final resp = await dio.get(
        "/recent_files/",
        options: Options(
          headers: token.isNotEmpty ? {"Authorization": "Bearer $token"} : null,
        ),
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data["files"] != null) {
          return (data["files"] as List).map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print("LIST FILES ERROR: $e");
      return [];
    }
  }
}
