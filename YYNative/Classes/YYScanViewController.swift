//
//  YYScanViewController.swift
//  YYNative_Example
//
//  Created by 江大盗 on 15/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class YYScanViewController: UIViewController {
    
    let session = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var videoZoomFactor: CGFloat = 1
    let closeButton = UIButton(type: .custom)
    
    let logBgView: UIView = {
        let label1 = UILabel()
        label1.textAlignment = .center
        label1.text = "未发现二维码信息"
        label1.font = .systemFont(ofSize: 18)
        label1.textColor = .white
        
        let label2 = UILabel()
        label2.textAlignment = .center
        label1.text = "轻触屏幕继续扫描"
        label1.font = .systemFont(ofSize: 14)
        label1.textColor = .lightGray
        
        let view = UIView()
        view.addSubview(label1)
        view.addSubview(label2)
        return view
    }()

    
    let flashButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(getImage("ic_torch_close"), for: .selected)
        button.setImage(getImage("ic_torch"), for: .normal)
        button.setTitle("关闭手电筒", for: .selected)
        button.setTitle("打开手电筒", for: .normal)
        return button
    }()
    
    let albumButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(getImage("icon_pic"), for: .normal)
        return button
    }()
    
    var preview: AVCaptureVideoPreviewLayer!
    var qrLocationLayer: CALayer?
    var scanLayer: CALayer!
    
    var torchObserve: NSKeyValueObservation?
    
    deinit {
        print(" YYScanViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        //添加摄像预览

        self.initSessionCapture()
        //添加图库按钮
        albumButton.sizeToFit()
        albumButton.addTarget(self, action: #selector(album), for: .touchUpInside)
        albumButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.height - albumButton.bounds.height * 0.5 - 10)
        view.addSubview(albumButton)
        
        var rect = preview.frame
        rect.size.height -= (albumButton.bounds.height + 20)
        preview.frame = rect
        
        //添加闪光灯
        let label = UILabel()
        label.text = "扫描二维码/条码"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15)
        label.sizeToFit()
        label.center = CGPoint(x: view.bounds.midX, y: albumButton.frame.minY - label.bounds.height * 0.5 - 20)
        view.addSubview(label)
        
        //添加闪光灯
        flashButton.sizeToFit()
        flashButton.addTarget(self, action: #selector(flash), for: .touchUpInside)
        flashButton.center = CGPoint(x: view.bounds.midX, y: label.frame.minY - flashButton.bounds.height * 0.5 - 20)
        view.addSubview(flashButton)
        flashButton.layoutTopImageButton(10)
        
        if let device = captureDevice {
           torchObserve = device.observe(\AVCaptureDevice.torchMode) {[unowned self] (object, change) in
                self.flashButton.isSelected = object.torchMode == .on
            }
        }
        
        //添加渐变图层
        let gradLayer = CAGradientLayer()
        gradLayer.frame = CGRect(x: 0, y: flashButton.frame.minY, width: preview.bounds.width, height: preview.frame.maxY - flashButton.frame.minY)
        gradLayer.colors = [UIColor.init(white: 0, alpha: 0).cgColor,UIColor.init(white: 0, alpha: 0.9).cgColor]
        gradLayer.startPoint = .zero
        gradLayer.endPoint = CGPoint(x: 0, y: 1)
        gradLayer.locations = [0, 1]
        preview.insertSublayer(gradLayer, above: scanLayer)
        
        //添加提示图层
        logBgView.frame = view.bounds
        logBgView.isHidden = true
        logBgView.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        let errorTap = UITapGestureRecognizer(target: self, action: #selector(tapError))
        logBgView.addGestureRecognizer(errorTap)
        view.addSubview(logBgView)
        
        //添加返回按钮
        closeButton.setImage(getImage("cross-circle-o"), for: .normal)
        closeButton.addTarget(self, action:#selector(pop) , for: .touchUpInside)
        closeButton.frame = CGRect(x: 15, y: 30, width: 40, height: 40)
        view.addSubview(closeButton)
        
        //添加缩放
        let pan = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))
        tap.require(toFail: pan)
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(pan)
    }
    
    @objc func pop() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func album(){
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .overCurrentContext
        present(imagePicker, animated: true, completion: nil)
        
        stopRunning()
    }
    
    @objc func tapError(){
        errorView(show: false)
        startRunning()
    }
    
    func errorView(show: Bool) {
        logBgView.isHidden = !show
    }
    
    @objc func flash(){
        guard let device = captureDevice else {
            return
        }
        let on = !flashButton.isSelected
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
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
        
        requestAccess(for: .video) { [unowned self] in
            if !self.session.isRunning {
                self.qrLocationLayer?.removeFromSuperlayer()
                self.qrLocationLayer = nil
                self.scanAnimation(start: true)
                DispatchQueue.global().async {
                    self.session.startRunning()
                }
            }
        }
    }
    
    func stopRunning() {
        if session.isRunning {
            self.scanAnimation(start: false)
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
        scanLayer.contents = getImage("ic_scanbar")?.cgImage
        scanLayer.frame = CGRect(origin: .zero, size: CGSize(width: preview.bounds.width, height: 96))
        
        preview.addSublayer(scanLayer)
        view.layer.insertSublayer(preview, at: 0)
        
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
        
        if let metadataObject = metadataObjects.first {
            stopRunning()

            guard let codeObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            // 显示定位蓝点
            showCodeLocationDot(codeObject.bounds)
            // 处理数据
            guard let metadataString = codeObject.stringValue  else {
                errorView(show: true)
                return
            }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            navigationController?.pushViewController(YYWebViewController(urlString: metadataString), animated: true)
        }
    }
    
    func showCodeLocationDot(_ frame: CGRect) {
        // 添加定位点 将扫码出来的坐标转换成手机布局坐标
        let rect = preview.layerRectConverted(fromMetadataOutputRect: frame)

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
    }
}


extension YYScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let originalImage = info[.originalImage] as? UIImage {
            let imageScan = YYImageScanViewController()
            imageScan.image = originalImage
            imageScan.detectorHandle = { [unowned self] (content) in
                if content != nil {
                    self.navigationController?.pushViewController(YYWebViewController(urlString: content!), animated: true)
                } else {
                    self.errorView(show: true)
                }
            }
            navigationController?.pushViewController(imageScan, animated: true)
        } else {
            startRunning()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        startRunning()
    }
}


