import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:memento/src/core/photos/google_photos_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

final videoGenerationServiceProvider = Provider<VideoGenerationService>((ref) {
  final logger = Logger();
  return VideoGenerationService(logger: logger);
});

class VideoGenerationService {
  final Logger _logger;
  
  VideoGenerationService({required Logger logger}) : _logger = logger;

  /// Generate a slideshow video from photos and music
  Future<File?> generateSlideshow({
    required List<GooglePhotoMedia> photos,
    required List<String> musicPaths,
    required Duration photoDuration,
    required Duration transitionDuration,
    VideoResolution resolution = VideoResolution.hd1080,
    void Function(double progress)? onProgress,
  }) async {
    if (photos.isEmpty) {
      throw ArgumentError('At least one photo required');
    }

    _logger.i('Starting slideshow generation with ${photos.length} photos');
    onProgress?.call(0.0);

    final tempDir = await getTemporaryDirectory();
    final sessionDir = Directory(path.join(tempDir.path, 'memento_${DateTime.now().millisecondsSinceEpoch}'));
    await sessionDir.create(recursive: true);

    try {
      // Step 1: Download photos
      _logger.i('Downloading photos...');
      final photoPaths = await _downloadPhotos(photos, sessionDir, resolution);
      onProgress?.call(0.3);

      // Step 2: Create FFmpeg concat script
      _logger.i('Creating FFmpeg script...');
      final concatFile = await _createConcatFile(
        photoPaths,
        photoDuration,
        transitionDuration,
        sessionDir,
      );
      onProgress?.call(0.4);

      // Step 3: Generate the video
      _logger.i('Generating video with FFmpeg...');
      final outputPath = path.join(sessionDir.path, 'output.mp4');
      final success = await _runFFmpeg(
        concatFile: concatFile,
        musicPaths: musicPaths,
        outputPath: outputPath,
        resolution: resolution,
        transitionDuration: transitionDuration,
      );
      onProgress?.call(0.9);

      if (!success) {
        throw Exception('FFmpeg processing failed');
      }

      // Step 4: Move to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final moviesDir = Directory(path.join(appDir.path, 'movies'));
      await moviesDir.create(recursive: true);
      
      final finalPath = path.join(
        moviesDir.path,
        'memento_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      
      final outputFile = File(outputPath);
      await outputFile.copy(finalPath);
      onProgress?.call(1.0);

      _logger.i('Slideshow saved to: $finalPath');
      return File(finalPath);

    } catch (e, stack) {
      _logger.e('Video generation failed', error: e, stackTrace: stack);
      rethrow;
    } finally {
      // Cleanup temp files
      await sessionDir.delete(recursive: true);
    }
  }

  Future<List<String>> _downloadPhotos(
    List<GooglePhotoMedia> photos,
    Directory sessionDir,
    VideoResolution resolution,
  ) async {
    final paths = <String>[];
    final (targetWidth, targetHeight) = resolution.dimensions;

    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final url = photo.getDownloadUrl(maxWidth: targetWidth, maxHeight: targetHeight);
      
      _logger.d('Downloading photo ${i + 1}/${photos.length}: ${photo.filename}');
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download ${photo.filename}: ${response.statusCode}');
      }

      final ext = path.extension(photo.filename);
      final filePath = path.join(sessionDir.path, 'photo_$i$ext');
      await File(filePath).writeAsBytes(response.bodyBytes);
      paths.add(filePath);
    }

