//
//  WPTwoStepAuthTableViewCell.h
//  WordPress
//
//  Created by Beau Collins on 9/26/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTPAuthURL.h"

extern CGFloat const WPTwoStepAuthTableViewCellHeight;

@interface WPTwoStepAuthTableViewCell : UITableViewCell

@property (nonatomic, retain) OTPAuthURL *authURL;

@end
