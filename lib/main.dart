import 'package:flutter/material.dart';
import './record.dart';
import './database_helper.dart';
import 'package:intl/intl.dart';

const double cmToFeet = 0.0328084;
const double feetToCm = 30.48;
const double kgToLbf = 2.20462;
const double lbfToKg = 0.453592;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // アプリ全体のデザインを設定する部分です
    return MaterialApp(
      title: '健康計算器', // AndroidやWindowsのタスクバーに表示される名前
      theme: ThemeData(
        // アプリ全体のテーマカラーを青色に設定
        primarySwatch: Colors.blue,
      ),
      // 最初に表示する画面を指定します
      home: const HealthCalculatorPage(),
    );
  }
}

// 健康計算機のメイン画面（入力と結果表示を行う場所）
class HealthCalculatorPage extends StatefulWidget {
  const HealthCalculatorPage({super.key});

  @override
  State<HealthCalculatorPage> createState() => _HealthCalculatorPageState();
}

class _HealthCalculatorPageState extends State<HealthCalculatorPage> {
  // ① 状態変数: 初期値は 'male' (男性) に設定
  String selectedGender = 'male';

  int age = 25; // 初期値として25歳を設定
  double height = 170.0; // 初期値として170.0cmを設定
  double weight = 65.0; // 初期値として65.0kgを設定
  double bmiResult = 0.0;
  double idealWeight = 0.0;

  // BMI判定結果の表示用変数
  String bmiJudgement = '未計算';

  bool isMetric = true;

  // ② コントローラー変数の宣言 ★ここから追加★
  // late final は「後で初期化する、一度きりの値」という意味です。
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  List<Record> historyList = [];

  @override
  void initState() {
    super.initState();
    // ③ initState: コントローラーを初期化し、初期値を設定
    _ageController = TextEditingController(text: age.toString());
    _heightController = TextEditingController(text: height.toString());
    _weightController = TextEditingController(text: weight.toString());
    _loadRecords();
  }

  // DBから全記録を読み込み、historyListを更新するメソッド
  Future<void> _loadRecords() async {
    final records = await DatabaseHelper.instance.readAllRecords();
    setState(() {
      historyList = records; // データベースから読み込んだ履歴でリストを上書き
    });
  }

