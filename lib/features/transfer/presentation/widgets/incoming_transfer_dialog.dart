import 'package:flutter/material.dart';
import '../../domain/transfer_request.dart';

class IncomingTransferDialog extends StatelessWidget {
  final TransferRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingTransferDialog({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSizeStr = _formatSize(request.totalSizeBytes);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.download_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incoming Transfer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'From ${request.senderName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${request.files.length} ${request.files.length == 1 ? "file" : "files"}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    totalSizeStr,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: request.files.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final file = request.files[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined, size: 20),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Text(
                      _formatSize(file.sizeInBytes),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: onReject,
          child: const Text('Decline'),
        ),
        FilledButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Accept'),
        ),
      ],
    );
  }
}
