//
//  ViewController.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 30/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var processor = ImageProcessorFactory.makeDefault(for: Filters.media)

    override func viewDidLoad() {
        super.viewDidLoad()
        processor?.processImage(image: #imageLiteral(resourceName: "starrynight")) { (success, finished, image, error) in
            DispatchQueue.main.async {
                print("\(success)\(finished)\(image?.size)\(error)")
                self.imageView.image = image
            }
        }
    }
}
