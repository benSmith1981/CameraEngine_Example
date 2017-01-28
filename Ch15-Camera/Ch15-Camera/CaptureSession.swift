//
//  CaptureSession.swift
//  Zombiefy2016
//
//  Created by Ben Smith on 21/11/16.
//  Copyright © 2016 Ben Smith. All rights reserved.
//

import UIKit

protocol CameraControlsProtocolSwift {
    func record()
    func switchCamera()
}

class CaptureSession: UIViewController, CameraControlsProtocolSwift, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    @IBOutlet weak var cameraControls: CameraControls?
    @IBOutlet weak var previewView: UIView?

    var videoFilter: VideoFilter!

    //Inputs and outputs
    var captureSession = AVCaptureSession()
    var videoOutput : AVCaptureVideoDataOutput!
    var videoDeviceInput: AVCaptureDeviceInput!
    var audioInput : AVCaptureDeviceInput!
    var audioOutput = AVCaptureAudioDataOutput()
    var videoLayer = AVCaptureVideoPreviewLayer()

    //ASSET WRITER
    var adapter:AVAssetWriterInputPixelBufferAdaptor!
    var videoWriter:AVAssetWriter!
    var writerInput:AVAssetWriterInput!
    var audioWriterInput:AVAssetWriterInput!
    var lastPath = ""
    var starTime = kCMTimeZero
    
    //DEVICE
    var devicePosition : AVCaptureDevicePosition!
    var captureDevice : AVCaptureDevice!

    //QUEUE
    var sessionQueue : DispatchQueue?
    var isRecording = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicePosition = AVCaptureDevicePosition.front
        videoFilter = VideoFilter.init()
        self.cameraControls?.delegate = self
        self.cameraControls?.recordButton?.setTitle("record", for: .normal)
        setupSession()
    }
    
    func setupSession() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch {
            print("error in audio")
        }
        
        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480
        self.sessionQueue = DispatchQueue(label: "sample buffer delegate")
        self.captureSession.beginConfiguration()
        self.addVideoInput()
        self.addVideoOutput()
        self.addAudioOutput()
        self.addAudioInput()
        captureSession.commitConfiguration()

        //Create videolayer or AVCaptureVideoPreviewLayer add to our rootlayer
        let rootLayer : CALayer = previewView!.layer
        rootLayer.masksToBounds = true
        //create AVCaptureVideoPreviewLayer
        self.videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect
        self.videoLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(self.videoLayer)
        
        captureSession.startRunning()
        
    }
    
    func deviceWithMediaType(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devices(withMediaType: mediaType as String)
        var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: mediaType as String)
        
        for device in devices!{
            let device = device as! AVCaptureDevice
            if device.position == position {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    func addVideoOutput() {
        //video output
        //set rgb settins for video
        let rgbOutputSettings = [ (kCVPixelBufferPixelFormatTypeKey as String) : Int(kCMPixelFormat_32BGRA) ]
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput.videoSettings = rgbOutputSettings
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        
        if self.captureSession.canAddOutput(self.videoOutput) {
            self.captureSession.addOutput(self.videoOutput)
        }
    }
    
    
    func addVideoInput() -> Bool {
        var success: Bool = false

        self.captureDevice = deviceWithMediaType(mediaType: AVMediaTypeVideo as NSString, position: devicePosition)
        do {
            self.videoDeviceInput = try AVCaptureDeviceInput(device: self.captureDevice)
            if self.captureSession.canAddInput(self.videoDeviceInput) {
                self.captureSession.addInput(self.videoDeviceInput)
                success = true
            }
        } catch {
            print("Failed to add video input")
        }
        
        return success
    }
    
    func addAudioInput() -> Bool {
        let audio = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do
        {
            self.audioInput = try AVCaptureDeviceInput(device: audio)
            captureSession.addInput(audioInput)
            return true
            
        }
        catch
        {
            print("can't access camera")
            return false
        }
    }
    
    func addAudioOutput(){
        //add audio to session
        self.audioOutput = AVCaptureAudioDataOutput()
        self.audioOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        if self.captureSession.canAddOutput(self.audioOutput) {
            captureSession.addOutput(audioOutput)
        }
    }
    
    //DELGEGATE CAMERA CONTROLS
    func switchCamera(){
        self.captureSession.stopRunning()
        //        previewLayer?.removeFromSuperlayer()
        if devicePosition == AVCaptureDevicePosition.back {
            devicePosition = AVCaptureDevicePosition.front
        } else {
            devicePosition = AVCaptureDevicePosition.back
        }
        setupSession()
    }
    
    
    func record() {
        
        if isRecording {
            self.cameraControls?.recordButton?.setTitle("record", for: .normal)
            isRecording = false
            self.writerInput.markAsFinished()
            audioWriterInput.markAsFinished()
            self.videoWriter.finishWriting { () -> Void in
                print("FINISHED!!!!!")
                UISaveVideoAtPathToSavedPhotosAlbum(self.lastPath, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)

            }
            
            
        } else{
            
            let fileUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(getCurrentDate())-capturedvideo.MP4")
            
            lastPath = fileUrl!.path
            
            videoWriter = try? AVAssetWriter(outputURL: fileUrl!, fileType: AVFileTypeMPEG4)
            
            let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(value: Float(previewView!.layer.bounds.size.width)), AVVideoHeightKey : NSNumber(value: Float(previewView!.layer.bounds.size.height))] as [String : Any]
            
            writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
            writerInput.expectsMediaDataInRealTime = true
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: videoFilter.getAudioDictionary() as? [String:AnyObject])
            
            videoWriter.add(writerInput)
            videoWriter.add(audioWriterInput)
            
            adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: videoFilter.getAdapterDictionary() as? [String:AnyObject])
            
            
            videoWriter.startWriting()
            videoWriter.startSession(atSourceTime: starTime)
            
            isRecording = true
            self.cameraControls?.recordButton?.setTitle("stop", for: .normal)
            
        }
        
        
    }
    
    func getCurrentDate()->String{
        let format = DateFormatter()
        format.dateFormat = "dd-MM-yyyy hh:mm:ss"
        format.locale = NSLocale(localeIdentifier: "en") as Locale!
        let date = format.string(from: NSDate() as Date)
        return date
    }
    
    
    // DELEGATE CAPUTER OUTPUT BUFFER
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        starTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if captureOutput == videoOutput {
            //WHY WHEN I USE THIS Line does the moustache disappear? But i need this line else the recorded video is the wrong orientation, how do i fix both?
//            connection.videoOrientation = AVCaptureVideoOrientation.portrait

            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
            
            //filter
            let comicEffect = CIFilter(name: "CIHexagonalPixellate")
            comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
            
            //WHY IS A BLACK IMAGE RETURNED AFTER PROCESSING THE FRAME?
            videoFilter.processCIImage(cameraImage, didOutputSampleBuffer: sampleBuffer, previewLayer: self.videoLayer, previewView: self.previewView, videoDataOutput: self.videoOutput, { (image) in
                if self.isRecording == true{
                    
                    DispatchQueue(label: "sample buffer append").sync(execute: {
                        if self.isRecording == true{
                            if self.writerInput.isReadyForMoreMediaData {
                                if let ciImage = CIImage(image: image!) {
                                    let cgiImage = self.convertCIImageToCGImage(inputImage: ciImage)
                                    let pixelBuffer = self.videoFilter.pixelBuffer(fromCGImageRef: cgiImage, size: (CGSize.init(width: 480, height: 640))).takeRetainedValue() as CVPixelBuffer
                                    let bo = self.adapter.append(pixelBuffer, withPresentationTime: self.starTime)
                                    print("Video \(bo)")
                                }
                            }
                        }
                    })
                }
            })

        } else if captureOutput == audioOutput{ //WHY IS THE AUDIO OUTPUT NOT CAPTURED?
            if self.isRecording == true{
                let bo = audioWriterInput.append(sampleBuffer)
                print("audio is \(bo)")
            }
        }
    }
    
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context:CIContext? = CIContext(options: nil)
        if context != nil {
            return context!.createCGImage(inputImage, from: inputImage.extent)
        }
        return nil
    }
    
    func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        var title = "Success"
        var message = "Video was saved"
        
        if let saveError = error {
            title = "Error"
            message = "Video failed to save"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
