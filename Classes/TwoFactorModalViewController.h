//
//  TwoFactoryAuthEntryViewController.h
//  WordPress
//
//  Created by Beau Collins on 10/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTPAuthURL.h"

@protocol TwoFactorModalViewControllerDelegate;
@protocol TwoFactorModalViewControllerDataSource;

@interface TwoFactorModalViewController : UIViewController
@property (nonatomic, weak) id<TwoFactorModalViewControllerDelegate> delegate;
@property (nonatomic, weak) id<TwoFactorModalViewControllerDataSource> datasource;
@end

@protocol TwoFactorModalViewControllerDelegate <NSObject>

- (void)viewControllerDidCancel:(TwoFactorModalViewController *)viewController;
- (void)viewController:(TwoFactorModalViewController *)viewController didReceiveAuthURL:(OTPAuthURL *)authURL;
@end

@protocol TwoFactorModalViewControllerDataSource <NSObject>

- (NSArray *)twoFactorAuthURLs;
- (BOOL)hasAuthURLs;
- (void)disableTwoFactor;

@end