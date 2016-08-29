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
    
    @IBOutlet var bannerView: GADBannerView?
    
    var mainURL:NSURL?
    
    var wkWebView: WKWebView!
    var popViewController:UIViewController?
    
    var load : MBProgressHUD = MBProgressHUD()
    
    var interstitial: GADInterstitial!
    let request = GADRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadWebView()
        self.loadInterstitalAd()
        self.loadBannerAd()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.loadWebView), name:"RefreshSite", object: nil)
    }
    
    func loadWebView() {
        self.load = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.load.mode = MBProgressHUDMode.Indeterminate
        self.load.label.text = "Loading";
        
        self.getURL()
        self.loadWebSite()
    }
    
    func getURL() {
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        let urlString = appData?.valueForKey("URL") as? String
        
        if let URL = NSUserDefaults.standardUserDefaults().stringForKey("URL") {
            self.mainURL = NSURL(string: URL)
        }
        
        if self.mainURL == nil {
            if urlString != nil {
                self.mainURL = NSURL(string: urlString!)
            } else {
                self.mainURL = NSBundle.mainBundle().URLForResource("index", withExtension: "html")!
            }
        }
        print(self.mainURL!)
    }
    
    func loadWebSite() {
        // Create url request
        let requestObj: NSURLRequest = NSURLRequest(URL: self.mainURL!);
        
        let theConfiguration:WKWebViewConfiguration? = WKWebViewConfiguration()
        let thisPref:WKPreferences = WKPreferences()
        thisPref.javaScriptCanOpenWindowsAutomatically = true;
        thisPref.javaScriptEnabled = true
        theConfiguration!.preferences = thisPref;

        self.wkWebView = WKWebView(frame: self.getFrame(), configuration: theConfiguration!)
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
            self.bannerView?.adUnitID = bannerId
            self.bannerView?.rootViewController = self
            self.bannerView?.loadRequest(self.request)
            self.bannerView?.delegate = self
        } else {
            self.bannerView?.hidden = true
            self.wkWebView.frame = self.getFrame()
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("WebView content loaded.")
        self.load.hideAnimated(true)
        
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let urlString = appData?.valueForKey("URL") as? String {
            if self.mainURL != NSURL(string: urlString) {
                self.mainURL = NSURL(string: urlString)
            }
        }
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("URL")
        
        if self.popViewController == nil {
            self.view.addSubview(self.wkWebView!)
            
            if self.interstitial != nil && self.interstitial.isReady {
                self.interstitial.presentFromRootViewController(self)
            } else {
                self.loadBannerAd()
            }
        }
    }
    
    func getViewController(configuration:WKWebViewConfiguration) -> UIViewController {
        let webView:WKWebView = WKWebView(frame: self.view.frame, configuration: configuration)
        webView.frame = UIScreen.mainScreen().bounds
        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
        webView.navigationDelegate = self
        webView.UIDelegate = self
        
        let newViewController = UIViewController()
        newViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(ViewController.dismiss))
        newViewController.modalPresentationStyle = .OverCurrentContext
        newViewController.view = webView
        return newViewController
    }
    
    func dismissPopWindow(webView:WKWebView) {
        if let url = webView.URL?.host?.lowercaseString {
            if url.containsString(mainURL!.host!.lowercaseString) {
                if self.popViewController != nil {
                    self.dismiss()
                }
            }
        }
    }
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        self.popViewController = self.getViewController(configuration)
        let navController = UINavigationController(rootViewController: self.popViewController!)
        self.presentViewController(navController, animated: true, completion: nil)
        return self.popViewController?.view as? WKWebView
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func userContentController(userContentController:WKUserContentController, message:WKScriptMessage) {
        print(message)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print(message)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        // You can inject java script here if required as below
//        let javascript = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
//        self.wkWebView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        let alert = UIAlertController(title: "Network Error", message:error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK.", style: .Default) { _ in })
        self.presentViewController(alert, animated: true){}
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
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

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.wkWebView.frame = self.getFrame()
    }
    
    func getFrame() -> CGRect {
        let bounds = UIScreen.mainScreen().bounds
        
        let frame:CGRect!
        if self.bannerView?.hidden == false {
            frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - self.bannerView!.frame.height)
        } else {
            frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        }
        return frame
    }
    
    //Commented:    black status bar.
    //Uncommented:  white status bar.
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
}

