import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memento/src/core/photos/google_photos_service.dart';
import 'package:memento/src/core/photos/photo_dedup_service.dart';
import 'package:memento/src/features/albums/data/albums_provider.dart';

final selectedPhotosProvider = StateProvider<Set<String>>((ref) => {});

final dedupedPhotosProvider = FutureProvider.family<List<GooglePhotoMedia>, String>((ref, albumId) async {
  final photosAsync = ref.watch(albumPhotosProvider(albumId));
  final dedupService = PhotoDedupService();
  
  return photosAsync.when(
    data: (photos) => dedupService.deduplicateAndRank(photos),
    loading: () => [],
    error: (err, stack) => [],
  );
});

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(dedupedPhotosProvider(albumId));
    final selectedPhotos = ref.watch(selectedPhotosProvider);
    final originalPhotosAsync = ref.watch(albumPhotosProvider(albumId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Photos'),
        actions: [
          if (selectedPhotos.isNotEmpty)
            TextButton(
              onPressed: () => _showDedupInfo(context, ref),
              child: Text('${selectedPhotos.length} selected'),
            ),
        ],
      ),
      body: originalPhotosAsync.when(
        data: (originalPhotos) {
          final dedupedCount = photosAsync.valueOrNull?.length ?? originalPhotos.length;
          return Column(
            children: [
              if (originalPhotos.length != dedupedCount)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Smart dedup: ${originalPhotos.length} → $dedupedCount best photos',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: photosAsync.when(
                  data: (photos) => _buildPhotoGrid(context, ref, photos),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: selectedPhotos.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => context.push('/create', extra: selectedPhotos.toList()),
                  child: Text('Create Slideshow (${selectedPhotos.length})'),
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, WidgetRef ref, List<GooglePhotoMedia> photos) {
    final selectedPhotos = ref.watch(selectedPhotosProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = selectedPhotos.contains(photo.id);

        return GestureDetector(
          onTap: () {
            final newSet = Set<String>.from(selectedPhotos);
            if (isSelected) {
              newSet.remove(photo.id);
            } else {
              newSet.add(photo.id);
            }
            ref.read(selectedPhotosProvider.notifier).state = newSet;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                '${photo.baseUrl}=w300-h300-c',
                fit: BoxFit.cover,
              ),
              if (isSelected)
                Container(
                  color: Colors.blue.withAlpha(77),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check : null,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDedupInfo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Photo Selection'),
        content: const Text(
          'Memento automatically detected and removed duplicate photos, '
          'keeping only the best quality version of each.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
