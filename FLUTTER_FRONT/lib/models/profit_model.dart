import 'quality_model.dart';

class TransitComparison {
  final QualityAnalysisResult originalQuality;
  final QualityAnalysisResult receivedQuality;
  final double weightLossPct;

  TransitComparison({
    required this.originalQuality,
    required this.receivedQuality,
    this.weightLossPct = 1.8,
  });

  double get deltaGood => receivedQuality.goodPercentage - originalQuality.goodPercentage;
  double get deltaSprout => receivedQuality.sproutedPercentage - originalQuality.sproutedPercentage;
  double get deltaDefective => receivedQuality.defectivePercentage - originalQuality.defectivePercentage;
  double get deltaUndersized => receivedQuality.undersizedPercentage - originalQuality.undersizedPercentage;

  String get conditionSummary {
    if (deltaGood >= -2.0 && deltaSprout <= 1.5) {
      return 'Excellent Transit Preservation. Minimal quality variance.';
    } else if (deltaGood >= -8.0 && deltaSprout <= 4.0) {
      return 'Moderate Transit Impact. Slight moisture or temperature rise during transit.';
    } else {
      return 'Significant Transit Degradation. Noticeable sprout escalation and rot development.';
    }
  }

  bool get requiresPriceRenegotiation => deltaGood < -5.0 || deltaDefective > 4.0;
}

class ProfitCalculation {
  final double batchQuantityKg;
  final double purchasePricePerKg;
  final double sellingPricePerKg;
  final double transportCostPerKg;
  final double storageCostPerKg;
  final double wasteDeductionPct;

  ProfitCalculation({
    required this.batchQuantityKg,
    required this.purchasePricePerKg,
    required this.sellingPricePerKg,
    this.transportCostPerKg = 2.5,
    this.storageCostPerKg = 1.0,
    this.wasteDeductionPct = 3.5,
  });

  double get effectiveSellableKg => batchQuantityKg * (1.0 - (wasteDeductionPct / 100.0));

  double get totalProcurementCost => batchQuantityKg * purchasePricePerKg;
  double get totalLogisticsCost => batchQuantityKg * (transportCostPerKg + storageCostPerKg);
  double get totalInvestment => totalProcurementCost + totalLogisticsCost;

  double get grossRevenue => effectiveSellableKg * sellingPricePerKg;
  double get netProfit => grossRevenue - totalInvestment;

  double get marginPercentage => totalInvestment > 0 ? (netProfit / totalInvestment) * 100.0 : 0.0;
  double get profitPerKg => batchQuantityKg > 0 ? netProfit / batchQuantityKg : 0.0;

  String get recommendation {
    if (marginPercentage >= 25.0) {
      return 'Highly Profitable. Favorable market condition for immediate wholesale liquidation.';
    } else if (marginPercentage >= 10.0) {
      return 'Healthy Margin. Proceed with scheduled distribution to regular retail outlets.';
    } else if (marginPercentage > 0.0) {
      return 'Slim Margin. Consider staggered selling or value-add grade sorting to maximize realization.';
    } else {
      return 'Potential Loss Warning. Recommend holding in cold ventilation storage or negotiating bulk processing off-take.';
    }
  }
}
