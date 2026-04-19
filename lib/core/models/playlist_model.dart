class PlaylistModels {
  final int? id;
  final String name;
  final int songCount;
  final DateTime? createdAt;

  PlaylistModels({
    this.id,
    required this.name,
    this.songCount = 0,
    this.createdAt,
  });

  // ✅ fromMap
  factory PlaylistModels.fromMap(Map<String, dynamic> map) {
    return PlaylistModels(
      id: map['id'],
      name: map['name'] ?? '',
      songCount: map['songCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

class PlaylistSong {
  final int? id;
  final int playlistId;
  final int songId;
  final String path;
  final String title;
  final String artist;
  final String? album;
  final DateTime? addedAt;

  PlaylistSong({
    this.id,
    required this.playlistId,
    required this.songId,
    required this.path,
    required this.title,
    required this.artist,
    this.album,
    this.addedAt,
  });

  // ✅ fromMap
  factory PlaylistSong.fromMap(Map<String, dynamic> map) {
    return PlaylistSong(
      id: map['id'],
      playlistId: map['playlistId'] ?? 0,
      songId: map['songId'] ?? 0,
      path: map['songPath'] ?? '',
      title: map['songTitle'] ?? 'Unknown',
      artist: map['songArtist'] ?? 'Unknown Artist',
      album: map['songAlbum'],
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'])
          : null,
    );
  }
}
