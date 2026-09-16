/// 计算器状态控制器：管理表达式输入、实时预览、历史记录与键盘输入。
///
/// 职责：
/// - [input] 智能追加 token（运算符替换、小数点去重、括号配对检查）；
/// - 实时预览：输入过程中持续求值，非法中间态保留上一个有效结果；
/// - [computeResult] 等号：成功写入历史并回填结果，失败进入错误态；
/// - [handleKeyLabel] 将物理键盘按键映射为计算器操作。
library;

import 'package:flutter/foundation.dart';

import '../models/calculator_engine.dart';
import '../models/history_entry.dart';

/// 计算器核心状态。
class CalculatorController extends ChangeNotifier {
  /// 二元运算符集合（内部统一使用 ASCII 表示）。
  static const _binaryOps = {'+', '-', '*', '/', '^'};

  /// 显示符号到内部 ASCII 符号的归一化表。
  static const _normalize = {'×': '*', '÷': '/', '−': '-'};

  String _expression = '';
  String _result = '0';
  String? _error;
  final List<HistoryEntry> _history = [];
  bool _isDegreeMode = true;
  bool _justEvaluated = false;

  /// 当前输入中的表达式（内部 ASCII 运算符）。
  String get expression => _expression;

  /// 实时预览结果（或等号后的计算结果）。
  String get result => _result;

  /// 是否处于错误状态（等号求值失败）。
  bool get hasError => _error != null;

  /// 错误提示文案，无错误时为 null。
  String? get error => _error;

  /// 历史记录，最新在前。
  List<HistoryEntry> get history => List.unmodifiable(_history);

  /// 是否角度制（否则弧度制）。
  bool get isDegreeMode => _isDegreeMode;

  // ---------------------------------------------------------------------
  // 输入
  // ---------------------------------------------------------------------

  /// 智能输入一个 token。
  ///
  /// token 可以是单字符（数字、运算符、括号、`π`、`e`），
  /// 也可以是复合 token（如 `sin(`），或归一化前的显示符号（`×`、`÷`）。
  void input(String token) {
    if (token.isEmpty) return;
    token = token.split('').map((c) => _normalize[c] ?? c).join();

    // 错误状态下任意输入都开启全新表达式。
    if (hasError) {
      _expression = '';
      _error = null;
    }

    final isBinaryOp = token.length == 1 && _binaryOps.contains(token);

    // 等号之后：运算符以结果为起点继续，其余输入开启新表达式。
    if (_justEvaluated) {
      _expression = isBinaryOp ? _result : '';
      _justEvaluated = false;
    }

    if (isBinaryOp) {
      _appendOperator(token);
    } else if (token == '.') {
      _appendDot();
    } else if (token == ')') {
      // 仅当存在未闭合的左括号时允许输入。
      if (_unmatchedOpens(_expression) > 0) _expression += token;
    } else {
      _expression += token;
    }
    _updatePreview();
    notifyListeners();
  }

  void _appendOperator(String op) {
    final expr = _expression;
    if (expr.isEmpty) {
      // 空表达式仅允许起始负号。
      if (op == '-') _expression = '-';
      return;
    }
    final last = expr[expr.length - 1];
    if (!_binaryOps.contains(last)) {
      _expression = expr + op;
      return;
    }
    // 乘除幂之后允许追加一元负号：12* + '-' -> 12*-
    final unaryMinusSpot = op == '-' && (last == '*' || last == '/' || last == '^');
    if (unaryMinusSpot) {
      _expression = expr + op;
      return;
    }
    // 末尾是一元负号（形如 "5*-"）时，替换运算符需连带删除负号。
    if (last == '-' && expr.length >= 2 && _binaryOps.contains(expr[expr.length - 2])) {
      _expression = expr.substring(0, expr.length - 2) + op;
      return;
    }
    // 常规替换末尾运算符。
    _expression = expr.substring(0, expr.length - 1) + op;
  }

