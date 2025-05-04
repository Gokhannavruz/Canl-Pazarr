import UIKit
import Flutter
import Firebase
import GoogleMobileAds
import FirebaseMessaging
import UserNotifications
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins first
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for StoreKit
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let storeReviewChannel = FlutterMethodChannel(name: "com.freecycle/storeReview", 
                                                 binaryMessenger: controller.binaryMessenger)
    
    // Handle method calls from Flutter
    storeReviewChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "requestReview" {
        if #available(iOS 10.3, *) {
          SKStoreReviewController.requestReview()
          result(nil)
        } else {
          // Fallback for older iOS versions
          let appStoreURL = URL(string: "https://apps.apple.com/us/app/free-stuff-freecycle/id6476391295?action=write-review")!
          if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
          }
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    // Set messaging delegate only if Firebase is already initialized by Flutter
    if FirebaseApp.app() != nil {
      // Set messaging delegate
      Messaging.messaging().delegate = self
      
      // Register for remote notifications
      if #available(iOS 10.0, *) {
        // For iOS 10 and above
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )
      } else {
        // For iOS 9 and below
        let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
      }
      
      application.registerForRemoteNotifications()
    }
    
    // Initialize Google Mobile Ads SDK
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      GADMobileAds.sharedInstance().start(completionHandler: { status in
        print("Google Mobile Ads SDK initialization completed")
      })
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    
    // Print full message for debugging
    print("Notification received in foreground: \(userInfo)")
    
    // With this, notification will display when app is in foreground too
    completionHandler([[.alert, .sound, .badge]])
  }
  
  // Handle when user taps on notification
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Print full message for debugging
    print("Notification tapped: \(userInfo)")
    
    completionHandler()
  }
  
  // Handle registration of remote notifications
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    print("APNs token retrieved: \(deviceToken)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle remote notification registration error
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(fcmToken ?? "nil")")
    
    // Store this token for sending FCM messages to this specific device
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
