//
//  photoViewController.swift
//  YYNative_Example
//
//  Created by 江大盗 on 14/9/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import YYNative
class photoViewController: UIViewController {

    @IBOutlet weak var imageVIew: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func quickImageSelectAction(_ sender: Any) {
        quickSelectImage(selectImageBlock: nil)
    }
    
    @IBAction func photoAlbumSelectAction(_ sender: Any) {
        selectPhoto(selectImageBlock: nil)
    }
    
    @IBAction func edit(_ sender: Any) {
        photoEdit(image: imageVIew.image!) {[weak self] (image, mode) in
            self?.imageVIew.image = image
        }
    }
    
    @IBAction func camera(_ sender: Any) {
        openCamera {[weak self] (image, _) in
            self?.imageVIew.image = image
        }
    }

}
