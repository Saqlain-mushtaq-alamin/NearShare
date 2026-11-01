import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/utils/formatters.dart';
import '../../transfer/domain/transfer_file.dart';
import '../domain/room.dart';
import '../domain/room_member.dart';
import 'room_provider.dart';

/// Active room view for both host and member.
class RoomActiveScreen extends ConsumerWidget {
  final String roomId;

  const RoomActiveScreen({super.key, required this.roomId});

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;

      final files = result.files
          .map(
            (file) => TransferFile(
              name: file.name,
              sizeInBytes: file.size,
              mimeType: 'application/octet-stream',
              localPath: file.path ?? '',
            ),
          )
          .toList();
      ref.read(roomProvider.notifier).addSelectedFiles(files);
    } catch (error) {
      debugPrint('[RoomActiveScreen] File picker error: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file picker.')),
        );
      }
    }
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final summary = await ref.read(roomProvider.notifier).sendFilesToAll();
    if (summary == null || !context.mounted) return;
    unawaited(context.push('/rooms/active/$roomId/transfer'));
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final state = ref.read(roomProvider);
    final isHost = state.isHost;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHost ? 'Close this room?' : 'Leave this room?'),
        content: Text(
          isHost
              ? 'Everyone joined will be notified and the room will end.'
              : 'You can rejoin later with the room code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isHost ? 'Close Room' : 'Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(roomProvider.notifier).leaveRoom();
    if (context.mounted) context.go('/rooms');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(roomProvider);
    final room = state.room;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: const Center(child: Text('This room is no longer active.')),
      );
    }

    final isHost = state.isHost;
    return Scaffold(
      appBar: AppBar(
        title: Text(isHost ? 'Your Room' : 'Room ${room.roomCode}'),
        actions: [
          IconButton(
            tooltip: isHost ? 'Close room' : 'Leave room',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _leave(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            96,
          ),
          children: [
            _RoomStatusBanner(room: room, isHost: isHost),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  'Members',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${room.memberCount}/${Room.maxMembers}',
                  style: AppTextStyles.cardSubtitle(theme),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: room.members.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No one has joined yet.',
                        style: AppTextStyles.muted(theme),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < room.members.length; i++) ...[
                          _MemberRow(member: room.members[i]),
                          if (i < room.members.length - 1)
                            const Divider(indent: 56, endIndent: 16),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isHost) ...[
              Row(
                children: [
                  Text(
                    'Files',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Choose files'),
                    onPressed: () => _pickFiles(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.selectedFiles.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Choose files to broadcast to the room.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.muted(theme),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Choose files'),
                          onPressed: () => _pickFiles(context, ref),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < state.selectedFiles.length; i++) ...[
                        _SelectedFileRow(
                          file: state.selectedFiles[i],
                          onRemove: () =>
                              ref.read(roomProvider.notifier).removeSelectedFile(i),
                        ),
                        if (i < state.selectedFiles.length - 1)
                          const Divider(indent: 56, endIndent: 16),
                      ],
                    ],
                  ),
                ),
              if (state.selectedFiles.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  fileCountLabel(
                    state.selectedFiles.length,
                    state.selectedSizeBytes,
                  ),
                  style: AppTextStyles.cardSubtitle(theme),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Send to All'),
                onPressed: room.members.isEmpty || state.selectedFiles.isEmpty
                    ? null
                    : () => _send(context, ref),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Waiting for the host to send files...',
                        style: AppTextStyles.muted(theme),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              icon: Icon(
                isHost ? Icons.power_settings_new_rounded : Icons.logout_rounded,
              ),
              label: Text(isHost ? 'Close Room' : 'Leave Room'),
              onPressed: () => _leave(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomStatusBanner extends StatelessWidget {
  const _RoomStatusBanner({required this.room, required this.isHost});

  final Room room;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final closed = room.isClosed;
    final color = closed ? palette.error : palette.primary;
    return Card(
      color: color.withValues(alpha: 0.08),
      child: ListTile(
        leading: Icon(
          closed ? Icons.lock_outline : Icons.groups_rounded,
          color: color,
        ),
        title: Text(
          closed
              ? 'Room closed'
              : isHost
                  ? 'Hosting room ${room.roomCode}'
                  : 'Connected to ${room.hostDeviceName}',
          style: AppTextStyles.cardTitle(theme),
        ),
        subtitle: Text(
          closed
              ? 'This room is no longer accepting transfers.'
              : 'Code ${room.roomCode} · ${room.memberCount} '
                  '${room.memberCount == 1 ? 'member' : 'members'}',
          style: AppTextStyles.cardSubtitle(theme),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final RoomMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final (IconData icon, Color color, String label) = switch (member.status) {
      RoomMemberStatus.completed => (
          Icons.check_circle_rounded,
          palette.primary,
          'Received'
        ),
      RoomMemberStatus.failed => (
          Icons.error_outline_rounded,
          palette.error,
          'Failed'
        ),
      RoomMemberStatus.disconnected => (
          Icons.wifi_off_rounded,
          palette.error,
          'Disconnected'
        ),
      RoomMemberStatus.sending => (
          Icons.sync_rounded,
          palette.secondary,
          'Sending'
        ),
      RoomMemberStatus.connected => (
          Icons.check_circle_outline_rounded,
          palette.primary,
          'Ready'
        ),
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: palette.secondaryContainer,
        child: Icon(
          AppIcons.platformFor(member.platform),
          color: palette.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(member.deviceName, style: AppTextStyles.cardTitle(theme)),
      subtitle: Text(
        '${member.ipAddress}:${member.port}',
        style: AppTextStyles.cardSubtitle(theme),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SelectedFileRow extends StatelessWidget {
  const _SelectedFileRow({required this.file, required this.onRemove});

  final TransferFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          AppIcons.fileFor(file.name, mimeType: file.mimeType),
          size: 20,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.cardTitle(theme),
      ),
      subtitle: Text(
        formatBytes(file.sizeInBytes),
        style: AppTextStyles.cardSubtitle(theme),
      ),
      trailing: IconButton(
        tooltip: 'Remove',
        icon: const Icon(Icons.close, size: 20),
        onPressed: onRemove,
      ),
    );
  }
}
