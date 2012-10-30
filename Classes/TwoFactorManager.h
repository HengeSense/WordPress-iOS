//
//  TwoFactorManager.h
//  WordPress
//
//  Created by Beau Collins on 10/23/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTPAuthURL.h"

@interface TwoFactorManager : NSObject


+ (TwoFactorManager *)sharedManager;
- (void)addAuthURL:(OTPAuthURL *)authURL;
- (void)showModalView;
- (BOOL)hasAuthURL;

@end

