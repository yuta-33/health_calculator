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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // バージョン1から2にアップデートする場合にのみ、goalsテーブルを作成
      const idType = 'INTEGER PRIMARY KEY';
      const realType = 'REAL NOT NULL';
      const textType = 'TEXT NOT NULL';

      await db.execute('''
        CREATE TABLE goals (
          id $idType, 
          targetWeight $realType,
          targetDate $textType
        )
      ''');
    }
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

  Future<Map<String, dynamic>?> readGoal() async {
    final db = await instance.database;
    final result = await db.query('goals', limit: 1); // 1行だけ取得
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 目標データを保存・更新する
  Future<void> saveGoal(double weight, String date) async {
    final db = await instance.database;
    final goalMap = {
      'id': 1, // 常にID=1の行を操作する
      'targetWeight': weight,
      'targetDate': date,
    };
    // 既存のデータがあれば更新 (replace)、なければ挿入 (insert)
    await db.insert(
      'goals',
      goalMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Record?> readFirstRecord() async {
    final db = await instance.database;
    final result = await db.query(
      'records',
      orderBy: 'id ASC', // IDの昇順でソート
      limit: 1, // 最初の1件だけ取得
    );
    if (result.isNotEmpty) {
      return Record.fromMap(result.first);
    } else {
      return null;
    }
  }

  // 最新の記録を取得
  Future<Record?> readLatestRecord() async {
    final db = await instance.database;
    final result = await db.query(
      'records',
      orderBy: 'id DESC', // IDの降順でソート
      limit: 1, // 最新の1件だけ取得
    );
    if (result.isNotEmpty) {
      return Record.fromMap(result.first);
    } else {
      return null;
    }
  }
}
