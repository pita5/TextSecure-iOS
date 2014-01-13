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
#import  "TSEncryptedWhisperMessage.hh"

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

/*
 PushMessageSignal.type = {3=PreKeyWhisperMessage,0=Unencrypted,1=WhisperMessage }
 PushMessageSignal.message = {PreKeyWhisperMessage,PushMessageContent,WhisperMessage}
 
 PreKeyWhisperMessage.message = WhisperMessage
 PushMessageContent.body = "hey, here's the real message"
 WhisperMessage.message = PushMessageContent
 */


-(void) testMessageSignalSerialization {
  TSMessageSignal* messageSignal = [[TSMessageSignal alloc] init];
  messageSignal.contentType = TSUnencryptedWhisperMessageType;
  messageSignal.source = @"+11111111";
  messageSignal.timestamp = [NSDate date];
 
  
  
  TSUnencryptedWhisperMessage *message = [[TSUnencryptedWhisperMessage alloc] init];
  TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
  pushContent.body = @"Surf is up";
  NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
  message.message = serializedMessageContent;
  
  
  messageSignal.message = message;
  

  
  NSData *serializedMessageSignal = [messageSignal serializedProtocolBuffer];
  TSMessageSignal* deserializedMessageSignal = [[TSMessageSignal alloc] initWithData:serializedMessageSignal];
  
  XCTAssertTrue(messageSignal.contentType == deserializedMessageSignal.contentType,@"TSMessageSignal contentType unequal after serialization");
  
  
  
  XCTAssertTrue([messageSignal.source isEqualToString:deserializedMessageSignal.source],@"TSMessageSignal source unequal after serialization");
  
  

#warning compare with a nstimeinterval
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  NSString* nowString = [dateFormatter stringFromDate:messageSignal.timestamp];
  NSString* convertedNowString  = [dateFormatter stringFromDate:deserializedMessageSignal.timestamp];

  
  XCTAssertTrue([nowString isEqualToString:convertedNowString],@"TSMessageSignal dates unequal after serialization");
  

  
  TSUnencryptedWhisperMessage *unencryptedDeserializedMessage = (TSUnencryptedWhisperMessage*)deserializedMessageSignal.message;
  
  TSPushMessageContent *deserializedPushMessageContent = [[TSPushMessageContent alloc] initWithData:unencryptedDeserializedMessage.message];
  XCTAssertTrue([pushContent.body isEqualToString:deserializedPushMessageContent.body],@"TSMessageSignal message unequal after serialization");
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

-(void)testPushMessageContentSerialization {
  TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
  pushContent.body = @"Surf is up";
  NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
  TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
  
  XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
}


-(void)testEncryptedWhisperMessageSerialization {
  TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc] init];
  encryptedWhisperMessage.ephemeralKey = [Cryptography generateRandomBytes:32];
  encryptedWhisperMessage.counter = [[NSNumber alloc] initWithInt:0];
  encryptedWhisperMessage.previousCounter = [[NSNumber alloc] initWithInt:0];
  
  TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
  pushContent.body = @"Surf is up";
  
  NSData *serializedPushMessageContent = [pushContent serializedProtocolBuffer];
  encryptedWhisperMessage.message = serializedPushMessageContent;

  
  NSData* serializedEncryptedMessage = [encryptedWhisperMessage serializedProtocolBuffer];
  
  TSEncryptedWhisperMessage *deserializedEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithData:serializedEncryptedMessage];

  NSLog(@"encrypted whispermessage original vs new %@ vs. %@",encryptedWhisperMessage,deserializedEncryptedMessage);
  XCTAssertTrue([deserializedEncryptedMessage.previousCounter isEqualToNumber:encryptedWhisperMessage.previousCounter], @"previous counters unequal");

  XCTAssertTrue([deserializedEncryptedMessage.counter isEqualToNumber:encryptedWhisperMessage.counter], @"counters unequal");
  XCTAssertTrue([deserializedEncryptedMessage.ephemeralKey isEqualToData:encryptedWhisperMessage.ephemeralKey], @"ephemeral keys unequal; deserialization %@, encrypted %@",deserializedEncryptedMessage.ephemeralKey,encryptedWhisperMessage.ephemeralKey);
  
  
  TSPushMessageContent *deserializedPushMessageContet = [[TSPushMessageContent alloc] initWithData:deserializedEncryptedMessage.message];
  
  
  XCTAssertTrue([deserializedPushMessageContet.body isEqualToString:pushContent.body], @"messages not equal");
  

}




-(void) testObjcDateToCpp {
  NSDate* now = [NSDate date];
  uint64_t cppDate = [self.pbWrapper objcDateToCpp:now];
  NSDate *convertedNow = [self.pbWrapper cppDateToObjc:cppDate];
#warning compare with a nstimeinterval
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
