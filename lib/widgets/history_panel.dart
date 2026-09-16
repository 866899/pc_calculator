import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import '../state/calculator_controller.dart';

/// 历史记录面板：宽窗口作为右侧常驻栏，窄窗口作为抽屉。
class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key, required this.controller, this.onClose});

  final CalculatorController controller;

  /// 抽屉模式下的关闭回调（宽窗口常驻模式为 null）。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Text('历史记录', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                key: const ValueKey('btn-clear-history'),
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: '清空历史',
                onPressed: controller.clearHistory,
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                  onPressed: onClose,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: controller.history.isEmpty
              ? _buildEmpty(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: controller.history.length,
                  itemBuilder: (context, index) => _buildEntry(context, controller.history[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 44, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('暂无历史记录', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildEntry(BuildContext context, HistoryEntry entry) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: () => controller.useHistoryResult(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.expression.replaceAll('*', '×').replaceAll('/', '÷'),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              '= ${entry.result}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
