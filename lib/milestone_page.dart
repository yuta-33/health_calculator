// lib/milestone_page.dart ファイル

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'record.dart';
import 'calender_page.dart';
import 'main.dart';
import 'goal.dart';

class MilestonePage extends StatefulWidget {
  const MilestonePage({super.key});

  @override
  State<MilestonePage> createState() => _MilestonePageState();
}

class _MilestonePageState extends State<MilestonePage> {
  Record? _initialRecord; // 初回測定の記録
  Record? _latestRecord; // 最新測定の記録
  double _targetWeight = 60.0; // ★目標体重を設定★
  DateTime? _targetDate; // 目標日付
  final TextEditingController _targetWeightController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMilestoneData();
  }

  // データをデータベースから読み込むメソッド
  Future<void> _loadMilestoneData() async {
    final first = await DatabaseHelper.instance.readFirstRecord();
    final latest = await DatabaseHelper.instance.readLatestRecord();

    // ★目標データを読み込む★
    final goalMap = await DatabaseHelper.instance.readGoal();

    setState(() {
      _initialRecord = first ?? _initialRecord;
      _latestRecord = latest;

      // 目標データがあれば読み込む
      if (goalMap != null) {
        _targetWeight = goalMap['targetWeight'];
        // 文字列として保存された目標日をDateTime型に変換
        _targetDate = DateFormat('yyyy/MM/dd').parse(goalMap['targetDate']);
      }

      // ... (既存の初回記録がnullの場合の処理をそのまま残す) ...
      _targetDate ??= DateTime.now().add(const Duration(days: 90));

      if (_initialRecord == null) {
        _initialRecord = Record(
          dateTime: '記録なし',
          weight: 0,
          bmi: 0,
          judgement: '',
        );
      }
      _isLoading = false; // ★データを全てセットし終えたら、ロード完了★
    });
  }

  // lib/milestone_page.dart

  // ... (_loadMilestoneData の後、build メソッドの上に追加) ...

  // 目標設定用のダイアログを表示するメソッド
  void _showGoalDialog() {
    // 現在の設定値をコントローラーにセット
    _targetWeightController.text = _targetWeight.toStringAsFixed(1);
    DateTime tempTargetDate = _targetDate!; // 現在の目標日を一時的に保持

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('目標設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '目標体重 (kg)'),
              ),
              const SizedBox(height: 20),
              // 日付選択ボタン
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: tempTargetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    tempTargetDate = picked;
                    // ダイアログを再描画するため、Navigatorをポップしてもう一度開く
                    Navigator.pop(context);
                    _showGoalDialog();
                  }
                },
                child: Text(
                  '目標達成日: ${DateFormat('yyyy/MM/dd').format(tempTargetDate)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final newWeight = double.tryParse(_targetWeightController.text);
                if (newWeight != null && newWeight > 0) {
                  // DBに保存し、画面を更新
                  DatabaseHelper.instance
                      .saveGoal(
                        newWeight,
                        DateFormat('yyyy/MM/dd').format(tempTargetDate),
                      )
                      .then((_) {
                        _loadMilestoneData(); // DBから最新データを再ロード
                        Navigator.pop(context);
                      });
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 全体で減らすべき目標体重 (開始体重 - 目標体重)
  double get totalWeightToLose {
    if (_initialRecord == null || _initialRecord!.weight == 0) return 0.0;
    return _initialRecord!.weight - _targetWeight;
  }

  // 現在までに減らした体重
  double get weightLostSoFar {
    if (_initialRecord == null || _latestRecord == null) return 0.0;
    return _initialRecord!.weight - _latestRecord!.weight;
  }

  // 総合進捗度 (減量目標に対する達成度)
  double get totalProgress {
    if (totalWeightToLose <= 0) return 0.0;
    final progress = (weightLostSoFar / totalWeightToLose) * 100;
    return progress.clamp(0.0, 100.0); // 0%から100%の間に収める
  }

  // 目標達成までにかかる総日数
  int get totalDaysToTarget {
    if (_initialRecord == null ||
        _targetDate == null ||
        _initialRecord!.dateTime == '記録なし')
      return 0;

    // 初回記録の日時文字列をDateTimeオブジェクトに変換 (時刻を無視して日付のみ)
    final initialDate = DateFormat(
      'yyyy/MM/dd HH:mm',
    ).parse(_initialRecord!.dateTime);
    final initialDay = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    final targetDay = DateTime(
      _targetDate!.year,
      _targetDate!.month,
      _targetDate!.day,
    );

    // 目標日と開始日の差分を日数で返す
    return targetDay.difference(initialDay).inDays;
  }

  // 目標達成までに必要な週間減量量
  double get requiredWeeklyLoss {
    if (totalDaysToTarget <= 0 || totalWeightToLose <= 0) return 0.0;
    final totalWeeks = totalDaysToTarget / 7;
    return totalWeightToLose / totalWeeks;
  }

  // 目標達成まで残り日数
  int get daysRemaining {
    if (_targetDate == null) return 0;
    final remaining = _targetDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    // ★最初にローディング状態をチェック★
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('進捗管理と目標'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ), // ロード中スピナー
      );
    }
    // 画面に表示する最新/初回体重
    final latestWeight = _latestRecord?.weight.toStringAsFixed(1) ?? '--';
    final initialWeight = _initialRecord?.weight.toStringAsFixed(1) ?? '--';

    if (_initialRecord?.weight == 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('進捗管理と目標'),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: Text('進捗を確認するには、まず体重を記録してください。')),
        floatingActionButton: FloatingActionButton(
          onPressed: _showGoalDialog,
          backgroundColor: Colors.green,
          child: const Icon(Icons.edit),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('進捗管理と目標'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGoalDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.edit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 目標サマリー ---
            Text(
              '目標体重: ${_targetWeight.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              '達成目標日: ${DateFormat('yyyy/MM/dd').format(_targetDate!)} (残り ${daysRemaining} 日)',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(),

            // --- 総合進捗表示 ---
            const Text(
              '総合進捗',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '開始体重: ${initialWeight} kg (開始日: ${(_initialRecord!.dateTime != '記録なし') ? _initialRecord!.dateTime.split(' ')[0] : '--'})',
            ),
            Text('最新体重: ${latestWeight} kg'),
            const SizedBox(height: 10),

            // 進捗状況
            Text(
              '総減量目標: ${totalWeightToLose.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '達成済み減量: ${weightLostSoFar.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 18, color: Colors.blue),
            ),
            Text(
              '目標まで残り: ${(totalWeightToLose - weightLostSoFar).toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),

            // プログレスバー
            LinearProgressIndicator(
              value: totalProgress / 100,
              backgroundColor: Colors.grey[300],
              color: Colors.lightGreen,
            ),
            const SizedBox(height: 10),
            Text('達成率: ${totalProgress.toStringAsFixed(1)} %'),

            const SizedBox(height: 40),
            const Text(
              '週間目標（ペース）',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // --- 週間目標表示 ---
            Text(
              '目標達成に必要な期間: ${(totalDaysToTarget / 7).toStringAsFixed(1)} 週間',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '★ 必要な週間減量目標: ${requiredWeeklyLoss.toStringAsFixed(2)} kg/週 ★',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '（このペースを維持して目標達成を目指します）',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
