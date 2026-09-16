import 'package:flutter/material.dart';

import '../state/calculator_controller.dart';
import 'calculator_key.dart';

/// 计算器键盘：标准模式 4×5，科学模式在上方追加 4×4 函数区。
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.controller, required this.scientific});

  final CalculatorController controller;

  /// 是否显示科学函数区。
  final bool scientific;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (scientific) ..._scientificRows(),
      ..._standardRows(),
    ];
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(child: rows[i]),
        ],
      ],
    );
  }

  Widget _row(List<Widget> keys) => Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: keys[i]),
          ],
        ],
      );

  Widget _key(
    String id,
    String label,
    String tooltip, {
    CalcKeyStyle style = CalcKeyStyle.digit,
    String? token,
    VoidCallback? onTap,
  }) =>
      CalculatorKey(
        key: ValueKey('key-$id'),
        label: label,
        tooltip: tooltip,
        style: style,
        onTap: onTap ?? (token == null ? () {} : () => controller.input(token)),
      );

  Widget _digit(String d) => _key(d, d, '输入 $d', token: d);

  // ------------------------------------------------------------------
  // 标准键盘
  // ------------------------------------------------------------------

  List<Widget> _standardRows() => [
        _row([
          _key('clear', 'C', '清空 (Esc)', style: CalcKeyStyle.danger, onTap: controller.clear),
          _key('backspace', '⌫', '退格 (Backspace)',
              style: CalcKeyStyle.function, onTap: controller.backspace),
          _key('percent', '%', '百分号 ( % )', style: CalcKeyStyle.function, token: '%'),
          _key('divide', '÷', '除 ( / )', style: CalcKeyStyle.operator, token: '÷'),
        ]),
        _row([
          _digit('7'),
          _digit('8'),
          _digit('9'),
          _key('multiply', '×', '乘 ( * )', style: CalcKeyStyle.operator, token: '×'),
        ]),
        _row([
          _digit('4'),
          _digit('5'),
          _digit('6'),
          _key('minus', '−', '减 ( - )', style: CalcKeyStyle.operator, token: '-'),
        ]),
        _row([
          _digit('1'),
          _digit('2'),
          _digit('3'),
          _key('plus', '+', '加 ( + )', style: CalcKeyStyle.operator, token: '+'),
        ]),
        _row([
          _key('negate', '±', '正负号', style: CalcKeyStyle.function, onTap: controller.negate),
          _digit('0'),
          _key('dot', '.', '小数点 ( . )', token: '.'),
          _key('equals', '=', '计算 (Enter)', style: CalcKeyStyle.accent, onTap: controller.computeResult),
        ]),
      ];

  // ------------------------------------------------------------------
  // 科学键盘
  // ------------------------------------------------------------------

  List<Widget> _scientificRows() => [
        _row([
          _key('sin', 'sin', '正弦', style: CalcKeyStyle.scientific, token: 'sin('),
          _key('cos', 'cos', '余弦', style: CalcKeyStyle.scientific, token: 'cos('),
          _key('tan', 'tan', '正切', style: CalcKeyStyle.scientific, token: 'tan('),
          _key('power', '^', '幂运算 ( ^ )', style: CalcKeyStyle.scientific, token: '^'),
        ]),
        _row([
          _key('ln', 'ln', '自然对数', style: CalcKeyStyle.scientific, token: 'ln('),
          _key('log', 'log', '常用对数', style: CalcKeyStyle.scientific, token: 'log('),
          _key('sqrt', '√', '平方根', style: CalcKeyStyle.scientific, token: 'sqrt('),
          _key('square', 'x²', '平方', style: CalcKeyStyle.scientific, token: '^2'),
        ]),
        _row([
          _key('pi', 'π', '圆周率 π', style: CalcKeyStyle.scientific, token: 'π'),
          _key('e-const', 'e', '自然常数 e', style: CalcKeyStyle.scientific, token: 'e'),
          _key('left-paren', '(', '左括号 ( ( )', style: CalcKeyStyle.scientific, token: '('),
          _key('right-paren', ')', '右括号 ( ) )', style: CalcKeyStyle.scientific, token: ')'),
        ]),
        _row([
          _key('asin', 'asin', '反正弦', style: CalcKeyStyle.scientific, token: 'asin('),
          _key('acos', 'acos', '反余弦', style: CalcKeyStyle.scientific, token: 'acos('),
          _key('atan', 'atan', '反正切', style: CalcKeyStyle.scientific, token: 'atan('),
          _key('exp', 'exp', '指数函数', style: CalcKeyStyle.scientific, token: 'exp('),
        ]),
      ];
}
