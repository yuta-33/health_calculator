// lib/goal.dart ファイル

class Goal {
  final double targetWeight;
  final String targetDate;

  Goal({required this.targetWeight, required this.targetDate});

  // MapからGoalオブジェクトに変換
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      targetWeight: map['targetWeight'],
      targetDate: map['targetDate'],
    );
  }
}
