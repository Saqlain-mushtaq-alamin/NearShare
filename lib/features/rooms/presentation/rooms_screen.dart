import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/room.dart';
import 'room_provider.dart';
import 'room_state.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    await ref.read(roomProvider.notifier).createRoom();
    if (!context.mounted) return;
    final state = ref.read(roomProvider);
    if (state.isInRoom) {
      unawaited(context.push('/rooms/create'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(roomProvider);

    ref.listen<String?>(
        roomProvider.select((s) => s.errorMessage), (previous, next) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next)));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        scrolledUnderElevation: 2,
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
            _RoomHero(theme: theme),
            const SizedBox(height: AppSpacing.lg),
            if (state.isInRoom) ...[
              _ActiveRoomCard(
                room: state.room!,
                role: state.role,
                onOpen: () => context.push(
                  state.isHost
                      ? '/rooms/create'
                      : '/rooms/active/${state.room!.roomId}',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _ActionCard(
              icon: Icons.add_circle_outline,
              title: 'Create Room',
              subtitle: 'Host a group and share with everyone at once',
              primary: true,
              onTap: state.isBusy ? null : () => _createRoom(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionCard(
              icon: Icons.qr_code_scanner,
              title: 'Join Room',
              subtitle: 'Scan a QR code or enter a 6-digit code',
              onTap: () => context.push('/rooms/join'),
            ),
            const SizedBox(height: AppSpacing.xl),
            _HowItWorks(theme: theme),
          ],
        ),
      ),
    );
  }
}

class _RoomHero extends StatelessWidget {
  const _RoomHero({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4BCF), Color(0xFF2F6BF0)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with the whole room',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'One host broadcasts files to every joined device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primary
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(
                  icon,
                  color: primary
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle(theme)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.cardSubtitle(theme)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveRoomCard extends StatelessWidget {
  const _ActiveRoomCard({
    required this.room,
    required this.role,
    required this.onOpen,
  });

  final Room room;
  final RoomRole role;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    return Card(
      color: palette.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: palette.primary,
          child: Icon(
            role == RoomRole.host ? Icons.wifi_tethering : Icons.groups,
            color: palette.onPrimary,
          ),
        ),
        title: Text(
          role == RoomRole.host ? 'Your room is live' : 'Room ${room.roomCode}',
          style: AppTextStyles.cardTitle(theme),
        ),
        subtitle: Text(
          'Code ${room.roomCode} · ${room.memberCount} '
          '${room.memberCount == 1 ? 'member' : 'members'}',
          style: AppTextStyles.cardSubtitle(theme),
        ),
        trailing: FilledButton(
          onPressed: onOpen,
          child: const Text('Open'),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW ROOMS WORK',
          style: AppTextStyles.sectionLabel(theme),
        ),
        const SizedBox(height: AppSpacing.md),
        const _StepRow(
          icon: Icons.person_add_alt_1_outlined,
          text: 'One device creates a room and shows a QR code.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _StepRow(
          icon: Icons.qr_code_2_outlined,
          text: 'Everyone else joins by scanning or typing the code.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _StepRow(
          icon: AppIcons.send,
          text: 'The host sends files to every member in parallel.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _StepRow(
          icon: Icons.power_settings_new_outlined,
          text: 'The room closes automatically when the host leaves.',
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: AppTextStyles.muted(theme)),
        ),
      ],
    );
  }
}
