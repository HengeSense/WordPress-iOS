//
//  TwoFactoryAuthEntryViewController.m
//  WordPress
//
//  Created by Beau Collins on 10/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "TwoFactorModalViewController.h"
#import "TwoFactorModalView.h"
#import "TwoDDecoderResult.h"
#import "Decoder.h"
#import "QRCodeReader.h"

@interface TwoFactorModalViewController () <UITextFieldDelegate, DecoderDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
@property (nonatomic, strong) Decoder *decoder;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *presentedView;
@property (nonatomic, strong) NSMutableArray *observers;
@property BOOL handleCapture;

- (IBAction)cancel:(id)sender;
- (IBAction)disableTwoFactor:(id)sender;
- (void)presentViewInContentView:(UIView *)view;
- (void)presentViewInContentView:(UIView *)view onComplete:(void(^)())completeBlock;
- (void)presentViewInContentView:(UIView *)view andAnimate:(BOOL)animate onComplete:(void(^)())completeBlock;
- (void)showCodeGenerator;

@end

@implementation TwoFactorModalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.observers = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

- (void)dealloc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [self.observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [nc removeObserver:obj];
    }];
    self.observers = nil;
    self.presentedView = nil;
    self.view = nil;
    self.captureConnection = nil;
    self.captureSession = nil;
    self.contentView = nil;
    self.delegate = nil;
    self.datasource = nil;
    
}

- (void)loadView {
    self.view = [[TwoFactorModalView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect navFrame = self.view.bounds;
    navFrame.size.height = 44.f;
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:navFrame];
    self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.navigationBar setItems:@[self.navigationItem]];
    [self.view addSubview:self.navigationBar];
    
    self.view.layer.cornerRadius = 2.0f;
    self.view.layer.masksToBounds = YES;
    
    UIBarButtonSystemItem itemType = [self.datasource hasAuthURLs] ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:itemType
                                                                                           target:self
                                                                                           action:@selector(cancel:)];
    
    self.view.backgroundColor = [UIColor whiteColor];

    
    CGRect contentViewFrame = self.view.bounds;
    contentViewFrame.size.height -= navFrame.size.height;
    contentViewFrame.origin.y += navFrame.size.height;
    
    self.contentView.layer.masksToBounds = YES;
    self.contentView = [[UIView alloc] initWithFrame:contentViewFrame];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentView];
    
    // listen for the keyboard so we can re-center the view
    
}

- (void)viewWillAppear:(BOOL)animated {
    if ([self.datasource hasAuthURLs]) {
        [self showCodeGenerator];
    } else {
        [self showAuthEntry];
    }
   
}

- (void)viewWillDisappear:(BOOL)animated {
    self.handleCapture = NO;
    [self.captureSession stopRunning];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [self.observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [nc removeObserver:obj];
    }];
    self.observers = [NSMutableArray arrayWithCapacity:3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didGenerateAuthURL:(OTPAuthURL *)authURL {
    // alert the delegate and show the verification code
    [self.delegate viewController:self didReceiveAuthURL:authURL];
    [self showCodeGenerator];
    
}

- (void)presentViewInContentView:(UIView *)view {
    [self presentViewInContentView:view andAnimate:NO onComplete:nil];
}
- (void)presentViewInContentView:(UIView *)view onComplete:(void (^)())completeBlock {
    [self presentViewInContentView:view andAnimate:YES onComplete:completeBlock];
}

- (void)presentViewInContentView:(UIView *)view andAnimate:(BOOL)animate onComplete:(void (^)())completeBlock  {
    // just change the vertical height to match and move the y position to compensate
    CGRect viewFrame = view.frame;
    CGRect contentViewFrame = self.contentView.frame;
    CGRect modalViewFrame = self.view.frame;
    CGFloat heightDelta = viewFrame.size.height - contentViewFrame.size.height;
    CGFloat yDelta = heightDelta * 0.5f;
    
    [self.navigationItem setLeftBarButtonItem:nil animated:animate];
    
    if (view.superview != self.contentView) {
        [self.contentView addSubview:view];
    }
    
    UIView *replacedView = self.presentedView;
    
    [self.view endEditing:YES];
    
    contentViewFrame.size.height = viewFrame.size.height;
    modalViewFrame.origin.y -= yDelta;
    modalViewFrame.size.height = contentViewFrame.size.height + self.navigationBar.frame.size.height;
    NSTimeInterval duration = animate ? 0.2f : 0.f;
    [UIView animateWithDuration:duration animations:^{
        self.view.frame = modalViewFrame;
        self.view.center = self.view.superview.center;
        self.contentView.frame = contentViewFrame;
        replacedView.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self.presentedView removeFromSuperview];
        self.presentedView = view;
        if (completeBlock) {
            completeBlock();
        }
    }];
    
    
}

