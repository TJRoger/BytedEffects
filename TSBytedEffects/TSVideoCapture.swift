//
//  TSVideoCapture.swift
//  BytedEffectsDemo
//
//  Created by Roger Luo on 4/2/20.
//  Copyright © 2020 Roger Luo. All rights reserved.
//

//import Foundation
import AVFoundation
import UIKit

enum VideoCaptureError: Int {
    case AuthNotGranted = 0
    case FailedCreateInput, FailedAddDataOutput, FailedAddDeviceInput
}

protocol TSVideoCaptureDelegate: NSObject {
    func didOutputSampleBuffer(sampleBuffer: CMSampleBuffer);
    func didFailedToStart(error: VideoCaptureError);
}


let mainScreenSize = UIScreen.main.bounds.size
let scanRectWidth: CGFloat = 240.0
let scanRectHeight: CGFloat = 360.0
let scanRect = CGRect(x: mainScreenSize.width/2 - scanRectWidth/2, y: mainScreenSize.height/2 - scanRectHeight/2, width: scanRectWidth, height: scanRectHeight)

class TSVideoCapture: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: TSVideoCaptureDelegate?
    /// default .Front
    private(set) var devicePosition: AVCaptureDevice.Position!
    /// default 1280x720
    var sessionPreset: AVCaptureSession.Preset!  {
        didSet {
            guard oldValue != sessionPreset && session != nil else {
                sessionPreset = oldValue
                return
            }
            self.pause()
            session.beginConfiguration()
            if session.canSetSessionPreset(sessionPreset) {
                session.sessionPreset = sessionPreset
            }
            session.commitConfiguration()
            self.resume()
        }
    }
    // default false
    var isOutputWithYUV: Bool = false {
        willSet {
            guard newValue != isOutputWithYUV else {
                return
            }
            let iCVPixelFormatType = newValue ? kCVPixelFormatType_420YpCbCr8BiPlanarFullRange : kCVPixelFormatType_32BGRA
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): iCVPixelFormatType]
            dataOutput.setSampleBufferDelegate(self, queue: bufferQueue)
            self.pause()
            session.beginConfiguration()
            session.removeOutput(self.dataOutput)
            if session.canAddOutput(dataOutput) {
                session.addOutput(dataOutput)
                self.dataOutput = dataOutput
            } else {
                self.throwError(error: .FailedAddDataOutput)
                print("session add data output failed when change output buffer pixel format.")
            }
            session.commitConfiguration()
            self.resume()
            self.setOrientation(self.videoOrientation)
            self.setFlip(self.isFlipped)
        }
    }
    
//    private(set) var isFrontCamera: Bool
//    var caputreFormat: Int
    internal var deviceInput: AVCaptureDeviceInput!
    internal var dataOutput: AVCaptureVideoDataOutput!
    internal var session: AVCaptureSession!
    internal var device: AVCaptureDevice!
    internal var bufferQueue: DispatchQueue!
    internal var isPaused: Bool
    internal var isFlipped: Bool {
        didSet {
            guard session != nil && dataOutput != nil else {
                print("failed to set isFlipped, session is \(String(describing: session)), dataOutput is \(String(describing: dataOutput))")
                isFlipped = oldValue
                return
            }
            if let videoConnection = dataOutput.connection(with: .video) {
                if videoConnection.isVideoMirroringSupported {
                    videoConnection.isVideoMirrored = isFlipped
                }
            }
        }
    }
    internal var videoOrientation: AVCaptureVideoOrientation
    internal var metaDataOutput: AVCaptureMetadataOutput!
    internal var previewLayer: AVCaptureVideoPreviewLayer?
