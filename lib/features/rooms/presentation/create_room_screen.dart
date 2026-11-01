import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/room.dart';
import '../domain/room_member.dart';
import 'room_provider.dart';

/// Host view: QR code, join code, live member list and broadcast controls.
class CreateRoomScreen extends ConsumerWidget {
  const CreateRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(roomProvider);
    final room = state.room;
    final notifier = ref.read(roomProvider.notifier);

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Room')),
        body: Center(
          child: state.isBusy
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No active room', style: AppTextStyles.muted(theme)),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => notifier.createRoom(),
                      child: const Text('Create Room'),
                    ),
                  ],
                ),
        ),
      );
    }

    final joinUri = notifier.joinUri;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        actions: [
          IconButton(
            tooltip: 'Close room',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmClose(context, ref, room),
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
            Text(
              'Scan to join',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: joinUri == null
                      ? SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: Text(
                              'QR code unavailable on this network',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.muted(theme),
                            ),
                          ),
                        )
                      : QrImageView(
                          key: const Key('room-qr-code'),
                          data: joinUri,
                          size: 220,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CodeCard(room: room),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(
                  'In this room',
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
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.wifi_tethering_rounded,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Waiting for devices to join...',
                            style: AppTextStyles.muted(theme),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < room.members.length; i++) ...[
                          _MemberTile(member: room.members[i]),
                          if (i < room.members.length - 1)
                            const Divider(indent: 56, endIndent: 16),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send Files'),
              onPressed: room.members.isEmpty
                  ? null
                  : () => context.push('/rooms/active/${room.roomId}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.power_settings_new_rounded),
              label: const Text('Close Room'),
              onPressed: () => _confirmClose(context, ref, room),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClose(
    BuildContext context,
    WidgetRef ref,
    Room room,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close this room?'),
        content: const Text(
          'Everyone joined will be notified and the room will end.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep open'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Close Room'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(roomProvider.notifier).closeRoom();
    if (context.mounted) context.go('/rooms');
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ROOM CODE', style: AppTextStyles.sectionLabel(theme)),
                  const SizedBox(height: 4),
                  Text(
                    room.roomCode,
                    key: const Key('room-code'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Type this code on another device',
                    style: AppTextStyles.cardSubtitle(theme),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Copy code',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: room.roomCode));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Room code copied')),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final RoomMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = member.status != RoomMemberStatus.disconnected;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          AppIcons.platformFor(member.platform),
          color: theme.colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(member.deviceName, style: AppTextStyles.cardTitle(theme)),
      subtitle: Text(
        connected ? 'Ready' : 'Disconnected',
        style: AppTextStyles.cardSubtitle(theme),
      ),
      trailing: Icon(
        connected ? Icons.check_circle : Icons.error_outline,
        color: connected ? theme.colorScheme.primary : theme.colorScheme.error,
        size: 20,
      ),
    );
  }
}
