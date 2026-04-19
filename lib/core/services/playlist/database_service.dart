import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _playlistsKey = 'playlists';
  static const String _songsKey = 'playlist_songs_';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Playlists logic
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final prefs = await _prefs;
    final String? playlistsJson = prefs.getString(_playlistsKey);
    if (playlistsJson == null) return [];
    
    try {
      final List<dynamic> list = json.decode(playlistsJson);
      final List<Map<String, dynamic>> playlists = List<Map<String, dynamic>>.from(list);
      
      // Calculate song count for each playlist
      for (var playlist in playlists) {
        final songs = await getSongsForPlaylist(playlist['id']);
        playlist['songCount'] = songs.length;
      }
      
      return playlists;
    } catch (e) {
      debugPrint('Error decoding playlists: $e');
      return [];
    }
  }

  Future<int> createPlaylist(String name) async {
    final prefs = await _prefs;
    final playlists = await getPlaylists(); // This will include songCount, but we don't save that
    
    final int newId = playlists.isEmpty ? 1 : (playlists.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    
    final newPlaylist = {
      'id': newId,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final List<Map<String, dynamic>> toSave = playlists.map((p) => {
      'id': p['id'],
      'name': p['name'],
      'createdAt': p['createdAt'],
    }).toList();
    
    toSave.add(newPlaylist);

    await prefs.setString(_playlistsKey, json.encode(toSave));
    return newId;
  }

  Future<void> renamePlaylist(int id, String newName) async {
    final prefs = await _prefs;
    final playlists = await getPlaylists();
    
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i]['id'] == id) {
        playlists[i]['name'] = newName;
        break;
      }
    }

    final List<Map<String, dynamic>> toSave = playlists.map((p) => {
      'id': p['id'],
      'name': p['name'],
      'createdAt': p['createdAt'],
    }).toList();

    await prefs.setString(_playlistsKey, json.encode(toSave));
  }

  Future<void> deletePlaylist(int id) async {
    final prefs = await _prefs;
    final playlists = await getPlaylists();
    
    final List<Map<String, dynamic>> toSave = playlists
        .where((p) => p['id'] != id)
        .map((p) => {
          'id': p['id'],
          'name': p['name'],
          'createdAt': p['createdAt'],
        }).toList();
        
    await prefs.setString(_playlistsKey, json.encode(toSave));
    await prefs.remove('$_songsKey$id');
  }

  // Songs logic
  Future<List<Map<String, dynamic>>> getSongsForPlaylist(int playlistId) async {
    final prefs = await _prefs;
    final String? songsJson = prefs.getString('$_songsKey$playlistId');
    if (songsJson == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(songsJson));
    } catch (e) {
      return [];
    }
  }

  Future<void> addSongToPlaylist(int playlistId, Map<String, dynamic> song) async {
    final prefs = await _prefs;
    final songs = await getSongsForPlaylist(playlistId);
    
    // Check for duplicates
    if (songs.any((s) => s['songId'] == song['songId'])) {
      return;
    }

    songs.add({
      ...song,
      'playlistId': playlistId,
      'addedAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString('$_songsKey$playlistId', json.encode(songs));
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final prefs = await _prefs;
    final songs = await getSongsForPlaylist(playlistId);
    songs.removeWhere((s) => s['songId'] == songId);
    await prefs.setString('$_songsKey$playlistId', json.encode(songs));
  }

  Future<void> removeSongFromAllPlaylists(int songId) async {
    final playlists = await getPlaylists();
    for (var p in playlists) {
      await removeSongFromPlaylist(p['id'], songId);
    }
  }
}
