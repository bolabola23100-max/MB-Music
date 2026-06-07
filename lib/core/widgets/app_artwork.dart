import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AppArtwork extends StatefulWidget {
  final int id;
  final double size;
  final double borderRadius;
  final bool isCurrent;
  final String? customArtPath;

  final bool highQuality;

  const AppArtwork({
    super.key,
    required this.id,
    this.size = 50,
    this.borderRadius = 10,
    this.isCurrent = false,
    this.customArtPath,
    this.highQuality = false,
  });

  @override
  State<AppArtwork> createState() => _AppArtworkState();
}

class _AppArtworkState extends State<AppArtwork> {
  static final Map<String, Uint8List?> _artworkCache = {};
  static final Map<String, Future<Uint8List?>> _pendingQueries = {};

  Uint8List? _bytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant AppArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.highQuality != widget.highQuality ||
        oldWidget.customArtPath != widget.customArtPath) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    if (widget.customArtPath != null) {
      if (mounted) {
        setState(() {
          _bytes = null;
          _isLoading = false;
        });
      }
      return;
    }

    final cacheKey = "${widget.id}_${widget.highQuality ? 'high' : 'low'}";

    if (_artworkCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _bytes = _artworkCache[cacheKey];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _bytes = null;
        _isLoading = true;
      });
    }

    Future<Uint8List?> future;
    if (_pendingQueries.containsKey(cacheKey)) {
      future = _pendingQueries[cacheKey]!;
    } else {
      future = OnAudioQuery()
          .queryArtwork(
            widget.id,
            ArtworkType.AUDIO,
            format: ArtworkFormat.JPEG,
            size: widget.highQuality ? 800 : 200,
          )
          .then((bytes) {
            _artworkCache[cacheKey] = bytes;
            _pendingQueries.remove(cacheKey);
            return bytes;
          })
          .catchError((_) {
            _artworkCache[cacheKey] = null;
            _pendingQueries.remove(cacheKey);
            return null;
          });
      _pendingQueries[cacheKey] = future;
    }

    future.then((bytes) {
      if (mounted && widget.customArtPath == null) {
        setState(() {
          _bytes = bytes;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (widget.customArtPath != null) {
      imageWidget = Image.file(
        File(widget.customArtPath!),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        cacheWidth: widget.highQuality ? 800 : 200,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (_isLoading && _bytes == null) {
      imageWidget = _buildPlaceholder();
    } else if (_bytes != null) {
      imageWidget = Image.memory(
        _bytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        cacheWidth: widget.highQuality ? 800 : 200,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: AppColors.gray,
        border: Border.all(
          color: widget.isCurrent ? AppColors.gray : Colors.transparent,
          width: widget.isCurrent ? 2 : 0,
        ),
        boxShadow: widget.isCurrent
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.25),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: AppColors.gray,
      ),
      child: Icon(
        Icons.music_note,
        size: (widget.size * 0.6).clamp(10.0, 100.0),
        color: AppColors.blue,
      ),
    );
  }
}
