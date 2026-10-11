import 'package:photo_manager/photo_manager.dart';

class VideoLibraryService {
  const VideoLibraryService();

  static const int pageSize = 60;

  Future<bool> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(type: RequestType.video, mediaLocation: false),
      ),
    );
    return state.hasAccess;
  }

  Future<List<AssetPathEntity>> getVideoAlbums() => PhotoManager.getAssetPathList(type: RequestType.video, hasAll: true);

  Future<List<AssetEntity>> getAlbumVideos(AssetPathEntity album, {int page = 0, int pageSize = VideoLibraryService.pageSize}) async {
    final videos = await album.getAssetListPaged(page: page, size: pageSize);
    videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return videos;
  }

  Future<int> getAlbumVideoCount(AssetPathEntity album) => album.assetCountAsync;

  Future<List<AssetEntity>> getAllVideos() async {
    final albums = await getVideoAlbums();
    if (albums.isEmpty) return [];
    final all = albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
    final count = await all.assetCountAsync;
    if (count <= 0) return [];

    final result = <AssetEntity>[];
    for (var page = 0; page * pageSize < count; page++) {
      final batch = await all.getAssetListPaged(page: page, size: pageSize);
      if (batch.isEmpty) break;
      result.addAll(batch);
      if (batch.length < pageSize) break;
      await Future<void>.delayed(Duration.zero);
    }
    result.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return result;
  }
}
