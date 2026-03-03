import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memento/src/core/photos/google_photos_service.dart';
import 'package:memento/src/features/albums/data/albums_provider.dart';
import 'package:memento/src/features/settings/data/credentials_provider.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(googleAuthStateProvider);
    final albumsAsync = ref.watch(albumsProvider);
    final credentialsAsync = ref.watch(credentialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(albumsProvider),
          ),
        ],
      ),
      body: credentialsAsync.when(
        data: (credentials) {
          // No credentials configured - show BYOC instructions
          if (!credentials.hasCredentials) {
            return _buildByocInstructions(context, ref);
          }
          
          // Has credentials - show normal flow
          return authState.when(
            data: (auth) {
              if (auth.error != null) {
                return _buildSignInError(context, ref, auth.error!);
              }
              if (!auth.isAuthenticated) {
                return _buildSignInPrompt(context, ref);
              }
              return albumsAsync.when(
                data: (albums) => _buildAlbumGrid(context, albums),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $err'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(albumsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Auth error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildByocInstructions(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.key_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Bring Your Own Credentials',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Memento uses a BYOC (Bring Your Own Credentials) model. '
              'You\'ll need to create your own Google OAuth credentials '
              'to access your Google Photos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Setup:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStep('1', 'Go to Google Cloud Console'),
                  _buildStep('2', 'Create a new project'),
                  _buildStep('3', 'Enable Photos Library API'),
                  _buildStep('4', 'Create OAuth credentials'),
                  _buildStep('5', 'Copy the Client ID'),
                  _buildStep('6', 'Paste it in Settings'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showDetailedInstructions(context),
              child: const Text('View Detailed Instructions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Sign-In Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(googleAuthStateProvider.notifier).signIn(),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/settings'),
              child: const Text('Check Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sign-In Setup'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Step 1: Create a Google Cloud Project',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Go to console.cloud.google.com and create a new project.'),
              SizedBox(height: 16),
              
              Text(
                'Step 2: Enable Photos Library API',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Search for "Photos Library API" in the API Library and enable it.'),
              SizedBox(height: 16),
              
              Text(
                'Step 3: Configure OAuth Consent Screen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Go to APIs & Services > OAuth consent screen. Select "External", fill in app name (Memento) and your email.'),
              SizedBox(height: 16),
              
              Text(
                'Step 4: Create OAuth Credentials',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Go to Credentials > Create Credentials > OAuth client ID:\n• For iOS: Select iOS, enter bundle ID (com.zachatrocity.memento)\n• For Android: Select Android, enter package name (com.zachatrocity.memento), add your SHA-1'),
              SizedBox(height: 16),
              
              Text(
                'Step 5: Add Test User',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Add your Google account email as a test user in the OAuth consent screen.'),
              SizedBox(height: 16),
              
              Text(
                'Step 6: Copy Client ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Copy the Client ID (looks like: 123-abc.apps.googleusercontent.com) and paste it in Settings.'),
            ],
          ),
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

  Widget _buildSignInPrompt(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Connect Google Photos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to access your photo albums',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(googleAuthStateProvider.notifier).signIn(),
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGrid(BuildContext context, List<GooglePhotoAlbum> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('No albums found'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return AlbumCard(
          album: album,
          onTap: () => context.push('/album/${album.id}'),
        );
      },
    );
  }
}

class AlbumCard extends StatelessWidget {
  final GooglePhotoAlbum album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: album.coverPhotoBaseUrl != null
                  ? Image.network(
                      '${album.coverPhotoBaseUrl}=w400-h400-c',
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.photo, size: 48, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (album.mediaItemsCount != null)
                    Text(
                      '${album.mediaItemsCount} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