    return paths;
  }

  Future<String> _createConcatFile(
    List<String> photoPaths,
    Duration photoDuration,
    Duration transitionDuration,
    Directory sessionDir,
  ) async {
    final concatPath = path.join(sessionDir.path, 'concat.txt');
    final buffer = StringBuffer();

    for (final photoPath in photoPaths) {
      // Each photo gets: duration + (transition if not last)
      final duration = photoDuration + transitionDuration;
      buffer.writeln("file '$photoPath'");
      buffer.writeln('duration ${duration.inMilliseconds / 1000}');
    }

    // FFmpeg concat demuxer requires the last file repeated
    if (photoPaths.isNotEmpty) {
      buffer.writeln("file '${photoPaths.last}'");
    }

    await File(concatPath).writeAsString(buffer.toString());
    return concatPath;
  }

  Future<bool> _runFFmpeg({
    required String concatFile,
    required List<String> musicPaths,
    required String outputPath,
    required VideoResolution resolution,
    required Duration transitionDuration,
  }) async {
    final (width, height) = resolution.dimensions;
    final fadeDuration = transitionDuration.inMilliseconds / 1000;

    // Build filter complex for crossfade transitions
    final filterComplex = _buildCrossfadeFilter(
      concatFile,
      fadeDuration,
      width,
      height,
    );

    // Build audio input args
    final audioArgs = <String>[];
    
    for (final musicPath in musicPaths) {
      audioArgs.addAll(['-i', musicPath]);
    }

    final args = <String>[
      '-f', 'concat',
      '-safe', '0',
      '-i', concatFile,
      ...audioArgs,
      '-filter_complex', filterComplex,
      '-map', '[v]',
      '-map', '[a]',
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '23',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-shortest',
      '-y',
      outputPath,
    ];

    _logger.d('FFmpeg command: ffmpeg ${args.join(' ')}');

    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();
    final output = await session.getOutput();
    final logs = await session.getLogs();

    if (ReturnCode.isSuccess(returnCode)) {
      _logger.i('FFmpeg completed successfully');
      return true;
    } else {
      _logger.e('FFmpeg failed with code $returnCode');
      _logger.e('Output: $output');
      for (final log in logs) {
        _logger.e('FFmpeg log: ${log.getMessage()}');
      }
      return false;
    }
  }

  String _buildCrossfadeFilter(
    String concatFile,
    double fadeDuration,
    int width,
    int height,
  ) {
    // Simple crossfade filter
    // For production, you'd want more sophisticated transitions
    return '''
      [0:v]format=pix_fmts=yuv420p,scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2:black[v0];
      [v0]fade=t=out:st=0:d=$fadeDuration:alpha=1[fv];
      [1:a]amix=inputs=1:duration=first:dropout_transition=3[a]
    '''.trim().replaceAll('\n', ' ');
  }

  /// Get info about a generated video
  Future<VideoInfo> getVideoInfo(String videoPath) async {
    // Use ffprobe via FFmpegKit to get media info
    final session = await FFmpegKit.execute('-i "$videoPath"');
    final output = await session.getOutput() ?? '';
    
    // Parse duration from output (basic regex)
    final durationMatch = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})').firstMatch(output);
    Duration? duration;
    if (durationMatch != null) {
      final hours = int.parse(durationMatch.group(1)!);
      final minutes = int.parse(durationMatch.group(2)!);
      final seconds = double.parse(durationMatch.group(3)!);
      duration = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds.toInt(),
        milliseconds: ((seconds % 1) * 1000).toInt(),
      );
    }
    
    // Parse resolution
    final resolutionMatch = RegExp(r'(\d{2,4})x(\d{2,4})').firstMatch(output);
    int width = 0;
    int height = 0;
    if (resolutionMatch != null) {
      width = int.parse(resolutionMatch.group(1)!);
      height = int.parse(resolutionMatch.group(2)!);
    }
    
    return VideoInfo(
      path: videoPath,
      duration: duration ?? Duration.zero,
      width: width,
      height: height,
      fileSize: await File(videoPath).length(),
    );
  }
}

enum VideoResolution {
  sd480('SD 480p', 854, 480),
  hd720('HD 720p', 1280, 720),
  hd1080('Full HD 1080p', 1920, 1080),
  hd4k('4K UHD', 3840, 2160);

  final String label;
  final int width;
  final int height;
  
  const VideoResolution(this.label, this.width, this.height);
  
  (int, int) get dimensions => (width, height);
}

class VideoInfo {
  final String path;
  final Duration duration;
  final int width;
  final int height;
  final int fileSize;

  VideoInfo({
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
