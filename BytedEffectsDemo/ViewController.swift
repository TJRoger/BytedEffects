//
//  ViewController.swift
//  BytedEffectsDemo
//
//  Created by Roger Luo on 4/1/20.
//  Copyright © 2020 Roger Luo. All rights reserved.
//

import UIKit
import AVFoundation

enum BefEffectMainStatue: Int {
    case BefEffectNone = 0
    case BefEffectDetect
    case BefEffectFaceBeauty
    case BefEffectSticker
}

class ViewController: UIViewController, TSVideoCaptureDelegate, TSFrameProcessorDelegate  {
    var capture: TSVideoCapture!
    var processor: TSFrameProcessor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.createCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        capture.stop()
    }
    
    private func createCamera() {
        capture = TSVideoCapture()
        capture.isOutputWithYUV = false
        capture.delegate = self
        
        guard let context = EAGLContext(api: .openGLES2) else {
            return
        }
        EAGLContext.setCurrent(context)
        processor = TSFrameProcessor(context: context, videoSize: capture.videoSize)
        processor.delegate = self
        
        capture.start()
    }
    // MARK: - TSVideoCaptureDelegate

    func didOutputSampleBuffer(sampleBuffer: CMSampleBuffer) {
        guard let imageRef = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timestamp = Double(sampleTime.value) / Double(sampleTime.timescale)
        processor.process(imageRef, timestamp: timestamp)
//        detect(imageRef: imageRef, timestamp: timestamp)
//        print(timestamp)
    }
    
   
//    func detect(imageRef: CVImageBuffer?, timestamp: Double) {
//    }


    func didFailedToStart(error: VideoCaptureError) {
        
    }
    
    // MARK: - TSFrameProcessorDelegate
    func didDetectFaceInfo(faceInfo: bef_ai_face_info) {
        let count = faceInfo.face_count
        print("detected face count: \(count)")
        print(faceInfo.base_infos.0)
        print(faceInfo.extra_infos.0)
    }
    
    func didDetectFaceAttr(faceAttr: bef_ai_face_attribute_result) {
        let count = faceAttr.face_count
        print("detected face attr: \(count)")
        print(faceAttr.attr_info.0)
    }
    

}


