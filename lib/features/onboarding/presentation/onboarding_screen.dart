import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/permission_service.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/app_logo.dart';
import '../application/onboarding_provider.dart';

final permissionStatusesProvider =
    FutureProvider.autoDispose<Map<Permission, PermissionStatus>>((ref) {
  return ref.watch(permissionServiceProvider).statuses();
});

/// Three-step first-launch flow: welcome → permissions → device name.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _stepCount = 3;

  final _pageController = PageController();
  final _nameController = TextEditingController();
  var _page = 0;
  var _nameTouched = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    await ref
        .read(onboardingProvider.notifier)
        .completeOnboarding(deviceName: name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onboarding = ref.watch(onboardingProvider);

    // Keep the name field in sync with the suggestion until the user edits it.
    ref.listen(onboardingProvider.select((s) => s.deviceName), (prev, next) {
      if (!_nameTouched && next != null && _nameController.text.isEmpty) {
        _nameController.text = next;
      }
    });
    if (!_nameTouched && _nameController.text.isEmpty && onboarding.deviceName != null) {
      _nameController.text = onboarding.deviceName!;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(
                children: [
                  const Spacer(),
                  if (_page < _stepCount - 1)
                    TextButton(
                      key: const Key('onboarding-skip'),
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _WelcomePage(
                    theme: theme,
                    onExplore: () => _goTo(1),
                  ),
                  _PermissionsPage(theme: theme),
                  _DeviceNamePage(
                    theme: theme,
                    controller: _nameController,
                    onChanged: () => _nameTouched = true,
                    suggestedName: onboarding.deviceName,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  _PageDots(current: _page, count: _stepCount),
                  const SizedBox(height: AppSpacing.lg),
                  _bottomActions(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions(ThemeData theme) {
    if (_page == 0) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('onboarding-get-started'),
          onPressed: () => _goTo(1),
          child: const Text('Get Started'),
        ),
      );
    }

    final isLast = _page == _stepCount - 1;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _goTo(_page - 1),
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: FilledButton(
            key: Key(isLast ? 'onboarding-done' : 'onboarding-continue'),
            onPressed: isLast ? _finish : () => _goTo(_page + 1),
            child: Text(isLast ? 'Done' : 'Continue'),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? primary : primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.theme, required this.onExplore});

  final ThemeData theme;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    // Centered when the viewport is tall enough; scrolls on short screens so
    // nothing (like the Skip affordance context) ever clips.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: const AppLogo(
                        size: 88,
                        padding: 16,
                        background: Color(0xFF1A4BCF),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'NearShare',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Send files. No internet.\nNo account. No ads.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _Promise(icon: Icons.wifi_off_rounded, text: 'Works on any local network — even without internet.'),
                  const _Promise(icon: Icons.lock_outline_rounded, text: 'Files travel device to device. Nothing hits a server.'),
                  const _Promise(icon: Icons.code_rounded, text: 'Open source. No analytics, no tracking, no surprises.'),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: TextButton.icon(
                      onPressed: onExplore,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('What it needs'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsPage extends ConsumerWidget {
  const _PermissionsPage({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(permissionServiceProvider);
    final requirements = service.requirements();
    final statuses = ref.watch(permissionStatusesProvider).value;

    if (requirements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nothing to set up',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This platform doesn\u2019t need any special permissions. '
              'You\u2019re ready to send and receive.',
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(theme),
            ),
          ],
        ),
      );
    }

    final pending = [
      for (final requirement in requirements)
        if (!(statuses?[requirement.permission]?.isGranted ?? false)) requirement,
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        Text(
          'A couple of things first',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'NearShare only asks for what it needs to find devices and share files. '
          'Everything stays on your network.',
          style: AppTextStyles.muted(theme),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final requirement in requirements)
          _PermissionTile(
            requirement: requirement,
            granted: statuses?[requirement.permission]?.isGranted ?? false,
          ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('onboarding-allow-access'),
            onPressed: () => _requestAll(context, ref),
            child: const Text('Allow access'),
          ),
        ],
      ],
    );
  }

  Future<void> _requestAll(BuildContext context, WidgetRef ref) async {
    final service = ref.read(permissionServiceProvider);
    await service.requestAll();
    final statuses = await service.statuses();
    final stuck = [
      for (final entry in statuses.entries)
        if (entry.value.isPermanentlyDenied) entry.key,
    ];
    if (!context.mounted) return;
    ref.invalidate(permissionStatusesProvider);
    if (stuck.isNotEmpty) {
      await _showSettingsDialog(context, service);
    }
  }

  Future<void> _showSettingsDialog(
    BuildContext context,
    PermissionService service,
  ) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission blocked'),
        content: const Text(
          'This permission was denied for good. You can still use NearShare '
          'with reduced functionality, or enable it from system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue anyway'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await service.openSettings();
    }
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.requirement, required this.granted});

  final PermissionRequirement requirement;
  final bool granted;

  IconData get _icon {
    switch (requirement.permission) {
      case Permission.nearbyWifiDevices:
      case Permission.accessLocalNetwork:
        return Icons.wifi_find_rounded;
      case Permission.photos:
        return Icons.photo_library_outlined;
      case Permission.storage:
        return Icons.folder_open_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = AppTheme.paletteOf(context).success;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, size: 22, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requirement.title, style: AppTextStyles.cardTitle(theme)),
                    const SizedBox(height: 2),
                    Text(requirement.description, style: AppTextStyles.cardSubtitle(theme)),
                  ],
                ),
              ),
              if (granted)
                Icon(Icons.check_circle_rounded, size: 22, color: success)
              else
                Text(
                  'Needed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceNamePage extends StatelessWidget {
  const _DeviceNamePage({
    required this.theme,
    required this.controller,
    required this.onChanged,
    required this.suggestedName,
  });

  final ThemeData theme;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? suggestedName;

  @override
  Widget build(BuildContext context) {
    final suggestion = suggestedName;
    final showSuggestion = suggestion != null &&
        suggestion.isNotEmpty &&
        controller.text != suggestion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should others call this device?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can change it any time in Settings.',
            style: AppTextStyles.muted(theme),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            key: const Key('onboarding-name-field'),
            controller: controller,
            autofocus: false,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Device name',
              counterText: '',
            ),
            onChanged: (_) => onChanged(),
          ),
          if (showSuggestion)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  controller.text = suggestion;
                  onChanged();
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text('Use “$suggestion”'),
              ),
            ),
        ],
      ),
    );
  }
}
