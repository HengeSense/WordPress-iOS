//
//  WPTwoStepManagerView.h
//  WordPress
//
//  Created by Beau Collins on 9/25/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WPTwoStepManagerView;

@protocol WPTwoStepManagerViewDelegate <NSObject>

@optional

- (void)managerViewDidPressAddButton:(WPTwoStepManagerView *)managerView;

@end

@interface WPTwoStepManagerView : UIView

@property (nonatomic, retain, readonly) UITableView *tableView;
@property (nonatomic, retain, readonly) UIToolbar *toolbar;
@property (nonatomic, retain, readonly) UIBarButtonItem *addButton;
@property (nonatomic, assign) id <WPTwoStepManagerViewDelegate> delegate;
@end
