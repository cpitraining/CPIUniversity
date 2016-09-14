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
    
    @IBOutlet weak var backgroundImage: UIImageView?

    var bannerView: GADBannerView?
    var toolbar:UIToolbar?
    var backButton: UIBarButtonItem?
    var forwardButton: UIBarButtonItem?
    var reloadButton: UIBarButtonItem?
    
    var mainURL:NSURL?
    var wkWebView: WKWebView?
    var popViewController:UIViewController?
    var load : MBProgressHUD = MBProgressHUD()
    var interstitial: GADInterstitial!
    let request = GADRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.request.testDevices = ["bb394635b98430350b538d1e2ea1e9d6", kGADSimulatorID];
        
        self.loadToolbar()
        self.loadInterstitalAd()
        self.loadBannerAd()
        self.loadWebView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.loadWebView), name:"RefreshSite", object: nil)
    }
    
    func showLoader() {
        self.load = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.load.mode = MBProgressHUDMode.Indeterminate
    }
    
    func loadToolbar() {
        self.toolbar = self.getToolbar()
        self.backButton?.enabled = false
        self.forwardButton?.enabled = false
    }
    
    func back() {
        self.wkWebView?.goBack()
    }
    
    func forward() {
        self.wkWebView?.goForward()
    }
    
    func reload() {
        if let URL = self.wkWebView?.URL {
            self.showLoader()
            let request = NSURLRequest(URL: URL)
            self.wkWebView?.loadRequest(request)
        }
    }
    
    func loadWebView() {
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
        let requestObj: NSURLRequest?
        
        if Reachability.isConnectedToNetwork() {
            requestObj = NSURLRequest(URL: self.mainURL!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 0)
        } else {
            requestObj = NSURLRequest(URL: self.mainURL!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataDontLoad, timeoutInterval: 0)
        }
        
        let theConfiguration:WKWebViewConfiguration? = WKWebViewConfiguration()
        let thisPref:WKPreferences = WKPreferences()
        thisPref.javaScriptCanOpenWindowsAutomatically = true;
        thisPref.javaScriptEnabled = true
        theConfiguration!.preferences = thisPref;

        self.wkWebView = WKWebView(frame: self.getFrame(), configuration: theConfiguration!)
        self.wkWebView?.loadRequest(requestObj!)
        self.wkWebView?.navigationDelegate = self
        self.wkWebView?.UIDelegate = self
        self.wkWebView?.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<()>) {
        if (keyPath == "loading") {
            self.backButton?.enabled = self.wkWebView!.canGoBack
            self.forwardButton?.enabled = self.wkWebView!.canGoForward
        }
    }

    func loadInterstitalAd() {
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let interstitialId = appData?.valueForKey("AdMobInterstitialUnitId") as? String {
            self.interstitial = GADInterstitial(adUnitID: interstitialId)
            self.interstitial.delegate = self
            self.interstitial.loadRequest(self.request)
        }
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        self.loadBannerAd()
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {

    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    func loadBannerAd(){
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let bannerId = appData?.valueForKey("AdMobBannerUnitId") as? String {
            let bounds = UIScreen.mainScreen().bounds

            var y:CGFloat = bounds.height - 50
            if self.toolbar != nil {
                y = y - self.toolbar!.frame.height
            }
            
            self.bannerView = GADBannerView(frame: CGRect(x: 0, y: y, width: bounds.width, height: 50))
            self.bannerView?.adUnitID = bannerId
            self.bannerView?.rootViewController = self
            self.bannerView?.loadRequest(self.request)
            self.bannerView?.delegate = self
        } else {
            self.bannerView?.removeFromSuperview()
            self.wkWebView?.frame = self.getFrame()
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        
        self.backgroundImage?.removeFromSuperview()
        
        UIView.transitionWithView(self.view, duration: 0.1, options: .TransitionCrossDissolve, animations: {
            
            let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
            if let urlString = appData?.valueForKey("URL") as? String {
                if self.mainURL != NSURL(string: urlString) {
                    self.mainURL = NSURL(string: urlString)
                }
            }
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey("URL")
            
            if self.popViewController == nil {
                if self.interstitial != nil && self.interstitial.isReady {
                    self.interstitial.presentFromRootViewController(self)
                } else {
                    self.loadBannerAd()
                }
                
                if self.wkWebView != nil {
                    self.view.addSubview(self.wkWebView!)
                }
                
                if self.toolbar != nil {
                    self.view.addSubview(self.toolbar!)
                }
                
                if self.bannerView != nil {
                    self.view.addSubview(self.bannerView!)
                }
            }
            
        }) { (success) in
            self.load.hideAnimated(true)
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
    
    func dismissPopViewController(domain:String) {
        let mainDomain = self.getDomainFromURL(self.mainURL!)
        if domain == mainDomain{
            if self.popViewController != nil {
                self.dismiss()
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
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if let backupURL = appData?.valueForKey("BackupURL") as? String {
            let request = NSURLRequest(URL: NSURL(string: backupURL)!)
            self.wkWebView?.loadRequest(request)
        }
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        let domain = self.getDomainFromURL(webView.URL)
        self.dismissPopViewController(domain)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        print("NAVIGATION URL: \(navigationAction.request.URL!.host)")
        print("MAIN URL: \(self.mainURL!.host)")

        let domain = self.getDomainFromURL(navigationAction.request.URL!)
        
        if (navigationAction.navigationType == WKNavigationType.LinkActivated) {
            print("domains: \(domain)")
            print("navigationType: LinkActivated")
            
            self.dismissPopViewController(domain)
            decisionHandler(WKNavigationActionPolicy.Allow)
        } else if (navigationAction.navigationType == WKNavigationType.BackForward) {
            print("navigationType: BackForward")
            decisionHandler(WKNavigationActionPolicy.Allow)
        } else if (navigationAction.navigationType == WKNavigationType.FormResubmitted) {
            print("navigationType: FormResubmitted")
            decisionHandler(WKNavigationActionPolicy.Allow)
        } else if (navigationAction.navigationType == WKNavigationType.FormSubmitted) {
            print("navigationType: FormSubmitted")
            self.dismissPopViewController(domain)
            decisionHandler(WKNavigationActionPolicy.Allow)
        } else if (navigationAction.navigationType == WKNavigationType.Reload) {
            print("navigationType: Reload")
            decisionHandler(WKNavigationActionPolicy.Allow)
        } else {
            self.dismissPopViewController(domain)
            decisionHandler(WKNavigationActionPolicy.Allow)
        }
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
        self.wkWebView?.frame = self.getFrame()
    }
    
    func getFrame() -> CGRect {
        let bounds = UIScreen.mainScreen().bounds
        
        var height:CGFloat = bounds.height
        if self.bannerView != nil {
            height = height - self.bannerView!.frame.height
        }
        
        if self.toolbar != nil {
            height = height - self.toolbar!.frame.height
        }

        return  CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    
    func getToolbar() -> UIToolbar? {
        var toolbar: UIToolbar?
        let appData = NSDictionary(contentsOfFile: AppDelegate.dataPath())
        if appData?.valueForKey("Toolbar") as? Bool == true {
            self.backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .Plain, target: self, action: #selector(ViewController.back))
            self.forwardButton = UIBarButtonItem(image: UIImage(named: "forward"), style: .Plain, target: self, action: #selector(ViewController.forward))
            self.reloadButton = UIBarButtonItem(image: UIImage(named: "refresh"), style: .Plain, target: self, action: #selector(ViewController.reload))
            
            self.backButton?.tintColor = UIColor(hexString: "0e8494")
            self.forwardButton?.tintColor = UIColor(hexString: "0e8494")
            self.reloadButton?.tintColor = UIColor(hexString: "0e8494")
            
            let fixedSpaceButton = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
            fixedSpaceButton.width = 42
            let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
            
            var items = [UIBarButtonItem]()
            items.append(self.backButton!)
            items.append(fixedSpaceButton)
            items.append(self.forwardButton!)
            items.append(flexibleSpaceButton)
            items.append(self.reloadButton!)
            
            let bounds = UIScreen.mainScreen().bounds
            toolbar = UIToolbar(frame: CGRect(x: 0, y: bounds.height - 40, width: bounds.width, height: 40))
            toolbar!.setItems(items, animated: true)
        }
        return toolbar
    }
    
    func getDomainFromURL(url:NSURL?) -> String {
        var domain:String = ""
        let domains = self.domains()
        if url?.host != nil {
            let host = url!.host?.lowercaseString
            var separatedHost = host?.componentsSeparatedByString(".")
            separatedHost = separatedHost?.reverse()
            
            for tld in separatedHost! {
                if domains.containsObject(tld.uppercaseString) {
                    domain = ".\(tld)\(domain)"
                } else {
                    domain = "\(tld)\(domain)"
                    break
                }
            }
        }
        return domain
    }
    
    func domains() -> NSArray {
        if let url = NSBundle.mainBundle().URLForResource("domains", withExtension: "json") {
            if let data = NSData(contentsOfURL: url) {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if let domains = json as? [String] {
                        return domains
                    }
                } catch {
                    print("error serializing JSON: \(error)")
                }
            }
            print("Error!! Unable to load domains.json.json")
        }
        return []
    }
    
    //Commented:    black status bar.
    //Uncommented:  white status bar.
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
}

