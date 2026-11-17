class CohortMeta {
  const CohortMeta({
    required this.key,
    required this.group,
    required this.count,
  });

  final String key;
  final String group;
  final int count;

  factory CohortMeta.fromJson(Map<String, dynamic> json) {
    return CohortMeta(
      key: json['key'] as String,
      group: json['group'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}

class WagePercentile {
  const WagePercentile({required this.pct, required this.kRwf});

  final int pct;
  final double kRwf;

  factory WagePercentile.fromJson(Map<String, dynamic> json) {
    return WagePercentile(
      pct: (json['pct'] as num).toInt(),
      kRwf: (json['k_rwf'] as num).toDouble(),
    );
  }
}

class OverviewStats {
  const OverviewStats({
    required this.group,
    required this.count,
    required this.sharePct,
    required this.meanK,
    required this.medianK,
    required this.p25K,
    required this.p75K,
    required this.minK,
    required this.maxK,
    required this.femalePct,
    required this.tvetPct,
  });

  final String group;
  final int count;
  final double sharePct;
  final double meanK;
  final double medianK;
  final double p25K;
  final double p75K;
  final double minK;
  final double maxK;
  final double femalePct;
  final double tvetPct;

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      group: (json['group'] as String?) ?? 'All',
      count: (json['count'] as num).toInt(),
      sharePct: (json['share_pct'] as num?)?.toDouble() ?? 100.0,
      meanK: (json['mean_k'] as num).toDouble(),
      medianK: (json['median_k'] as num).toDouble(),
      p25K: (json['p25_k'] as num?)?.toDouble() ?? (json['median_k'] as num).toDouble(),
      p75K: (json['p75_k'] as num?)?.toDouble() ?? (json['mean_k'] as num).toDouble(),
      minK: (json['min_k'] as num).toDouble(),
      maxK: (json['max_k'] as num).toDouble(),
      femalePct: (json['female_pct'] as num?)?.toDouble() ?? 0.0,
      tvetPct: (json['tvet_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HeatmapData {
  const HeatmapData({required this.labels, required this.matrix});

  final List<String> labels;
  final List<List<double>> matrix;

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      labels: List<String>.from(json['labels'] as List),
      matrix: (json['matrix'] as List)
          .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
          .toList(),
    );
  }
}

class ScatterPoint {
  const ScatterPoint(this.x, this.y);
  final double x;
  final double y;
}

class ScatterDataset {
  const ScatterDataset({
    required this.points,
    required this.slope,
    required this.intercept,
    required this.r,
    required this.xMin,
    required this.xMax,
    required this.count,
  });

  final List<ScatterPoint> points;
  final double slope;
  final double intercept;
  final double r;
  final double xMin;
  final double xMax;
  final int count;

  factory ScatterDataset.fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List)
        .map((p) => ScatterPoint((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    return ScatterDataset(
      points: pts,
      slope: (json['slope'] as num).toDouble(),
      intercept: (json['intercept'] as num).toDouble(),
      r: (json['r'] as num).toDouble(),
      xMin: (json['x_min'] as num).toDouble(),
      xMax: (json['x_max'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );
  }
}

class SgdCurveData {
  const SgdCurveData({
    required this.epochs,
    required this.trainMse,
    required this.testMse,
  });

  final List<int> epochs;
  final List<double> trainMse;
  final List<double> testMse;

  factory SgdCurveData.fromJson(Map<String, dynamic> json) {
    return SgdCurveData(
      epochs: (json['epochs'] as List).map((e) => (e as num).toInt()).toList(),
      trainMse: (json['train_mse'] as List).map((e) => (e as num).toDouble()).toList(),
      testMse: (json['test_mse'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class ModelMetric {
  const ModelMetric({
    required this.name,
    required this.trainMse,
    required this.testMse,
    required this.testR2,
    required this.isBest,
  });

  final String name;
  final double trainMse;
  final double testMse;
  final double testR2;
  final bool isBest;

  factory ModelMetric.fromJson(Map<String, dynamic> json) {
    return ModelMetric(
      name: json['name'] as String,
      trainMse: (json['train_mse'] as num).toDouble(),
      testMse: (json['test_mse'] as num).toDouble(),
      testR2: (json['test_r2'] as num).toDouble(),
      isBest: json['is_best'] as bool,
    );
  }
}

class FeatureImportanceItem {
  const FeatureImportanceItem({required this.name, required this.importance});

  final String name;
  final double importance;

  factory FeatureImportanceItem.fromJson(Map<String, dynamic> json) {
    return FeatureImportanceItem(
      name: json['name'] as String,
      importance: (json['importance'] as num).toDouble(),
    );
  }
}

class AnalyticsBundle {
  const AnalyticsBundle({
    required this.cohorts,
    required this.percentiles,
    required this.overview,
    required this.heatmap,
    required this.scatter,
    required this.sgdCurves,
    required this.modelComparison,
    required this.featureImportance,
  });

  final List<CohortMeta> cohorts;
  final List<WagePercentile> percentiles;
  final Map<String, OverviewStats> overview;
  final Map<String, Map<String, HeatmapData>> heatmap;
  final Map<String, ScatterDataset> scatter;
  final Map<String, SgdCurveData> sgdCurves;
  final List<ModelMetric> modelComparison;
  final Map<String, List<FeatureImportanceItem>> featureImportance;

  /// Linearly interpolates a wage (`k_rwf`) onto the empirical LFS 2022 percentile ladder.
  int estimatePercentile(double incomeKRwf) {
    if (percentiles.isEmpty) return 50;
    if (incomeKRwf <= percentiles.first.kRwf) return percentiles.first.pct;
    if (incomeKRwf >= percentiles.last.kRwf) return percentiles.last.pct;

    for (var i = 1; i < percentiles.length; i++) {
      final prev = percentiles[i - 1];
      final curr = percentiles[i];
      if (incomeKRwf <= curr.kRwf) {
        final span = curr.kRwf - prev.kRwf;
        if (span <= 0) return curr.pct;
        final frac = (incomeKRwf - prev.kRwf) / span;
        return (prev.pct + frac * (curr.pct - prev.pct)).round().clamp(1, 99);
      }
    }
    return 99;
  }

  factory AnalyticsBundle.fromJson(Map<String, dynamic> json) {
    final rawHeatmap = json['heatmap'] as Map<String, dynamic>;
    final parsedHeatmap = rawHeatmap.map((cohortKey, inner) {
      final innerMap = (inner as Map<String, dynamic>).map(
        (varSetKey, data) => MapEntry(
          varSetKey,
          HeatmapData.fromJson(data as Map<String, dynamic>),
        ),
      );
      return MapEntry(cohortKey, innerMap);
    });

    return AnalyticsBundle(
      cohorts: ((json['cohorts'] as List?) ?? const [])
          .map((e) => CohortMeta.fromJson(e as Map<String, dynamic>))
          .toList(),
      percentiles: ((json['percentiles'] as List?) ?? const [])
          .map((e) => WagePercentile.fromJson(e as Map<String, dynamic>))
          .toList(),
      overview: (json['overview'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, OverviewStats.fromJson(v as Map<String, dynamic>)),
      ),
      heatmap: parsedHeatmap,
      scatter: (json['scatter'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, ScatterDataset.fromJson(v as Map<String, dynamic>)),
      ),
      sgdCurves: (json['sgd_curves'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, SgdCurveData.fromJson(v as Map<String, dynamic>)),
      ),
      modelComparison: (json['model_comparison'] as List)
          .map((e) => ModelMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      featureImportance: (json['feature_importance'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => FeatureImportanceItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }
}
