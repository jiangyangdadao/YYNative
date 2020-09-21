//
//  YYPhotoManager.swift
//  FBSnapshotTestCase
//
//  Created by 江大盗 on 11/9/2020.
//

import UIKit
import Photos
import ZLPhotoBrowser

public extension UIViewController {
    
    func quickSelectImage(selectImageBlock: ( ([UIImage], [PHAsset], Bool) -> Void )?)  {
        let ac = ZLPhotoPreviewSheet()
        ac.selectImageBlock = selectImageBlock
        ac.showPreview(animate: true, sender: self)
    }
    
    func selectPhoto(selectImageBlock: ( ([UIImage], [PHAsset], Bool) -> Void )?)  {
        //直接进入相册选择
        let ac = ZLPhotoPreviewSheet()
        ac.selectImageBlock = selectImageBlock
        ac.showPhotoLibrary(sender: self)
    }
    
    func openCamera(doneBlock: ( (UIImage?, URL?) -> Void )?) {
        //调用自定义相机
        let camera = ZLCustomCamera()
        camera.takeDoneBlock = doneBlock
        self.showDetailViewController(camera, sender: self)
    }
    
    func photoEdit(image: UIImage, editFinishBlock: ( (UIImage, ZLEditImageModel) -> Void )?) {
        //调用编辑图片
        let editVC = ZLEditImageViewController(image: image, tools: [.draw, .clip, .mosaic])
        editVC.editFinishBlock = editFinishBlock
        present(editVC, animated: true, completion: nil)
    }
    
}
