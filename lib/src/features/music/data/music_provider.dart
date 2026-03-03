import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final musicFilesProvider = StateNotifierProvider<MusicFilesNotifier, List<File>>((ref) {
  return MusicFilesNotifier();
});

class MusicFilesNotifier extends StateNotifier<List<File>> {
  MusicFilesNotifier() : super([]);

  void addMusic(File file) {
    state = [...state, file];
  }

  void removeMusic(int index) {
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
  }

  void clear() {
    state = [];
  }
}
