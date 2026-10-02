import 'package:photo_manager/photo_manager.dart';

class VideoLibraryService {
  const VideoLibraryService();

  Future<bool> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        android: AndroidPermission(
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
  }) {
    return album.getAssetListPaged(page: page, size: pageSize);
  }
}
