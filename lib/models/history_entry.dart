/// 一条历史计算记录。
class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  /// 用户输入的原始表达式（如 `1+2`）。
  final String expression;

  /// 格式化后的计算结果（如 `3`）。
  final String result;

  /// 计算时间。
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      other is HistoryEntry &&
      other.expression == expression &&
      other.result == result;

  @override
  int get hashCode => Object.hash(expression, result);

  @override
  String toString() => '$expression = $result';
}
