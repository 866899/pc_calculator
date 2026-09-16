import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pc_calculator/models/calculator_engine.dart';

void main() {
  group('CalculatorEngine 四则运算', () {
    test('加法 1+2=3', () {
      expect(CalculatorEngine.evaluate('1+2'), 3);
    });

    test('减法 5-8=-3', () {
      expect(CalculatorEngine.evaluate('5-8'), -3);
    });

    test('乘法 6*7=42', () {
      expect(CalculatorEngine.evaluate('6*7'), 42);
    });

    test('除法 8/2=4', () {
      expect(CalculatorEngine.evaluate('8/2'), 4);
    });

    test('除法为左结合 8/4/2=1', () {
      expect(CalculatorEngine.evaluate('8/4/2'), 1);
    });

    test('支持显示用符号 × 与 ÷', () {
      expect(CalculatorEngine.evaluate('6×7'), 42);
      expect(CalculatorEngine.evaluate('8÷2'), 4);
    });
  });

  group('CalculatorEngine 优先级与结合性', () {
    test('乘法优先于加法 2+3*4=14', () {
      expect(CalculatorEngine.evaluate('2+3*4'), 14);
    });

    test('连续减法左结合 10-4-3=3', () {
      expect(CalculatorEngine.evaluate('10-4-3'), 3);
    });

    test('幂运算右结合 2^3^2=512', () {
      expect(CalculatorEngine.evaluate('2^3^2'), 512);
    });

    test('幂运算优先于加减乘 2+3*4^2=50', () {
      expect(CalculatorEngine.evaluate('2+3*4^2'), 50);
    });
  });

  group('CalculatorEngine 括号', () {
    test('括号改变优先级 (2+3)*4=20', () {
      expect(CalculatorEngine.evaluate('(2+3)*4'), 20);
    });

    test('嵌套括号 ((1+2)*(3+4))=21', () {
      expect(CalculatorEngine.evaluate('((1+2)*(3+4))'), 21);
    });

    test('括号前的一元负号 -(2+3)=-5', () {
      expect(CalculatorEngine.evaluate('-(2+3)'), -5);
    });
  });

  group('CalculatorEngine 一元负号', () {
    test('开头负号 -5+3=-2', () {
      expect(CalculatorEngine.evaluate('-5+3'), -2);
    });

    test('运算符后负号 2*-3=-6', () {
      expect(CalculatorEngine.evaluate('2*-3'), -6);
    });

    test('负负得正 2--3=5', () {
      expect(CalculatorEngine.evaluate('2--3'), 5);
    });

    test('一元负号优先级低于幂 -2^2=-4', () {
      expect(CalculatorEngine.evaluate('-2^2'), -4);
    });
  });

  group('CalculatorEngine 小数与科学计数法', () {
    test('浮点精度 0.1+0.2≈0.3', () {
      expect(CalculatorEngine.evaluate('0.1+0.2'), closeTo(0.3, 1e-9));
    });

    test('省略前导零 .5*4=2', () {
      expect(CalculatorEngine.evaluate('.5*4'), 2);
    });

    test('小数运算 1.5*2=3', () {
      expect(CalculatorEngine.evaluate('1.5*2'), 3);
    });

    test('科学计数法输入 1.5e2=150', () {
      expect(CalculatorEngine.evaluate('1.5e2'), 150);
    });

    test('e 后无数字时视为常量 2e≈2*e', () {
      expect(CalculatorEngine.evaluate('2e'), closeTo(2 * math.e, 1e-12));
    });
  });

  group('CalculatorEngine 百分号', () {
    test('单独百分号 50%=0.5', () {
      expect(CalculatorEngine.evaluate('50%'), 0.5);
    });

    test('百分号参与乘法 200*5%=10', () {
      expect(CalculatorEngine.evaluate('200*5%'), closeTo(10, 1e-9));
    });

    test('百分号可叠加 50%%=0.005', () {
      expect(CalculatorEngine.evaluate('50%%'), closeTo(0.005, 1e-12));
    });
  });

  group('CalculatorEngine 常量与隐式乘法', () {
    test('常量 π', () {
      expect(CalculatorEngine.evaluate('π'), closeTo(math.pi, 1e-12));
    });

    test('常量 pi 拼写', () {
      expect(CalculatorEngine.evaluate('pi'), closeTo(math.pi, 1e-12));
    });

    test('数字与常量隐式相乘 2π', () {
      expect(CalculatorEngine.evaluate('2π'), closeTo(2 * math.pi, 1e-12));
    });

    test('数字与括号隐式相乘 2(3+4)=14', () {
      expect(CalculatorEngine.evaluate('2(3+4)'), 14);
    });

    test('括号与括号隐式相乘 (2)(3)=6', () {
      expect(CalculatorEngine.evaluate('(2)(3)'), 6);
    });

    test('常量与括号隐式相乘 π(2)', () {
      expect(CalculatorEngine.evaluate('π(2)'), closeTo(2 * math.pi, 1e-12));
    });

    test('数字与函数隐式相乘 2sin(30)=1', () {
      expect(CalculatorEngine.evaluate('2sin(30)'), closeTo(1, 1e-9));
    });
  });

  group('CalculatorEngine 科学函数', () {
    test('sqrt(16)=4', () {
      expect(CalculatorEngine.evaluate('sqrt(16)'), 4);
    });

    test('sqrt(2)^2≈2', () {
      expect(CalculatorEngine.evaluate('sqrt(2)^2'), closeTo(2, 1e-9));
    });

    test('abs(-5)=5', () {
      expect(CalculatorEngine.evaluate('abs(-5)'), 5);
    });

    test('ln(e)=1', () {
      expect(CalculatorEngine.evaluate('ln(e)'), closeTo(1, 1e-12));
    });

    test('log(100)=2', () {
      expect(CalculatorEngine.evaluate('log(100)'), closeTo(2, 1e-12));
    });

    test('exp(1)≈e', () {
      expect(CalculatorEngine.evaluate('exp(1)'), closeTo(math.e, 1e-12));
    });

    test('默认角度制 sin(30)=0.5', () {
      expect(CalculatorEngine.evaluate('sin(30)'), closeTo(0.5, 1e-9));
    });

    test('角度制 cos(60)=0.5、tan(45)=1', () {
      expect(CalculatorEngine.evaluate('cos(60)'), closeTo(0.5, 1e-9));
      expect(CalculatorEngine.evaluate('tan(45)'), closeTo(1, 1e-9));
    });

    test('弧度制 sin(π/6)=0.5', () {
      expect(
        CalculatorEngine.evaluate('sin(π/6)', angleUnit: AngleUnit.radian),
        closeTo(0.5, 1e-9),
      );
    });

    test('弧度制下 sin(30) 不等于 0.5', () {
      final v = CalculatorEngine.evaluate('sin(30)', angleUnit: AngleUnit.radian);
      expect((v - 0.5).abs(), greaterThan(1e-3));
    });

    test('函数名大小写不敏感 SIN(30)=0.5', () {
      expect(CalculatorEngine.evaluate('SIN(30)'), closeTo(0.5, 1e-9));
    });

    test('反三角函数角度制 asin(0.5)=30', () {
      expect(CalculatorEngine.evaluate('asin(0.5)'), closeTo(30, 1e-9));
    });

    test('反三角函数弧度制 asin(0.5)=π/6', () {
      expect(
        CalculatorEngine.evaluate('asin(0.5)', angleUnit: AngleUnit.radian),
        closeTo(math.pi / 6, 1e-9),
      );
    });
  });

  group('CalculatorEngine 空白字符', () {
    test('忽略空格', () {
      expect(CalculatorEngine.evaluate(' 1 + 2 '), 3);
    });

    test('忽略制表符与换行', () {
      expect(CalculatorEngine.evaluate('1\t+\n2'), 3);
    });
  });

  group('CalculatorEngine 错误处理', () {
    test('除以零抛出异常', () {
      expect(() => CalculatorEngine.evaluate('1/0'), throwsA(isA<CalculatorException>()));
    });

    test('运算结果除以零抛出异常 1/(2-2)', () {
      expect(
        () => CalculatorEngine.evaluate('1/(2-2)'),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('以运算符结尾抛出异常', () {
      expect(() => CalculatorEngine.evaluate('1+'), throwsA(isA<CalculatorException>()));
    });

    test('缺少右括号抛出异常', () {
      expect(() => CalculatorEngine.evaluate('(1+2'), throwsA(isA<CalculatorException>()));
    });

    test('多余右括号抛出异常', () {
      expect(() => CalculatorEngine.evaluate('1+2)'), throwsA(isA<CalculatorException>()));
    });

    test('空表达式抛出异常', () {
      expect(() => CalculatorEngine.evaluate(''), throwsA(isA<CalculatorException>()));
      expect(() => CalculatorEngine.evaluate('   '), throwsA(isA<CalculatorException>()));
    });

    test('非法字符抛出异常', () {
      expect(() => CalculatorEngine.evaluate('abc'), throwsA(isA<CalculatorException>()));
    });

    test('函数无参数抛出异常', () {
      expect(() => CalculatorEngine.evaluate('sin()'), throwsA(isA<CalculatorException>()));
    });

    test('双小数点抛出异常', () {
      expect(() => CalculatorEngine.evaluate('1..2'), throwsA(isA<CalculatorException>()));
    });

    test('连续运算符抛出异常 2**3', () {
      expect(() => CalculatorEngine.evaluate('2**3'), throwsA(isA<CalculatorException>()));
    });

    test('无理数域外 sqrt(-1) 抛出异常', () {
      expect(() => CalculatorEngine.evaluate('sqrt(-1)'), throwsA(isA<CalculatorException>()));
    });

    test('结果溢出抛出异常', () {
      expect(
        () => CalculatorEngine.evaluate('9e307*10'),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('异常携带可读消息', () {
      try {
        CalculatorEngine.evaluate('1+');
        fail('应当抛出 CalculatorException');
      } on CalculatorException catch (e) {
        expect(e.message, isNotEmpty);
      }
    });
  });

  group('formatResult 结果格式化', () {
    test('整数去掉小数点', () {
      expect(formatResult(3.0), '3');
    });

    test('消除浮点误差 0.30000000000000004 -> 0.3', () {
      expect(formatResult(0.1 + 0.2), '0.3');
    });

    test('保留 12 位有效数字', () {
      expect(formatResult(1 / 3), '0.333333333333');
    });

    test('去掉末尾多余零', () {
      expect(formatResult(100.0), '100');
      expect(formatResult(2.50), '2.5');
    });

    test('负零显示为 0', () {
      expect(formatResult(-0.0), '0');
    });

    test('超大数使用科学计数法', () {
      expect(formatResult(1e16), '1e16');
    });

    test('极小数使用科学计数法', () {
      expect(formatResult(1.5e-10), '1.5e-10');
    });

    test('负数', () {
      expect(formatResult(-2.5), '-2.5');
    });
  });
}