//    internal var maskView: UIView // scan frame
    internal var maskLayer: CAShapeLayer?
    internal var isFirstApply: Bool
    
    var videoSize: CGSize {
        get {
            guard dataOutput.videoSettings != nil else {
                return CGSize.zero;
            }
            let width = dataOutput.videoSettings["Width"] as! CGFloat
//            [[dataOutput.videoSettings objectForKey:@"Width"] floatValue];
            let height = dataOutput.videoSettings["Height"] as! CGFloat
            // [[dataOutput.videoSettings objectForKey:@"Height"] floatValue];
            return CGSize(width: width, height: height);
        }
    }
    
    init(position: AVCaptureDevice.Position = .front) {
        self.devicePosition = position
        self.isPaused = true
        self.isFlipped = true
        self.videoOrientation = .portrait
        self.isFirstApply = true
        super.init()
        self.setupCaptureSession()
    }
    
    func setupCaptureSession() {
//        weak var weakSelf = self
        requestCameraAuthorization { (granted) in
            if granted {
                self.setupSession()
            } else {
                self.throwError(error: VideoCaptureError.AuthNotGranted)
            }
        }
    }
    
    // MARK: - private functions
    internal func requestCameraAuthorization(handler: @escaping (_ granted: Bool) -> ()) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .authorized:
            handler(true)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: handler)
            break
        case .denied, .restricted:
            handler(false)
        @unknown default:
            handler(false)
        }
    }
    
    internal func throwError(error: VideoCaptureError) {
        delegate?.didFailedToStart(error: error)
    }
    
    internal func setupSession() {
        session = AVCaptureSession()
        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else {
            session.sessionPreset = .high
        }
        session.commitConfiguration()
        device = cameraDevice(position: .front)
        devicePosition = .front
        bufferQueue = DispatchQueue(label: "HTSCameraBufferQueue")
        // input
        do {
            deviceInput = try AVCaptureDeviceInput(device: device!)
        } catch {
            delegate?.didFailedToStart(error: .FailedAddDeviceInput)
            return
        }
        // output
        let iCVPixelFormatType = isOutputWithYUV ? kCVPixelFormatType_420YpCbCr8BiPlanarFullRange : kCVPixelFormatType_32BGRA
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): iCVPixelFormatType]
        dataOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        
        session.beginConfiguration()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        } else {
            self.throwError(error: .FailedAddDataOutput)
            print("Could not add video data output to the session")
        }
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        } else {
            self.throwError(error: .FailedAddDeviceInput)
            print("Could not add device input to the session")
        }
        session.commitConfiguration()
        self.setFlip(isFlipped)
        self.setOrientation(videoOrientation)
        self.registerNotification()
        self.start()
    }
    
    func registerNotification() {
//        weak var weakSelf  = self
    }
    
    internal func cameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera,.builtInWideAngleCamera],
                                                       mediaType: .video,
                                                       position: position).devices
//        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    internal func switchCamera(position: AVCaptureDevice.Position) {
        if devicePosition == position {return}
        guard let targetDevice = cameraDevice(position: position) else {
            print("failed to find target device \(position)")
            return
        }
        do {
            let deviceInput = try AVCaptureDeviceInput(device: targetDevice)
            self.pause()
            session!.beginConfiguration()
            session!.removeInput(self.deviceInput)
            if session!.canAddInput(deviceInput) {
                session!.addInput(deviceInput)
                self.deviceInput = deviceInput
                self.device = targetDevice
                self.devicePosition = position
                self.setOrientation(videoOrientation)
                self.setFlip(position == .front)
            }
            session!.commitConfiguration()
            self.resume()
        } catch {
            self.throwError(error: .FailedCreateInput)
            print("Error creating capture device input: \(error.localizedDescription)")
            return
        }
    }
    
    func start() {
        if dataOutput != nil && metaDataOutput != nil  { return }
        if session != nil && !session!.isRunning {
            session!.startRunning()
            isPaused = false
        }
    }
    
    func stop() {
        if session != nil  && session!.isRunning {
            session!.stopRunning()
            isPaused = true
        }
    }
    
    func switchCamera() {
        if session == nil {return}
        let targetPosion: AVCaptureDevice.Position = devicePosition == .front ? .back : .front
        switchCamera(position: targetPosion)
    }
    
    func pause() {
        self.isPaused = true
    }
    
    func resume() {
        self.isPaused = false
    }
    
    func setFlip(_ isFlip: Bool) {
        self.isFlipped = isFlip
    }
    
    func setOrientation(_ orientation: AVCaptureVideoOrientation) {
        guard session != nil && dataOutput != nil else {
            print("failed to set videoOrientation, session is \(String(describing: session)), dataOutput is \(String(describing: dataOutput))")
            return
        }
        if let videoConnection = dataOutput.connection(with: .video) {
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = orientation
                videoOrientation = orientation
            }
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 { return }
        let result = metadataObjects.first.debugDescription
        print(result)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isPaused {
            delegate?.didOutputSampleBuffer(sampleBuffer: sampleBuffer)
        }
    }

}
