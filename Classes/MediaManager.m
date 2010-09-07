//
//  MediaManager.m
//  WordPress
//
//  Created by Chris Boyd on 8/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "MediaManager.h"

@implementation MediaManager

- (id)init {
    if((self = [super init])) {
		appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (Media *)get:(NSString *)uniqueID {
	NSArray *items = nil;
	if(uniqueID != nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueID like %@)", uniqueID];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	Media *media = nil;
	if((items != nil) && (items.count > 0)) {
		media = [items objectAtIndex:0];
	}
	else {
		media = (Media *)[NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[media setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	
	[self doReport];
	
	return media;
}

- (NSMutableArray *)getForPostID:(NSString *)postID andBlogURL:(NSString *)blogURL andMediaType:(MediaType)mediaType {
	NSArray *items = nil;
	NSMutableArray *results = [[NSMutableArray alloc] init];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	if(postID != nil) {
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSString *mediaTypeString = @"image";
		if(mediaType == kVideo)
			mediaTypeString = @"video";
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(postID like %@) AND (blogURL like %@) AND (mediaType like %@)", postID, blogURL, mediaTypeString];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		
		for(Media *media in items) {
			[results addObject:media];
		}
		
		[request release];
	}
	
	[self doReport];
	
	return results;
}

- (NSMutableArray *)getForBlogURL:(NSString *)blogURL {
	NSArray *items = nil;
	NSMutableArray *results = [[NSMutableArray alloc] init];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	if(blogURL != nil) {
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(blogURL like %@)", blogURL];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		
		for(Media *media in items) {
			[results addObject:media];
		}
		
		[request release];
	}
	
	[self doReport];
	
	return results;
}

- (BOOL)exists:(NSString *)uniqueID {
	NSArray *items = nil;
	if(uniqueID != nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueID like %@)", uniqueID];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	[self doReport];
	
	if((items != nil) && (items.count > 0))
		return YES;
	else
		return NO;
}

- (void)save:(Media *)media {
	if((media.uniqueID == nil) || ([self exists:media.uniqueID] == NO)) {
		[media setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
		[self insert:media];
	}
	else {
		[self update:media];
	}
	
	[self doReport];
}

- (void)insert:(Media *)media {
	[self dataSave];
}

- (void)update:(Media *)media {
	[self dataSave];
}

- (void)remove:(Media *)media {
	NSManagedObject *objectToDelete = media;
	[appDelegate.managedObjectContext deleteObject:objectToDelete];
	[appDelegate.managedObjectContext processPendingChanges];
}

- (void)removeForPostID:(NSString *)postID andBlogURL:(NSString *)blogURL {
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSMutableArray *images = [self getForPostID:postID andBlogURL:blogURL andMediaType:kImage];
	NSMutableArray *videos = [self getForPostID:postID andBlogURL:blogURL andMediaType:kVideo];
	NSString *filepath;
	
	for(Media *image in images) {
		filepath = [documentsDirectory stringByAppendingPathComponent:image.filename];
		[fileManager removeItemAtURL:[NSURL fileURLWithPath:filepath] error:&error];
		NSManagedObject *objectToDelete = image;
		[appDelegate.managedObjectContext deleteObject:objectToDelete];
	}
	
	for(Media *video in videos) {
		filepath = [documentsDirectory stringByAppendingPathComponent:video.filename];
		[fileManager removeItemAtURL:[NSURL fileURLWithPath:filepath] error:&error];
		NSManagedObject *objectToDelete = video;
		[appDelegate.managedObjectContext deleteObject:objectToDelete];
	}
	
	[self dataSave];
}

- (void)removeForBlogURL:(NSString *)blogURL {
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSMutableArray *items = [self getForBlogURL:blogURL];
	NSString *filepath;
	
	for(Media *media in items) {
		filepath = [documentsDirectory stringByAppendingPathComponent:media.filename];
		[fileManager removeItemAtURL:[NSURL fileURLWithPath:filepath] error:&error];
		NSManagedObject *objectToDelete = media;
		[appDelegate.managedObjectContext deleteObject:objectToDelete];
	}
	
	[self dataSave];
}

- (void)dataSave {
    NSError *error;
    if (![appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
	
	[self doReport];
}

- (void)doReport {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
	[request setEntity:entity];
	
	NSError *error;
	NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
	
	NSLog(@"%d total media objects on this device.", items.count);
	
	[request release];
}

@end
