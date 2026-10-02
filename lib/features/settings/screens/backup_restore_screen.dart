import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/backup/google_drive_backup_service.dart';
import 'package:music/core/widgets/dialog/my_snack_bar.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final GoogleDriveBackupService _backupService =
      GoogleDriveBackupService.instance;

  String? _email;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final user = await _backupService.getSignedInUser();
    if (!mounted) return;
    setState(() {
      _email = user?.email;
      _loading = false;
    });
  }

  Future<void> _connect() async {
    await _runAction(() async {
      final user = await _backupService.signIn();
      if (!mounted) return;
      setState(() => _email = user.email);
    });
  }

  Future<void> _backup() async {
    await _runAction(() async {
      await _backupService.backupToDrive();
      if (!mounted) return;
      _showMessage('backup_restore.backup_success'.tr());
    });
  }

  Future<void> _restore() async {
    await _runAction(() async {
      final restored = await _backupService.restoreFromDrive();
      if (!mounted) return;

      _showMessage(
        restored
            ? 'backup_restore.restore_success'.tr()
            : 'backup_restore.no_backup'.tr(),
      );
    });
  }

  Future<void> _disconnect() async {
    await _runAction(() async {
      await _backupService.disconnect();
      if (!mounted) return;
      setState(() => _email = null);
      _showMessage('backup_restore.disconnected'.tr());
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e is GoogleDriveBackupException
            ? e.message
            : 'backup_restore.operation_failed'.tr(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message) {
    MySnackBar(
      context: context,
    ).showSnackBar(message, AppColors.blue);
  }

  @override
  Widget build(BuildContext context) {
    final connected = _email != null;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'backup_restore.title'.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(connected),
          const SizedBox(height: 24),
          _buildTile(
            icon: connected
                ? Icons.cloud_done_rounded
                : Icons.cloud_outlined,
            title: connected
                ? 'backup_restore.connected'.tr()
                : 'backup_restore.connect'.tr(),
            subtitle: connected
                ? _email!
                : 'backup_restore.connect_desc'.tr(),
            onTap: connected ? null : _connect,
          ),
          if (connected) ...[
            _buildTile(
              icon: Icons.backup_rounded,
              title: 'backup_restore.backup'.tr(),
              subtitle: 'backup_restore.backup_desc'.tr(),
              onTap: _backup,
            ),
            _buildTile(
              icon: Icons.restore_rounded,
              title: 'backup_restore.restore'.tr(),
              subtitle: 'backup_restore.restore_desc'.tr(),
              onTap: _restore,
            ),
            _buildTile(
              icon: Icons.link_off_rounded,
              title: 'backup_restore.disconnect'.tr(),
              subtitle: 'backup_restore.disconnect_desc'.tr(),
              onTap: _disconnect,
            ),
          ],
          if (_busy || _loading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool connected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_rounded,
              color: AppColors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              connected
                  ? 'backup_restore.cloud_ready'.tr()
                  : 'backup_restore.cloud_not_connected'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.gray.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 7,
        ),
        leading: Icon(icon, color: AppColors.blue, size: 26),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        trailing: onTap == null
            ? null
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.white,
              ),
        onTap: _busy ? null : onTap,
      ),
    );
  }
}
