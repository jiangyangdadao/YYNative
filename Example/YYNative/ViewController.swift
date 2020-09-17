//
//  ViewController.swift
//  YYNative
//
//  Created by JYY on 09/10/2020.
//  Copyright (c) 2020 JYY. All rights reserved.
//

import UIKit
import YYNative
import AVKit
import WebKit

class ViewController: UIViewController, YYRecorderManagerDelegate {

    @IBOutlet weak var operationButton: UIButton!
    
    @IBOutlet weak var detailLabel: UILabel!
    
    var displayLink: CADisplayLink!
    
    var recorderManager: YYRecorderManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recorderManager = YYRecorderManager()
        recorderManager.logVC = self
        recorderManager.delegate = self
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateStatus))
        displayLink.add(to: RunLoop.main, forMode: .common)
        displayLink.preferredFramesPerSecond = 1
        displayLink.isPaused = true
    }

    @IBAction func operationButtonAction(_ sender: UIButton) {
        if sender.isSelected {
            _ = recorderManager.doSomeOperation(.pause)
            sender.isSelected = false
        } else {
            sender.isSelected = recorderManager.doSomeOperation(.record)
        }
        displayLink.isPaused = !sender.isSelected
    }
    
    @IBAction func playRecord(_ sender: Any) {
        
        _ = recorderManager.doSomeOperation(.stop)
        
        let copyUrl = recorderManager.recorder!.url.deletingLastPathComponent().appendingPathComponent("cacheRecording.m4a")
        
        try? FileManager.default.copyItem(at: recorderManager.recorder!.url, to: copyUrl)
        
        let player = AVPlayer(url: copyUrl)
        let playerController = AVPlayerViewController()
        playerController.player = player
        navigationController?.pushViewController(playerController, animated: true)
    }
    
    @IBAction func stopRrecord(_ sender: Any) {
       _ = recorderManager.doSomeOperation(.stop)
    }
    
    @objc func updateStatus() {
        detailLabel.text = "\(recorderManager.currentTime)"
    }

    func recorderManagerUpdateLog(log: RecorderInfo) {
        detailLabel.text = log.toJsonString()
    }

}

