/// 计算器核心引擎：表达式词法分析、语法分析与求值。
///
/// 采用递归下降文法：
/// ```text
/// expression := term (('+' | '-') term)*
/// term       := unary (('*' | '/') unary | 隐式乘 unary)*
/// unary      := ('-' | '+') unary | power
/// power      := postfix ('^' unary)?          // 右结合
/// postfix    := primary ('%')*
/// primary    := 数字 | 常量 | 函数 '(' expression ')' | '(' expression ')'
/// ```
library;

import 'dart:math' as math;

/// 角度单位（三角函数入参/出参单位）。
enum AngleUnit { degree, radian }

/// 计算器求值异常：表达式非法、除零、结果无效等。
class CalculatorException implements Exception {
  const CalculatorException(this.message);

  /// 面向用户的错误描述。
  final String message;

  @override
  String toString() => 'CalculatorException: $message';
}

/// 表达式求值引擎（纯静态，无状态）。
class CalculatorEngine {
  /// 对 [expression] 求值并返回结果。
  ///
  /// 支持：四则运算、幂 `^`、百分号 `%`、括号、一元负号、
  /// 常量 `π` / `pi` / `e`、函数 `sin` `cos` `tan` `asin` `acos` `atan`
  /// `ln` `log` `sqrt` `abs` `exp`、隐式乘法与科学计数法。
  /// 三角函数按 [angleUnit] 解释角度（默认角度制）。
  ///
  /// 表达式非法或结果无效（除零、NaN、溢出）时抛出 [CalculatorException]。
  static double evaluate(String expression, {AngleUnit angleUnit = AngleUnit.degree}) {
    final parser = _Parser(_Tokenizer(expression).tokenize(), angleUnit);
    return parser.parse();
  }
}

// ---------------------------------------------------------------------------
// 词法分析
// ---------------------------------------------------------------------------

/// Token 类型常量。
class _T {
  static const number = 'number';
  static const identifier = 'identifier';
  static const plus = '+';
  static const minus = '-';
  static const star = '*';
  static const slash = '/';
  static const caret = '^';
  static const percent = '%';
  static const lparen = '(';
  static const rparen = ')';
  static const end = 'end';
}

class _Token {
  const _Token(this.type, {this.value, this.name});

  final String type;

  /// 数字字面量的值（仅 [type] 为 number 时有效）。
  final double? value;

  /// 标识符名称（仅 [type] 为 identifier 时有效，已转小写）。
  final String? name;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

bool _isLetter(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A);
}

class _Tokenizer {
  _Tokenizer(this._input);

  final String _input;
  int _pos = 0;

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (true) {
      _skipWhitespace();
      if (_pos >= _input.length) break;
      final c = _input[_pos];
      if (_isDigit(c) || c == '.') {
        tokens.add(_readNumber());
      } else if (_isLetter(c) || c == 'π') {
        tokens.add(_readIdentifier());
      } else {
        tokens.add(_readSymbol(c));
      }
    }
    tokens.add(const _Token(_T.end));
    return tokens;
  }

  void _skipWhitespace() {
    while (_pos < _input.length && ' \t\r\n'.contains(_input[_pos])) {
      _pos++;
    }
  }

  _Token _readNumber() {
    var hasDot = false;
    final buf = StringBuffer();
    while (_pos < _input.length) {
      final c = _input[_pos];
      if (_isDigit(c)) {
        buf.write(c);
        _pos++;
      } else if (c == '.') {
        if (hasDot) throw const CalculatorException('数字格式无效');
        hasDot = true;
        buf.write(c);
        _pos++;
      } else {
        break;
      }
    }
    // 科学计数法：仅当 e/E 后跟可选符号 + 数字时才并入当前数字。
    if (_pos < _input.length && (_input[_pos] == 'e' || _input[_pos] == 'E')) {
      var look = _pos + 1;
      if (look < _input.length && (_input[look] == '+' || _input[look] == '-')) look++;
      if (look < _input.length && _isDigit(_input[look])) {
        while (_pos < look) {
          buf.write(_input[_pos]);
          _pos++;
        }
        while (_pos < _input.length && _isDigit(_input[_pos])) {
          buf.write(_input[_pos]);
          _pos++;
        }
      }
    }
    final value = double.tryParse(buf.toString());
    if (value == null) throw const CalculatorException('数字格式无效');
    return _Token(_T.number, value: value);
  }

  _Token _readIdentifier() {
    final buf = StringBuffer();
    while (_pos < _input.length) {
      final c = _input[_pos];
      if (_isLetter(c) || c == 'π') {
        buf.write(c);
        _pos++;
      } else {
        break;
      }
    }
    return _Token(_T.identifier, name: buf.toString().toLowerCase());
  }

  _Token _readSymbol(String c) {
    _pos++;
    switch (c) {
      case '+':
        return const _Token(_T.plus);
      case '-':
        return const _Token(_T.minus);
      case '*':
      case '×':
        return const _Token(_T.star);
      case '/':
      case '÷':
        return const _Token(_T.slash);
      case '^':
        return const _Token(_T.caret);
      case '%':
        return const _Token(_T.percent);
      case '(':
        return const _Token(_T.lparen);
      case ')':
        return const _Token(_T.rparen);
      default:
        throw CalculatorException('无法识别的字符 "$c"');
    }
  }
}

// ---------------------------------------------------------------------------
// 语法分析与求值
// ---------------------------------------------------------------------------

const _kFunctions = <String>{
  'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
  'ln', 'log', 'sqrt', 'abs', 'exp',
};

class _Parser {
  _Parser(this._tokens, this._angleUnit);

