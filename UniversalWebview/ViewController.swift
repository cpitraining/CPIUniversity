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
    
    var wkWebView: WKWebView!
    var popWindow:WKWebView?
    
    var load : MBProgressHUD = MBProgressHUD()
    
    var interstitial: GADInterstitial!
    let request = GADRequest()
    
    let social = ["facebook.com", "linkedin.com", "google.com"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        load.mode = MBProgressHUDMode.Indeterminate
        load.label.text = "Loading";
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        let urlString = appData?.valueForKey("URL") as? String
        
        let url:NSURL?
        if urlString != nil {
            url = NSURL(string: urlString!)
        } else {
            url = NSBundle.mainBundle().URLForResource("index", withExtension: "html")!
        }
        print(url!)
        
        // Create url request
        let requestObj: NSURLRequest = NSURLRequest(URL: url!);
        
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
        
        let interstitialId = appData?.valueForKey("AdMobInterstitialUnitId") as? String
        
        if interstitialId != nil {
            self.interstitial = GADInterstitial(adUnitID: interstitialId!)
            self.interstitial.delegate = self
            self.interstitial.loadRequest(self.request)
        }
        
        self.loadBannerAd()
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
            self.wkWebView = WKWebView(frame: frame)
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("WebView content loaded.")
        self.load.hideAnimated(true)
        self.view.addSubview(self.wkWebView!)
        
        if self.interstitial != nil && self.interstitial.isReady {
            self.interstitial.presentFromRootViewController(self)
        } else {
            self.loadBannerAd()
        }
    }
    
    func getPopwindow(configuration:WKWebViewConfiguration) -> WKWebView {
        let webView:WKWebView = WKWebView(frame: self.view.frame, configuration: configuration)
        webView.frame =  CGRectMake(self.view.frame.origin.x,self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
        return webView
    }
    
    func dismissPopWindow(webView:WKWebView) {
        if let url = webView.URL?.host?.lowercaseString {
            var exist = false
            for host in social {
                if url.containsString(host) {
                    exist = true
                }
            }
            
            if exist == true {
                if self.popWindow != nil {
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                        if self.popWindow != nil {
                            self.popWindow?.removeFromSuperview()
                            self.popWindow = nil
                        }
                    }
                }
            }
        }
    }
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        self.popWindow = self.getPopwindow(configuration)
        self.popWindow?.navigationDelegate = self
        self.view.addSubview(self.popWindow!)
        return self.popWindow
    }
    
    func userContentController(userContentController:WKUserContentController, message:WKScriptMessage) {
        print(message)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print(message)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        print(#function)
        // You can inject java script here if required as below
        //    //NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
        //    //[webView evaluateJavaScript:javascript completionHandler:nil];
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print(#function)
        let alert = UIAlertController(title: "Network Error", message:error.description, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK.", style: .Default) { _ in })
        self.presentViewController(alert, animated: true){}
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
        print(webView.URL?.absoluteString.lowercaseString)
        self.dismissPopWindow(webView)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        self.dismissPopWindow(webView)
        decisionHandler(.Allow);
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
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

