import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:memento/src/features/settings/data/credentials_provider.dart';
import 'package:memento/src/features/settings/data/app_settings_provider.dart';

final googlePhotosServiceProvider = Provider<GooglePhotosService>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://photoslibrary.googleapis.com/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final logger = Logger();
  
  return GooglePhotosService(
    dio: dio, 
    logger: logger,
    ref: ref,
  );
});

/// Debug log entry for troubleshooting
class DebugLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[${timestamp.toIso8601String()}] $level: $message');
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    if (stackTrace != null) {
      buffer.writeln('StackTrace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Provider for debug logs
final debugLogsProvider = StateProvider<List<DebugLogEntry>>((ref) => []);

class GooglePhotosService {
  final Dio _dio;
  final Logger _logger;
  final Ref _ref;
  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;

  GooglePhotosService({
    required Dio dio,
    required Logger logger,
    required Ref ref,
  })  : _dio = dio,
        _logger = logger,
        _ref = ref;

  bool get isSignedIn => _currentUser != null;

  void _log(String level, String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.log(
      level == 'ERROR' ? Level.error : Level.debug,
      message,
      error: error,
      stackTrace: stackTrace,
    );
    
    // Also add to debug logs if debug mode is enabled
    final settings = _ref.read(appSettingsProvider).valueOrNull;
    if (settings?.debugModeEnabled == true) {
      final logs = _ref.read(debugLogsProvider);
      _ref.read(debugLogsProvider.notifier).state = [
        ...logs,
        DebugLogEntry(
          timestamp: DateTime.now(),
          level: level,
          message: message,
          error: error,
          stackTrace: stackTrace,
        ),
      ];
    }
  }

  /// Initialize GoogleSignIn with the stored client ID
  Future<GoogleSignIn> _getGoogleSignIn() async {
    if (_googleSignIn != null) return _googleSignIn!;
    
    final credentials = _ref.read(credentialsProvider).valueOrNull;
    final clientId = credentials?.clientId;
    
    _log('INFO', 'Initializing GoogleSignIn with clientId: ${clientId != null ? "[REDACTED]" : "null"}');
    
    try {
      _googleSignIn = GoogleSignIn(
        clientId: clientId, // Used on iOS, ignored on Android
        scopes: [
          'email',
          'https://www.googleapis.com/auth/photoslibrary.readonly',
          'https://www.googleapis.com/auth/photoslibrary.sharing',
        ],
      );
      _log('INFO', 'GoogleSignIn initialized successfully');
    } catch (e, st) {
      _log('ERROR', 'Failed to initialize GoogleSignIn', error: e, stackTrace: st);
      rethrow;
    }
    
    return _googleSignIn!;
  }

  Future<Map<String, dynamic>> signIn() async {
    _log('INFO', 'Starting Google Sign-In flow');
    
    try {
      final googleSignIn = await _getGoogleSignIn();
      
      _log('INFO', 'Calling googleSignIn.signIn()...');
      _currentUser = await googleSignIn.signIn();
      
      if (_currentUser != null) {
        _log('INFO', 'Sign-in successful. User: ${_currentUser!.email}');
        
        // Try to get auth token to verify it works
        _log('INFO', 'Requesting auth token...');
        final auth = await _currentUser!.authentication;
        _log('INFO', 'Auth token obtained. Access token length: ${auth.accessToken?.length ?? 0}');
        
        return {
          'success': true,
          'email': _currentUser!.email,
          'displayName': _currentUser!.displayName,
        };
      } else {
        _log('WARN', 'Sign-in returned null (user cancelled?)');
        return {
          'success': false,
          'error': 'Sign-in cancelled or failed silently',
        };
      }
    } on PlatformException catch (e, st) {
      _log('ERROR', 'PlatformException during sign-in', error: e, stackTrace: st);
      return {
        'success': false,
        'error': 'Platform error: ${e.code} - ${e.message}',
        'details': e.details?.toString(),
      };
    } catch (e, st) {
      _log('ERROR', 'Unexpected error during sign-in', error: e, stackTrace: st);
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  Future<void> signOut() async {
    _log('INFO', 'Signing out...');
    if (_googleSignIn != null) {
      try {
        await _googleSignIn!.signOut();
        _log('INFO', 'Sign-out successful');
      } catch (e, st) {
        _log('ERROR', 'Error during sign-out', error: e, stackTrace: st);
      }
    }
    _currentUser = null;
  }

  Future<String?> _getAuthToken() async {
    if (_currentUser == null) {
      _log('WARN', 'Attempted to get auth token but no current user');
      return null;
    }
    
    try {
      final auth = await _currentUser!.authentication;
      _log('DEBUG', 'Auth token refreshed. Length: ${auth.accessToken?.length ?? 0}');
      return auth.accessToken;
    } catch (e, st) {
      _log('ERROR', 'Failed to get auth token', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<GooglePhotoAlbum>> getAlbums() async {
    _log('INFO', 'Fetching albums...');
    
    final token = await _getAuthToken();
    if (token == null) {
      _log('ERROR', 'Cannot fetch albums: no auth token');
      throw Exception('Not authenticated');
    }

    try {
      _log('DEBUG', 'Making API request to /albums');
      final response = await _dio.get(
        '/albums',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final albums = (response.data['albums'] as List?)
          ?.map((a) => GooglePhotoAlbum.fromJson(a))
          .toList() ?? [];
      
      _log('INFO', 'Fetched ${albums.length} albums');
      return albums;
    } on DioException catch (e, st) {
      _log('ERROR', 'DioException fetching albums', error: e, stackTrace: st);
      _log('ERROR', 'Response: ${e.response?.data}');
      rethrow;
    } catch (e, st) {
      _log('ERROR', 'Unexpected error fetching albums', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<GooglePhotoMedia>> getPhotos(String albumId, {int pageSize = 100}) async {
    _log('INFO', 'Fetching photos for album: $albumId');
    
    final token = await _getAuthToken();
    if (token == null) {
      _log('ERROR', 'Cannot fetch photos: no auth token');
      throw Exception('Not authenticated');
    }

    try {
      final response = await _dio.post(
        '/mediaItems:search',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'albumId': albumId,
          'pageSize': pageSize,
        },
      );

      final items = (response.data['mediaItems'] as List?)
          ?.map((m) => GooglePhotoMedia.fromJson(m))
          .toList() ?? [];
      
      _log('INFO', 'Fetched ${items.length} photos');
      return items;
    } catch (e, st) {
      _log('ERROR', 'Error fetching photos', error: e, stackTrace: st);
      rethrow;
    }
  }

  String getThumbnailUrl(String mediaItemId, {int width = 300, int height = 300}) {
    return 'https://photoslibrary.googleapis.com/v1/mediaItems/$mediaItemId?access_token=$_getAuthToken()&w=$width&h=$height';
  }
}

class GooglePhotoAlbum {
  final String id;
  final String title;
  final String? coverPhotoBaseUrl;
  final int? mediaItemsCount;

  GooglePhotoAlbum({
    required this.id,
    required this.title,
    this.coverPhotoBaseUrl,
    this.mediaItemsCount,
  });

  factory GooglePhotoAlbum.fromJson(Map<String, dynamic> json) {
    return GooglePhotoAlbum(
      id: json['id'] as String,
      title: json['title'] as String,
      coverPhotoBaseUrl: json['coverPhotoBaseUrl'] as String?,
      mediaItemsCount: json['mediaItemsCount'] as int?,
    );
  }
}

class GooglePhotoMedia {
  final String id;
  final String description;
  final String baseUrl;
  final String mimeType;
  final String filename;
  final MediaMetadata? mediaMetadata;

  GooglePhotoMedia({
    required this.id,
    required this.description,
    required this.baseUrl,
    required this.mimeType,
    required this.filename,
    this.mediaMetadata,
  });

  factory GooglePhotoMedia.fromJson(Map<String, dynamic> json) {
    return GooglePhotoMedia(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      baseUrl: json['baseUrl'] as String,
      mimeType: json['mimeType'] as String,
      filename: json['filename'] as String,
      mediaMetadata: json['mediaMetadata'] != null
          ? MediaMetadata.fromJson(json['mediaMetadata'])
          : null,
    );
  }

  bool get isVideo => mimeType.startsWith('video/');
  bool get isImage => mimeType.startsWith('image/');
  
  String getDownloadUrl({int? maxWidth, int? maxHeight}) {
    if (isVideo) return '$baseUrl=dv';
    var url = '$baseUrl=d';
    if (maxWidth != null) url += '-w$maxWidth';
    if (maxHeight != null) url += '-h$maxHeight';
    return url;
  }
}

class MediaMetadata {
  final DateTime? creationTime;
  final String? width;
  final String? height;

  MediaMetadata({this.creationTime, this.width, this.height});

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      creationTime: json['creationTime'] != null
          ? DateTime.tryParse(json['creationTime'])
          : null,
      width: json['width'] as String?,
      height: json['height'] as String?,
    );
  }
}