class YYImageScanViewController: UIViewController {
    
    var image: UIImage?
    
    var detectorHandle: ((String?) -> Void)?
    
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        defer { imageView.image = image  }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(done))
        
        imageView.frame = view.bounds
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
    }
    
    @objc func done() {
        guard let img = image else {return}
        guard let ciImage = CIImage(image: img) else { return  }
        
        DispatchQueue.global().async {
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            let features = detector?.features(in: ciImage)
            
            var content: String? = nil
            guard let feature = features?.first as? CIQRCodeFeature else {
                content = nil
                return
            }
            
            let imageSize = img.size
            UIGraphicsBeginImageContext(imageSize)
            img.draw(in: CGRect(origin: .zero, size: imageSize))
            
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -imageSize.height)
            
            let path = UIBezierPath()
            path.move(to: feature.topLeft.applying(transform))
            path.addLine(to: feature.topRight.applying(transform))
            path.addLine(to: feature.bottomRight.applying(transform))
            path.addLine(to: feature.bottomLeft.applying(transform))
            path.close()
            
            path.lineWidth = 20
            UIColor.blue.setStroke()
            path.stroke()
            let codeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                self.imageView.image = codeImage
                content = feature.messageString
                guard let handle = self.detectorHandle else {
                    return
                }
                handle(content)
            }
        }
    }
}
