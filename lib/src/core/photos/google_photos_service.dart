import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/photoslibrary.readonly',
      'https://www.googleapis.com/auth/photoslibrary.sharing',
    ],
  );
});

final googlePhotosServiceProvider = Provider<GooglePhotosService>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://photoslibrary.googleapis.com/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final logger = Logger();
  final googleSignIn = ref.watch(googleSignInProvider);
  
  return GooglePhotosService(dio: dio, logger: logger, googleSignIn: googleSignIn);
});

class GooglePhotosService {
  final Dio _dio;
  final Logger _logger;
  final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;

  GooglePhotosService({
    required Dio dio,
    required Logger logger,
    required GoogleSignIn googleSignIn,
  })  : _dio = dio,
        _logger = logger,
        _googleSignIn = googleSignIn;

  bool get isSignedIn => _currentUser != null;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      _logger.e('Google Sign-In failed', error: e);
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<String?> _getAuthToken() async {
    if (_currentUser == null) return null;
    final auth = await _currentUser!.authentication;
    return auth.accessToken;
  }

  Future<List<GooglePhotoAlbum>> getAlbums() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _dio.get(
      '/albums',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final albums = (response.data['albums'] as List?)
        ?.map((a) => GooglePhotoAlbum.fromJson(a))
        .toList() ?? [];
    
    return albums;
  }

  Future<List<GooglePhotoMedia>> getPhotos(String albumId, {int pageSize = 100}) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');

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
    
    return items;
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
