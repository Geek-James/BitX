import 'dart:math';
import '../models/kline_data.dart';

/// 技术指标计算器
class IndicatorCalculator {
  /// 计算简单移动平均线 (SMA/MA)
  /// 
  /// [data] K线数据列表
  /// [period] 周期
  /// 返回: MA值列表，前period-1个值为null
  static List<double?> calculateMA(List<KlineData> data, int period) {
    if (data.length < period) {
      return List.filled(data.length, null);
    }

    final result = <double?>[];
    
    for (int i = 0; i < data.length; i++) {
      if (i < period - 1) {
        result.add(null);
      } else {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += data[i - j].close;
        }
        result.add(sum / period);
      }
    }
    
    return result;
  }

  /// 计算指数移动平均线 (EMA)
  /// 
  /// [data] K线数据列表
  /// [period] 周期
  /// 返回: EMA值列表
  static List<double?> calculateEMA(List<KlineData> data, int period) {
    if (data.isEmpty) return [];
    if (data.length < period) {
      return List.filled(data.length, null);
    }

    final result = <double?>[];
    final multiplier = 2.0 / (period + 1);
    
    // 第一个EMA值使用SMA
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += data[i].close;
      if (i < period - 1) {
        result.add(null);
      }
    }
    
    double ema = sum / period;
    result.add(ema);
    
    // 后续EMA值
    for (int i = period; i < data.length; i++) {
      ema = (data[i].close - ema) * multiplier + ema;
      result.add(ema);
    }
    
    return result;
  }

  /// 计算布林带 (BOLL)
  /// 
  /// [data] K线数据列表
  /// [period] 周期，默认20
  /// [stdDev] 标准差倍数，默认2
  /// 返回: Map包含upper、middle、lower三条线
  static Map<String, List<double?>> calculateBOLL(
    List<KlineData> data, {
    int period = 20,
    double stdDev = 2.0,
  }) {
    final middle = calculateMA(data, period);
    final upper = <double?>[];
    final lower = <double?>[];
    
    for (int i = 0; i < data.length; i++) {
      if (i < period - 1 || middle[i] == null) {
        upper.add(null);
        lower.add(null);
      } else {
        // 计算标准差
        double sum = 0;
        for (int j = 0; j < period; j++) {
          final diff = data[i - j].close - middle[i]!;
          sum += diff * diff;
        }
        final sd = sqrt(sum / period);
        
        upper.add(middle[i]! + stdDev * sd);
        lower.add(middle[i]! - stdDev * sd);
      }
    }
    
    return {
      'upper': upper,
      'middle': middle,
      'lower': lower,
    };
  }

  /// 计算MACD指标
  /// 
  /// [data] K线数据列表
  /// [fastPeriod] 快线周期，默认12
  /// [slowPeriod] 慢线周期，默认26
  /// [signalPeriod] 信号线周期，默认9
  /// 返回: Map包含dif、dea、macd三个值
  static Map<String, List<double?>> calculateMACD(
    List<KlineData> data, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    if (data.length < slowPeriod) {
      return {
        'dif': List.filled(data.length, null),
        'dea': List.filled(data.length, null),
        'macd': List.filled(data.length, null),
      };
    }

    // 计算快线和慢线EMA
    final fastEMA = calculateEMA(data, fastPeriod);
    final slowEMA = calculateEMA(data, slowPeriod);
    
    // 计算DIF (快线 - 慢线)
    final dif = <double?>[];
    for (int i = 0; i < data.length; i++) {
      if (fastEMA[i] == null || slowEMA[i] == null) {
        dif.add(null);
      } else {
        dif.add(fastEMA[i]! - slowEMA[i]!);
      }
    }
    
    // 计算DEA (DIF的EMA)
    final dea = _calculateEMAFromValues(dif, signalPeriod);
    
    // 计算MACD柱状图 (DIF - DEA) * 2
    final macd = <double?>[];
    for (int i = 0; i < data.length; i++) {
      if (dif[i] == null || dea[i] == null) {
        macd.add(null);
      } else {
        macd.add((dif[i]! - dea[i]!) * 2);
      }
    }
    
    return {
      'dif': dif,
      'dea': dea,
      'macd': macd,
    };
  }

  /// 计算RSI指标
  /// 
  /// [data] K线数据列表
  /// [period] 周期，默认14
  /// 返回: RSI值列表
  static List<double?> calculateRSI(List<KlineData> data, {int period = 14}) {
    if (data.length < period + 1) {
      return List.filled(data.length, null);
    }

    final result = <double?>[];
    result.add(null); // 第一个值无法计算
    
    double avgGain = 0;
    double avgLoss = 0;
    
    // 计算初始平均涨跌
    for (int i = 1; i <= period; i++) {
      final change = data[i].close - data[i - 1].close;
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
      
      if (i < period) {
        result.add(null);
      }
    }
    
    avgGain /= period;
    avgLoss /= period;
    
    // 计算第一个RSI
    if (avgLoss == 0) {
      result.add(100);
    } else {
      final rs = avgGain / avgLoss;
      result.add(100 - (100 / (1 + rs)));
    }
    
    // 计算后续RSI
    for (int i = period + 1; i < data.length; i++) {
      final change = data[i].close - data[i - 1].close;
      final gain = change > 0 ? change : 0;
      final loss = change < 0 ? change.abs() : 0;
      
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
      
      if (avgLoss == 0) {
        result.add(100);
      } else {
        final rs = avgGain / avgLoss;
        result.add(100 - (100 / (1 + rs)));
      }
    }
    
    return result;
  }

  /// 计算KDJ指标
  /// 
  /// [data] K线数据列表
  /// [period] 周期，默认9
  /// 返回: Map包含k、d、j三个值
  static Map<String, List<double?>> calculateKDJ(
    List<KlineData> data, {
    int period = 9,
  }) {
    if (data.length < period) {
      return {
        'k': List.filled(data.length, null),
        'd': List.filled(data.length, null),
        'j': List.filled(data.length, null),
      };
    }

    final k = <double?>[];
    final d = <double?>[];
    final j = <double?>[];
    
    double prevK = 50;
    double prevD = 50;
    
    for (int i = 0; i < data.length; i++) {
      if (i < period - 1) {
        k.add(null);
        d.add(null);
        j.add(null);
        continue;
      }
      
      // 计算周期内的最高价和最低价
      double highest = data[i].high;
      double lowest = data[i].low;
      
      for (int j = 1; j < period; j++) {
        if (i - j >= 0) {
          highest = max(highest, data[i - j].high);
          lowest = min(lowest, data[i - j].low);
        }
      }
      
      // 计算RSV
      double rsv;
      if (highest == lowest) {
        rsv = 50;
      } else {
        rsv = (data[i].close - lowest) / (highest - lowest) * 100;
      }
      
      // 计算K、D、J
      final currentK = (2 * prevK + rsv) / 3;
      final currentD = (2 * prevD + currentK) / 3;
      final currentJ = 3 * currentK - 2 * currentD;
      
      k.add(currentK);
      d.add(currentD);
      j.add(currentJ);
      
      prevK = currentK;
      prevD = currentD;
    }
    
    return {
      'k': k,
      'd': d,
      'j': j,
    };
  }

  /// 从值列表计算EMA (辅助方法)
  static List<double?> _calculateEMAFromValues(
    List<double?> values,
    int period,
  ) {
    final result = <double?>[];
    final multiplier = 2.0 / (period + 1);
    
    // 找到第一个非null值的位置
    int firstValidIndex = -1;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != null) {
        firstValidIndex = i;
        break;
      }
    }
    
    if (firstValidIndex == -1 || firstValidIndex + period > values.length) {
      return List.filled(values.length, null);
    }
    
    // 前面的null值
    for (int i = 0; i < firstValidIndex + period - 1; i++) {
      result.add(null);
    }
    
    // 第一个EMA值使用SMA
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += values[firstValidIndex + i]!;
    }
    double ema = sum / period;
    result.add(ema);
    
    // 后续EMA值
    for (int i = firstValidIndex + period; i < values.length; i++) {
      if (values[i] == null) {
        result.add(null);
      } else {
        ema = (values[i]! - ema) * multiplier + ema;
        result.add(ema);
      }
    }
    
    return result;
  }
}

