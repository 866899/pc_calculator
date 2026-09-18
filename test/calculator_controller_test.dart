import 'package:flutter_test/flutter_test.dart';
import 'package:pc_calculator/state/calculator_controller.dart';

void main() {
  late CalculatorController controller;

  setUp(() {
    controller = CalculatorController();
    addTearDown(controller.dispose);
  });

  /// 快捷输入一串 token。
  void type(Iterable<String> tokens) {
    for (final t in tokens) {
      controller.input(t);
    }
  }

  group('初始状态', () {
    test('表达式为空、结果为 0、无历史、默认角度制', () {
      expect(controller.expression, '');
      expect(controller.result, '0');
      expect(controller.hasError, isFalse);
      expect(controller.error, isNull);
      expect(controller.history, isEmpty);
      expect(controller.isDegreeMode, isTrue);
    });
  });

  group('智能输入', () {
    test('连续输入数字拼接', () {
      type(['1', '2', '3']);
      expect(controller.expression, '123');
      expect(controller.result, '123');
    });

    test('同一数字段内小数点不重复', () {
      type(['1', '.', '5', '.']);
      expect(controller.expression, '1.5');
    });

    test('运算符后输入小数点自动补 0', () {
      type(['1', '+', '.']);
      expect(controller.expression, '1+0.');
    });

    test('不同数字段可各有小数点', () {
      type(['1', '.', '5', '+', '2', '.']);
      expect(controller.expression, '1.5+2.');
    });

    test('末尾二元运算符被替换', () {
      type(['1', '2', '+', '*']);
      expect(controller.expression, '12*');
      type(['/']);
      expect(controller.expression, '12/');
      type(['^']);
      expect(controller.expression, '12^');
    });

    test('乘除幂后可追加一元负号', () {
      type(['1', '2', '*', '-']);
      expect(controller.expression, '12*-');
      type(['3']);
      expect(controller.result, '-36');
    });

    test('加号后再按减号替换为减号', () {
      type(['1', '2', '+', '-']);
      expect(controller.expression, '12-');
    });

    test('一元负号后的二元运算符替换连带负号', () {
      type(['1', '2', '*', '-']);
      type(['+']);
      expect(controller.expression, '12+');
    });

    test('接受显示用符号 × 与 ÷ 并归一化为 * 与 /', () {
      type(['6', '×', '7']);
      expect(controller.expression, '6*7');
      controller.backspace();
      controller.backspace();
      expect(controller.expression, '6');
      type(['÷']);
      expect(controller.expression, '6/');
    });

    test('右括号仅在存在未闭合左括号时可输入', () {
      type(['(', '1', '+', '2', ')']);
      expect(controller.expression, '(1+2)');
      type([')']);
      expect(controller.expression, '(1+2)');
    });

    test('函数与常量输入', () {
      type(['sin(', '3', '0', ')']);
      expect(controller.expression, 'sin(30)');
      expect(controller.result, '0.5');
      type(['+', 'π']);
      expect(controller.expression, 'sin(30)+π');
    });
  });

  group('实时预览', () {
    test('输入过程中实时计算结果', () {
      type(['1', '+', '2']);
      expect(controller.result, '3');
    });

    test('中间态（末尾为运算符）保留上一个有效结果', () {
      type(['1']);
      expect(controller.result, '1');
      type(['+']);
      expect(controller.expression, '1+');
      expect(controller.result, '1');
    });

    test('除零在预览中不报错、保留旧值', () {
      type(['1', '0', '/', '0']);
      expect(controller.expression, '10/0');
      expect(controller.result, '10');
      expect(controller.hasError, isFalse);
    });

    test('角度制切换影响预览', () {
      controller.input('sin(30)');
      expect(controller.result, '0.5');
      controller.toggleAngleUnit();
      expect(controller.isDegreeMode, isFalse);
      expect(controller.result, isNot('0.5'));
      controller.toggleAngleUnit();
      expect(controller.result, '0.5');
    });
  });

  group('等号与历史', () {
    test('计算成功后表达式变为结果并写入历史', () {
      type(['1', '+', '2']);
      controller.computeResult();
      expect(controller.expression, '3');
      expect(controller.result, '3');
      expect(controller.history, hasLength(1));
      expect(controller.history.first.expression, '1+2');
      expect(controller.history.first.result, '3');
    });

    test('重复按等号不重复写入历史', () {
      type(['1', '+', '2']);
      controller.computeResult();
      controller.computeResult();
      expect(controller.history, hasLength(1));
    });

    test('空表达式按等号无操作', () {
      controller.computeResult();
      expect(controller.expression, '');
      expect(controller.history, isEmpty);
    });

    test('计算失败显示错误且不写历史', () {
      type(['1', '/', '0']);
      controller.computeResult();
      expect(controller.hasError, isTrue);
      expect(controller.error, isNotNull);
      expect(controller.expression, '1/0');
      expect(controller.history, isEmpty);
    });

    test('错误后继续输入开启全新表达式并清除错误', () {
      type(['1', '/', '0']);
      controller.computeResult();
      expect(controller.hasError, isTrue);
      type(['5']);
      expect(controller.hasError, isFalse);
      expect(controller.expression, '5');
    });

    test('多次计算历史最新在前', () {
      type(['1', '+', '1']);
      controller.computeResult();
      type(['2', '+', '2']);
      controller.computeResult();
      type(['3', '+', '3']);
      controller.computeResult();
      expect(controller.history, hasLength(3));
      expect(controller.history.first.expression, '3+3');
      expect(controller.history.last.expression, '1+1');
    });

    test('clearHistory 清空历史', () {
      type(['1', '+', '1']);
      controller.computeResult();
      controller.clearHistory();
      expect(controller.history, isEmpty);
    });

    test('useHistoryResult 将历史结果设为当前表达式', () {
      type(['2', '+', '3']);
      controller.computeResult();
      final entry = controller.history.first;
      controller.clear();
      controller.useHistoryResult(entry);
      expect(controller.expression, '5');
      expect(controller.result, '5');
      expect(controller.hasError, isFalse);
    });
  });

  group('等号后继续输入', () {
    test('输入运算符以结果为起点继续运算', () {
      type(['1', '+', '2']);
      controller.computeResult();
      type(['+']);
      expect(controller.expression, '3+');
      type(['1']);
      controller.computeResult();
      expect(controller.result, '4');
      expect(controller.history.first.expression, '3+1');
    });

    test('输入数字开启全新表达式', () {
      type(['1', '+', '2']);
      controller.computeResult();
      type(['5']);
      expect(controller.expression, '5');
    });

    test('输入常量开启全新表达式', () {
      type(['1', '+', '2']);
      controller.computeResult();
      type(['π']);
      expect(controller.expression, 'π');
    });
  });

  group('退格与清空', () {
    test('退格删除末尾字符', () {
      type(['1', '2', '3']);
      controller.backspace();
      expect(controller.expression, '12');
    });

    test('退格到空后结果归零', () {
      type(['9']);
      controller.backspace();
      expect(controller.expression, '');
      expect(controller.result, '0');
    });

    test('空表达式退格无操作', () {
      controller.backspace();
      expect(controller.expression, '');
    });

    test('退格删除整个函数 token', () {
      controller.input('sin(');
      expect(controller.expression, 'sin(');
      controller.backspace();
      expect(controller.expression, '');
      controller.input('sqrt(');
      controller.backspace();
      expect(controller.expression, '');
    });

    test('普通左括号退格只删一个字符', () {
      controller.input('(');
      controller.backspace();
      expect(controller.expression, '');
      controller.input('2');
      controller.input('(');
      controller.backspace();
      expect(controller.expression, '2');
    });

    test('clear 重置全部输入状态', () {
      type(['1', '+', '2']);
      controller.clear();
      expect(controller.expression, '');
      expect(controller.result, '0');
      expect(controller.hasError, isFalse);
    });
  });

  group('取反 negate', () {
    test('对末尾数字取反', () {
      type(['5']);
      controller.negate();
      expect(controller.expression, '-5');
    });

    test('再次取反恢复', () {
      type(['5']);
      controller.negate();
      controller.negate();
      expect(controller.expression, '5');
    });

    test('表达式中对末尾操作数取反', () {
      type(['2', '+', '3']);
      controller.negate();
      expect(controller.expression, '2+-3');
      expect(controller.result, '-1');
    });

    test('末尾无数字时取反无操作', () {
      type(['2', '+']);
      controller.negate();
      expect(controller.expression, '2+');
    });

    test('小数取反', () {
      type(['1', '.', '5']);
      controller.negate();
      expect(controller.expression, '-1.5');
    });
  });

  group('键盘输入 handleKeyLabel', () {
    test('数字与小数点（含逗号映射）', () {
      expect(controller.handleKeyLabel('5'), isTrue);
      expect(controller.expression, '5');
      expect(controller.handleKeyLabel('.'), isTrue);
      expect(controller.expression, '5.');
      expect(controller.handleKeyLabel(','), isTrue);
      expect(controller.expression, '5.');
    });

    test('运算符映射（x 为乘号）', () {
      expect(controller.handleKeyLabel('2'), isTrue);
      expect(controller.handleKeyLabel('x'), isTrue);
      expect(controller.expression, '2*');
      expect(controller.handleKeyLabel('X'), isTrue);
      expect(controller.expression, '2*');
    });

    test('Enter 与 = 触发等号', () {
      type(['1', '+', '2']);
      expect(controller.handleKeyLabel('Enter'), isTrue);
      expect(controller.result, '3');
      expect(controller.history, hasLength(1));
      expect(controller.handleKeyLabel('='), isTrue);
    });

    test('Backspace 退格、Escape/Delete 清空', () {
      type(['1', '2']);
      expect(controller.handleKeyLabel('Backspace'), isTrue);
      expect(controller.expression, '1');
      expect(controller.handleKeyLabel('Escape'), isTrue);
      expect(controller.expression, '');
      type(['7']);
      expect(controller.handleKeyLabel('Delete'), isTrue);
      expect(controller.expression, '');
    });

    test('未绑定的按键返回 false', () {
      expect(controller.handleKeyLabel('F5'), isFalse);
      expect(controller.handleKeyLabel('Shift'), isFalse);
      expect(controller.expression, '');
    });

    test('科学函数快捷键（小写）', () {
      const cases = {
        's': 'sin(',
        'o': 'cos(',
        't': 'tan(',
        'l': 'ln(',
        'g': 'log(',
        'q': 'sqrt(',
        'p': 'π',
        'e': 'e',
      };
      for (final entry in cases.entries) {
        controller.clear();
        expect(
          controller.handleKeyLabel(entry.key),
          isTrue,
          reason: '${entry.key} 应被识别',
        );
        expect(
          controller.expression,
          entry.value,
          reason: '${entry.key} 应输入 ${entry.value}',
        );
      }
    });

    test('大写函数快捷键（反函数与 exp）', () {
      const cases = {'S': 'asin(', 'O': 'acos(', 'T': 'atan(', 'E': 'exp('};
      for (final entry in cases.entries) {
        controller.clear();
        expect(controller.handleKeyLabel(entry.key), isTrue);
        expect(controller.expression, entry.value);
      }
    });

    test('科学计数法：2 e 3 求值 2000', () {
      type(['2', 'e', '3']);
      expect(controller.expression, '2e3');
      controller.computeResult();
      expect(controller.result, '2000');
    });

    test('函数快捷键组合求值 sin(30)', () {
      controller.handleKeyLabel('s');
      controller.handleKeyLabel('3');
      controller.handleKeyLabel('0');
      controller.handleKeyLabel(')');
      controller.computeResult();
      expect(controller.result, '0.5');
    });
  });

  group('变更通知', () {
    test('input 触发 notifyListeners', () {
      var notified = 0;
      controller.addListener(() => notified++);
      type(['1']);
      expect(notified, greaterThan(0));
    });
  });

  group('括号输入', () {
    test('左括号可直接追加', () {
      type(['(', '(', '1']);
      expect(controller.expression, '((1');
    });
  });
}