- (BOOL)deviceSupportsVideo {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    return device != nil;
}

- (void)showAuthEntry {
    if ( [self deviceSupportsVideo]) {
        [self showBarCodeScanner];
    } else {
        [self showTextFieldInput];
    }
}

- (void)showBarCodeScanner {
    self.navigationItem.title = NSLocalizedString(@"Scan Code", @"Two factor title for scanning qrcode");
    
    CGRect frame = self.contentView.bounds;
    frame.size.height = 260.f;
    UIView *captureView = [[UIView alloc] initWithFrame:frame];
    captureView.backgroundColor = [UIColor blackColor];
    
    UIBarButtonItem *textButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered
                                                                                target:self
                                                                                action:@selector(showTextFieldInput)];
    
    [self presentViewInContentView:captureView andAnimate:YES onComplete:^{
        [self setupPreviewLayerInView:captureView];
        
        [self.navigationItem setLeftBarButtonItem:textButton animated:YES];
    }];

}

- (void)showCodeGenerator {
    
    self.navigationItem.title = NSLocalizedString(@"Secret Code", @"Two factor title for code generator");
    CGRect frame = self.contentView.bounds;
    frame.size.height = 80.f;
    
    UIView *generatorView = [[UIView alloc] initWithFrame:frame];
    UILabel *label = [self buildCodeLabel:generatorView.bounds];
    
    OTPAuthURL *authURL = (OTPAuthURL *)[[self.datasource twoFactorAuthURLs] objectAtIndex:0];
    label.text = [authURL otpCode];
    label.userInteractionEnabled = YES;
    
    [generatorView addSubview:label];
        
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    id observer = [nc addObserverForName:OTPAuthURLDidGenerateNewOTPNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
        label.textColor = [UIColor blackColor];
        label.text = authURL.otpCode;
    }];
    
    [self.observers addObject:observer];
    
    id observer2 = [nc addObserverForName:OTPAuthURLWillGenerateNewOTPWarningNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
        label.textColor = [UIColor redColor];
    }];
    
    [self.observers addObject:observer2];
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    CGRect infoButtonFrame = infoButton.frame;
    infoButtonFrame.origin.x = frame.size.width - infoButtonFrame.size.width - 8.f;
    infoButtonFrame.origin.y = frame.size.height - infoButtonFrame.size.height - 8.f;
    
    infoButton.frame = infoButtonFrame;
    
    [infoButton addTarget:self action:@selector(showInfoView:) forControlEvents:UIControlEventTouchUpInside];
    
    [generatorView addSubview:infoButton];
    
    [self presentViewInContentView:generatorView];
        
}

- (void)showTextFieldInput {
    
    self.navigationItem.title = NSLocalizedString(@"Account Key", @"Two Factor title for providing key via textfield");
    
    
    CGRect frame = self.contentView.bounds;
    frame.size.height = 74.f;
    UIView *textFieldContainer = [[UIView alloc] initWithFrame:frame];
    textFieldContainer.backgroundColor = [UIColor whiteColor];
    
    CGRect textFieldFrame = CGRectInset(textFieldContainer.bounds, 8.f, 20.f);
    UITextField *codeTextField = [[UITextField alloc] initWithFrame:textFieldFrame];
    codeTextField.font = [UIFont systemFontOfSize:24.f];
    codeTextField.placeholder = NSLocalizedString(@"Key", @"Placeholder for Two-Auth key entry textfield");
    codeTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    codeTextField.returnKeyType = UIReturnKeyDone;
    codeTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    codeTextField.delegate = self;
    
    [textFieldContainer addSubview:codeTextField];
        
    self.handleCapture = NO;
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                  target:self
                                                                                  action:@selector(showBarCodeScanner)];

    [self presentViewInContentView:textFieldContainer onComplete:^{
        [self.navigationItem setLeftBarButtonItem:cameraButton animated:YES];
        [codeTextField becomeFirstResponder];
    }];
    
}

