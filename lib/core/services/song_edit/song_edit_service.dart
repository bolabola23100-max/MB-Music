import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongEditService {
  static final SongEditService _instance = SongEditService._internal();
  factory SongEditService() => _instance;
  SongEditService._internal();

  static const String _editsKey = 'song_edits';
  final ValueNotifier<int> editNotifier = ValueNotifier(0);

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<Map<int, Map<String, dynamic>>> _getAllEdits() async {
    final prefs = await _prefs;
    final String? editsJson = prefs.getString(_editsKey);
    if (editsJson == null) return {};
    try {
      final Map<String, dynamic> decoded = json.decode(editsJson);
      return decoded.map((key, value) => MapEntry(int.parse(key), Map<String, dynamic>.from(value)));
    } catch (e) {
      return {};
    }
  }

  Future<void> saveEdit({
    required int songId,
    required String title,
    required String artist,
    String? artPath,
  }) async {
    final edits = await _getAllEdits();
    edits[songId] = {
      'songId': songId,
      'title': title,
      'artist': artist,
      'artPath': artPath,
    };
    
    final prefs = await _prefs;
    // Store with string keys because JSON keys must be strings
    final Map<String, dynamic> toStore = edits.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_editsKey, json.encode(toStore));
    
    editNotifier.value++;
  }

  Future<Map<String, dynamic>?> getEdit(int songId) async {
    final edits = await _getAllEdits();
    return edits[songId];
  }
}
