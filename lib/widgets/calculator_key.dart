import 'package:flutter/material.dart';

/// 计算器按键的视觉风格。
enum CalcKeyStyle {
  /// 数字键。
  digit,

  /// 二元运算符键（÷ × − +）。
  operator,

  /// 功能键（⌫、±、%）。
  function,

  /// 科学函数键。
  scientific,

  /// 强调键（=）。
  accent,

  /// 危险键（C）。
  danger,
}

/// Material Design 3 风格的计算器按键。
///
/// 自适应内容缩放、悬停水波纹、可选 Tooltip（PC 端显示键盘快捷键提示）。
class CalculatorKey extends StatelessWidget {
  const CalculatorKey({
    super.key,
    required this.label,
    required this.onTap,
    this.style = CalcKeyStyle.digit,
    this.tooltip,
  });

  /// 按键显示文本（支持 Unicode 符号如 `÷`、`⌫`、`π`）。
  final String label;

  /// 点击回调。
  final VoidCallback onTap;

  /// 视觉风格。
  final CalcKeyStyle style;

  /// 悬停提示（通常为键盘快捷键说明）。
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (style) {
      CalcKeyStyle.digit => (scheme.surfaceContainerHigh, scheme.onSurface),
      CalcKeyStyle.operator => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      CalcKeyStyle.function => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      CalcKeyStyle.scientific => (scheme.surfaceContainer, scheme.onSurfaceVariant),
      CalcKeyStyle.accent => (scheme.primary, scheme.onPrimary),
      CalcKeyStyle.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };
    final fontSize = switch (style) {
      CalcKeyStyle.digit => 22.0,
      CalcKeyStyle.operator => 24.0,
      CalcKeyStyle.accent => 26.0,
      _ => 16.0,
    };
    final fontWeight = switch (style) {
      CalcKeyStyle.digit || CalcKeyStyle.accent => FontWeight.w600,
      _ => FontWeight.w500,
    };

    final button = Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: foreground,
                letterSpacing: style == CalcKeyStyle.scientific ? 0.2 : 0,
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(
      message: tooltip!,
      waitDuration: const Duration(milliseconds: 600),
      child: button,
    );
  }
}
