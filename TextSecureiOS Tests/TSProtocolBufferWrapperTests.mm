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
#import "TSWhisperMessage.hh"
#import "TSUnencryptedWhisperMessage.hh"
#import "TSMessageSignal.hh"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSPushMessageContent.hh"

@interface TSProtocolBufferWrapper (Test)
- (textsecure::IncomingPushMessageSignal *)deserialize:(NSData *)data;
@end



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


-(void) testMessageSignalSerialization {
//  TSMessageSignal* messageSignal = [[TSMessageSignal alloc] init];
//  messageSignal.contentType = TSUnencryptedWhisperMessageType;
//  messageSignal.source = @"+11111111";
//  messageSignal.destinations = @[@"+2222222"];
//  messageSignal.timestamp = [NSDate date];
//  
//  TSUnencryptedWhisperMessage *message = [[TSUnencryptedWhisperMessage alloc] init];
//  
//  TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
//  pushContent.body = @"Surf is up";
//  message.message = [pushContent serializedProtocolBuffer]; // this is crashing as isn't calling serializedprotocolbuffer on stcring, not available
//  messageSignal.message = message;
//
//
//  NSData *serializedMessageSignal = [messageSignal serializedProtocolBuffer];
//  
//  TSMessageSignal* deserializedMessageSignal = [[TSMessageSignal alloc] initWithData:serializedMessageSignal];
//  
//  XCTAssertTrue(messageSignal.contentType == deserializedMessageSignal.contentType,@"TSMessageSignal contentType unequal after serialization");
//  XCTAssertTrue([messageSignal.source isEqualToString:deserializedMessageSignal.source],@"TSMessageSignal source unequal after serialization");
//  XCTAssertTrue([messageSignal.destinations isEqualToArray:deserializedMessageSignal.destinations],@"TSMessageSignal destinations unequal after serialization");
//  
//  XCTAssertTrue([messageSignal.timestamp isEqualToDate:deserializedMessageSignal.timestamp],@"TSMessageSignal source unequal after serialization");
//  
//  
//  
//  XCTAssertTrue([messageSignal.message.message isEqualToData:message.message],@"TSMessageSignal message unequal after serialization");
}


-(void)testUnencryptedWhisperMessageSerialization {
  TSUnencryptedWhisperMessage *message = [[TSUnencryptedWhisperMessage alloc] init];
  TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
  pushContent.body = @"Surf is up";
  NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
  message.message = serializedMessageContent;
  
  
  NSData *serializedMessage = [message serializedProtocolBuffer];
  TSUnencryptedWhisperMessage *deserializedMessage  = [[TSUnencryptedWhisperMessage alloc] initWithData:serializedMessage];
  
  XCTAssertTrue([deserializedMessage.message isEqualToData:serializedMessageContent], @"TSUnencryptedWhisperMessage serialization/deserialization failed");

}


-(void)testUnencryptedWhisperMessageSerialization {
  
}


-(void)testPushMessageContentSerialization {
  TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
  pushContent.body = @"Surf is up";
  NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
  TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
  
  XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
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
  XCTAssertTrue([convertedData isEqualToData:data], @"data conversion is off conversion %@ not equal to original %@",convertedData,data);
  
}

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
