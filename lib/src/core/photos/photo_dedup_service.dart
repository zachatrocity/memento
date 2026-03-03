import 'package:image/image.dart' as img;
import 'package:memento/src/core/photos/google_photos_service.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class PhotoDedupService {
  final Logger _logger = Logger();

  /// Group photos by similarity and return only the best from each group
  Future<List<GooglePhotoMedia>> deduplicateAndRank(
    List<GooglePhotoMedia> photos, {
    double similarityThreshold = 0.9,
    int maxDownloadBytes = 500 * 1024, // 500KB thumbnails for hashing
  }) async {
    if (photos.length < 2) return photos;

    _logger.i('Starting deduplication for ${photos.length} photos');

    // First, group by perceptual hash similarity
    final groups = await _groupBySimilarity(photos, similarityThreshold, maxDownloadBytes);
    
    // From each group, pick the best photo
    final bestPhotos = <GooglePhotoMedia>[];
    for (final group in groups) {
      if (group.length == 1) {
        bestPhotos.add(group.first);
      } else {
        final best = await _selectBestPhoto(group, maxDownloadBytes);
        _logger.i('Selected best from group of ${group.length}: ${best.filename}');
        bestPhotos.add(best);
      }
    }

    _logger.i('Deduplication complete: ${photos.length} → ${bestPhotos.length} photos');
    return bestPhotos;
  }

  Future<List<List<GooglePhotoMedia>>> _groupBySimilarity(
    List<GooglePhotoMedia> photos,
    double threshold,
    int maxBytes,
  ) async {
    final groups = <List<GooglePhotoMedia>>[];
    final processed = <GooglePhotoMedia>{};

    for (final photo in photos) {
      if (processed.contains(photo)) continue;

      final similarPhotos = <GooglePhotoMedia>[photo];
      processed.add(photo);

      // Get hash for this photo
      final hash1 = await _getPerceptualHash(photo, maxBytes);
      if (hash1 == null) continue;

      for (final other in photos) {
        if (processed.contains(other)) continue;

        final hash2 = await _getPerceptualHash(other, maxBytes);
        if (hash2 == null) continue;

        final similarity = _compareHashes(hash1, hash2);
        if (similarity >= threshold) {
          similarPhotos.add(other);
          processed.add(other);
        }
      }

      groups.add(similarPhotos);
    }

    return groups;
  }

  Future<String?> _getPerceptualHash(GooglePhotoMedia photo, int maxBytes) async {
    try {
      // Download a small version for hashing
      final url = photo.getDownloadUrl(maxWidth: 128, maxHeight: 128);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) return null;

      final image = img.decodeImage(response.bodyBytes);
      if (image == null) return null;

      // Resize to 32x32 for consistent hashing
      final resized = img.copyResize(image, width: 32, height: 32);
      
      // Convert to grayscale
      final grayscale = img.grayscale(resized);
      
      // Compute average pixel value
      var total = 0;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          total += grayscale.getPixel(x, y).r.toInt();
        }
      }
      final avg = total / 1024;

      // Create hash based on whether each pixel is above/below average
      final hashBits = <int>[];
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          hashBits.add(grayscale.getPixel(x, y).r > avg ? 1 : 0);
        }
      }

      // Convert to hex string
      final hash = hashBits.join('');
      return BigInt.parse(hash, radix: 2).toRadixString(16).padLeft(64, '0');
    } catch (e) {
      _logger.w('Failed to hash ${photo.filename}', error: e);
      return null;
    }
  }

  double _compareHashes(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 0.0;
    
    var matches = 0;
    for (var i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) matches++;
    }
    
    return matches / hash1.length;
  }

  /// Select the best photo from a group of similar photos
  Future<GooglePhotoMedia> _selectBestPhoto(
    List<GooglePhotoMedia> group,
    int maxBytes,
  ) async {
    var best = group.first;
    var bestScore = 0.0;

    for (final photo in group) {
      final score = await _calculateQualityScore(photo, maxBytes);
      _logger.d('Quality score for ${photo.filename}: $score');
      
      if (score > bestScore) {
        bestScore = score;
        best = photo;
      }
    }

    return best;
  }

  /// Calculate quality score based on:
  /// - Resolution (higher is better)
  /// - Sharpness (Laplacian variance)
  /// - Has faces (if face detection metadata available)
  Future<double> _calculateQualityScore(GooglePhotoMedia photo, int maxBytes) async {
    var score = 0.0;

    // Resolution score
    final width = int.tryParse(photo.mediaMetadata?.width ?? '0') ?? 0;
    final height = int.tryParse(photo.mediaMetadata?.height ?? '0') ?? 0;
    final megapixels = (width * height) / 1000000;
    score += megapixels * 10; // 10 points per megapixel

    // Try to measure sharpness
    try {
      final url = photo.getDownloadUrl(maxWidth: 256, maxHeight: 256);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final image = img.decodeImage(response.bodyBytes);
        if (image != null) {
          final sharpness = _calculateSharpness(image);
          score += sharpness * 50; // Up to 50 points for sharpness
        }
      }
    } catch (e) {
      _logger.w('Could not calculate sharpness for ${photo.filename}');
    }

    return score;
  }

  /// Calculate image sharpness using Laplacian variance
  double _calculateSharpness(img.Image image) {
    final grayscale = img.grayscale(image);
    final laplacian = _applyLaplacian(grayscale);
    
    // Calculate variance
    var sum = 0.0;
    var sumSq = 0.0;
    var count = 0;
    
    for (var y = 0; y < laplacian.height; y++) {
      for (var x = 0; x < laplacian.width; x++) {
        final val = laplacian.getPixel(x, y).r;
        sum += val;
        sumSq += val * val;
        count++;
      }
    }
    
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    
    // Normalize to 0-1 range (typical variance ranges from 0 to ~10000)
    return (variance / 10000).clamp(0.0, 1.0);
  }

  img.Image _applyLaplacian(img.Image source) {
    final result = img.Image(width: source.width - 2, height: source.height - 2);
    
    // Laplacian kernel
    const kernel = [
      [0, -1, 0],
      [-1, 4, -1],
      [0, -1, 0],
    ];
    
    for (var y = 1; y < source.height - 1; y++) {
      for (var x = 1; x < source.width - 1; x++) {
        var sum = 0.0;
        for (var ky = 0; ky < 3; ky++) {
          for (var kx = 0; kx < 3; kx++) {
            final px = source.getPixel(x + kx - 1, y + ky - 1).r;
            sum += px * kernel[ky][kx];
          }
        }
        result.setPixel(x - 1, y - 1, img.ColorFloat64.rgb(sum.abs(), sum.abs(), sum.abs()));
      }
    }
    
    return result;
  }
}
