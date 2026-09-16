import 'package:flutter/material.dart';

import '../state/calculator_controller.dart';

/// 计算器显示屏：上方表达式（自动滚动到末尾、可复制），下方实时预览结果。
class DisplayPanel extends StatelessWidget {
  const DisplayPanel({super.key, required this.controller});

  final CalculatorController controller;

  /// 将内部 ASCII 运算符转为显示符号。
  static String pretty(String expression) =>
      expression.replaceAll('*', '×').replaceAll('/', '÷');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 34,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SelectableText(
              pretty(controller.expression),
              maxLines: 1,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: controller.hasError ? scheme.error : scheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontFamilyFallback: const ['monospace'],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: controller.hasError
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    controller.error ?? '错误',
                    style: theme.textTheme.headlineMedium?.copyWith(color: scheme.error),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    controller.result,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
