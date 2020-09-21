//
//  YYWebViewController.swift
//  YYNative_Example
//
//  Created by 江大盗 on 17/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import WebKit

class YYWebViewController: UIViewController {
    
    var urlString: String = "加载失败" {
        didSet {
            loadData()
        }
    }
    
    var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.frame = view.bounds
        view.addSubview(webView)
        loadData()
    }
    
    func loadData() {
        if  urlString.hasPrefix("http"),
            let url = URL(string: urlString)  {
            webView.load(URLRequest(url: url))
        } else {
            webView.loadHTMLString(urlString, baseURL: nil)
        }
    }
    
    init(urlString: String) {
        super.init(nibName: nil, bundle: nil)
        self.urlString = urlString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension YYWebViewController: WKUIDelegate,WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        title = "扫码结果"
        //禁止放大缩小
        let injectionJSString = """
            var script = document.createElement('meta');
            script.name = 'viewport';
            script.content=\"width=device-width, user-scalable=no\";
            document.getElementsByTagName('head')[0].appendChild(script);
            """
        webView.evaluateJavaScript(injectionJSString, completionHandler: nil)
    
    }
}