  void _appendDot() {
    final seg = RegExp(r'[0-9.]*$').firstMatch(_expression)?.group(0) ?? '';
    if (seg.contains('.')) return; // 同一数字段内小数点不重复
    _expression += seg.isEmpty ? '0.' : '.';
  }

  /// 退格：删除末尾 token（函数 token 整体删除）。
  void backspace() {
    if (_expression.isEmpty) return;
    _justEvaluated = false;
    _error = null;
    final funcMatch =
        RegExp(r'(?:sin|cos|tan|asin|acos|atan|ln|log|sqrt|abs|exp)\($').firstMatch(_expression);
    if (funcMatch != null) {
      _expression = _expression.substring(0, funcMatch.start);
    } else {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _updatePreview();
    notifyListeners();
  }

  /// 清空当前表达式（不影响历史）。
  void clear() {
    _expression = '';
    _result = '0';
    _error = null;
    _justEvaluated = false;
    notifyListeners();
  }

  /// 对末尾操作数取反。
  void negate() {
    final m = RegExp(r'[0-9.]+$').firstMatch(_expression);
    if (m == null) return;
    final start = m.start;
    final before = start > 0 ? _expression[start - 1] : '';
    final before2 = start > 1 ? _expression[start - 2] : '';
    final hasOwnMinus = before == '-' && (start == 1 || _binaryOps.contains(before2) || before2 == '(');
    if (hasOwnMinus) {
      _expression = '${_expression.substring(0, start - 1)}${_expression.substring(start)}';
    } else {
      _expression = '${_expression.substring(0, start)}-${_expression.substring(start)}';
    }
    _justEvaluated = false;
    _updatePreview();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 等号与历史
  // ---------------------------------------------------------------------

  /// 等号：求值并写入历史；失败时进入错误状态。
  void computeResult() {
    if (_justEvaluated || _expression.isEmpty) return;
    try {
      final value = _evaluate(_expression);
      final formatted = formatResult(value);
      _history.insert(0, HistoryEntry(
        expression: _expression,
        result: formatted,
        timestamp: DateTime.now(),
      ));
      _expression = formatted;
      _result = formatted;
      _error = null;
      _justEvaluated = true;
    } on CalculatorException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  /// 将某条历史记录的结果作为当前表达式。
  void useHistoryResult(HistoryEntry entry) {
    _expression = entry.result;
    _error = null;
    _justEvaluated = false;
    _updatePreview();
    notifyListeners();
  }

  /// 清空历史记录。
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 设置
  // ---------------------------------------------------------------------

  /// 在角度制 / 弧度制之间切换，并刷新预览。
  void toggleAngleUnit() {
    _isDegreeMode = !_isDegreeMode;
    _updatePreview();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 键盘
  // ---------------------------------------------------------------------

  /// 处理键盘按键（keyLabel 或字符），返回是否被识别。
  bool handleKeyLabel(String label) {
    switch (label) {
      case 'Enter':
      case 'Return':
      case '=':
        computeResult();
        return true;
      case 'Backspace':
        backspace();
        return true;
      case 'Escape':
      case 'Delete':
        clear();
        return true;
      case '.':
      case ',':
        input('.');
        return true;
      case 'x':
      case 'X':
        input('*');
        return true;
      case '+':
      case '-':
      case '*':
      case '/':
      case '^':
      case '%':
      case '(':
      case ')':
      case '×':
      case '÷':
        input(label);
        return true;
    }
    if (label.length == 1 && '0123456789'.contains(label)) {
      input(label);
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------

  double _evaluate(String expression) => CalculatorEngine.evaluate(
        expression,
        angleUnit: _isDegreeMode ? AngleUnit.degree : AngleUnit.radian,
      );

  /// 实时预览：非法中间态不报错，保留上一个有效结果。
  void _updatePreview() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    try {
      _result = formatResult(_evaluate(_expression));
    } on CalculatorException {
      // 保留旧值
    }
  }

  int _unmatchedOpens(String s) {
    var n = 0;
    for (final c in s.split('')) {
      if (c == '(') {
        n++;
      } else if (c == ')') {
        n--;
      }
    }
    return n;
  }
}