- (IBAction)showInfoView:(id)sender {
    // flip it and show the info view
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CGRect frame = self.contentView.bounds;
    frame.size.height = 140.f;
    UIView *infoView = [[UIView alloc] initWithFrame:frame];
    
    UILabel *accountLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.f, 10.f, frame.size.width - 20.f, 22.f)];
    OTPAuthURL *authURL = (OTPAuthURL *)[[self.datasource twoFactorAuthURLs] objectAtIndex:0];
    accountLabel.text = authURL.name;
    
    [infoView addSubview:accountLabel];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [resetButton setTitle:NSLocalizedString(@"Disable", "Two-factor reset button") forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(disableTwoFactor:) forControlEvents:UIControlEventTouchUpInside];
    
    [infoView addSubview:resetButton];
    
    resetButton.frame = CGRectMake(0.f, 0.f, 120.f, 44.f);
    resetButton.center = CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f);
    
    
    [UIView transitionWithView:self.view duration:0.6f options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        [self.presentedView removeFromSuperview];
        self.navigationItem.title = NSLocalizedString(@"Two Factor Authentication", @"Title for two-factor info view");
        [self presentViewInContentView:infoView andAnimate:NO onComplete:nil];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(cancel:)];
    } completion:nil];
}

- (UILabel *)buildCodeLabel:(CGRect)frame {
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:32.f];
    return label;
}

#pragma mark - AVCaptureSession

- (void)setupPreviewLayerInView:(UIView *)view {
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, DISPATCH_QUEUE_SERIAL), ^{
        self.decoder = [[Decoder alloc] init];
        QRCodeReader *qrCodeReader = [[QRCodeReader alloc] init];
        self.decoder.readers = [NSSet setWithObject:qrCodeReader];
        self.decoder.delegate = self;
        
        AVCaptureSession *captureSession = [self startCaptureSession];
        
        self.handleCapture = YES;
        [captureSession startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            previewLayer.frame = view.bounds;
            
            [view.layer addSublayer:previewLayer];
        });
        
    });

}

- (AVCaptureSession *)startCaptureSession {
    
    if (self.captureSession != nil) {
        return self.captureSession;
    }
    
    
    self.captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    [self.captureSession addInput:captureInput];
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t dispatchQueue = dispatch_queue_create("org.wordpress.ios.authcapture", 0);
    [captureOutput setSampleBufferDelegate:self queue:dispatchQueue];
#if !OS_OBJECT_USE_OBJC
    dispatch_release(dispatchQueue);
#endif
    
    NSNumber *bgra = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   bgra, kCVPixelBufferPixelFormatTypeKey,
                                   nil];
    
    
    [captureOutput setVideoSettings:videoSettings];
    [self.captureSession addOutput:captureOutput];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    self.captureConnection = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
        
    
    return self.captureSession;
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (!self.handleCapture) return;
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (imageBuffer) {
            CVReturn ret = CVPixelBufferLockBaseAddress(imageBuffer, 0);
            if (ret == kCVReturnSuccess) {
                uint8_t *base = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
                size_t width = CVPixelBufferGetWidth(imageBuffer);
                size_t height = CVPixelBufferGetHeight(imageBuffer);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef context
                = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace,
                                        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                CGImageRef cgImage = CGBitmapContextCreateImage(context);
                CGContextRelease(context);
                UIImage *image = [UIImage imageWithCGImage:cgImage];
                CFRelease(cgImage);
                CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
                [self.decoder performSelectorOnMainThread:@selector(decodeImage:)
                                               withObject:image
                                            waitUntilDone:NO];
            } else {
                NSLog(@"Unable to lock buffer %d", ret);
            }
        } else {
            NSLog(@"Unable to get imageBuffer from %@", sampleBuffer);
        }
    }
}

#pragma mark - DecoderDelegate

- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)twoDResult {
    if (self.handleCapture) {
        self.handleCapture = NO;
        NSString *urlString = twoDResult.text;
        NSURL *url = [NSURL URLWithString:urlString];
        OTPAuthURL *authURL = [OTPAuthURL authURLWithURL:url
                                                  secret:nil];
        [self.captureSession stopRunning];
        self.captureSession = nil;
        self.captureConnection = nil;
        if (authURL) {
            NSLog(@"Captured URL: %@", authURL);
            [self didGenerateAuthURL:authURL];
        } else {
            NSLog(@"QRCode was not a valid auth URL: %@", urlString);
        }
    }
}

#pragma mark - IBAction

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}
- (IBAction)disableTwoFactor:(id)sender {
    [self.datasource disableTwoFactor];
    [self.delegate viewControllerDidCancel:self];
}

#pragma mark - UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = textField.text;
    
    NSString *encodedSecret = textField.text;
    NSData *secret = [OTPAuthURL base32Decode:encodedSecret];

    OTPAuthURL *url = [[HOTPAuthURL alloc] initWithSecret:secret name:@"WordPress.com"];
    [self didGenerateAuthURL:url];
    return NO;
}

@end
