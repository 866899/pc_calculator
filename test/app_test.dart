import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pc_calculator/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());
    // 等待首次帧与焦点就绪
    await tester.pumpAndSettle();
  }

  group('CalculatorApp 冒烟与交互', () {
    testWidgets('初始渲染：显示 0 与核心按键', (tester) async {
      await pumpApp(tester);
      expect(find.text('0'), findsWidgets);
      expect(find.byKey(const ValueKey('key-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('key-plus')), findsOneWidget);
      expect(find.byKey(const ValueKey('key-equals')), findsOneWidget);
      expect(find.byKey(const ValueKey('key-clear')), findsOneWidget);
      expect(find.byKey(const ValueKey('key-backspace')), findsOneWidget);
    });

    testWidgets('点击按键完成 12+3.5=15.5 并写入历史', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('key-1')));
      await tester.tap(find.byKey(const ValueKey('key-2')));
      await tester.tap(find.byKey(const ValueKey('key-plus')));
      await tester.pump();
      // 实时预览
      expect(find.text('12'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('key-3')));
      await tester.tap(find.byKey(const ValueKey('key-dot')));
      await tester.tap(find.byKey(const ValueKey('key-5')));
      await tester.pump();
      expect(find.text('15.5'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('key-equals')));
      await tester.pumpAndSettle();
      expect(find.text('15.5'), findsWidgets);
      // 打开历史面板应能看到该记录
      await tester.tap(find.byKey(const ValueKey('btn-history')));
      await tester.pumpAndSettle();
      expect(find.text('12+3.5'), findsOneWidget);
    });

    testWidgets('物理键盘：数字、Enter、Backspace、Escape', (tester) async {
      await pumpApp(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pump();
      expect(find.text('78'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('78'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const ValueKey('key-0')), findsOneWidget);
    });

    testWidgets('科学模式切换后出现函数按键且可计算', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('mode-scientific')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('key-sin')), findsOneWidget);
      expect(find.byKey(const ValueKey('key-pi')), findsOneWidget);
      expect(find.byKey(const ValueKey('key-sqrt')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('key-sin')));
      await tester.tap(find.byKey(const ValueKey('key-3')));
      await tester.tap(find.byKey(const ValueKey('key-0')));
      await tester.tap(find.byKey(const ValueKey('key-right-paren')));
      await tester.pump();
      expect(find.text('0.5'), findsWidgets);
      // 切回标准模式后函数按键消失
      await tester.tap(find.byKey(const ValueKey('mode-standard')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('key-sin')), findsNothing);
    });

    testWidgets('角度/弧度切换', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('mode-scientific')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('key-sin')));
      await tester.tap(find.byKey(const ValueKey('key-3')));
      await tester.tap(find.byKey(const ValueKey('key-0')));
      await tester.tap(find.byKey(const ValueKey('key-right-paren')));
      await tester.pump();
      expect(find.text('0.5'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('btn-angle-unit')));
      await tester.pump();
      expect(find.text('0.5'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('btn-angle-unit')));
      await tester.pump();
      expect(find.text('0.5'), findsWidgets);
    });

    testWidgets('历史面板清空', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('key-1')));
      await tester.tap(find.byKey(const ValueKey('key-plus')));
      await tester.tap(find.byKey(const ValueKey('key-1')));
      await tester.tap(find.byKey(const ValueKey('key-equals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('btn-history')));
      await tester.pumpAndSettle();
      expect(find.text('1+1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('btn-clear-history')));
      await tester.pumpAndSettle();
      expect(find.text('1+1'), findsNothing);
    });
  });
}
