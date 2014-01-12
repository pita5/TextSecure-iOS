//
//  TSProtocolBufferWrapperTests.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/11/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSProtocolBufferWrapper.hh"
#import "Cryptography.h"
@interface TSProtocolBufferWrapperTests : XCTestCase
@property(nonatomic,strong) TSProtocolBufferWrapper *pbWrapper;
@end

@implementation TSProtocolBufferWrapperTests

- (void)setUp {
  [super setUp];
  self.pbWrapper = [[TSProtocolBufferWrapper alloc] init];

}

- (void)tearDown {
  [super tearDown];
}


-(void) testObjcDateToCpp {
  NSDate* now = [NSDate date];
  
  uint64_t cppDate = [self.pbWrapper objcDateToCpp:now];
  NSDate *convertedNow = [self.pbWrapper cppDateToObjc:cppDate];
  // due to roundoff issues two dates will never be equal to the second but we'll compare via the formatting string we actually use in the app
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  NSString* nowString = [dateFormatter stringFromDate:now];
  NSString* convertedNowString  = [dateFormatter stringFromDate:convertedNow];
  XCTAssertTrue([nowString isEqualToString:convertedNowString], @"date conversion is off conversion %@ not equal to original %@",convertedNowString,nowString);
  
}

-(void) testObjcStringToCpp {
  NSString *string = @"Hawaii is amazing";
  const std::string  cppString = [self.pbWrapper objcStringToCpp:string];
  NSString *convertedString = [self.pbWrapper cppStringToObjc:cppString];
  XCTAssertTrue([convertedString isEqualToString:string], @"date conversion is off conversion %@ not equal to original %@",convertedString,string);
}

-(void) testObjcDataToCppString  {
  NSData* data = [Cryptography generateRandomBytes:64];
  const std::string cppDataString = [self.pbWrapper objcDataToCppString:data];
  NSData* convertedData = [self.pbWrapper cppStringToObjcData:cppDataString];
  XCTAssertTrue([convertedData isEqualToData:data], @"date conversion is off conversion %@ not equal to original %@",convertedData,data);
  
}

// C++<->Objc ints
-(void) testObjcNumberToCppUInt32 {
  NSNumber *number = [NSNumber numberWithUnsignedInt:arc4random()];
  uint32_t cppNumber = [self.pbWrapper objcNumberToCppUInt32:number];
  NSNumber *convertedNumber = [self.pbWrapper cppUInt32ToNSNumber:cppNumber];
  XCTAssertTrue([number isEqualToNumber:convertedNumber], @"date conversion is off conversion %@ not equal to original %@",convertedNumber,number);
}

-(void) testObjcNumberToCppUInt64 {
  NSNumber *number = [NSNumber numberWithUnsignedLong:arc4random()];
  uint64_t cppNumber = [self.pbWrapper objcNumberToCppUInt64:number];
  NSNumber *convertedNumber = [self.pbWrapper cppUInt64ToNSNumber:cppNumber];
  XCTAssertTrue([number isEqualToNumber:convertedNumber], @"date conversion is off conversion %@ not equal to original %@",convertedNumber,number);
}


@end
