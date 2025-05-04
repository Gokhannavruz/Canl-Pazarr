import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the RevenueCat experiment for free trials
class ExperimentManager {
  // Experiment ID from RevenueCat
  static const String experimentId = 'prexp84d8c63974';

  // Variant names
  static const String controlVariant = 'default';
  static const String treatmentVariant = 'trial_test';

  // Product IDs
  // Control variant products
  static const List<String> controlProducts = [
    'fc_premium_monthly',
    'fc_premium_week',
    'fc_premium_year',
  ];

  // Treatment variant products (with free trial)
  static const List<String> treatmentProducts = [
    'fc_premium_monthly_trial',
    'fc_premium_week_trial',
    'fc_premium_year_trial',
  ];

  // Key for storing the variant in SharedPreferences
  static const String _variantKey = 'revenueCat_experiment_variant';

  /// Gets the current experiment variant for the user
  /// Returns either 'default' or 'trial_test'
  static Future<String> getCurrentVariant() async {
    try {
      // First check if we have a cached variant
      final prefs = await SharedPreferences.getInstance();
      final cachedVariant = prefs.getString(_variantKey);

      if (cachedVariant != null) {
        return cachedVariant;
      }

      // If no cached variant, fetch from RevenueCat
      // Note: RevenueCat automatically assigns users to experiment variants
      // We'll need to check the offerings to determine which variant the user is in
      final offerings = await Purchases.getOfferings();

      // Check if the treatment variant products are available in the offerings
      bool hasTreatmentProducts = false;

      if (offerings.current != null) {
        for (final package in offerings.current!.availablePackages) {
          if (treatmentProducts.contains(package.identifier)) {
            hasTreatmentProducts = true;
            break;
          }
        }
      }

      // Determine the variant based on available products
      final variant = hasTreatmentProducts ? treatmentVariant : controlVariant;

      // Cache the variant for future use
      await prefs.setString(_variantKey, variant);

      return variant;
    } catch (e) {
      print('Error determining experiment variant: $e');
      // Default to control variant in case of error
      return controlVariant;
    }
  }

  /// Checks if the user is in the treatment group (free trial)
  static Future<bool> isInTreatmentGroup() async {
    final variant = await getCurrentVariant();
    return variant == treatmentVariant;
  }

  /// Gets the appropriate product IDs based on the user's experiment variant
  static Future<List<String>> getProductIdsForCurrentVariant() async {
    try {
      final isInTreatment = await isInTreatmentGroup();
      return isInTreatment ? treatmentProducts : controlProducts;
    } catch (e) {
      print('Error getting product IDs for experiment variant: $e');
      // Return control products as fallback in case of error
      return controlProducts;
    }
  }
}