  @override
  void dispose() {
    // ④ dispose: 画面が閉じるときにコントローラーを破棄 (メモリ管理のため重要)
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // 計算を実行するメソッド (単位変換ロジック入り)
  void calculate() async {
    // 計算に使用するメートル法 (m, kg) のローカル変数
    double heightInMeters;
    double weightInKg = weight; // 初期値として現在の体重をセット

    // 1. 単位の確認と変換
    if (isMetric) {
      // メートル法 (cm/kg) の場合: cm を m に変換
      heightInMeters = height / 100;
    } else {
      // ヤード・ポンド法 (ft/lbf) の場合: ft と lbf を m と kg に変換

      // 身長: ft を m に変換 (1 ft = 0.3048 m)
      heightInMeters = height * 0.3048;

      // 体重: lbf を kg に変換 (1 lbf ≈ 0.453592 kg)
      weightInKg = weight * 0.453592;
    }

    // 2. コア計算
    // BMIの計算: kg / (m * m)
    double bmi = weightInKg / (heightInMeters * heightInMeters);

    // 理想体重の計算 (BMI 22として): 22 * (m * m) -> 結果は kg
    double idealKg = 22 * (heightInMeters * heightInMeters);

    //3. 体型判定ロジック
    String judgement;
    if (bmi < 18.5) {
      judgement = '低体重';
    } else if (bmi < 25) {
      judgement = '普通体重';
    } else if (bmi < 30) {
      judgement = '肥満（1度）-やや太りすぎ';
    } else if (bmi < 35) {
      judgement = '肥満（2度）-太りすぎ';
    } else if (bmi < 40) {
      judgement = '肥満（3度）-でっかいうんこしそうだね';
    } else {
      judgement = '肥満（4度）-怪物じゃんお前';
    }

    // データベースに記録を保存
    final newRecord = Record(
      dateTime: DateFormat(
        'yyyy/MM/dd HH:mm',
      ).format(DateTime.now()), // 日時を整形して保存
      weight: weightInKg,
      bmi: bmi,
      judgement: judgement,
    );
    await DatabaseHelper.instance.create(newRecord); // DBに挿入
    // 4. 結果の表示と単位変換 (表示用)
    setState(() {
      bmiResult = bmi;
      bmiJudgement = judgement;

      // 理想体重をユーザーの選択した単位に戻す
      if (isMetric) {
        idealWeight = idealKg; // kg のまま
      } else {
        // kg を lbf に変換 (1 kg ≈ 2.20462 lbf)
        idealWeight = idealKg * 2.20462;
      }
    });
  }

  // ... (Widget build メソッドに続く)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康計算器')),

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            // 画面全体にコンテンツを配置するために、中央寄せを解除（または上に寄せます）
            // mainAxisAlignment: MainAxisAlignment.center, を削除
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '性別を選択してください',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // ② 性別選択ボタン (Rowとボタンを使って横並びにする)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 男性のボタン
                  ElevatedButton(
                    onPressed: () {
                      // ③ 状態を更新する (setState)
                      setState(() {
                        selectedGender = 'male';
                      });
                    },
                    // 選択されていたら青色、そうでなければ灰色にする
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGender == 'male'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: const Text('男性'),
                  ),

                  const SizedBox(width: 20), // ボタン間のスペース
                  // 女性のボタン
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedGender = 'female';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGender == 'female'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: const Text('女性'),
                  ),
                ],
              ),

              // ★ここに追加★ 単位切り替えスイッチ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ヤード・ポンド法 (ft/lbf)'),
                  Switch(
                    value: isMetric,
                    onChanged: (newValue) {
                      setState(() {
                        bool oldIsMetric = isMetric;
                        isMetric = newValue;
                        // 単位切り替え時に、入力値を一旦クリアするか、変換するかは次のステップで考慮
                        // 今回はシンプルに、ラベル表示を切り替えるだけにします。
                        // cm -> ft または ft -> cm の変換
                        if (oldIsMetric && !isMetric) {
                          // メートル法(cm)からヤード・ポンド法(ft)へ
                          height = height * cmToFeet;
                        } else if (!oldIsMetric && isMetric) {
                          // ヤード・ポンド法(ft)からメートル法(cm)へ
                          height = height * feetToCm;
                        }

                        // kg -> lbf または lbf -> kg の変換
                        if (oldIsMetric && !isMetric) {
                          // メートル法(kg)からヤード・ポンド法(lbf)へ
                          weight = weight * kgToLbf;
                        } else if (!oldIsMetric && isMetric) {
                          // ヤード・ポンド法(lbf)からメートル法(kg)へ
                          weight = weight * lbfToKg;
                        }
                      });
                      // 3. コントローラーを更新して画面に反映させる（重要！）
                      // TextEditingControllerはsetStateでは自動で更新されないため、手動で更新します
                      _heightController.text = height.toStringAsFixed(1);
                      _weightController.text = weight.toStringAsFixed(1);

                      // 4. 計算結果も即座に更新する
                      calculate();
                    },
                  ),
                  const Text('メートル法 (cm/kg)'),
                ],
              ),

              const SizedBox(height: 30), // ← この後に年齢のTextFieldが続く
              // 年齢の入力欄
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: TextField(
                  keyboardType: TextInputType.number, // 数字キーボードを表示
                  decoration: const InputDecoration(
                    labelText: '年齢 (歳)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // 入力された値を状態変数にセット
                    age = int.tryParse(value) ?? 0; // 数字に変換できなければ0にする
                  },
                  controller: _ageController,
                ),
              ),

              const SizedBox(height: 20),

              // 身長の入力欄
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isMetric ? '身長 (cm)' : '身長 (ft)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    height = double.tryParse(value) ?? 0.0;
                  },
                  controller: _heightController,
                ),
              ),

              const SizedBox(height: 20),

              // 体重の入力欄
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isMetric ? '体重 (kg)' : '体重 (lbf)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    weight = double.tryParse(value) ?? 0.0;
                  },
                  controller: _weightController,
                ),
              ),

              // 体重のTextFieldの直後に追加
              const SizedBox(height: 40),

              // 計算ボタン
              ElevatedButton(
                onPressed: calculate, // 上で定義した calculate メソッドを呼び出す
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('結果を計算する'),
              ),

              const SizedBox(height: 40),

              // 計算結果の表示
              Text(
                'あなたのBMI: ${bmiResult.toStringAsFixed(1)}', // 小数点第1位まで表示
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              // BMI判定結果の表示
              Text(
                bmiJudgement,
                style: TextStyle(
                  fontSize: bmiJudgement == '肥満（4度）-怪物じゃんお前' ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: bmiJudgement == '普通体重'
                      ? Colors.green
                      : bmiJudgement == '低体重'
                      ? Colors.orange
                      : Colors.red,
                ),
              ),

              const SizedBox(height: 10),
              Text(
                '理想体重: ${idealWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),

              // ④ 現在の選択状態を表示 (デバッグ用)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('現在の選択: $selectedGender'),
              ),
              // 履歴リストの表示
              // ListをWidgetのリストに変換し、Columnの子要素として展開
              const SizedBox(height: 50),
              const Text(
                '--- 計算履歴 ---',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ...historyList.map((record) {
                // Recordオブジェクトを使って表示を整形
                return ListTile(
                  title: Text(
                    '${record.dateTime} - ${record.judgement}',
                  ), // 日時と判定を表示
                  subtitle: Text(
                    'BMI: ${record.bmi.toStringAsFixed(1)} / W: ${record.weight.toStringAsFixed(1)} kg',
                  ), // 詳細を表示
                );
              }).toList(),

              const SizedBox(height: 50), // 最下部の余白
            ],
          ),
        ),
      ),
    );
  }
}
