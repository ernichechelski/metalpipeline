//
//  Any+Extensions.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

@inline(__always) func with<T>(_ target: T, block: (T) -> Void) -> T {
    block(target)
    return target
}
