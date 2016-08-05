//
//  ViewController.swift
//  UniversalWebview
//
//  Created by Mario Kovacevic on 05/08/2016.
//  Copyright (c) 2016 Brommko LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    var wkWebView: WKWebView?
    var uiWebView: UIWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let data = NSArray(contentsOfFile: dataPath()) as? [String]
        let url = NSURL(string: data![0])
        print(url!)
        
        // Create url request
        let requestObj: NSURLRequest = NSURLRequest(URL: url!);
        
        self.wkWebView = WKWebView(frame: UIScreen.mainScreen().bounds)
        self.wkWebView?.loadRequest(requestObj)
        self.view.addSubview(self.wkWebView!)

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

