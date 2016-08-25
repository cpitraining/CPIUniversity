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
import GoogleMobileAds

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, MBProgressHUDDelegate, GADBannerViewDelegate, GADInterstitialDelegate  {
    
    @IBOutlet var bannerView: GADBannerView!
    
    var mainURL:NSURL!
    
    var wkWebView: WKWebView!
    var popWindow:WKWebView?
    
    var load : MBProgressHUD = MBProgressHUD()
    
    var interstitial: GADInterstitial!
    let request = GADRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.load = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.load.mode = MBProgressHUDMode.Indeterminate
        self.load.label.text = "Loading";
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        let urlString = appData?.valueForKey("URL") as? String
        
        if urlString != nil {
            mainURL = NSURL(string: urlString!)
        } else {
            mainURL = NSBundle.mainBundle().URLForResource("index", withExtension: "html")!
        }
        print(mainURL!)
        
        self.loadWebSite()
        self.loadInterstitalAd()
        self.loadBannerAd()
    }
    
    func loadWebSite() {
        // Create url request
        let requestObj: NSURLRequest = NSURLRequest(URL: self.mainURL!);
        
        let theConfiguration:WKWebViewConfiguration? = WKWebViewConfiguration()
        let thisPref:WKPreferences = WKPreferences()
        thisPref.javaScriptCanOpenWindowsAutomatically = true;
        thisPref.javaScriptEnabled = true
        theConfiguration!.preferences = thisPref;
        
        let bounds = UIScreen.mainScreen().bounds
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - self.bannerView!.frame.height)
        self.wkWebView = WKWebView(frame: frame, configuration: theConfiguration!)
        self.wkWebView?.loadRequest(requestObj)
        self.wkWebView?.navigationDelegate = self
        self.wkWebView?.UIDelegate = self
    }

    func loadInterstitalAd() {
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        let interstitialId = appData?.valueForKey("AdMobInterstitialUnitId") as? String
        if interstitialId != nil {
            self.interstitial = GADInterstitial(adUnitID: interstitialId!)
            self.interstitial.delegate = self
            self.interstitial.loadRequest(self.request)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        self.loadBannerAd()
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        bannerView.hidden = false
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    func loadBannerAd(){
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        let bannerId = appData?.valueForKey("AdMobBannerUnitId") as? String
        if bannerId != nil {
            bannerView.adUnitID = bannerId
            bannerView.rootViewController = self
            bannerView.loadRequest(self.request)
            bannerView.delegate = self
        } else {
            bannerView.hidden = true
            let bounds = UIScreen.mainScreen().bounds
            let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            self.wkWebView.frame = frame
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("WebView content loaded.")
        self.load.hideAnimated(true)
        
        if self.popWindow == nil {
            self.view.addSubview(self.wkWebView!)
            
            if self.interstitial != nil && self.interstitial.isReady {
                self.interstitial.presentFromRootViewController(self)
            } else {
                self.loadBannerAd()
            }
        }
    }
    
    func getPopwindow(configuration:WKWebViewConfiguration) -> WKWebView {
        print(#function)

        let webView:WKWebView = WKWebView(frame: self.view.frame, configuration: configuration)
        webView.frame =  CGRectMake(self.view.frame.origin.x,self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
        return webView
    }
    
    func dismissPopWindow(webView:WKWebView) {
        print(#function)
        
        if let url = webView.URL?.host?.lowercaseString {
            if url.containsString(mainURL.host!.lowercaseString) {
                if self.popWindow != nil {
                    self.dismiss()
                }
            }
        }
    }
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print(#function)
        
        self.popWindow = self.getPopwindow(configuration)
        self.popWindow?.navigationDelegate = self
        self.popWindow?.UIDelegate = self
        
        let newViewController = UIViewController()
        newViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(ViewController.dismiss))
        newViewController.modalPresentationStyle = .OverCurrentContext
        newViewController.view = self.popWindow
        let navController = UINavigationController(rootViewController: newViewController)
        self.presentViewController(navController, animated: true, completion: nil)
        
        return self.popWindow
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func userContentController(userContentController:WKUserContentController, message:WKScriptMessage) {
        print(#function)
        print(message)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print(#function)
        print(message)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        print(#function)
        // You can inject java script here if required as below
//        let javascript = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
//        self.wkWebView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print(#function)
        let alert = UIAlertController(title: "Network Error", message:error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK.", style: .Default) { _ in })
        self.presentViewController(alert, animated: true){}
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
        print(webView.URL?.absoluteString.lowercaseString)
        self.dismissPopWindow(webView)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        print(#function)
        self.dismissPopWindow(webView)
        decisionHandler(.Allow);
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        print(#function)
        decisionHandler(.Allow);
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        print(#function)
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

