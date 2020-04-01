//
//  Media.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//


import UIKit
import AVFoundation

enum MediaElementType {
    case image
    case view
    case text
}

class MediaElement {
    var frame: CGRect = .zero
    var type: MediaElementType = .image

    private(set) var contentImage: UIImage! = nil
    private(set) var contentView: UIView! = nil
    private(set) var contentText: NSAttributedString! = nil

    init(image: UIImage) {
        contentImage = image
        type = .image
    }

    init(view: UIView) {
        contentView = view
        type = .view
    }

    init(text: NSAttributedString) {
        contentText = text
        type = .text
    }
}

extension MediaProcessor {
    func processImageWithElements(item: MediaItem, completion: @escaping ProcessCompletionHandler) {
        if item.filter != nil {
            filterProcessor = FilterProcessor(mediaFilter: item.filter)
            filterProcessor.processImage(image: item.sourceImage.fixedOrientation(), completion: { [weak self] (success, finished, image, error) in
                if error != nil {
                    completion(MediaProcessResult(processedUrl: nil, image: nil), error)
                } else if image != nil && finished == true {
                    completion(MediaProcessResult(processedUrl: nil, image: image), nil)

                    let updatedMediaItem = MediaItem(image: image!)
                    updatedMediaItem.add(elements: item.mediaElements)
                    self?.processItemAfterFiltering(item: updatedMediaItem, completion: completion)
                }
            })

        } else {
            processItemAfterFiltering(item: item, completion: completion)
        }
    }

    func processItemAfterFiltering(item: MediaItem, completion: @escaping ProcessCompletionHandler) {
        UIGraphicsBeginImageContextWithOptions(item.sourceImage.size, false, item.sourceImage.scale)
        item.sourceImage.draw(in: CGRect(x: 0, y: 0, width: item.sourceImage.size.width, height: item.sourceImage.size.height))

        for element in item.mediaElements {
            if element.type == .view {
                UIImage(view: element.contentView).draw(in: element.frame)
            } else if element.type == .image {
                element.contentImage.draw(in: element.frame)
            } else if element.type == .text {
                element.contentText.draw(in: element.frame)
            }
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        completion(MediaProcessResult(processedUrl: nil, image: newImage), nil)
    }
}

enum MediaItemType {
    case image
    case video
}

struct MediaProcessResult {
    var processedUrl: URL?
    var image: UIImage?
}

typealias ProcessCompletionHandler = ((_ result: MediaProcessResult, _ error: Error?) -> ())

class MediaItem {
    var type: MediaItemType {
        return sourceAsset != nil ? .video : .image
    }

    var size: CGSize {
        get {
            if sourceAsset != nil {
                if let track = AVAsset(url: sourceAsset.url).tracks(withMediaType: AVMediaType.video).first {
                    let size = track.naturalSize.applying(track.preferredTransform)
                    return CGSize(width: fabs(size.width), height: fabs(size.height))
                } else {
                    return CGSize.zero
                }
            } else if sourceImage != nil {
                return sourceImage.size
            }

            return CGSize.zero
        }
    }

    private(set) var sourceAsset: AVURLAsset! = nil
    private(set) var sourceImage: UIImage! = nil
    private(set) var mediaElements = [MediaElement]()
    private(set) var filter: Filter! = nil

    // MARK: - init
    init(asset: AVURLAsset) {
        sourceAsset = asset
    }

    init(image: UIImage) {
        sourceImage = image
    }

    init?(url: URL) {
        if urlHasImageExtension(url: url) {
            do {
                let data = try Data(contentsOf: url)
                sourceImage = UIImage(data: data)
            } catch {
                return nil
            }
        } else {
            sourceAsset = AVURLAsset(url: url)
        }
    }

    // MARK: - elements
    func add(element: MediaElement) {
        mediaElements.append(element)
    }

    func add(elements: [MediaElement]) {
        mediaElements.append(contentsOf: elements)
    }

    func removeAllElements() {
        mediaElements.removeAll()
    }

    // MARK: - filters
    func applyFilter(mediaFilter: Filter) {
        filter = mediaFilter
    }

    // MARK: - private
    private func urlHasImageExtension(url: URL) -> Bool {
        let imageExtensions = ["png", "jpg", "gif"]
        return imageExtensions.contains(url.pathExtension)
    }
}

class MediaProcessor {
    var filterProcessor: FilterProcessor! = nil

