#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//To make objective classes access swift classes you need to include forward declaration here
@class CameraControls;

@protocol CameraControlsProtocol
- (void)record;
- (void)switchCamera;
@end

@interface VideoFilter : UIViewController
<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>{
    BOOL WeAreRecording;
    NSURL *outputURL;
    CMTime lastSampleTime;
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
}

- (void)processCIImage:(CIImage *)ciImage
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
          previewLayer:(AVCaptureVideoPreviewLayer *) previewLayer
           previewView:(UIView *) previewView
       videoDataOutput:(AVCaptureVideoDataOutput *) videoDataOutput
                      :(void(^)(UIImage* image)) completion;
- (void)record;
- (CVPixelBufferRef)pixelBufferFromCGImageRef:(CGImageRef)image size:(CGSize)size;
- (NSDictionary *)getAdapterDictionary;
- (NSDictionary *) getAudioDictionary;
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end
