//
//  Filters.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Foundation

enum Filters {

    static let sepia = SepiaFilter()
    static let color = ColorFilter()
    static let blur = BlurFilter()
    static let sobel = SobelFilter()
    static let threashold = ThresholdFilter()
}
