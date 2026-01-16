import 'package:flutter/foundation.dart';

class ApiServices {
  static String get _host {
    if (kIsWeb) {
      return "http://localhost";
    } else {
      // 10.0.2.2 adalah localhost komputer jika diakses dari Emulator Android
      return "http://10.0.2.2";
    }
  }

  static String get baseUrlUser => "$_host:8091";
  static String get baseUrlProduct => "$_host:8092";
  static String get baseUrlCart => "$_host:8093"; // Port Go Service
  static String get baseUrlChat => "$_host:8094";
}