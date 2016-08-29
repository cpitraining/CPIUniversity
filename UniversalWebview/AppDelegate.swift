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
import Mixpanel

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
        
        UIApplication.sharedApplication().registerForRemoteNotifications()

        if googlePlistExists == true {
            
            FIRApp.configure()
            
            // Add observer for InstanceID token refresh callback.
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.tokenRefreshNotification), name: kFIRInstanceIDTokenRefreshNotification, object: nil)
        }
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let oneSignalAppID = appData?.valueForKey("OneSignalAppID") as? String {
            OneSignal.initWithLaunchOptions(launchOptions, appId: oneSignalAppID, handleNotificationAction: nil, settings:
                [kOSSettingsKeyInAppAlerts: false,
                    kOSSettingsKeyAutoPrompt: false,
                    kOSSettingsKeyInAppLaunchURL: false
                ])
        } else {
            print("OneSignal API Key is not in the plist file!")
        }
        
        if let mixpanelToken = appData?.valueForKey("MixpanelToken") as? String {
            let mixpanel = Mixpanel.sharedInstanceWithToken(mixpanelToken)
            mixpanel.identify(mixpanel.distinctId)
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
        if application.applicationState == UIApplicationState.Background || application.applicationState == UIApplicationState.Inactive {

        } else {
            print("user info: %@", userInfo)
            if let url:String? = userInfo["custom"]?.objectForKey("u") as? String {
                print("PUSH url  %@", url)
                UIApplication.sharedApplication().openURL(NSURL(string : url!)!)
            } else {
                let notificationMessage : AnyObject? =  userInfo["alert"]
                let alert = UIAlertController(title: "UniversalWebView", message:notificationMessage as? String, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK.", style: .Default) { _ in })
                self.window?.rootViewController?.presentViewController(alert, animated: true){}
            }
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Sandbox)
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if appData?.valueForKey("MixpanelToken") != nil {
            Mixpanel.sharedInstance().people.addPushDeviceToken(deviceToken)
        }
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
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        print("openURL \(url)")

        var urlString = url.absoluteString
        let queryArray = urlString.componentsSeparatedByString("//")
        
        var host:String = "http"
        if queryArray.count > 2 {
            host = queryArray[1]
            urlString = queryArray[2]
        } else {
            urlString = queryArray[1]
        }
        
        let parsedURLString:String? = "\(host)://\(urlString)"
        if parsedURLString != nil {
            NSUserDefaults.standardUserDefaults().setObject(parsedURLString, forKey: "URL")
            NSNotificationCenter.defaultCenter().postNotificationName("RefreshSite", object: nil)
        }
        
        return true
    }

    static func dataPath() -> String {
        return NSBundle.mainBundle().pathForResource("UniversalWebView", ofType: "plist")!
    }
}

