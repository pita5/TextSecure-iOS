//
//  BloomFilterTests.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
@class Server;
@class BloomFilter;
@interface BloomFilterTest : SenTestCase
@property (nonatomic,strong) Server *server;
@property (nonatomic,strong) BloomFilter *bloomFilter;
@property (nonatomic,strong) BloomFilter *localBloomFilter;
@end
