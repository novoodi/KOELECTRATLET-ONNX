import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'kobert_tokenizer.dart';
import 'emotion_model.dart';

class EmotionClassifierService {
  Interpreter? _interpreter;
  KoBertTokenizer? _tokenizer;

  static const int maxLen = 128;
  static const int numClasses = 6;

  Future<void> init() async {
    try {
      final options = InterpreterOptions()..threads = 1;

      _interpreter = await Interpreter.fromAsset(
        'assets/model_float32.tflite',
        options: options,
      );


      print('✅ 모델 로드 성공');

      // 입력 텐서 크기 명시적 설정
      _interpreter!.resizeInputTensor(0, [1, maxLen]);
      _interpreter!.resizeInputTensor(1, [1, maxLen]);
      _interpreter!.resizeInputTensor(2, [1, maxLen]);

      _interpreter!.allocateTensors();
      print('✅ 텐서 크기 조정 및 메모리 할당 완료');

      print("🔍 --- 모델 텐서 상세 정보 ---");
      for (var t in _interpreter!.getInputTensors()) {
        print("📥 Input: 이름=${t.name}, shape=${t.shape}, type=${t.type}");
      }
      for (var t in _interpreter!.getOutputTensors()) {
        print("📤 Output: 이름=${t.name}, shape=${t.shape}, type=${t.type}");
      }
      print("------------------------------");

      _tokenizer = await KoBertTokenizer.loadFromFile('assets/vocab.txt');

      print('✅ 토크나이저 로드 완료');

    } catch (e, st) {
      print("❌ 초기화 실패: $e");
      print(st);
    }
  }

  // List<int> → Int32List 변환
  Int32List _toInt32(List<int> list) => Int32List.fromList(list);

  AnalysisResult? analyze(String text) {
    if (_interpreter == null || _tokenizer == null) {
      print("❌ 모델 준비 안됨");
      return null;
    }

    try {
      // ----------------------
      // 1. 토크나이징
      // ----------------------
      final tokens = _tokenizer!.tokenize(text);
      final paddedTokens = _tokenizer!.padSequence(tokens, maxLen);

      final inputIds = paddedTokens;
      final attentionMask = List.generate(maxLen, (i) => i < tokens.length ? 1 : 0);
      final tokenTypeIds = List.filled(maxLen, 0);

      // ----------------------
      // 2. Int32List 변환
      // ----------------------
      final idsTensor = _toInt32(inputIds);
      final maskTensor = _toInt32(attentionMask);
      final typeTensor = _toInt32(tokenTypeIds);

      // ----------------------
      // 3. TFLite 입력 구성 (순서 100% 정확)
      // ----------------------
      final inputs = <Object>[
        [maskTensor],   // Input 0 → attention_mask
        [idsTensor],    // Input 1 → input_ids
        [typeTensor],   // Input 2 → token_type_ids
      ];

      // ----------------------
      // 4. 출력 shape = [1, 6]
// ----------------------
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));
      final outputs = {0: output};

// ----------------------
// 5. 실행
// ----------------------
      _interpreter!.runForMultipleInputs(inputs, outputs);

// logits = output[0].toList()  // List<double>
      final logits = output[0];
      final probs = _softmax(logits);

      // Debug
      final emotionLabels = EmotionLabel.values;
      for (int i = 0; i < probs.length; i++) {
        print(" - ${emotionLabels[i].title}: ${(probs[i] * 100).toStringAsFixed(2)}%");
      }

      // ----------------------
      // 6. 최고 감정 선택
      // ----------------------
      int maxIndex = 0;
      double maxScore = probs[0];

      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxScore) {
          maxScore = probs[i];
          maxIndex = i;
        }
      }

      final emotion = EmotionLabel.fromIndex(maxIndex);

      return AnalysisResult(
        emotion: emotion,
        score: maxScore,
        empathyComment: _getEmpathyComment(emotion),
      );

    } catch (e, st) {
      print("❌ 분석 중 오류: $e");
      print(st);
      return null;
    }
  }

  // Softmax
  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final maxLogit = logits.reduce(max);
    final expVals = logits.map((e) => exp(e - maxLogit)).toList();
    final sum = expVals.reduce((a, b) => a + b);
    return expVals.map((e) => e / sum).toList();
  }

  String _getEmpathyComment(EmotionLabel emotion) {
    switch (emotion) {
      case EmotionLabel.anger:
        return "마음이 많이 복잡하시군요. 잠시 쉬어가는 건 어때요?";
      case EmotionLabel.sadness:
        return "힘든 하루였나요? 따뜻한 위로가 필요해 보여요.";
      case EmotionLabel.anxiety:
        return "불안한 마음이 드는군요. 차분해지는 시간이 필요해요.";
      case EmotionLabel.hurt:
        return "상처받은 마음, 소확행이 어루만져 드릴게요.";
      case EmotionLabel.embarrassment:
        return "당황스러운 일이 있으셨나요? 괜찮아요, 누구나 그러니까요.";
      case EmotionLabel.happiness:
        return "오늘 정말 좋은 일이 있으셨군요! 이 기분을 유지해봐요.";
    }
  }

  void close() {
    _interpreter?.close();
  }
}
