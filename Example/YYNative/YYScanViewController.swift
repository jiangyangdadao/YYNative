//
//  YYScanViewController.swift
//  YYNative_Example
//
//  Created by 江大盗 on 15/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

class YYScanViewController: UIViewController {
    
    let session = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var videoZoomFactor: CGFloat = 1
    let closeButton = UIButton(type: .contactAdd)
    
    let logBgView = UIView()
    let logTitleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let logSubtitleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let flashButton: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()
    
    var preview: AVCaptureVideoPreviewLayer!
    var qrLocationLayer: CALayer?
    var scanLayer: CALayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        //添加摄像预览
        initSessionCapture()
        //添加闪光灯
        
        //添加图库按钮
        
        //添加提示图层
        
        //添加返回按钮
        closeButton.addTarget(self, action:#selector(pop) , for: .touchUpInside)
        closeButton.frame = CGRect(x: 30, y: 30, width: 40, height: 40)
        view.addSubview(closeButton)
        
        //添加缩放
        let pan = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))
        tap.require(toFail: pan)
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(pan)
    }
    
    @objc func pop(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func pinch(gesture: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }
        switch gesture.state {
        case .began:
            videoZoomFactor = device.videoZoomFactor
        case .changed:
            do {
                let min = CGFloat.maximum(gesture.scale * videoZoomFactor, 1)
                let max = CGFloat.minimum(min, device.activeFormat.videoMaxZoomFactor)
                
                try device.lockForConfiguration()
                device.videoZoomFactor = max
                device.unlockForConfiguration()
            } catch {  }
        default: break
            
        }
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        
        guard let device = captureDevice else { return }
        guard device.isFocusPointOfInterestSupported else { return }

        let point = gesture.location(in: view)
        let devicePoint = preview.captureDevicePointConverted(fromLayerPoint: point)
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = devicePoint
            device.focusMode = .autoFocus
            device.exposurePointOfInterest = devicePoint
            device.exposureMode = .autoExpose
            device.unlockForConfiguration()
        } catch {  }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopRunning()
    }
    
    func startRunning() {
        if !session.isRunning {
            //            scanAnimation(start: true)
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
    
    func stopRunning() {
        if session.isRunning {
            qrLocationLayer?.removeFromSuperlayer()
            qrLocationLayer = nil
            //            self.scanAnimation(start: false)
            DispatchQueue.global().async {
                self.session.stopRunning()
            }
        }
    }
    
    func initSessionCapture()  {
        captureDevice = AVCaptureDevice.default(for: .video)
        
        guard let device = captureDevice else {
            showAlert(message: "摄像头不可用")
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            } else if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
        } catch {  }
        
        guard let input  = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCaptureMetadataOutput()
        
        if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        
        scanLayer = CALayer()
        scanLayer.frame = CGRect(origin: .zero, size: CGSize(width: preview.bounds.width, height: 96))
        scanLayer.backgroundColor = UIColor.init(white: 0, alpha: 1).cgColor
        
        preview.addSublayer(scanLayer)
        view.layer.addSublayer(preview)
        
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr, .aztec, .ean13]
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "确定", style: .default) {[weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func scanAnimation(start: Bool) {
        
        scanLayer.isHidden = !start
        guard start else {
            scanLayer.removeAllAnimations()
            return
        }
        
        let opacity0 = CABasicAnimation(keyPath: "opacity")
        opacity0.fromValue = 0
        opacity0.toValue = 1
        opacity0.duration = 0.25
        opacity0.fillMode = .forwards
        
        let position = CABasicAnimation(keyPath: "position.y")
        position.fromValue = 96
        position.toValue = preview.bounds.height - 96
        position.duration = 2.55
        position.fillMode = .forwards
        
        let opacity1 = CABasicAnimation(keyPath: "opacity")
        opacity1.beginTime = 2.55 - 0.25
        opacity1.fromValue = 1
        opacity1.toValue = 0
        opacity1.duration = 0.25
        opacity1.fillMode = .forwards
        
        let group = CAAnimationGroup()
        group.duration = 3
        group.animations = [opacity0, position, opacity1]
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        scanLayer.add(group, forKey: "group")
    }
}


extension YYScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        stopRunning()
        
        if let metadataObject = metadataObjects.first {
            
            guard let codeObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            
            // 添加定位点 将扫码出来的坐标转换成手机布局坐标
            let rect = preview.layerRectConverted(fromMetadataOutputRect: codeObject.bounds)
            
            let dotLayer = CALayer()
            dotLayer.frame = rect.insetBy(dx: (rect.width - 16) * 0.5, dy: (rect.height - 16) * 0.5)
            dotLayer.backgroundColor = UIColor.blue.cgColor
            dotLayer.cornerRadius = 8
            dotLayer.borderColor = UIColor.white.cgColor
            dotLayer.borderWidth = 1
            
            //animationGroups
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1
            scale.toValue = 2
            
            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 0.0
            opacity.toValue = 1.0
            
            let group = CAAnimationGroup()
            group.animations = [scale, opacity]
            group.duration = 0.2
            group.autoreverses = true
            group.repeatCount = MAXFLOAT
            
            dotLayer.add(group, forKey: "blink")
            preview.addSublayer(dotLayer)
            qrLocationLayer = dotLayer
            
            // 处理数据
            guard let metadataString = codeObject.stringValue  else {
                showAlert(message:"无法识别二维码")
                return
            }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if metadataString.hasPrefix("http") {
                let webVC = YYWebViewController(urlString: metadataString)
                
                navigationController?.pushViewController(webVC, animated: true)
            } else {
                showAlert(message:metadataString)
            }
        }
    }
}
