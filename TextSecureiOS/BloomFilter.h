//
//  BloomFilter.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BloomFilter : NSObject

@property (nonatomic) long capacity;
@property (nonatomic)  int hashCount;
@property (nonatomic,strong) NSString* url;
@property (nonatomic,strong) id version;
@property (nonatomic,strong) id directory;

-(void) createDirectoryForData:(NSData*)data;
-(void)updateDirectory:(NSNotification*)notification;
-(void)updateDirectoryInfo:(NSNotification*)notification;
@end
