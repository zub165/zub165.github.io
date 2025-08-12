class Config {
  // Development API endpoint (local)
  static const String devApiUrl = 'http://localhost:5001/api/chat';
  
  // Production API endpoint (needs to be updated when deployed)
  static const String prodApiUrl = 'https://your-production-domain.com/api/chat';
  
  // Set this to false for production builds
  static const bool isDevelopment = true;
  
  // Current API endpoint based on environment
  static String get apiUrl => isDevelopment ? devApiUrl : prodApiUrl;
} 