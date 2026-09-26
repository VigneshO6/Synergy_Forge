class AppStrings {
  static const String appName = 'ONION SMART';
  static const String appTagline = 'Image Processing Based Onion Quality Analysis';
  static const String appSubtitle = 'Smart Procurement • Quality • Traceability';

  // Scientific Limitation Statement (Required)
  static const String rgbLimitationDisclaimer =
      'The image-processing system primarily evaluates externally visible onion quality characteristics from RGB images. Internal defects that cannot be visually observed are not detected by standard RGB cameras.';

  static const String rgbLimitationShort =
      'Analysis is based on externally visible characteristics from RGB images.';

  // Demo Credentials (Strictly Gmail Only)
  static const String demoProcurementEmail = 'procurement.onionsmart@gmail.com';
  static const String demoSellerEmail = 'seller.mandi@gmail.com';

  // Quality Categories (Strict 4-Class System: Medium Removed)
  static const String catGood = 'Good';
  static const String catDefective = 'Defective';
  static const String catSprouted = 'Sprouted';
  static const String catUndersized = 'Undersized / URS';

  // Quality Descriptions
  static const String descGood = 'Optimal bulb firmness, healthy golden/red skin tunic, no external decay.';
  static const String descDefective = 'Visible soft rot, surface mould necrosis, or mechanical rupture.';
  static const String descSprouted = 'Visible active green shoots emerging from the neck; rapid shelf-life decline.';
  static const String descUndersized = 'Bulb diameter below standard grade specification (< 40mm). Non-defective, suitable for URS / processing.';
}
