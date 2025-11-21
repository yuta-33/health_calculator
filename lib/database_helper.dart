// lib/database_helper.dart ファイル

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'record.dart'; // 作成したデータモデルをインポート

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database; // データベースインスタンスを保持

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // データベースファイルのパスを取得
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // DBを開き、なければ onCreate を実行してテーブルを作成
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // テーブルを作成するSQL文を実行
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL'; // double型を保存

    await db.execute('''
      CREATE TABLE records (
        id $idType,
        dateTime $textType,
        weight $realType,
        bmi $realType,
        judgement $textType
      )
    ''');
  }

  // データの挿入 (INSERT)
  Future<Record> create(Record record) async {
    final db = await instance.database;
    final id = await db.insert('records', record.toMap());
    return record.copyWith(id: id); // 挿入されたIDを付けて返す
  }

  // 全データの取得 (SELECT)
  Future<List<Record>> readAllRecords() async {
    final db = await instance.database;
    // 最新の記録が上に来るように降順でソート
    final result = await db.query('records', orderBy: 'id DESC');

    // MapのリストをRecordオブジェクトのリストに変換
    return result.map((json) => Record.fromMap(json)).toList();
  }
}
