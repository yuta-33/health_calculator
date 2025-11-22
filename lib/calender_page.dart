// lib/calendar_page.dart ファイル

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';
import 'record.dart';
import 'package:intl/intl.dart'; // ← Add this line

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // 表示形式 (月表示)
  DateTime _focusedDay = DateTime.now(); // 現在選択されている月/日
  DateTime? _selectedDay; // ユーザーがタップして選択した日

  // データベースから読み込んだ全記録
  List<Record> _records = [];
  // 日付ごとの記録をマッピングするためのMap
  Map<DateTime, List<Record>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // データベースからデータを読み込み、カレンダー用の形式に整形する
  void _loadRecords() async {
    final allRecords = await DatabaseHelper.instance.readAllRecords();
    // DateFormatを定義 (保存時と同じ形式: yyyy/MM/dd HH:mm)
    final formatter = DateFormat('yyyy/MM/dd HH:mm');
    // 読み込んだ記録を日付ごとにグループ化する
    final Map<DateTime, List<Record>> eventMap = {};
    for (var record in allRecords) {
      try {
        // ★修正: try-catchで囲み、不正なデータをスキップ★
        final date = formatter.parse(record.dateTime);

        // 時刻を無視して日付部分だけを取り出す
        final normalizedDate = DateTime(date.year, date.month, date.day);

        if (eventMap[normalizedDate] == null) {
          eventMap[normalizedDate] = [];
        }
        eventMap[normalizedDate]!.add(record);
      } catch (e) {
        // 不正な形式のレコードを検知した場合、そのレコードをスキップし、他の処理を続行
        print('警告: 不正な日付形式のレコードをスキップしました: ${record.dateTime}');
        continue;
      }
    }

    setState(() {
      _records = allRecords;
      _events = eventMap;
    });
  }

  // 特定の日のイベント（記録）を取得するヘルパー関数
  List<Record> _getEventsForDay(DateTime day) {
    // 時刻を無視して検索キーを作成
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('測定履歴カレンダー'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          TableCalendar<Record>(
            // TableCalendar ウィジェット
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay, // イベントの読み込み
            // 測定日を示すマークの設定
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // 選択された日の記録リスト
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay ?? _focusedDay).length,
              itemBuilder: (context, index) {
                final record = _getEventsForDay(
                  _selectedDay ?? _focusedDay,
                )[index];
                return ListTile(
                  title: Text(
                    '${record.dateTime.split(' ')[1]} - ${record.judgement}',
                  ),
                  subtitle: Text(
                    'BMI: ${record.bmi.toStringAsFixed(1)} / W: ${record.weight.toStringAsFixed(1)} kg',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// TableCalendarのユーティリティ関数（main.dartからコピー）
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
