//
//  WPTwoStepManagerView.m
//  WordPress
//
//  Created by Beau Collins on 9/25/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPTwoStepManagerView.h"

@interface WPTwoStepManagerView ()

@property (nonatomic, retain, readwrite) UITableView *tableView;
@property (nonatomic, retain, readwrite) UIToolbar *toolbar;
@property (nonatomic, retain, readwrite) UIBarButtonItem *addButton;

- (void)addButtonPressed:(id)sender;

@end

@implementation WPTwoStepManagerView

@synthesize tableView, toolbar, addButton = _addButton, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        CGRect toolbarFrame = frame;
        toolbarFrame.size.height = 44.f;
        toolbarFrame.origin.y = frame.size.height - toolbarFrame.size.height;
        self.toolbar = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];

        CGRect tableViewRect = frame;
        tableViewRect.size.height -= toolbarFrame.size.height;
        tableViewRect.origin.y = 0.f;
        self.tableView = [[[UITableView alloc] initWithFrame:tableViewRect style:UITableViewStyleGrouped] autorelease];
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        
        UIView *tableViewBackground = [[UIView alloc] initWithFrame:self.tableView.bounds];
        tableViewBackground.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        tableViewBackground.backgroundColor = [UIColor whiteColor];
        self.tableView.backgroundView = tableViewBackground;
        [tableViewBackground release];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
        
        self.toolbar.items = @[space, addButton];
        
        self.addButton = addButton;
        
        [space release];
        [addButton release];
         
        [self addSubview:self.tableView];
        [self addSubview:self.toolbar];
        
    }
    return self;
}

- (void)addButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(managerViewDidPressAddButton:)]) {
        [self.delegate managerViewDidPressAddButton:self];
    }
}

- (void)dealloc {
    self.tableView = nil;
    self.toolbar = nil;
    self.addButton = nil;
    [super dealloc];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
