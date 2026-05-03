import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class SongEditDialog extends StatefulWidget {
  final SongModel song;

  const SongEditDialog({super.key, required this.song});

  @override
  State<SongEditDialog> createState() => _SongEditDialogState();
}

class _SongEditDialogState extends State<SongEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  String? _artPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist ?? '');
    _loadExistingEdit();
  }

  Future<void> _loadExistingEdit() async {
    final edit = await SongEditService().getEdit(widget.song.id);
    if (edit != null && mounted) {
      setState(() {
        _titleController.text = edit['title'] ?? widget.song.title;
        _artistController.text = edit['artist'] ?? widget.song.artist ?? '';
        _artPath = edit['artPath'];
      });
    }
  }

  Future<void> _pickImage() async {
    // طلب الـ permission أول
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب السماح بالوصول للصور'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _artPath = picked.path);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await SongEditService().saveEdit(
      songId: widget.song.id,
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      artPath: _artPath,
    );
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Song',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(12),
                    image: _artPath != null
                        ? DecorationImage(
                            image: FileImage(File(_artPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _artPath == null
                      ? Icon(
                          Icons.add_photo_alternate_rounded,
                          color: AppColors.white,
                          size: 36,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط لتغيير الصورة',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _titleController,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Song Title',
                  labelStyle: TextStyle(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.gray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _artistController,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Artist',
                  labelStyle: TextStyle(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.gray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
