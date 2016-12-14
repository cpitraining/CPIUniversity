//
//  AppDelegate.swift
//  UniversalWebview
//
//  Created by Mario Kovacevic on 05/08/2016.
//  Copyright (c) 2016 Brommko LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseInstanceID
import SwiftyUserDefaults
import SwiftyStoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    var googlePlistExists = false
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
        URLCache.shared = urlCache
        
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            googlePlistExists = true
        }
        
        if #available(iOS 10, *) {
            //Notifications get posted to the function (delegate):  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void)"
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                guard error == nil else {
                    //Display Error.. Handle Error.. etc..
                    return
                }
                
                if granted {
                    //Do stuff here..
                } else {
                    //Handle user denying permissions..
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        if googlePlistExists == true {
            
            FIRApp.configure()
            
            // Add observer for InstanceID token refresh callback.
            NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.tokenRefreshNotification), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        }
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let oneSignalAppID = appData?.value(forKey: "OneSignalAppID") as? String {
            if !oneSignalAppID.isEmpty {
                OneSignal.initWithLaunchOptions(launchOptions, appId: oneSignalAppID, handleNotificationAction: nil, settings:
                    [kOSSettingsKeyInAppAlerts: false,
                     kOSSettingsKeyAutoPrompt: false,
                     kOSSettingsKeyInAppLaunchURL: false
                    ])
                print("OneSignal registered!")
            }
        } else {
            print("OneSignal API Key is not in the plist file!")
        }
        
        if let productId = appData?.value(forKey: "RemoveAdsPurchaseId") as? String {
            if !productId.isEmpty {
                SwiftyStoreKit.completeTransactions() { completedTransactions in
                    for completedTransaction in completedTransactions {
                        if completedTransaction.transactionState == .purchased || completedTransaction.transactionState == .restored {
                            print("purchased: \(completedTransaction.productId)")
                            
                            if completedTransaction.productId == productId {
                                Defaults[.adsPurchased] = true
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        let refreshedToken:String? = FIRInstanceID.instanceID().token()
        print("FOREBASE TOKEN: \(refreshedToken)")
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([UNNotificationPresentationOptions.alert, UNNotificationPresentationOptions.sound, UNNotificationPresentationOptions.badge])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if #available(iOS 10.0, *) {
//            completionHandler()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 10.0, *)
    private func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print(notification.request.content.userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if application.applicationState == UIApplicationState.background || application.applicationState == UIApplicationState.inactive {
            
        } else {
            print("user info: %@", userInfo)
            let notificationMessage : AnyObject? =  userInfo["alert"] as AnyObject?
            let alert = UIAlertController(title: "SuperView", message:notificationMessage as? String, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK.", style: .default) { _ in })
            self.window?.rootViewController?.present(alert, animated: true){}
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Couldn't register: \(error)")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if googlePlistExists == true {
            FIRMessaging.messaging().disconnect()
            print("Disconnected from FCM.")
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("openURL \(url)")
        
        var urlString = url.absoluteString
        let queryArray = urlString.components(separatedBy: "//")
        
        var host:String = "http"
        if queryArray.count > 2 {
            host = queryArray[1]
            urlString = queryArray[2]
        } else {
            urlString = queryArray[1]
        }
        
        let parsedURLString:String? = "\(host)://\(urlString)"
        if parsedURLString != nil {
            UserDefaults.standard.set(parsedURLString, forKey: "URL")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshSite"), object: nil)
        }
        
        return true
    }
    
    static func dataPath() -> String {
        return Bundle.main.path(forResource: "SuperView", ofType: "plist")!
    }
}

