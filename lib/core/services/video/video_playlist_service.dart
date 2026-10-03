import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoPlaylist {
  final String id;
  final String name;
  final List<String> videoIds;
  final DateTime createdAt;

  const VideoPlaylist({required this.id, required this.name, required this.videoIds, required this.createdAt});

  factory VideoPlaylist.fromMap(Map<String, dynamic> map) {
    return VideoPlaylist(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Playlist',
      videoIds: List<String>.from(map['videoIds'] as List? ?? const []),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'videoIds': videoIds,
        'createdAt': createdAt.toIso8601String(),
      };
}

class VideoPlaylistService {
  VideoPlaylistService._internal();
  static final VideoPlaylistService _instance = VideoPlaylistService._internal();
  factory VideoPlaylistService() => _instance;

  static const String _key = 'video_playlists';

  Future<List<VideoPlaylist>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => VideoPlaylist.fromMap(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('Video playlists decode error: $e');
      return [];
    }
  }

  Future<void> _save(List<VideoPlaylist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(playlists.map((p) => p.toMap()).toList()));
  }

  Future<String> createPlaylist(String name) async {
    final playlists = await getPlaylists();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    playlists.add(VideoPlaylist(id: id, name: name.trim(), videoIds: const [], createdAt: DateTime.now()));
    await _save(playlists);
    return id;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final old = playlists[index];
    playlists[index] = VideoPlaylist(id: old.id, name: name.trim(), videoIds: old.videoIds, createdAt: old.createdAt);
    await _save(playlists);
  }

  Future<void> deletePlaylist(String id) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == id);
    await _save(playlists);
  }

  Future<bool> addVideo(String playlistId, String videoId) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return false;
    final playlist = playlists[index];
    if (playlist.videoIds.contains(videoId)) return false;
    playlists[index] = VideoPlaylist(
      id: playlist.id, name: playlist.name,
      videoIds: [...playlist.videoIds, videoId], createdAt: playlist.createdAt,
    );
    await _save(playlists);
    return true;
  }

  Future<void> removeVideo(String playlistId, String videoId) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;
    final playlist = playlists[index];
    playlists[index] = VideoPlaylist(
      id: playlist.id, name: playlist.name,
      videoIds: playlist.videoIds.where((id) => id != videoId).toList(),
      createdAt: playlist.createdAt,
    );
    await _save(playlists);
  }
}
