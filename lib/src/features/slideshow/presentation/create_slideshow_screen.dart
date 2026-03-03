import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memento/src/core/video/video_generation_service.dart';
import 'package:memento/src/features/music/data/music_provider.dart';
import 'package:share_plus/share_plus.dart';

class CreateSlideshowScreen extends ConsumerStatefulWidget {
  final List<String> selectedPhotoIds;

  const CreateSlideshowScreen({super.key, required this.selectedPhotoIds});

  @override
  ConsumerState<CreateSlideshowScreen> createState() => _CreateSlideshowScreenState();
}

class _CreateSlideshowScreenState extends ConsumerState<CreateSlideshowScreen> {
  Duration _photoDuration = const Duration(seconds: 3);
  Duration _transitionDuration = const Duration(milliseconds: 500);
  VideoResolution _resolution = VideoResolution.hd1080;
  bool _isGenerating = false;
  double _progress = 0;
  File? _generatedVideo;

  @override
  Widget build(BuildContext context) {
    final musicFiles = ref.watch(musicFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Slideshow'),
      ),
      body: _generatedVideo != null
          ? _buildResultView()
          : _isGenerating
              ? _buildProgressView()
              : _buildConfigurationView(musicFiles),
    );
  }

  Widget _buildConfigurationView(List<File> musicFiles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo count summary
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photos'),
              subtitle: Text('${widget.selectedPhotoIds.length} photos selected'),
            ),
          ),
          const SizedBox(height: 16),

          // Music section
          Text('Music', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...musicFiles.asMap().entries.map((entry) {
            return ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(entry.value.path.split('/').last),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => ref.read(musicFilesProvider.notifier).removeMusic(entry.key),
              ),
            );
          }),
          if (musicFiles.isEmpty)
            const ListTile(
              leading: Icon(Icons.music_off, color: Colors.grey),
              title: Text('No music added', style: TextStyle(color: Colors.grey)),
              subtitle: Text('Slideshow will have no audio'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickMusic,
            icon: const Icon(Icons.add),
            label: const Text('Add Music'),
          ),
          const SizedBox(height: 24),

          // Duration settings
          Text('Timing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Photo duration'),
            subtitle: Slider(
              value: _photoDuration.inSeconds.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_photoDuration.inSeconds}s',
              onChanged: (value) => setState(() {
                _photoDuration = Duration(seconds: value.toInt());
              }),
            ),
            trailing: Text('${_photoDuration.inSeconds}s'),
          ),
          ListTile(
            title: const Text('Transition duration'),
            subtitle: Slider(
              value: _transitionDuration.inMilliseconds.toDouble(),
              min: 0,
              max: 2000,
              divisions: 8,
              label: '${_transitionDuration.inMilliseconds}ms',
              onChanged: (value) => setState(() {
                _transitionDuration = Duration(milliseconds: value.toInt());
              }),
            ),
            trailing: Text('${_transitionDuration.inMilliseconds}ms'),
          ),
          const SizedBox(height: 24),

          // Resolution
          Text('Quality', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: VideoResolution.values.map((res) {
              final isSelected = _resolution == res;
              return ChoiceChip(
                label: Text(res.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _resolution = res),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Estimated duration
          Builder(
            builder: (context) {
              final estimatedDuration = Duration(
                seconds: widget.selectedPhotoIds.length * _photoDuration.inSeconds,
              );
              return Center(
                child: Text(
                  'Estimated video length: ${_formatDuration(estimatedDuration)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _generateVideo,
              child: const Text('Generate Slideshow'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 8,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Creating your slideshow...'),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Slideshow created!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _shareVideo,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickMusic() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        if (file.path != null) {
          ref.read(musicFilesProvider.notifier).addMusic(File(file.path!));
        }
      }
    }
  }

  Future<void> _generateVideo() async {
    setState(() {
      _isGenerating = true;
      _progress = 0;
    });

    try {
      final service = ref.read(videoGenerationServiceProvider);
      
      // TODO: Need to fetch actual photo media from selected IDs
      // For now this is a placeholder - we need to wire up the photos from the album screen
      
      final video = await service.generateSlideshow(
        photos: [], // TODO: Get photos from selected IDs
        musicPaths: ref.read(musicFilesProvider).map((f) => f.path).toList(),
        photoDuration: _photoDuration,
        transitionDuration: _transitionDuration,
        resolution: _resolution,
        onProgress: (progress) => setState(() => _progress = progress),
      );

      setState(() {
        _generatedVideo = video;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_generatedVideo != null) {
      await Share.shareXFiles([XFile(_generatedVideo!.path)]);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
