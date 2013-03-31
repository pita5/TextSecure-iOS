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
    // how outside world tells server to serve
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirectoryInfo:) name:@"UpdateDirectoryInfo" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirectory:) name:@"UpdateDirectory" object:nil];
    
  }
  return self;
}

-(void) demoBloomFilter {
  NSLog(@"filter contains Corbett %d",[self containsUser:@"+41799624499"]);
  NSLog(@"filter contains Abolish %d",[self containsUser:@"+15074588516"]);
  NSLog(@"filter contains Eqe %d",[self containsUser:@"+14155093112"]);
  NSLog(@"filter contains Moxie %d",[self containsUser:@"+14152671806"]);
  
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
  [self demoBloomFilter];
}


-(void) createDirectoryForData:(NSData*)data{
  self.directory = data;
  NSUInteger len = [data length];
  self.byteDirectory = (Byte*)malloc(len);
  memcpy(self.byteDirectory, [data bytes], len);
  NSLog(@"directory is of length %d",len);
  
  for(int b=0; b<len; b++) {
    NSLog(@"byte i of DIRECTORY is %d",self.byteDirectory[b]);
  }

  NSLog(@"directory bieing created at %@ for data %@",[FilePath pathInDocumentsDirectory:@"BloomFilter.bin"] ,data);
  [data writeToFile:[FilePath pathInDocumentsDirectory:@"BloomFilter.bin"] atomically:YES];
  NSLog(@"data stored locally for directory");
}


-(BOOL) isBitSet:(long) bitIndex {
  /*
   // TODO: remove
   //port of Java:
   private boolean isBitSet(long bitIndex) {
      int byteInQuestion = this.buffer.get((int)(bitIndex / 8));
      int bitOffset      = (0x01 << (bitIndex % 8));
      return (byteInQuestion & bitOffset) > 0;
   }
   */
  int byteInQuestion = self.byteDirectory[(int)(bitIndex/8)];
  int bitOffset      = (0x01 << (bitIndex % 8));
  NSLog(@"bitIndex %ld,byteInQuestion %d,nubmr %d in array,bitOffset %d",bitIndex,byteInQuestion,(int)(bitIndex/8),bitOffset);
  return (byteInQuestion & bitOffset) > 0;
}


-(BOOL) containsUser:(NSString*)username {
  /*
   // TODO: remove
   //port of Java:
   for (int i=0;i<this.hashCount;i++) {
      Mac mac = Mac.getInstance("HmacSHA1");
      mac.init(new SecretKeySpec((i+"").getBytes(), "HmacSHA1"));
      byte[] hashValue = mac.doFinal(entity.getBytes());
      long bitIndex    =
        Math.abs(Conversions.byteArrayToLong(hashValue, 0)) % (this.length * 8);
      if (!isBitSet(bitIndex))
        return false;
   }
   return true;
   */
  // TODO: remove after fixing this
  return YES;
  for (int i=0;i<self.hashCount;i++) {
    NSData *hashValue = [Cryptography computeMACDigestForString:username withSeed:[NSString stringWithFormat:@"%d",i]];
    // 20 bytes long [hashValue length]
    NSLog(@"hash is %d long",[hashValue length]);
    const   long *hashValueBytes= (const  long *)[hashValue bytes];
    for(int b=0; b<[hashValue length]; b++) {
      NSLog(@"byte i of HASH is %ld",hashValueBytes[b]);
    }
    long bitIndex = labs(hashValueBytes[0]) % (self.capacity * 8);
    if (![self isBitSet:bitIndex]) {
      return NO;
    }
  }
  return YES;
}

@end
