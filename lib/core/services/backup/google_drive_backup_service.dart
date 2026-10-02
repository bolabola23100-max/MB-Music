import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveBackupException implements Exception {
  final String message;

  const GoogleDriveBackupException(this.message);

  @override
  String toString() => message;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService._internal();

  static final GoogleDriveBackupService instance =
      GoogleDriveBackupService._internal();

  static const String _backupFileName = 'MB_Music_Backup.json';
  static const String _backupVersion = '1';
  static const List<String> _scopes = <String>[
    drive.DriveApi.driveFileScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;
  GoogleSignInAccount? _currentUser;

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    const serverClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    );

    if (serverClientId.isEmpty) {
      throw const GoogleDriveBackupException(
        'Google Drive is not configured yet. '
        'Set GOOGLE_SERVER_CLIENT_ID before building the app.',
      );
    }

    await _googleSignIn.initialize(serverClientId: serverClientId);
  }

  Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();

    final lightweightUser = await _googleSignIn
        .attemptLightweightAuthentication();
    final user = lightweightUser ?? await _googleSignIn.authenticate();

    _currentUser = user;
    await _authorizeDrive(user);
    return user;
  }

  Future<GoogleSignInAccount?> getSignedInUser() async {
    try {
      await _ensureInitialized();
      _currentUser ??= await _googleSignIn.attemptLightweightAuthentication();
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _authorizeDrive(GoogleSignInAccount user) async {
    final authorization = await user.authorizationClient.authorizationForScopes(
      _scopes,
    );

    if (authorization == null) {
      await user.authorizationClient.authorizeScopes(_scopes);
    }
  }

  Future<drive.DriveApi> _createDriveApi() async {
    final user = _currentUser ?? await signIn();
    final authorization = await user.authorizationClient.authorizationForScopes(
      _scopes,
    );

    final grantedAuthorization =
        authorization ?? await user.authorizationClient.authorizeScopes(_scopes);

    final authClient = grantedAuthorization.authClient(scopes: _scopes);
    return drive.DriveApi(authClient);
  }

  Future<Map<String, dynamic>> _createBackupPayload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final data = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      if (_shouldSkipKey(key)) continue;

      final value = prefs.get(key);
      if (value is String ||
          value is int ||
          value is double ||
          value is bool ||
          value is List<String>) {
        data[key] = value;
      }
    }

    return <String, dynamic>{
      'format': 'mb_music_backup',
      'version': _backupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
  }

  bool _shouldSkipKey(String key) {
    return key == 'app_version' ||
        key == 'review_action_count' ||
        key == 'notification_message_index';
  }

  Future<void> backupToDrive() async {
    final payload = await _createBackupPayload();
    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(payload)),
    );

    final api = await _createDriveApi();

    final existing = await api.files.list(
      q: "name = '$_backupFileName' and trashed = false",
      spaces: 'drive',
      pageSize: 10,
      $fields: 'files(id,name,modifiedTime)',
    );

    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final files = existing.files ?? <drive.File>[];
    final existingFile = files.isEmpty ? null : files.first;

    if (existingFile?.id != null) {
      await api.files.update(
        drive.File(
          name: _backupFileName,
          mimeType: 'application/json',
        ),
        existingFile!.id!,
        uploadMedia: media,
      );
    } else {
      await api.files.create(
        drive.File(
          name: _backupFileName,
          mimeType: 'application/json',
        ),
        uploadMedia: media,
      );
    }
  }

  Future<bool> restoreFromDrive() async {
    final api = await _createDriveApi();

    final result = await api.files.list(
      q: "name = '$_backupFileName' and trashed = false",
      spaces: 'drive',
      pageSize: 10,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );

    final files = result.files ?? <drive.File>[];
    if (files.isEmpty || files.first.id == null) {
      return false;
    }

    final response = await api.files.get(
      files.first.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is! drive.Media) {
      throw const GoogleDriveBackupException(
        'The backup file could not be downloaded.',
      );
    }

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'mb_music_backup' ||
        decoded['version'] != _backupVersion ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const GoogleDriveBackupException(
        'This file is not a valid MB Music backup.',
      );
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    await _restorePreferences(data);
    return true;
  }

  Future<void> _restorePreferences(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List) {
        final strings = value.whereType<String>().toList();
        if (strings.length == value.length) {
          await prefs.setStringList(key, strings);
        }
      }
    }

    await prefs.reload();
  }

  Future<void> disconnect() async {
    await _ensureInitialized();
    _currentUser = null;
    await _googleSignIn.disconnect();
  }
}
