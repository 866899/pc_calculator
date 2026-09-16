import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/calculator_controller.dart';
import 'display_panel.dart';
import 'history_panel.dart';
import 'keypad.dart';

/// 计算器主页面。
///
/// PC 端特性：
/// - 全局物理键盘支持（数字、运算符、Enter、Backspace、Esc 等）；
/// - 宽窗口（>= 720）时历史记录常驻右侧，窄窗口时收纳为抽屉；
/// - 标准 / 科学两种键盘模式切换。
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// 宽窗口下显示常驻历史栏的宽度阈值。
  static const _wideBreakpoint = 720.0;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _controller = CalculatorController();
  final _focusNode = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _scientific = false;
  bool _historyOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final ch = event.character;
    final label = (ch != null && ch.isNotEmpty && ch != '\r' && ch != '\n' && ch != '\t')
        ? ch
        : event.logicalKey.keyLabel;
    return _controller.handleKeyLabel(label)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  void _toggleHistory() {
    final isWide = MediaQuery.sizeOf(context).width >= CalculatorPage._wideBreakpoint;
    if (isWide) {
      setState(() => _historyOpen = !_historyOpen);
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: Drawer(
          width: 320,
          child: HistoryPanel(
            controller: _controller,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= CalculatorPage._wideBreakpoint;
                final showSidePanel = isWide && _historyOpen;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _buildCalculator(context),
                        ),
                      ),
                    ),
                    if (showSidePanel) ...[
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 300,
                        child: HistoryPanel(controller: _controller),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: DisplayPanel(controller: _controller),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Keypad(controller: _controller, scientific: _scientific),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = widget.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, color: scheme.primary),
          const SizedBox(width: 8),
          Text('计算器', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          FilledButton.tonal(
            key: const ValueKey('btn-angle-unit'),
            onPressed: _controller.toggleAngleUnit,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            child: Text(_controller.isDegreeMode ? 'DEG' : 'RAD'),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: KeyedSubtree(key: ValueKey('mode-standard'), child: Text('标准')),
              ),
              ButtonSegment(
                value: true,
                label: KeyedSubtree(key: ValueKey('mode-scientific'), child: Text('科学')),
              ),
            ],
            selected: {_scientific},
            onSelectionChanged: (selection) => setState(() => _scientific = selection.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const ValueKey('btn-theme'),
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isDark ? '浅色主题' : '深色主题',
            onPressed: () => widget.onThemeModeChanged(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          IconButton(
            key: const ValueKey('btn-history'),
            icon: const Icon(Icons.history_rounded),
            tooltip: '历史记录',
            onPressed: _toggleHistory,
          ),
        ],
      ),
    );
  }
}
