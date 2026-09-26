import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'transaction_history_screen.dart';

class ProfitCalculatorScreen extends StatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  State<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends State<ProfitCalculatorScreen> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final seller = Provider.of<SellerProvider>(context, listen: false);
    _priceController = TextEditingController(text: seller.sellingPricePerKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seller = Provider.of<SellerProvider>(context);
    final calc = seller.profitCalculation;
    final batch = seller.verifiedBatch;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isProfitable = calc.netProfit >= 0;

    return ResponsiveScaffold(
      title: 'Market Pricing & Profit Analysis',
      actions: [
        IconButton(
          tooltip: 'Sales History',
          icon: const Icon(Icons.receipt_long_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Live Profit Outcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfitable
                      ? [const Color(0xFF065F46), const Color(0xFF059669)]
                      : [const Color(0xFF991B1B), const Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isProfitable ? AppColors.primary : Colors.red).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isProfitable ? 'ESTIMATED NET PROFIT' : 'ESTIMATED DEFICIT / LOSS',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${calc.netProfit.abs().toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${calc.marginPercentage.toStringAsFixed(1)}% Net Margin  •  ₹${calc.profitPerKg.toStringAsFixed(1)}/kg profit',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recommendation Card
            OnionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isProfitable ? Icons.auto_graph_rounded : Icons.warning_rounded,
                    color: isProfitable ? AppColors.primary : AppColors.defectiveQuality,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MARKET LIQUIDATION ADVISORY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calc.recommendation,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cost & Pricing Inputs
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MARKET PRICING & LOGISTICS INPUTS',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 14),

                  // Selling Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target Market Selling Price',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        '₹${seller.sellingPricePerKg.toStringAsFixed(1)} / kg',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: seller.sellingPricePerKg.clamp(20.0, 75.0),
                    min: 20.0,
                    max: 75.0,
                    divisions: 55,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      seller.updatePricing(sellingPrice: val);
                      _priceController.text = val.toStringAsFixed(1);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Transport Cost
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transport & Freight Cost',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '₹${seller.transportCostPerKg.toStringAsFixed(1)} / kg',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: seller.transportCostPerKg.clamp(0.5, 8.0),
                    min: 0.5,
                    max: 8.0,
                    divisions: 15,
                    activeColor: AppColors.onionAmber,
                    onChanged: (val) => seller.updatePricing(transportCost: val),
                  ),
                  const SizedBox(height: 10),

                  // Waste Margin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cull & Moisture Waste Margin',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '${seller.wasteMarginPct.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: seller.wasteMarginPct.clamp(0.0, 10.0),
                    min: 0.0,
                    max: 10.0,
                    divisions: 20,
                    activeColor: AppColors.defectiveQuality,
                    onChanged: (val) => seller.updatePricing(wasteMargin: val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Detailed P&L Breakdown
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FINANCIAL SETTLEMENT BREAKDOWN',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

                  _buildFinancialRow('Consignment Net Volume', '${calc.batchQuantityKg.toStringAsFixed(0)} kg', isDark),
                  _buildFinancialRow('Effective Sellable Weight', '${calc.effectiveSellableKg.toStringAsFixed(0)} kg', isDark),
                  _buildFinancialRow('Procurement Purchase Cost', '₹${calc.totalProcurementCost.toStringAsFixed(0)}', isDark),
                  _buildFinancialRow('Logistics & Handling Costs', '₹${calc.totalLogisticsCost.toStringAsFixed(0)}', isDark),
                  _buildFinancialRow(
                    'Total Capital Outlay',
                    '₹${calc.totalInvestment.toStringAsFixed(0)}',
                    isDark,
                    isBold: true,
                  ),
                  _buildFinancialRow('Expected Gross Revenue', '₹${calc.grossRevenue.toStringAsFixed(0)}', isDark),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildFinancialRow(
                    'Estimated Net Profit',
                    '₹${calc.netProfit.toStringAsFixed(0)}',
                    isDark,
                    isBold: true,
                    highlightColor: isProfitable ? AppColors.goodQuality : AppColors.defectiveQuality,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settlement CTA
            ElevatedButton.icon(
              onPressed: () {
                seller.recordTransaction();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction recorded! Net profit: ₹${calc.netProfit.toStringAsFixed(0)}'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                );
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('CONFIRM SALE & SETTLE TRANSACTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: highlightColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
