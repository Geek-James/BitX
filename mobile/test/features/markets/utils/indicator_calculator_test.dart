import 'package:flutter_test/flutter_test.dart';
import 'package:bitx_mobile/features/markets/models/kline_data.dart';
import 'package:bitx_mobile/features/markets/utils/indicator_calculator.dart';

void main() {
  group('IndicatorCalculator', () {
    late List<KlineData> testData;

    setUp(() {
      // 创建测试数据
      testData = [
        KlineData(
          timestamp: DateTime(2024, 1, 1),
          open: 100,
          high: 110,
          low: 95,
          close: 105,
          volume: 1000,
        ),
        KlineData(
          timestamp: DateTime(2024, 1, 2),
          open: 105,
          high: 115,
          low: 100,
          close: 110,
          volume: 1100,
        ),
        KlineData(
          timestamp: DateTime(2024, 1, 3),
          open: 110,
          high: 120,
          low: 105,
          close: 115,
          volume: 1200,
        ),
        KlineData(
          timestamp: DateTime(2024, 1, 4),
          open: 115,
          high: 125,
          low: 110,
          close: 120,
          volume: 1300,
        ),
        KlineData(
          timestamp: DateTime(2024, 1, 5),
          open: 120,
          high: 130,
          low: 115,
          close: 125,
          volume: 1400,
        ),
      ];
    });

    group('calculateMA', () {
      test('计算MA3正确', () {
        final result = IndicatorCalculator.calculateMA(testData, 3);
        
        expect(result.length, testData.length);
        expect(result[0], isNull);
        expect(result[1], isNull);
        expect(result[2], closeTo(110, 0.01)); // (105+110+115)/3
        expect(result[3], closeTo(115, 0.01)); // (110+115+120)/3
        expect(result[4], closeTo(120, 0.01)); // (115+120+125)/3
      });

      test('数据不足时返回null', () {
        final result = IndicatorCalculator.calculateMA(testData.take(2).toList(), 3);
        
        expect(result.length, 2);
        expect(result[0], isNull);
        expect(result[1], isNull);
      });
    });

    group('calculateEMA', () {
      test('计算EMA正确', () {
        final result = IndicatorCalculator.calculateEMA(testData, 3);
        
        expect(result.length, testData.length);
        expect(result[0], isNull);
        expect(result[1], isNull);
        expect(result[2], isNotNull);
        
        // 第一个EMA值应该等于MA
        expect(result[2], closeTo(110, 0.01));
      });

      test('数据不足时返回null', () {
        final result = IndicatorCalculator.calculateEMA(testData.take(2).toList(), 3);
        
        expect(result.length, 2);
        expect(result.every((v) => v == null), isTrue);
      });
    });

    group('calculateBOLL', () {
      test('计算布林带正确', () {
        final result = IndicatorCalculator.calculateBOLL(testData, period: 3);
        
        expect(result.containsKey('upper'), isTrue);
        expect(result.containsKey('middle'), isTrue);
        expect(result.containsKey('lower'), isTrue);
        
        final upper = result['upper']!;
        final middle = result['middle']!;
        final lower = result['lower']!;
        
        expect(upper.length, testData.length);
        expect(middle.length, testData.length);
        expect(lower.length, testData.length);
        
        // 前两个值应该为null
        expect(upper[0], isNull);
        expect(upper[1], isNull);
        
        // 上轨应该大于中轨，中轨应该大于下轨
        for (int i = 2; i < testData.length; i++) {
          if (upper[i] != null && middle[i] != null && lower[i] != null) {
            expect(upper[i]! > middle[i]!, isTrue);
            expect(middle[i]! > lower[i]!, isTrue);
          }
        }
      });
    });

    group('calculateMACD', () {
      test('计算MACD正确', () {
        // 需要更多数据来测试MACD
        final moreData = List.generate(30, (i) {
          return KlineData(
            timestamp: DateTime(2024, 1, i + 1),
            open: 100 + i.toDouble(),
            high: 110 + i.toDouble(),
            low: 95 + i.toDouble(),
            close: 105 + i.toDouble(),
            volume: 1000 + i.toDouble(),
          );
        });
        
        final result = IndicatorCalculator.calculateMACD(moreData);
        
        expect(result.containsKey('dif'), isTrue);
        expect(result.containsKey('dea'), isTrue);
        expect(result.containsKey('macd'), isTrue);
        
        final dif = result['dif']!;
        final dea = result['dea']!;
        final macd = result['macd']!;
        
        expect(dif.length, moreData.length);
        expect(dea.length, moreData.length);
        expect(macd.length, moreData.length);
      });

      test('数据不足时返回null', () {
        final result = IndicatorCalculator.calculateMACD(testData);
        
        final dif = result['dif']!;
        expect(dif.every((v) => v == null), isTrue);
      });
    });

    group('calculateRSI', () {
      test('计算RSI正确', () {
        // 需要更多数据来测试RSI
        final moreData = List.generate(20, (i) {
          return KlineData(
            timestamp: DateTime(2024, 1, i + 1),
            open: 100 + i.toDouble(),
            high: 110 + i.toDouble(),
            low: 95 + i.toDouble(),
            close: 105 + i.toDouble() * (i % 2 == 0 ? 1 : -0.5),
            volume: 1000 + i.toDouble(),
          );
        });
        
        final result = IndicatorCalculator.calculateRSI(moreData, period: 14);
        
        expect(result.length, moreData.length);
        
        // RSI值应该在0-100之间
        for (final value in result) {
          if (value != null) {
            expect(value >= 0 && value <= 100, isTrue);
          }
        }
      });
    });

    group('calculateKDJ', () {
      test('计算KDJ正确', () {
        // 需要更多数据来测试KDJ
        final moreData = List.generate(15, (i) {
          return KlineData(
            timestamp: DateTime(2024, 1, i + 1),
            open: 100 + i.toDouble(),
            high: 110 + i.toDouble(),
            low: 95 + i.toDouble(),
            close: 105 + i.toDouble(),
            volume: 1000 + i.toDouble(),
          );
        });
        
        final result = IndicatorCalculator.calculateKDJ(moreData, period: 9);
        
        expect(result.containsKey('k'), isTrue);
        expect(result.containsKey('d'), isTrue);
        expect(result.containsKey('j'), isTrue);
        
        final k = result['k']!;
        final d = result['d']!;
        final j = result['j']!;
        
        expect(k.length, moreData.length);
        expect(d.length, moreData.length);
        expect(j.length, moreData.length);
        
        // 前8个值应该为null
        for (int i = 0; i < 8; i++) {
          expect(k[i], isNull);
          expect(d[i], isNull);
          expect(j[i], isNull);
        }
      });
    });
  });
}

