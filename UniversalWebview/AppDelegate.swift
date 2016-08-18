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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var googlePlistExists = false


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0

        
        if NSBundle.mainBundle().pathForResource("GoogleService-Info", ofType: "plist") != nil {
            googlePlistExists = true
        }

        let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        
        if googlePlistExists == true {
            UIApplication.sharedApplication().registerForRemoteNotifications()
            
            FIRApp.configure()
            
            // Add observer for InstanceID token refresh callback.
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.tokenRefreshNotification), name: kFIRInstanceIDTokenRefreshNotification, object: nil)
        }
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let oneSignalAppID = appData?.valueForKey("OneSignalAppID") as? String {
            var oneSignal  = OneSignal(launchOptions: launchOptions, appId: oneSignalAppID, handleNotification: nil)
            OneSignal.defaultClient().enableInAppAlertNotification(true)
            
            oneSignal = OneSignal(launchOptions: launchOptions, appId: oneSignalAppID) { (message, additionalData, isActive) in
                NSLog("OneSignal Notification opened:\nMessage: %@", message)
                
                if additionalData != nil {
                    NSLog("additionalData: %@", additionalData)
                    // Check for and read any custom values you added to the notification
                    // This done with the "Additonal Data" section the dashbaord.
                    // OR setting the 'data' field on our REST API.
                    if let customKey = additionalData["customKey"] as! String? {
                        NSLog("customKey: %@", customKey)
                    }
                }
            }
            
            oneSignal.IdsAvailable { (userId, pushToken) -> Void in
                NSLog("OneSignal userId: %@", userId)
                if pushToken != nil {
                    NSLog("OneSignal pushToken: %@", pushToken)
                }
            }
        } else {
            print("OneSignal API Key is not in the plist file!")
        }
        
        return true
    }
    
    func tokenRefreshNotification(notification: NSNotification) {
        let refreshedToken:String? = FIRInstanceID.instanceID().token()
        print("FOREBASE TOKEN: \(refreshedToken)")
        FIRMessaging.messaging().connectWithCompletion { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
        print("%@", userInfo)
        
        let notificationMessage : AnyObject? =  userInfo["alert"]
        let alert = UIAlertController(title: "UniversalWebView", message:notificationMessage as? String, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK.", style: .Default) { _ in })
        self.window?.rootViewController?.presentViewController(alert, animated: true){}
        
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Sandbox)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Couldn't register: \(error)")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        if googlePlistExists == true {
            FIRMessaging.messaging().disconnect()
            print("Disconnected from FCM.")
        }
    }

    static func dataPath() -> String {
        return NSBundle.mainBundle().pathForResource("UniversalWebView", ofType: "plist")!
    }
}

