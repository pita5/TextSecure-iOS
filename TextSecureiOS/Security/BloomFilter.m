//
//  BloomFilter.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "BloomFilter.h"
#import "FilePath.h"
#import "Cryptography.h"
@implementation BloomFilter
@synthesize capacity;
@synthesize hashCount;
@synthesize url;
@synthesize version;
@synthesize byteDirectory;


-(id) init {
	if(self==[super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirectoryInfo:) name:@"UpdateDirectoryInfo" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirectory:) name:@"UpdateDirectory" object:nil];
  }
  return self;
}


-(id) initWithBloomFilter:(NSString*) localBloomFilter {
	if(self==[super init]) {
    NSData* directory = [NSData dataWithContentsOfFile:[FilePath pathInBundleDirectory:localBloomFilter]];
    [self createDirectoryForData:directory];
  }
  return self;
}



-(void)updateDirectoryInfo:(NSNotification*)notification {
  NSDictionary* notificationInfo = [notification userInfo];
  self.capacity = [[notificationInfo objectForKey:@"capacity"] longValue];
  self.hashCount = [[notificationInfo objectForKey:@"hashCount"] intValue];
  self.url = [notificationInfo objectForKey:@"url"];
  self.version = [notificationInfo objectForKey:@"version"];
  
  
}

-(void)updateDirectory:(NSNotification*)notification {
  NSDictionary* notificationInfo = [notification userInfo];
  NSData* dir = [notificationInfo objectForKey:@"directory"];
  [self createDirectoryForData:dir];
}


-(void) createDirectoryForData:(NSData*)data{
  self.directory = data;
  NSUInteger len = [data length];
  self.byteDirectory = (Byte*)malloc(len);
  memcpy(self.byteDirectory, [data bytes], len);
  [data writeToFile:[FilePath pathInDocumentsDirectory:@"BloomFilter.bin"] atomically:YES];
}


-(BOOL) isBitSet:(long) bitIndex {
  int byteInQuestion = self.byteDirectory[(int)(bitIndex/8)];
  int bitOffset      = (0x01 << (bitIndex % 8));
  return (byteInQuestion & bitOffset) > 0;
}


-(BOOL) containsUser:(NSString*)username {
  for (int i=0;i<self.hashCount;i++) {
    NSData *hashValue = [Cryptography computeMACDigestForString:username withSeed:[NSString stringWithFormat:@"%d",i]];
    const   long *hashValueBytes= (const  long *)[hashValue bytes];
    long bitIndex = labs(hashValueBytes[0]) % (self.capacity * 8);
    if (![self isBitSet:bitIndex]) {
      return NO;
    }
  }
  return YES;
}

@end
