//
//  TwoStepAuthManager.m
//  WordPress
//
//  Created by Beau Collins on 9/25/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "TwoStepAuthManager.h"

NSString * const TwoStepAuthManagerTableCellIdentifier = @"Two Step Table Cell";
NSString * const TwoStepAuthManagerKeychainEntriesArray = @"OTPKeychainEntries";

@interface TwoStepAuthManager ()
@property (nonatomic, retain) NSMutableArray *authURLs;

- (void)loadKeychainReferences;
- (void)saveKeychainReferences;

@end

@implementation TwoStepAuthManager

@synthesize authURLs = _authURLs;

+ (TwoStepAuthManager *)authManager {
    TwoStepAuthManager *manager = [[TwoStepAuthManager alloc] init];
    
    return [manager autorelease];
}

- (id)init {
    if (self = [super init]) {
        [self loadKeychainReferences];
    }
    return self;
}

- (void)manageTableView:(UITableView *)tableView {
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TwoStepAuthManagerTableCellIdentifier];
}

- (void)loadKeychainReferences {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *savedKeychainReferences = [ud arrayForKey:TwoStepAuthManagerKeychainEntriesArray];
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
    [ud setObject:keychainReferences forKey:TwoStepAuthManagerKeychainEntriesArray];
    [ud synchronize];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.authURLs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TwoStepAuthManagerTableCellIdentifier forIndexPath:indexPath];
    OTPAuthURL *authURL = (OTPAuthURL *)[self.authURLs objectAtIndex:indexPath.section];
    cell.textLabel.text = authURL.otpCode;
    cell.detailTextLabel.text = authURL.name;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

- (void)addAuthURL:(OTPAuthURL *)authURL {
    [authURL saveToKeychain];
    [self.authURLs addObject:authURL];
    [self saveKeychainReferences];
}

@end
