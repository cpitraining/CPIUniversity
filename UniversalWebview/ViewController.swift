//
//  ViewController.swift
//  UniversalWebview
//
//  Created by Mario Kovacevic on 05/08/2016.
//  Copyright (c) 2016 Brommko LLC. All rights reserved.
//

import UIKit
import WebKit
import MBProgressHUD

class ViewController: UIViewController, WKNavigationDelegate, MBProgressHUDDelegate {
    
    var wkWebView: WKWebView?
    var uiWebView: UIWebView?
    var load : MBProgressHUD = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        load.mode = MBProgressHUDMode.Indeterminate
        load.label.text = "Loading";
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let data = NSArray(contentsOfFile: dataPath()) as? [String]
        let url = NSURL(string: data![0])
        print(url!)
        
        // Create url request
        let requestObj: NSURLRequest = NSURLRequest(URL: url!);
        
        self.wkWebView = WKWebView(frame: UIScreen.mainScreen().bounds)
        self.wkWebView?.loadRequest(requestObj)
        self.wkWebView?.navigationDelegate = self

    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("WebView content loaded.")
        dispatch_async(dispatch_get_main_queue()) {
            self.load.hideAnimated(true)
            self.view.addSubview(self.wkWebView!)
        }
    }
    
    func dataPath() -> String {
        return NSBundle.mainBundle().pathForResource("WebView", ofType: "plist")!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Commented:    black status bar.
    //Uncommented:  white status bar.
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

}

