import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class KoBertTokenizer {
  final Map<String, int> vocab = {};

  static Future<KoBertTokenizer> loadFromFile(String assetPath) async {
    final tokenizer = KoBertTokenizer();
    try {
      final vocabText = await rootBundle.loadString(assetPath);
      final lines = vocabText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final token = lines[i].trim();
        if (token.isNotEmpty) {
          tokenizer.vocab[token] = i;
        }
      }
      print("✅ 단어 사전 로드 완료 (단어 수: ${tokenizer.vocab.length})");
    } catch (e) {
      print("❌ 단어 사전 로드 실패: $e");
    }
    return tokenizer;
  }

  List<int> tokenize(String text) {
    List<int> tokens = [2]; // [CLS]

    // 텍스트 정제 (코틀린과 동일)
    String cleanText = text
        .replaceAllMapped(RegExp(r"([?.!,;])"), (match) => " ${match.group(1)} ")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();

    final basicTokens = cleanText.split(" ");

    // WordPiece MaxMatch 알고리즘 (코틀린과 100% 동일)
    for (String token in basicTokens) {
      if (token.isEmpty) continue;

      int start = 0;
      while (start < token.length) {
        int end = token.length;
        int matchedId = -1;
        int matchedEnd = -1;

        // 가장 긴 일치하는 조각을 찾을 때까지 길이를 줄여가며 탐색
        while (end > start) {
          String subText = token.substring(start, end);

          // 첫 번째 조각이 아니면 앞에 "##"을 붙여서 탐색
          if (start > 0) {
            subText = "##$subText";
          }

          if (vocab.containsKey(subText)) {
            matchedId = vocab[subText]!;
            matchedEnd = end;
            break; // 가장 긴 것을 찾았으면 중단
          }
          end--;
        }

        if (matchedId != -1) {
          tokens.add(matchedId);
          start = matchedEnd;
        } else {
          tokens.add(1); // [UNK]
          start++;
        }
      }
    }

    tokens.add(3); // [SEP]
    return tokens;
  }

  // 코틀린의 padSequence와 동일
  List<int> padSequence(List<int> tokens, int maxLength) {
    final padded = List<int>.filled(maxLength, 0);
    for (int i = 0; i < tokens.length && i < maxLength; i++) {
      padded[i] = tokens[i];
    }
    return padded;
  }
}