// lib/record.dart ファイル

class Record {
  final int? id; // ID: データベースの主キー (自動採番)
  final String dateTime; // 測定日時 (TEXT型で保存)
  final double weight; // 体重 (REAL型)
  final double bmi; // BMI結果 (REAL型)
  final String judgement; // 判定結果 (TEXT型)

  Record({
    this.id,
    required this.dateTime,
    required this.weight,
    required this.bmi,
    required this.judgement,
  });

  // DBへ保存するためにMapに変換するメソッド
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime,
      'weight': weight,
      'bmi': bmi,
      'judgement': judgement,
    };
  }

  // MapからRecordオブジェクトに変換するファクトリコンストラクタ
  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      dateTime: map['dateTime'],
      weight: map['weight'],
      bmi: map['bmi'],
      judgement: map['judgement'],
    );
  }

  // レコードをコピーし、一部の値だけを上書きするためのメソッド
  Record copyWith({
    int? id,
    String? dateTime,
    double? weight,
    double? bmi,
    String? judgement,
  }) {
    return Record(
      id: id ?? this.id, // IDが指定されていなければ、既存のIDを使う
      dateTime: dateTime ?? this.dateTime,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      judgement: judgement ?? this.judgement,
    );
  }
}
