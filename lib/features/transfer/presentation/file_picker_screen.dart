import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/file_category.dart';
import '../domain/transfer_file.dart';
import 'transfer_provider.dart';

/// Picker tabs. "Documents" doubles as the home for anything that isn't a
/// photo or video (archives, audio, unknown types).
enum _PickerTab {
  photos('Photos', FileType.image),
  videos('Videos', FileType.video),
  documents('Documents', FileType.custom),
  all('All files', FileType.any);

  const _PickerTab(this.label, this.fileType);

  final String label;
  final FileType fileType;
}

class FilePickerScreen extends ConsumerStatefulWidget {
  const FilePickerScreen({super.key});

  @override
  ConsumerState<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends ConsumerState<FilePickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: _PickerTab.values.length,
    vsync: this,
  );

  static const List<String> _documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'csv',
    'md',
    'zip',
    'rar',
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _PickerTab get _tab => _PickerTab.values[_tabController.index];

  List<TransferFile> _visibleFiles(List<TransferFile> selected) {
    switch (_tab) {
      case _PickerTab.photos:
        return selected
            .where(
              (f) =>
                  categorizeFile(name: f.name, mimeType: f.mimeType) ==
                  FileCategory.photos,
            )
            .toList();
      case _PickerTab.videos:
        return selected
            .where(
              (f) =>
                  categorizeFile(name: f.name, mimeType: f.mimeType) ==
                  FileCategory.videos,
            )
            .toList();
      case _PickerTab.documents:
        return selected.where((f) {
          final category = categorizeFile(name: f.name, mimeType: f.mimeType);
          return category == FileCategory.documents ||
              category == FileCategory.other;
        }).toList();
      case _PickerTab.all:
        return selected;
    }
  }

  Future<void> _pickFiles() async {
    final tab = _tab;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: tab.fileType,
        withData: false,
        allowedExtensions:
            tab == _PickerTab.documents ? _documentExtensions : null,
      );

      if (result == null || result.files.isEmpty) return;

      final newFiles = result.files.map((f) {
        final ext = f.extension?.toLowerCase() ?? '';
        return TransferFile(
          name: f.name,
          sizeInBytes: f.size,
          mimeType: _getMimeType(ext),
          localPath: f.path ?? '',
        );
      }).toList();

      ref.read(transferStateProvider.notifier).addSelectedFiles(newFiles);
    } catch (e) {
      debugPrint('[FilePickerScreen] Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn\u2019t open the file picker. Try again.'),
          ),
        );
      }
    }
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'pdf':
        return 'application/pdf';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }

  void _remove(TransferFile file, List<TransferFile> selected) {
    final index = selected.indexOf(file);
    if (index >= 0) {
      ref.read(transferStateProvider.notifier).removeSelectedFile(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(transferStateProvider);
    final selectedFiles = transferState.selectedFiles;
    final visibleFiles = _visibleFiles(selectedFiles);
    final totalSize = transferState.totalSelectedSizeBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select files'),
        actions: [
          if (selectedFiles.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(transferStateProvider.notifier).clearSelectedFiles(),
              child: const Text('Clear all'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelPadding: EdgeInsets.zero,
          tabs: [
            for (final tab in _PickerTab.values) Tab(text: tab.label),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final tab in _PickerTab.values)
                  _buildTabView(tab, visibleFiles, selectedFiles),
              ],
            ),
          ),
          if (selectedFiles.isNotEmpty)
            _SelectionBar(
              count: selectedFiles.length,
              totalSize: totalSize,
              onAddMore: _pickFiles,
              onNext: () => context.push('/send/select-device'),
            ),
        ],
      ),
    );
  }

  Widget _buildTabView(
    _PickerTab tab,
    List<TransferFile> visibleFiles,
    List<TransferFile> selectedFiles,
  ) {
    if (visibleFiles.isEmpty) {
      return _EmptyPickerState(tab: tab, onAdd: _pickFiles);
    }

    final isVisual = tab == _PickerTab.photos || tab == _PickerTab.videos;
    if (isVisual) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
        ),
        itemCount: visibleFiles.length + 1,
        itemBuilder: (context, index) {
          if (index == visibleFiles.length) {
            return _AddTile(onTap: _pickFiles);
          }
          return _MediaTile(
            file: visibleFiles[index],
            onRemove: () => _remove(visibleFiles[index], selectedFiles),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      itemCount: visibleFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final file = visibleFiles[index];
        final theme = Theme.of(context);
        return Card(
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                AppIcons.fileFor(file.name, mimeType: file.mimeType),
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
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
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Remove',
              onPressed: () => _remove(file, selectedFiles),
            ),
          ),
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.file, required this.onRemove});

  final TransferFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = file.localPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: path.isNotEmpty && File(path).existsSync()
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(theme),
                )
              : _fallbackIcon(theme),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: 'Remove ${file.name}',
            onTap: onRemove,
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('remove-${file.name}'),
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatBytes(file.sizeInBytes),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: Center(
        child: Icon(
          AppIcons.fileFor(file.name, mimeType: file.mimeType),
          size: 40,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPickerState extends StatelessWidget {
  const _EmptyPickerState({required this.tab, required this.onAdd});

  final _PickerTab tab;
  final VoidCallback onAdd;

  String get _message {
    switch (tab) {
      case _PickerTab.photos:
        return 'Photos you add will show up here.';
      case _PickerTab.videos:
        return 'Videos you add will show up here.';
      case _PickerTab.documents:
        return 'Documents, archives, and other files land here.';
      case _PickerTab.all:
        return 'Pick any files to share across your local network.';
    }
  }

  IconData get _icon {
    switch (tab) {
      case _PickerTab.photos:
        return Icons.photo_outlined;
      case _PickerTab.videos:
        return Icons.movie_outlined;
      case _PickerTab.documents:
        return Icons.description_outlined;
      case _PickerTab.all:
        return Icons.folder_open_outlined;
    }
  }

  String get _buttonLabel {
    switch (tab) {
      case _PickerTab.photos:
        return 'Add photos';
      case _PickerTab.videos:
        return 'Add videos';
      case _PickerTab.documents:
        return 'Add documents';
      case _PickerTab.all:
        return 'Choose files';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nothing selected yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(theme),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(_buttonLabel),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.totalSize,
    required this.onAddMore,
    required this.onNext,
  });

  final int count;
  final int totalSize;
  final VoidCallback onAddMore;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count ${count == 1 ? 'file' : 'files'} selected',
                      style: AppTextStyles.cardTitle(theme),
                    ),
                    Text(
                      formatBytes(totalSize),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: onAddMore,
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next'),
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
