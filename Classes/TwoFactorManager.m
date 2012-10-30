//
//  TwoFactorManager.m
//  WordPress
//
//  Created by Beau Collins on 10/23/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "TwoFactorManager.h"
#import "TwoFactorModalViewController.h"

NSString * const TwoFactorManagerKeychainEntriesArray = @"OTPKeychainEntries";

@interface TwoFactorManager () <TwoFactorModalViewControllerDelegate, TwoFactorModalViewControllerDataSource>
@property (nonatomic, strong) NSMutableArray *authURLs;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) TwoFactorModalViewController *controller;

- (void)loadKeychainReferences;
- (void)saveKeychainReferences;
- (BOOL)hasAuthURL;
- (IBAction)closeModalView:(id)sender;
@end

@implementation TwoFactorManager

+ (TwoFactorManager *)sharedManager
{
    static TwoFactorManager *sharedManager;
    
    @synchronized(self)
    {
        if (!sharedManager)
            sharedManager = [[TwoFactorManager alloc] init];
        
        return sharedManager;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [self loadKeychainReferences];
    }
    return self;
}

- (BOOL)hasAuthURL {
    return [self.authURLs count] > 0;
}

- (void)loadKeychainReferences {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *savedKeychainReferences = [ud arrayForKey:TwoFactorManagerKeychainEntriesArray];
    self.authURLs = [NSMutableArray arrayWithCapacity:[savedKeychainReferences count]];
    
    for (NSData *keychainRef in savedKeychainReferences) {
        OTPAuthURL *authURL = [OTPAuthURL authURLWithKeychainItemRef:keychainRef];
        if (authURL) {
            [self.authURLs addObject:authURL];
        }
    }
    
}

- (void)saveKeychainReferences {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *keychainReferences = [self valueForKeyPath:@"authURLs.keychainItemRef"];
    [ud setObject:keychainReferences forKey:TwoFactorManagerKeychainEntriesArray];
    [ud synchronize];
}



- (void)addAuthURL:(OTPAuthURL *)authURL {
    [authURL saveToKeychain];
    [self.authURLs addObject:authURL];
    [self saveKeychainReferences];
}

- (void)showModalView {
    
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    CGRect overlayFrame = keyWindow.bounds;
    self.overlayView = [[UIView alloc] initWithFrame:overlayFrame];
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.controller = [[TwoFactorModalViewController alloc] init];
    self.controller.delegate = self;
    self.controller.datasource = self;
    
    CGSize viewSize = CGSizeMake(300.f, 320.f);
    CGRect viewFrame = CGRectZero;
    viewFrame.size = viewSize;
    self.controller.view.frame = viewFrame;
    self.controller.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    [keyWindow addSubview:self.overlayView];
    [self.overlayView addSubview:self.controller.view];
    
    self.controller.view.center = self.overlayView.center;
    
    self.controller.view.transform = [TwoFactorManager transformforDeviceOrientation:app.statusBarOrientation];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rotateView:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resizeForKeyboard:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    self.overlayView.alpha = 0.f;
    self.controller.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.f, 0.f);
    self.controller.view.alpha = 0.f;
    [UIView animateWithDuration:0.3f animations:^{
        self.overlayView.alpha = 1.f;
        self.controller.view.alpha = 1.f;
        self.controller.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.f, 1.f);
    }];
        
}

- (IBAction)closeModalView:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.controller.delegate = nil;
    [UIView animateWithDuration:0.3f animations:^{
        self.overlayView.alpha = 0.f;
        self.controller.view.alpha = 0.f;
        self.controller.view.transform = CGAffineTransformScale(self.controller.view.transform, 2.f, 2.f);
    } completion:^(BOOL finished) {
        [self.controller.view removeFromSuperview];
        [self.overlayView removeFromSuperview];
        self.controller = nil;
        self.overlayView = nil;
    }];
}

- (void)rotateView:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [(UIApplication *)notification.object statusBarOrientation];
    self.controller.view.transform = [TwoFactorManager transformforDeviceOrientation:orientation];
}

- (void)resizeForKeyboard:(NSNotification *)notification {
    
    // find out the height that intersects the overlay and resize the overlay view
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect overlayFrame = keyWindow.bounds;
    
    CGRect intersection = CGRectIntersection(keyboardFrame, overlayFrame);
    overlayFrame.size.height -= intersection.size.height;
    
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:duration delay:0.f options:curve animations:^{
        self.overlayView.frame = overlayFrame;
    } completion:nil];
    
}

+ (CGAffineTransform)transformforDeviceOrientation:(UIInterfaceOrientation)orientation {
    CGFloat angle = 0.f;
        
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI / 2.0f;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI / 2.0f;
            break;
        default: // as UIInterfaceOrientationPortrait
            angle = 0.f;
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle);
    return transform;
}

#pragma mark - TwoFactorModalViewControllerDelegate

- (void)viewControllerDidCancel:(TwoFactorModalViewController *)viewController {
    [self closeModalView:nil];
}

- (void)viewController:(TwoFactorModalViewController *)viewController didReceiveAuthURL:(OTPAuthURL *)authURL {
    [self addAuthURL:authURL];
}

#pragma mark - TwoFactorModalViewControllerDatasource

- (BOOL)hasAuthURLs {
    return [self hasAuthURL];
}

- (NSArray *)twoFactorAuthURLs {
    return [NSArray arrayWithArray:self.authURLs];
}

- (void)disableTwoFactor {
    self.authURLs = [NSMutableArray arrayWithCapacity:0];
    [self saveKeychainReferences];
}

@end
