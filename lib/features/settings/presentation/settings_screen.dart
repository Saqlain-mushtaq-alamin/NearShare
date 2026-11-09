import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/app_lock.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/utils/formatters.dart';
import '../../history/presentation/history_provider.dart';
import '../../onboarding/application/onboarding_provider.dart';
import '../../transfer/data/file_storage_service.dart';
import '../application/settings_provider.dart';

/// Full app configuration: identity, storage, transfer behaviour, and app
/// preferences. Every switch persists immediately.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final appLock = ref.watch(appLockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), scrolledUnderElevation: 2),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _Section(
                  title: 'DEVICE',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.devices_other_outlined),
                      title: const Text('Device name'),
                      subtitle: Text(
                        settings.deviceName.isEmpty
                            ? 'Loading…'
                            : settings.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _editDeviceName(context, ref, settings),
                    ),
                    if (settings.deviceId.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.fingerprint),
                        title: const Text('Device ID'),
                        subtitle: Text(
                          settings.deviceId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Copy device ID',
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          onPressed: () => _copyDeviceId(context, settings),
                        ),
                      ),
                  ],
                ),
                _Section(
                  title: 'STORAGE',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder_open_outlined),
                      title: const Text('Save location'),
                      subtitle: Text(
                        settings.customSaveLocation ?? 'NearShare/Received',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 22),
                      onTap: () => _pickSaveLocation(context, ref),
                    ),
                    ListTile(
                      leading: const Icon(Icons.pie_chart_outline),
                      title: const Text('NearShare storage'),
                      subtitle: Text(
                        ref.watch(nearShareStorageUsageProvider).when(
                              data: (bytes) => formatBytes(bytes),
                              loading: () => 'Calculating…',
                              error: (_, __) => 'Unavailable',
                            ),
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'TRANSFER',
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.flash_auto_outlined),
                      title: const Text('Auto-accept known devices'),
                      subtitle: const Text(
                        'Skip the confirmation when a trusted device sends files.',
                      ),
                      value: settings.autoAcceptKnownDevices,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setAutoAcceptKnownDevices(value),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.enhanced_encryption_outlined),
                      title: const Text('Encrypt transfers'),
                      subtitle: const Text(
                        'Protect file data in transit between devices.',
                      ),
                      value: settings.transferEncryption,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setTransferEncryption(value),
                    ),
                  ],
                ),
                _Section(
                  title: 'APP',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: const Text('Appearance'),
                      trailing: Text(
                        settings.themePreference.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _pickTheme(context, ref, settings),
                    ),
                    const ListTile(
                      leading: Icon(Icons.translate_outlined),
                      title: Text('Language'),
                      subtitle: Text('System default'),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.lock_outline),
                      title: const Text('App lock'),
                      subtitle: const Text(
                        'Require your device PIN, password, or biometrics.',
                      ),
                      value: appLock.isEnabled,
                      onChanged: appLock.isBusy
                          ? null
                          : (value) async {
                              final ok = await ref
                                  .read(appLockProvider.notifier)
                                  .setEnabled(value);
                              if (!ok && context.mounted) {
                                final error =
                                    ref.read(appLockProvider).errorMessage;
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                }
                              }
                            },
                    ),
                    if (appLock.isEnabled)
                      ListTile(
                        leading: const Icon(Icons.lock_clock_outlined),
                        title: const Text('Lock now'),
                        subtitle: const Text(
                          'Lock NearShare until you authenticate again.',
                        ),
                        onTap: () => ref.read(appLockProvider.notifier).lock(),
                      ),
                    ListTile(
                      leading: const Icon(Icons.replay_outlined),
                      title: const Text('Replay welcome tour'),
                      onTap: () => _replayOnboarding(context, ref),
                    ),
                  ],
                ),
                _Section(
                  title: 'DATA',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Transfer history'),
                      subtitle: const Text('Everything stays on this device'),
                      trailing: const Icon(Icons.chevron_right, size: 22),
                      onTap: () => context.push('/history'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_sweep_outlined,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Clear transfer history',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text('Files themselves are not deleted'),
                      onTap: () => _confirmClearHistory(context, ref),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: const Text('Clear cache'),
                      subtitle: const Text('Remove temporary transfer data'),
                      onTap: () => _confirmClearCache(context, ref),
                    ),
                  ],
                ),
                _Section(
                  title: 'ABOUT',
                  children: [
                    const ListTile(
                      leading: Icon(Icons.cloud_off_outlined),
                      title:
                          Text('We don\u2019t collect your data. Full stop.'),
                      subtitle: Text(
                        'No account, no cloud, no analytics — your files never '
                        'leave your Wi-Fi network.',
                      ),
                    ),
                    const _VersionTile(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy policy'),
                      trailing: const Icon(Icons.chevron_right, size: 22),
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Open source licenses'),
                      trailing: const Icon(Icons.chevron_right, size: 22),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'NearShare',
                        applicationLegalese:
                            'MIT licensed. Built with Flutter and open-source '
                            'packages.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Made with care. Shared freely.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy policy'),
        content: const SingleChildScrollView(
          child: Text(
            'NearShare does not collect, transmit, sell, or share personal '
            'data. There is no account, cloud service, analytics SDK, or '
            'telemetry.\n\n'
            'Files are sent directly between devices on your local network. '
            'The app stores device identity, transfer history, settings, and '
            'security keys on this device. Secrets are stored in the platform '
            'secure store and local databases are encrypted.\n\n'
            'NearShare advertises a local mDNS record so nearby devices can '
            'find it. Anyone on your network may be able to see the device '
            'name and a TLS certificate fingerprint.\n\n'
            'The full policy is in PRIVACY.md in the NearShare repository.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDeviceName(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final controller = TextEditingController(text: settings.deviceName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Device name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setDeviceName(newName);
    }
  }

  void _copyDeviceId(BuildContext context, SettingsState settings) {
    Clipboard.setData(ClipboardData(text: settings.deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device ID copied.')),
    );
  }

  Future<void> _pickSaveLocation(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Choose a folder…'),
              subtitle: const Text('Pick anywhere this device can write to'),
              onTap: () async {
                final path = await FilePicker.platform.getDirectoryPath();
                if (ctx.mounted) Navigator.of(ctx).pop(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Use default'),
              subtitle: const Text('NearShare/Received'),
              onTap: () => Navigator.of(ctx).pop(''),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await notifier.setSaveLocation(chosen.isEmpty ? null : chosen);
    }
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final selected = await showDialog<ThemePreference>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          for (final preference in ThemePreference.values)
            RadioListTile<ThemePreference>(
              title: Text(preference.label),
              value: preference,
              groupValue: settings.themePreference,
              onChanged: (value) => Navigator.of(ctx).pop(value),
            ),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(settingsProvider.notifier).setThemePreference(selected);
    }
  }

  Future<void> _replayOnboarding(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).reset();
    if (context.mounted) context.go('/onboarding');
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'Every transfer record on this device will be removed. '
          'The files themselves are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAllHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer history cleared.')),
        );
      }
    }
  }

  Future<void> _confirmClearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'Temporary files left over from interrupted transfers will be '
          'deleted. Received files stay where they are.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _clearTempFiles();
      ref.invalidate(nearShareStorageUsageProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared.')),
        );
      }
    }
  }

  Future<void> _clearTempFiles() async {
    final tempDirectory =
        Directory(await FileStorageService().getTempDirectory());
    if (!await tempDirectory.exists()) return;

    await for (final entity in tempDirectory.list()) {
      try {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      } catch (_) {
        // A locked temp file is not worth failing the whole sweep over.
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(title, style: AppTextStyles.sectionLabel(theme)),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(indent: 56, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends ConsumerWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value ?? '—';
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Version'),
      trailing: Text(
        version,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
