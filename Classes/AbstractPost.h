//
//  AbstractPost.h
//  WordPress
//
//  Created by Jorge Bernal on 12/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blog.h"

typedef enum {
    AbstractPostRemoteStatusPushing,    // Uploading post
    AbstractPostRemoteStatusFailed,      // Upload failed
    AbstractPostRemoteStatusLocal,       // Only local version
    AbstractPostRemoteStatusSync,       // Post uploaded
} AbstractPostRemoteStatus;

@interface AbstractPost : NSManagedObject {

}

// Attributes
@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * postTitle;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, assign) NSString * statusTitle;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic) AbstractPostRemoteStatus remoteStatus;

// Relationships
@property (nonatomic, retain) Blog * blog;
@property (nonatomic, retain) NSMutableSet * media;
@property (readonly) AbstractPost *original;
@property (readonly) AbstractPost *revision;

// Does the post exist on the blog?
- (BOOL)hasRemote;
- (void)remove;
// Save changes to disk
- (void)save;

// Revision management
- (AbstractPost *)createRevision;
- (void)deleteRevision;
- (void)applyRevision;
- (BOOL)isRevision;
- (BOOL)isOriginal;

// Subclass methods
- (void)upload;
- (NSString *)remoteStatusText;
+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus;
@end