//
//  TwoStepAuthManager.h
//  WordPress
//
//  Created by Beau Collins on 9/25/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTPAuthURL.h"

@interface TwoStepAuthManager : NSObject <UITableViewDataSource>

+ (TwoStepAuthManager *)authManager;
- (void)manageTableView:(UITableView *)tableView;
- (void)addAuthURL:(OTPAuthURL *)authURL;

@end
