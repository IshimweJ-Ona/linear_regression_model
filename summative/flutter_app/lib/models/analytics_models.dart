class OverviewStats {
  const OverviewStats({
    required this.count,
    required this.meanK,
    required this.medianK,
    required this.minK,
    required this.maxK,
  });

  final int count;
  final double meanK;
  final double medianK;
  final double minK;
  final double maxK;

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      count: (json['count'] as num).toInt(),
      meanK: (json['mean_k'] as num).toDouble(),
      medianK: (json['median_k'] as num).toDouble(),
      minK: (json['min_k'] as num).toDouble(),
      maxK: (json['max_k'] as num).toDouble(),
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
    required this.overview,
    required this.heatmap,
    required this.scatter,
    required this.sgdCurves,
    required this.modelComparison,
    required this.featureImportance,
  });

  final Map<String, OverviewStats> overview;
  final Map<String, HeatmapData> heatmap;
  final Map<String, ScatterDataset> scatter;
  final Map<String, SgdCurveData> sgdCurves;
  final List<ModelMetric> modelComparison;
  final Map<String, List<FeatureImportanceItem>> featureImportance;

  factory AnalyticsBundle.fromJson(Map<String, dynamic> json) {
    return AnalyticsBundle(
      overview: (json['overview'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, OverviewStats.fromJson(v as Map<String, dynamic>)),
      ),
      heatmap: (json['heatmap'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, HeatmapData.fromJson(v as Map<String, dynamic>)),
      ),
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
