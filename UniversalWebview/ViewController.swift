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

class ViewController: UIViewController, WKNavigationDelegate, MBProgressHUDDelegate, GADBannerViewDelegate, GADInterstitialDelegate  {
    
    @IBOutlet var bannerView: GADBannerView!

    var wkWebView: WKWebView!
    var load : MBProgressHUD = MBProgressHUD()
    
    var interstitial: GADInterstitial!
    let request = GADRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        load.mode = MBProgressHUDMode.Indeterminate
        load.label.text = "Loading";
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let appData = NSDictionary(contentsOfFile: dataPath())
        let url = NSURL(string: appData?.valueForKey("URL") as! String)
        print(url!)
        
        // Create url request
        let requestObj: NSURLRequest = NSURLRequest(URL: url!);
        
        let bounds = UIScreen.mainScreen().bounds
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - self.bannerView!.frame.height)
        self.wkWebView = WKWebView(frame: frame)
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
        let appData = NSDictionary(contentsOfFile: dataPath())
        let bannerId = appData?.valueForKey("AdMobBannerUnitId") as? String
        if bannerId != nil {
            bannerView.adUnitID = bannerId
            bannerView.rootViewController = self
            bannerView.loadRequest(self.request)
            bannerView.delegate = self
        } else {
            bannerView.hidden = true
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
    
    func dataPath() -> String {
        return NSBundle.mainBundle().pathForResource("UniversalWebView", ofType: "plist")!
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

