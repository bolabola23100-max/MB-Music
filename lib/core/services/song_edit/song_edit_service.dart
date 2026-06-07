import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongEditService {
  static final SongEditService _instance = SongEditService._internal();
  factory SongEditService() => _instance;
  SongEditService._internal();

  static const String _editsKey = 'song_edits';
  final ValueNotifier<int> editNotifier = ValueNotifier(0);

  // ذاكرة مؤقتة للاحتفاظ بالتعديلات في الذاكرة لتسريع الوصول إليها
  Map<int, Map<String, dynamic>>? _cachedEdits;

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<Map<int, Map<String, dynamic>>> _getAllEdits() async {
    if (_cachedEdits != null) {
      return _cachedEdits!;
    }
    final prefs = await _prefs;
    final String? editsJson = prefs.getString(_editsKey);
    if (editsJson == null) {
      _cachedEdits = {};
      return _cachedEdits!;
    }
    try {
      final Map<String, dynamic> decoded = json.decode(editsJson);
      _cachedEdits = decoded.map((key, value) => MapEntry(int.parse(key), Map<String, dynamic>.from(value)));
      return _cachedEdits!;
    } catch (e) {
      _cachedEdits = {};
      return _cachedEdits!;
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
    _cachedEdits = edits;
    
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
