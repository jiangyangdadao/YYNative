//
//  YYWebViewController.swift
//  YYNative_Example
//
//  Created by 江大盗 on 17/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import YYNative

class YYWebViewController: UIViewController {
    
    var urlString: String! = "" {
        didSet {
            guard let url = URL(string: urlString) else { return }
            webView.load(URLRequest(url: url))
        }
    }
    
    let webView: YYWebView = {
        let webView = YYWebView(frame: .zero)
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = view.bounds
    }
    
    init(urlString: String) {
        super.init(nibName: nil, bundle: nil)
        self.urlString = urlString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
