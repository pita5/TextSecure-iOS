//
//  BloomFilter.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "BloomFilter.h"

@implementation BloomFilter
@synthesize capacity;
@synthesize hashCount;
@synthesize url;
@synthesize version;


-(id) init {
	if(self==[super init]) {
    // how outside world tells server to serve
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirectoryInfo:) name:@"UpdateDirectoryInfo" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDirectory:) name:@"UpdateDirectory" object:nil];
    
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
}

/*
 Java
 public class BloomFilter {
 
 private final MappedByteBuffer buffer;
 private final long length;
 private final int hashCount;
 
 public BloomFilter(File bloomFilter, int hashCount)
 throws IOException
 {
 this.length    = bloomFilter.length();
 this.buffer    = new FileInputStream(bloomFilter).getChannel()
 
 .map(FileChannel.MapMode.READ_ONLY, 0, length);
 this.hashCount = hashCount;
 }
 
 public int getHashCount() {
 return hashCount;
 }
 
 private boolean isBitSet(long bitIndex) {
 int byteInQuestion = this.buffer.get((int)(bitIndex / 8));
 int bitOffset      = (0x01 << (bitIndex % 8));
 
 return (byteInQuestion & bitOffset) > 0;
 }
 
 public boolean contains(String entity) {
 try {
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
 } catch (NoSuchAlgorithmException e) {
 throw new AssertionError(e);
 } catch (InvalidKeyException e) {
 throw new AssertionError(e);
 }
 }
 
 }
 */

@end
