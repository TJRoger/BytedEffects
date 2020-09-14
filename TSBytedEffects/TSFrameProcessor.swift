//
//  TSFrameProcessor.swift
//  BytedEffectsDemo
//
//  Created by Roger Luo on 4/3/20.
//  Copyright © 2020 Roger Luo. All rights reserved.
//

import Foundation
import AVFoundation
import OpenGLES.ES2
import UIKit

@objc protocol TSFrameProcessorDelegate {
    @objc optional func didDetectFaceInfo(faceInfo: bef_ai_face_info)
    @objc optional func didDetectFaceAttr(faceAttr: bef_ai_face_attribute_result)
}

class TSFrameProcessor: NSObject {
    static let LICENSE_PATH = "/yuban_test_20200331_20200415_com.mikasa.Moe-dev2_yuban_test_v3.8.2.licbag"
    static let FACE_106_MODEL_INPUT: CGSize = CGSize(width: 128, height: 224)
    weak var delegate: TSFrameProcessorDelegate?
    var glContext: EAGLContext!
    var videoDimensions: CGSize
    var triggerAction: String!
    let detect: TSDetect
    
    init(context: EAGLContext, videoSize size: CGSize) {
        self.glContext = context
        self.videoDimensions = size
        self.detect = TSDetect()
        super.init()
        self.setupBytedEffectsSDK()
    }
    
    
    func reset() {
        print("TSFrameProcessor reset")
        self.releaseSDK()
        self.setupBytedEffectsSDK()
    }
    
    deinit {
        EAGLContext.setCurrent(glContext)
        self.releaseSDK()
    }
    
    func setupBytedEffectsSDK() {
        self.detect.setupBytedEffectsSDK()
    }
    
    func releaseSDK() {
        self.detect.releaseBytedEffects()
    }
    
    func getDeviceOrientation() -> bef_ai_rotate_type {
        let orientation = UIDevice.current.orientation
        switch (orientation) {
        case .portrait:
            return BEF_AI_CLOCKWISE_ROTATE_0

        case .portraitUpsideDown:
            return BEF_AI_CLOCKWISE_ROTATE_180

        case .landscapeLeft:
            return BEF_AI_CLOCKWISE_ROTATE_270

        case .landscapeRight:
            return BEF_AI_CLOCKWISE_ROTATE_90

        default:
            return BEF_AI_CLOCKWISE_ROTATE_0
        }
    }
    
    private func getModelResizeRatio(width: Int, height: Int) {
        var xRatio: Float = 0, yRatio: Float = 0, retRatio: Float = 0
        xRatio = max(xRatio, Float(TSFrameProcessor.FACE_106_MODEL_INPUT.width) / Float(width));
        yRatio = max(yRatio, Float(TSFrameProcessor.FACE_106_MODEL_INPUT.height) / Float(height));
        retRatio = max(retRatio, max(xRatio, yRatio));
    }
    
    func process(_ pixelBuffer: CVPixelBuffer, timestamp: Double) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        let buf = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        let iBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let iWidth = CVPixelBufferGetWidth(pixelBuffer)
        let iHeight = CVPixelBufferGetHeight(pixelBuffer)
        var iLeft: Int = 0, iRight: Int = 0, iTop: Int = 0, iBottom: Int = 0
        CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom)
        if EAGLContext.current() != glContext {
            EAGLContext.setCurrent(glContext)
        }
        // 需要将输入图片变小时处理
//        let resizeRatio = self.getModelResizeRatio(width: iWidth, height: iHeight)
        let resizeRatio: Float = 1.0
        if resizeRatio != 0.0 {
            let resizeWidth = Float(iWidth) * resizeRatio
            let resizeHeight = Float(iHeight) * resizeRatio
            let imageFormat = BEF_AI_PIX_FMT_RGBA8888
            detect.setSDK(width: Int32(resizeWidth), height: Int32(resizeHeight), bytesPerRow: Int32(iBytesPerRow))
            // detect face info
            var faceInfo: bef_ai_face_info = bef_ai_face_info()
            let size = MemoryLayout.size(ofValue: faceInfo)
            memset(&faceInfo, 0, size)
            detect.faceDetect(faceInfo: &faceInfo, buffer: buf, format: imageFormat, orientation: self.getDeviceOrientation())
            weak var weakSelf = self
            DispatchQueue.main.async {
                weakSelf?.delegate?.didDetectFaceInfo?(faceInfo: faceInfo)
            }
            
            // detect face attributes
            var faceAttr = bef_ai_face_attribute_result()
            memset(&faceAttr, 0, MemoryLayout.size(ofValue: faceAttr))
            if faceInfo.face_count > 0 {
                detect.faceAttributeDetect(faceAttributeResult: &faceAttr, buffer: buf, faceInfo: &faceInfo.base_infos.0, faceCount: faceInfo.face_count, format: imageFormat)
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}
