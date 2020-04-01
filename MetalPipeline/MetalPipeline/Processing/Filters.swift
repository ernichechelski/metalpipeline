//
//  Filters.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import UIKit
 
protocol ImageProcessor {
    func processImage(image: UIImage, completion: @escaping ((_ success: Bool, _ finished: Bool, _ image: UIImage?, _ error: Error?) -> ()))
}

enum ImageProcessorFactory {

    static func makeDefault(for filter: Filter) -> ImageProcessor? {
        FilterProcessor(mediaFilter: filter)
    }
}

enum Filters {

    static let media = Filter()
    static let sepia = SepiaFilter()
    static let color = ColorFilter()
    static let blur = BlurFilter()
    static let sobel = SobelFilter()
    static let threashold = ThresholdFilter()
    static let nothing = NothingFilter()
}
