//
//  BloomFilterTests.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "BloomFilterTest.h"
#import "BloomFilter.h"
#import "Server.h"
@implementation BloomFilterTest
// Primatives
// STFail
// STAssertTrue
// STAssertFalse
// STAssertEquals


- (void)setUp {
  [super setUp];
  self.server = [[Server alloc] init];
  self.bloomFilter = [[BloomFilter alloc] init];
  self.localBloomFilter = [[BloomFilter alloc] initWithBloomFilter:@"DefaultBloomfilter.bin"];
}

- (void)tearDown {
  
  [super tearDown];
}

- (void)testBloomFilterServerSide {
  STAssertTrue([self.bloomFilter containsUser:@"+41799624499"],@"should contain Corbett");
  STAssertTrue([self.bloomFilter containsUser:@"+15074588516"],@"should contain AB");
  STAssertFalse([self.bloomFilter containsUser:@"+14155093112"],@"should not contain eqe");
  STAssertTrue([self.bloomFilter containsUser:@"+14152671806"],@"should contain Moxie");
}


- (void)testLocalBloomFilter {
  STAssertTrue([self.localBloomFilter containsUser:@"+41799624499"],@"should contain Corbett");
  STAssertTrue([self.localBloomFilter containsUser:@"+15074588516"],@"should contain AB");
  STAssertFalse([self.localBloomFilter containsUser:@"+14155093112"],@"should not contain eqe");
  STAssertTrue([self.localBloomFilter containsUser:@"+14152671806"],@"should contain Moxie");
}

@end
