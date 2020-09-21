//
//  YYWebView.swift
//  YYNative_Example
//
//  Created by 江大盗 on 10/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import WebKit

public class YYWebView: WKWebView {
 
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
    }
}
