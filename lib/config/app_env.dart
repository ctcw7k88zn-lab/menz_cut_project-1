import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get apiBaseUrl => dotenv.env['APP_API_BASE_URL'] ?? 'http://localhost:3000';
  static bool get enableMock => dotenv.env['APP_ENABLE_MOCK']?.toLowerCase() == 'true';
  static String get googleMapsApiKey => dotenv.env['APP_GOOGLE_MAPS_API_KEY'] ?? '';
  static String get environment => dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
}
