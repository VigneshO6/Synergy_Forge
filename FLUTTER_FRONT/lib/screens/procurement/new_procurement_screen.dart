import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/batch_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'batch_details_screen.dart';

class NewProcurementScreen extends StatefulWidget {
  const NewProcurementScreen({super.key});

  @override
  State<NewProcurementScreen> createState() => _NewProcurementScreenState();
}

class _NewProcurementScreenState extends State<NewProcurementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _procurementDate = DateTime.now();

  @override
  void dispose() {
    _contactController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final locText = _locationController.text.trim();
    final batchProv = Provider.of<BatchProvider>(context, listen: false);
    final newBatch = batchProv.createNewBatch(
      supplierName: locText.isNotEmpty ? 'Consignment Lot ($locText)' : 'Consignment Lot',
      contactNumber: _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : 'N/A',
      location: locText.isNotEmpty ? locText : 'Nashik Mandi Yard',
      totalQuantityKg: double.tryParse(_quantityController.text.trim()) ?? 1000.0,
      purchasePricePerKg: double.tryParse(_priceController.text.trim()) ?? 30.0,
      procurementDate: _procurementDate,
      notes: _notesController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created Batch ${newBatch.id} successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BatchDetailsScreen(batch: newBatch)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      title: 'New Procurement',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DisclaimerBanner(compact: true),
              const SizedBox(height: 16),

              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consignment Registration',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'A unique Batch ID will be generated upon creation',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Contact & Location
                    Text(
                      'Contact Number (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+91 98765 43210',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) => null,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Location / Mandi Yard *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lasalgaon, Nashik',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter location' : null,
                    ),
                    const SizedBox(height: 16),

                    // Quantity and Price
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Quantity (kg) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '5000',
                                  suffixText: 'kg',
                                  prefixIcon: Icon(Icons.scale_rounded, size: 20),
                                ),
                                validator: (val) => val == null || double.tryParse(val) == null
                                    ? 'Enter valid quantity'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Purchase Price (₹/kg) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '32',
                                  prefixText: '₹ ',
                                  prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                                ),
                                validator: (val) => val == null || double.tryParse(val) == null
                                    ? 'Enter valid price'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Procurement Date
                    Text(
                      'Procurement Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _procurementDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _procurementDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              '${_procurementDate.day.toString().padLeft(2, '0')}/${_procurementDate.month.toString().padLeft(2, '0')}/${_procurementDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text(
                      'Batch Notes & Observations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dry skin moisture content, vehicle registration, variety details',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'CREATE BATCH & GENERATE ID',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