  final List<_Token> _tokens;
  final AngleUnit _angleUnit;
  int _pos = 0;

  _Token get _peek => _tokens[_pos];

  bool get _atEnd => _peek.type == _T.end;

  double parse() {
    if (_atEnd) throw const CalculatorException('表达式为空');
    final value = _expression();
    if (!_atEnd) throw const CalculatorException('表达式无效');
    if (value.isNaN) throw const CalculatorException('结果无效');
    if (value.isInfinite) throw const CalculatorException('结果溢出');
    return value;
  }

  double _expression() {
    var value = _term();
    while (_peek.type == _T.plus || _peek.type == _T.minus) {
      final isPlus = _peek.type == _T.plus;
      _pos++;
      final right = _term();
      value = isPlus ? value + right : value - right;
    }
    return value;
  }

  double _term() {
    var value = _unary();
    while (true) {
      final t = _peek.type;
      if (t == _T.star || t == _T.slash) {
        final isDiv = t == _T.slash;
        _pos++;
        final right = _unary();
        if (isDiv && right == 0) throw const CalculatorException('不能除以零');
        value = isDiv ? value / right : value * right;
      } else if (_startsPrimary()) {
        // 隐式乘法：2π、2(3+4)、(2)(3)、2sin(30)
        value = value * _unary();
      } else {
        break;
      }
    }
    return value;
  }

  bool _startsPrimary() {
    final t = _peek.type;
    return t == _T.number || t == _T.identifier || t == _T.lparen;
  }

  double _unary() {
    if (_peek.type == _T.minus) {
      _pos++;
      return -_unary();
    }
    if (_peek.type == _T.plus) {
      _pos++;
      return _unary();
    }
    return _power();
  }

  double _power() {
    final base = _postfix();
    if (_peek.type == _T.caret) {
      _pos++;
      final exponent = _unary();
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  double _postfix() {
    var value = _primary();
    while (_peek.type == _T.percent) {
      _pos++;
      value = value / 100;
    }
    return value;
  }

  double _primary() {
    final token = _peek;
    switch (token.type) {
      case _T.number:
        _pos++;
        return token.value!;
      case _T.identifier:
        final name = token.name!;
        if (name == 'π' || name == 'pi') {
          _pos++;
          return math.pi;
        }
        if (name == 'e') {
          _pos++;
          return math.e;
        }
        if (_kFunctions.contains(name)) {
          _pos++;
          _expect(_T.lparen, '函数缺少左括号');
          final arg = _expression();
          _expect(_T.rparen, '缺少右括号');
          return _applyFunction(name, arg);
        }
        throw CalculatorException('无法识别的符号 "$name"');
      case _T.lparen:
        _pos++;
        final value = _expression();
        _expect(_T.rparen, '缺少右括号');
        return value;
      default:
        throw const CalculatorException('表达式无效');
    }
  }

  void _expect(String type, String message) {
    if (_peek.type != type) throw CalculatorException(message);
    _pos++;
  }

  double _toRadians(double v) =>
      _angleUnit == AngleUnit.degree ? v * math.pi / 180 : v;

  double _fromRadians(double v) =>
      _angleUnit == AngleUnit.degree ? v * 180 / math.pi : v;

  double _applyFunction(String name, double arg) {
    switch (name) {
      case 'sin':
        return math.sin(_toRadians(arg));
      case 'cos':
        return math.cos(_toRadians(arg));
      case 'tan':
        return math.tan(_toRadians(arg));
      case 'asin':
        return _fromRadians(math.asin(arg));
      case 'acos':
        return _fromRadians(math.acos(arg));
      case 'atan':
        return _fromRadians(math.atan(arg));
      case 'ln':
        return math.log(arg);
      case 'log':
        return math.log(arg) / math.ln10;
      case 'sqrt':
        return math.sqrt(arg);
      case 'abs':
        return arg.abs();
      case 'exp':
        return math.exp(arg);
      default:
        throw CalculatorException('无法识别的函数 "$name"');
    }
  }

}

// ---------------------------------------------------------------------------
// 结果格式化
// ---------------------------------------------------------------------------

/// 将求值结果格式化为用户友好的显示字符串。
///
/// 规则：
/// - 消除浮点误差（0.1+0.2 显示为 0.3）；
/// - 整数不带小数点，去掉末尾多余的零；
/// - 最多保留 12 位有效数字；
/// - 绝对值 >= 1e16 或 < 1e-9 时使用科学计数法；
/// - -0.0 显示为 0。
String formatResult(double value) {
  if (value.isNaN) return '无效';
  if (value.isInfinite) return '溢出';
  if (value == 0) return '0';

  final abs = value.abs();
  if (abs >= 1e16 || abs < 1e-9) {
    return _formatExponential(value.toStringAsExponential(9));
  }

  final intDigits = abs >= 1 ? abs.truncate().toString().length : 0;
  final decimals = (12 - intDigits).clamp(0, 12);
  var s = value.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

/// 将 "1.500000000e+16" 规范化为 "1.5e16"，负指数保留负号。
String _formatExponential(String s) {
  final match = RegExp(r'^(-?\d)(?:\.(\d+))?e([+-])(\d+)$').firstMatch(s);
  if (match == null) return s;
  final mantissa = match.group(1)!;
  final frac = (match.group(2) ?? '').replaceAll(RegExp(r'0+$'), '');
  final sign = match.group(3) == '-' ? '-' : '';
  final exponent = match.group(4)!;
  return frac.isEmpty
      ? '${mantissa}e$sign$exponent'
      : '$mantissa.${frac}e$sign$exponent';
}
