//
//  WPTwoStepAuthTableViewCell.m
//  WordPress
//
//  Created by Beau Collins on 9/26/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WPTwoStepAuthTableViewCell.h"

CGFloat const WPTwoStepAuthTableViewCellHeight = 60.f;

@implementation WPTwoStepAuthTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        backgroundView.layer.cornerRadius = 2.f;
        backgroundView.layer.borderColor = [[UIColor colorWithHue:0.f saturation:0.f brightness:0.8f alpha:1.f] CGColor];
        backgroundView.backgroundColor = [UIColor whiteColor];
        backgroundView.layer.borderWidth = 1.f;
        
        self.textLabel.backgroundColor = [UIColor whiteColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.backgroundView = backgroundView;
        
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.backgroundColor = [UIColor whiteColor];
        
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        selectedBackgroundView.backgroundColor = [UIColor grayColor];
        selectedBackgroundView.layer.cornerRadius = 2.f;
        self.selectedBackgroundView = selectedBackgroundView;
        [backgroundView release];
        [selectedBackgroundView release];

    }
    return self;
}

- (void)dealloc {
    self.authURL = nil;
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setAuthURL:(OTPAuthURL *)authURL {
    if (authURL != _authURL) {
        // clear the notification
        [_authURL release];
        _authURL = [authURL retain];
        // set the new notification
    }
}

@end
