import 'package:flutter/foundation.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/playlist/database_service.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  final DatabaseService _dbService = DatabaseService();

  Future<int> createPlaylist(String name) async {
    try {
      final id = await _dbService.createPlaylist(name);
      debugPrint('✅ Playlist created: $name (id: $id)');
      return id;
    } catch (e) {
      debugPrint('❌ Error creating playlist: $e');
      return -1;
    }
  }

  Future<List<PlaylistModels>> getPlaylists() async {
    try {
      final results = await _dbService.getPlaylists();
      debugPrint('📋 Found ${results.length} playlists');
      return results.map((map) => PlaylistModels.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting playlists: $e');
      return [];
    }
  }

  Future<List<PlaylistModels>> getAllPlaylists() => getPlaylists();

  Future<bool> addSongToPlaylist(int playlistId, SongModel song) async {
    try {
      final songs = await _dbService.getSongsForPlaylist(playlistId);

      if (songs.any((s) => s['songId'] == song.id)) {
        debugPrint('⚠️ Song already in playlist');
        return false;
      }

      await _dbService.addSongToPlaylist(playlistId, {
        'songId': song.id,
        'songPath': song.data,
        'songTitle': song.title,
        'songArtist': song.artist ?? 'Unknown Artist',
        'songAlbum': song.album ?? 'Unknown Album',
      });
      
      debugPrint('✅ Song added: ${song.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding song: $e');
      return false;
    }
  }

  Future<int> addSongsToPlaylist(int playlistId, List<SongModel> songs) async {
    int addedCount = 0;
    for (final song in songs) {
      final success = await addSongToPlaylist(playlistId, song);
      if (success) addedCount++;
    }
    return addedCount;
  }

  Future<List<PlaylistSong>> getPlaylistSongs(int playlistId) async {
    try {
      final results = await _dbService.getSongsForPlaylist(playlistId);
      return results.map((map) => PlaylistSong.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting songs: $e');
      return [];
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _dbService.removeSongFromPlaylist(playlistId, songId);
  }

  Future<void> removeSongFromAllPlaylists(int songId) async {
    try {
      await _dbService.removeSongFromAllPlaylists(songId);
      debugPrint('🗑️ Removed song $songId from all playlists');
    } catch (e) {
      debugPrint('❌ Error removing song from playlists: $e');
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _dbService.deletePlaylist(playlistId);
  }

  Future<void> renamePlaylist(int playlistId, String newName) async {
    await _dbService.renamePlaylist(playlistId, newName);
  }
}
