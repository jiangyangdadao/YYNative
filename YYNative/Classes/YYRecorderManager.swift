//
//  YYRecorderManager.swift
//  YYNative_Example
//
//  Created by 江大盗 on 10/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import AVKit
import ZLPhotoBrowser
let documentPath =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
let recorderPath = documentPath + "/YYNative/recorder.m4a"

public struct RecorderInfo {
    var fail: Bool = false
    var msg: String = ""
    var time: Int = 0
    let path: String = recorderPath
    
    public func toJsonString() -> String {
        return "{fail: \(fail),msg: \(msg),time: \(time),path: \(path)}"
    }
}

public protocol YYRecorderManagerDelegate {
    func recorderManagerUpdateLog(log: RecorderInfo)
}

public class YYRecorderManager: NSObject {
    
    public enum RecorderControl {
        case record
        case pause
        case stop
        case recordForDuradion(duration: TimeInterval)
    }
    
    public var delegate: YYRecorderManagerDelegate?
    
    public var logVC: UIViewController?
    
    var _currentTime: Int = 0
    public var currentTime : Int {
        if isRecording {  _currentTime = Int(self.recorder!.currentTime)  }
        return _currentTime
    }
    
    public var isRecording: Bool {
        return self.recorder?.isRecording ?? false
    }
    
    public var recorder: AVAudioRecorder?
    
    deinit {
        recorder?.stop()
        recorder?.deleteRecording()
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    public override init() {
        super.init()
        initRecorder()
    }
    
    func initRecorder() {
        AVCaptureDevice.requestAccess(for: .audio) {[unowned self] (audioGranted) in
            if !audioGranted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showAlertAndDismissAfterDoneAction(message: String(format: "请在iPhone的\"设置-隐私-麦克风\"选项中，允许%@访问你的麦克风", self.getAppName()))
                }
            } else {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                
                let url = URL(fileURLWithPath: recorderPath)
                if (!FileManager.default.fileExists(atPath: recorderPath)) {
                    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                }
                
                let recordSettings: [String:Any] = [
                    AVFormatIDKey:kAudioFormatMPEG4AAC,
                    AVLinearPCMBitDepthKey:16,
                    AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                    AVNumberOfChannelsKey: 2,
                    AVSampleRateKey: 44100.0]
                
                self.recorder = try? AVAudioRecorder(url: url, settings: recordSettings)
                self.recorder?.prepareToRecord()
                self.recorder?.delegate = self
            }
        }
    }
    
    public func doSomeOperation(_ type: RecorderControl) -> Bool {
        if recorder == nil  { initRecorder() }
        
        switch type {
        case .record: return recorder?.record() ?? false
        case .pause:  recorder?.pause()
        case .stop:   recorder?.stop()
        case .recordForDuradion(let dur): return recorder?.record(forDuration: dur) ?? false
        }
        return false
    }
    
    func updateInfo(fail: Bool, msg: String) {
        delegate?.recorderManagerUpdateLog(log: RecorderInfo(fail: fail, msg: msg, time: currentTime))
    }

    func showAlertAndDismissAfterDoneAction(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "确定", style: .default) { (_) in
            self.logVC?.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        logVC?.showDetailViewController(alert, sender: nil)
    }
    
    func getAppName() -> String {
        if let name = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return "App"
    }
}

extension YYRecorderManager: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        updateInfo(fail: !flag, msg: "录制完成")
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        updateInfo(fail: true, msg: "录制失败")
    }
    
    public func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder) {
        updateInfo(fail: false, msg: "录制中断中")
    }
    
    public func audioRecorderEndInterruption(_ recorder: AVAudioRecorder, withOptions flags: Int) {
        updateInfo(fail: false, msg: "录制中断结束")
    }
}
