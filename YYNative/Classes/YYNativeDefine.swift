//
//  YYNativeDefine.swift
//  FBSnapshotTestCase
//
//  Created by 江洋洋(金服稽核监察项目中心智慧司法团队) on 2020/9/18.
//

import UIKit
import AVKit
public func getImage(_ named: String) -> UIImage? {

    return UIImage(named: named, in: YYBundle(), compatibleWith: nil)
}

public func YYBundle() -> Bundle? {
    guard let resourcePath = Bundle(for: YYRecorderManager.self).resourcePath else {
        return nil
    }
    return Bundle(path: resourcePath + "/YYNative.bundle")
}

public func getAppName() -> String {
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


public func showAlertAndDismissAfterDoneAction(message: String) {
    guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
        return
    }
    
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "确定", style: .default) { (_) in
        rootVC.dismiss(animated: true, completion: nil)
    }
    alert.addAction(action)
    rootVC.showDetailViewController(alert, sender: nil)
 }

public func requestAccess(for mediaType: AVMediaType, completionHandler handler:@escaping () -> Void) {
    AVCaptureDevice.requestAccess(for: mediaType) {(audioGranted) in
        if !audioGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                var message = ""
                switch (mediaType) {
                    case .audio: message = String(format: "请在iPhone的\"设置-隐私-麦克风\"选项中，允许%@访问你的麦克风", getAppName())
                    case .video: message = String(format: "请在iPhone的\"设置-隐私-相机\"选项中，允许%@访问你的相机", getAppName())
                default:
                    break
                }
                showAlertAndDismissAfterDoneAction(message: message)
            }
        } else {
            handler()
        }
    }
}




public extension UIButton {
    func layoutTopImageButton(_ space: CGFloat) {
        //得到imageView和titleLabel的宽高
        guard let imageViewSize = self.imageView?.intrinsicContentSize else { return }
        guard let titleSize = self.titleLabel?.intrinsicContentSize else { return }
        
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + space * 0.5), left: 0, bottom: 0, right: -titleSize.width)
        self.titleEdgeInsets = UIEdgeInsets(top:0, left:-imageViewSize.width, bottom:-(imageViewSize.height + space * 0.5), right:0)
    }
}
