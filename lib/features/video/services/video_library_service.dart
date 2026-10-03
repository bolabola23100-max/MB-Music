import 'package:photo_manager/photo_manager.dart';

class VideoLibraryService {
  const VideoLibraryService();

  Future<bool> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.video,
          mediaLocation: false,
        ),
      ),
    );
    return state.hasAccess;
  }

  Future<List<AssetPathEntity>> getVideoAlbums() {
    return PhotoManager.getAssetPathList(
      type: RequestType.video,
      hasAll: true,
    );
  }

  Future<List<AssetEntity>> getAlbumVideos(
    AssetPathEntity album, {
    int page = 0,
    int pageSize = 60,
  }) async {
    final videos = await album.getAssetListPaged(page: page, size: pageSize);
    videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return videos;
  }

  Future<List<AssetEntity>> getAllVideos() async {
    final albums = await getVideoAlbums();
    if (albums.isEmpty) return [];

    final all = albums.firstWhere(
      (album) => album.isAll,
      orElse: () => albums.first,
    );
    final count = await all.assetCountAsync;
    if (count <= 0) return [];

    final videos = await all.getAssetListRange(start: 0, end: count);
    videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return videos;
  }
}
