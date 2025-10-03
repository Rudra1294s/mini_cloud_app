import 'package:flutter/foundation.dart';

class ApiConfig {
  static final String baseUrl = kIsWeb
      ? "http://127.0.0.1:5000"   // Web
      : "http://10.0.2.2:5000";  // Android emulator
}
