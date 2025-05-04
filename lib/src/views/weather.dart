import 'package:freecycle/src/views/paywall.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freecycle/src/components/native_dialog.dart';
import 'package:freecycle/src/components/top_bar.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/model/styles.dart';
import 'package:freecycle/src/model/weather_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/paywallfirstlaunch.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:freecycle/src/model/experiment_manager.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({
    Key? key,
  }) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = false;

  /*
    We should check if we can magically change the weather 
    (subscription active) and if not, display the paywall.
  */
  void perfomMagic() async {
    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      appData.currentData = WeatherData.generateData();

      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        // Get the appropriate offerings based on experiment variant
        offerings = await Purchases.getOfferings();

        // Log the experiment variant for analytics
        final variant = await ExperimentManager.getCurrentVariant();
        print('RevenueCat Experiment Variant: $variant');

        // Track experiment view for analytics
        final isInTreatment = await ExperimentManager.isInTreatmentGroup();
        print('User is in treatment group: $isInTreatment');
      } on PlatformException catch (e) {
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: e.message ?? "Unknown error",
                buttonText: 'OK'));
      }

      setState(() {
        _isLoading = false;
      });

      if (offerings == null || offerings.current == null) {
        // offerings are empty, show a message to your user
      } else {
        // current offering is available, show paywall
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopBar(
        text: "✨ Magic Weather",
        style: kTitleTextStyle,
        uniqueHeroTag: 'weather',
        child: Scaffold(
          backgroundColor: appData.currentData.weatherColor,
          body: ModalProgressHUD(
            inAsyncCall: _isLoading,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          "${appData.currentData.emoji}\n${appData.currentData.temperature}°${appData.currentData.unit.toString().split('.')[1].toUpperCase()}",
                          textAlign: TextAlign.center,
                          style: kDescriptionTextStyle.copyWith(
                              fontSize: kFontSizeLarge),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.near_me),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                    appData.currentData.environment
                                        .toString()
                                        .split('.')[1]
                                        .toUpperCase(),
                                    style: kDescriptionTextStyle.copyWith(
                                        fontSize: kFontSizeMedium,
                                        fontWeight: FontWeight.bold)),
                              ),
                              // buton for navigate to paywall
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: TextButton(
                    onPressed: () => perfomMagic(),
                    child: Text(
                      "✨ Change the Weather",
                      style: kDescriptionTextStyle.copyWith(
                          fontSize: kFontSizeMedium,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