    // MARK: - process elements
    func processElements(item: MediaItem, completion: @escaping ProcessCompletionHandler) {
        item.type == .video ? processVideoWithElements(item: item, completion: completion) : processImageWithElements(item: item, completion: completion)
    }
}

let kMediaContentDefaultScale: CGFloat = 1
let kProcessedTemporaryVideoFileName = "/processed.mov"
let kMediaContentTimeValue: Int64 = 1
let kMediaContentTimeScale: Int32 = 30

extension MediaProcessor {
    func processVideoWithElements(item: MediaItem, completion: @escaping ProcessCompletionHandler) {
        let mixComposition = AVMutableComposition()
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let clipVideoTrack = item.sourceAsset.tracks(withMediaType: AVMediaType.video).first
        let clipAudioTrack = item.sourceAsset.tracks(withMediaType: AVMediaType.audio).first

        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: item.sourceAsset.duration), of: clipVideoTrack!, at: CMTime.zero)
        } catch {
            completion(MediaProcessResult(processedUrl: nil, image: nil), error)
        }

        if (clipAudioTrack != nil) {
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)

            do {
                try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: item.sourceAsset.duration), of: clipAudioTrack!, at: CMTime.zero)
            } catch {
                completion(MediaProcessResult(processedUrl: nil, image: nil), error)
            }
        }

        compositionVideoTrack?.preferredTransform = (item.sourceAsset.tracks(withMediaType: AVMediaType.video).first?.preferredTransform)!

        let sizeOfVideo = item.size

        let optionalLayer = CALayer()
        processAndAddElements(item: item, layer: optionalLayer)
        optionalLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        optionalLayer.masksToBounds = true

        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(optionalLayer)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(value: kMediaContentTimeValue, timescale: kMediaContentTimeScale)
        videoComposition.renderSize = sizeOfVideo
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: mixComposition.duration)

        let videoTrack = mixComposition.tracks(withMediaType: AVMediaType.video).first
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        layerInstruction.setTransform(transform(avAsset: item.sourceAsset, scaleFactor: kMediaContentDefaultScale), at: CMTime.zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let processedUrl = processedMoviePath()
        clearTemporaryData(url: processedUrl, completion: completion)

        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.videoComposition = videoComposition
        exportSession?.outputURL = processedUrl
        exportSession?.outputFileType = AVFileType.mp4

        exportSession?.exportAsynchronously(completionHandler: {
            if exportSession?.status == AVAssetExportSession.Status.completed {
                completion(MediaProcessResult(processedUrl: processedUrl, image: nil), nil)
            } else {
                completion(MediaProcessResult(processedUrl: nil, image: nil), exportSession?.error)
            }
        })
    }

    // MARK: - private
    private func processAndAddElements(item: MediaItem, layer: CALayer) {
        for element in item.mediaElements {
            var elementLayer: CALayer! = nil

            if element.type == .view {
                elementLayer = CALayer()
                elementLayer.contents = UIImage(view: element.contentView).cgImage
            } else if element.type == .image {
                elementLayer = CALayer()
                elementLayer.contents = element.contentImage.cgImage
            } else if element.type == .text {
                elementLayer = CATextLayer()
                (elementLayer as! CATextLayer).string = element.contentText
            }

            elementLayer.frame = element.frame
            layer.addSublayer(elementLayer)
        }
    }

    private func processedMoviePath() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + kProcessedTemporaryVideoFileName
        return URL(fileURLWithPath: documentsPath)
    }

    private func clearTemporaryData(url: URL, completion: ProcessCompletionHandler!) {
        if (FileManager.default.fileExists(atPath: url.path)) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                completion(MediaProcessResult(processedUrl: nil, image: nil), error)
            }
        }
    }

    private func transform(avAsset: AVAsset, scaleFactor: CGFloat) -> CGAffineTransform {
        var offset = CGPoint.zero
        var angle: Double = 0

        switch avAsset.contentOrientation {
        case .left:
            offset = CGPoint(x: avAsset.contentCorrectSize.height, y: avAsset.contentCorrectSize.width)
            angle = Double.pi
        case .right:
            offset = CGPoint.zero
            angle = 0
        case .down:
            offset = CGPoint(x: 0, y: avAsset.contentCorrectSize.width)
            angle = -(Double.pi / 2)
        default:
            offset = CGPoint(x: avAsset.contentCorrectSize.height, y: 0)
            angle = Double.pi / 2
        }

        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translation = scale.translatedBy(x: offset.x, y: offset.y)
        let rotation = translation.rotated(by: CGFloat(angle))

        return rotation
    }
}
let kImageBitsPerComponent: Int = 8
let kImageBitsPerPixel: Int = 32
let kImageBytesCount: Int = 4

extension UIImage {
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage)!)
    }

    convenience init?(fromTexture: MTLTexture) {
        let width = fromTexture.width
        let height = fromTexture.height

        let rowBytes = width * kImageBytesCount
        let textureResize = width * height * kImageBytesCount

        let memory = malloc(textureResize)

        fromTexture.getBytes(memory!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.first.rawValue

        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }

        let provider = CGDataProvider(dataInfo: nil, data: memory!, size: textureResize, releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: width,
                                 height: height,
                                 bitsPerComponent: kImageBitsPerComponent,
                                 bitsPerPixel: kImageBitsPerPixel,
                                 bytesPerRow: rowBytes,
                                 space: colorSpace,
                                 bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                 provider: provider!,
                                 decode: nil,
                                 shouldInterpolate: true,
                                 intent: CGColorRenderingIntent.defaultIntent)

        self.init(cgImage: cgImageRef!)
    }

    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        var transform: CGAffineTransform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            break
        case .up, .upMirrored:
            break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        }

        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: (self.cgImage?.colorSpace)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        ctx.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            break
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }

        let cgImage: CGImage = ctx.makeImage()!

        return UIImage(cgImage: cgImage)
    }
}

extension AVAsset {
    private var contentNaturalSize: CGSize {
        return tracks(withMediaType: AVMediaType.video).first?.naturalSize ?? .zero
    }

    var contentCorrectSize: CGSize {
        return isContentPortrait ? CGSize(width: contentNaturalSize.height, height: contentNaturalSize.width) : contentNaturalSize
    }

    var contentOrientation: UIImage.Orientation {
        var assetOrientation = UIImage.Orientation.up
        let transform = tracks(withMediaType: AVMediaType.video)[0].preferredTransform

        if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
            assetOrientation = .up
        }

        if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {
            assetOrientation = .down
        }

        if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0) {
            assetOrientation = .right
        }

        if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
            assetOrientation = .left
        }

        return assetOrientation
    }

    var isContentPortrait: Bool {
        let portraits: [UIImage.Orientation] = [.left, .right]
        return portraits.contains(contentOrientation)
    }
}

