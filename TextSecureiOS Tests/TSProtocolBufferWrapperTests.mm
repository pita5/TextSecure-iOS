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
#import "TSMessageSignal.hh"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSPushMessageContent.hh"
#import "TSEncryptedWhisperMessage.hh"

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
    messageSignal.contentType = TSEncryptedWhisperMessageType;
    messageSignal.source = @"+11111111";
    messageSignal.timestamp = [NSDate date];
    messageSignal.sourceDevice = [NSNumber numberWithUnsignedLong:7654321];
    /* messageSignal.message  contains a TextSecure_WhisperMessage or a TextSecure_PrekeyWhisperMessage
     we are testing a TextSecure_WhisperMessage here
    */
    // Generating the TextSecure_WhisperMessage
    NSData* ephemeral = [Cryptography generateRandomBytes:32];
    NSNumber* prevCounter = [NSNumber numberWithInt:0];
    NSNumber* counter = [NSNumber numberWithInt:0];
    // Normally the encrypted message would contain, well an encrypted PushMessageContent. Here we don't test encryption, so it's unencrypted for the test
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
    pushContent.body = @"hello Hawaii";
    NSData *serializedPushMessageContent = [pushContent serializedProtocolBuffer];
    NSData* version = [Cryptography generateRandomBytes:1];
    NSData *hmacKey = [Cryptography generateRandomBytes:32];
    NSMutableData* toHmac = [NSMutableData data];
    [toHmac appendData:version];
    [toHmac appendData:serializedPushMessageContent];
    NSData* hmac = [Cryptography truncatedHMAC:toHmac withHMACKey:hmacKey truncation:8];
    TSEncryptedWhisperMessage *tsEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:ephemeral previousCounter:prevCounter counter:counter encryptedMessage:serializedPushMessageContent forVersion:version withHMAC:hmac];
    // Have everything we need to fill out our message signal message
    messageSignal.message = tsEncryptedMessage;

    
    NSData *serializedMessageSignal = [messageSignal serializedProtocolBuffer];
    TSMessageSignal* deserializedMessageSignal = [[TSMessageSignal alloc] initWithData:serializedMessageSignal];
    
    XCTAssertTrue(messageSignal.contentType == deserializedMessageSignal.contentType,@"TSMessageSignal contentType unequal after serialization");
    XCTAssertTrue([messageSignal.sourceDevice isEqualToNumber:deserializedMessageSignal.sourceDevice],@"TSMessageSignal sourceDevice unequal after serialization");
    XCTAssertTrue([messageSignal.source isEqualToString:deserializedMessageSignal.source],@"TSMessageSignal source unequal after serialization");
#warning compare with a nstimeinterval
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString* nowString = [dateFormatter stringFromDate:messageSignal.timestamp];
    NSString* convertedNowString  = [dateFormatter stringFromDate:deserializedMessageSignal.timestamp];
    
    XCTAssertTrue([nowString isEqualToString:convertedNowString],@"TSMessageSignal dates unequal after serialization");
    
    
    
    TSEncryptedWhisperMessage *encryptedDeserializedMessage = (TSEncryptedWhisperMessage*)deserializedMessageSignal.message;
    
    TSPushMessageContent *deserializedPushMessageContent = [[TSPushMessageContent alloc] initWithData:encryptedDeserializedMessage.message];
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushMessageContent.body],@"TSMessageSignal message unequal after serialization");
}



-(void)testPushMessageContentBodySerialization {
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
    pushContent.body = @"Surf is up";
    NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
}


-(void)testEncryptedWhisperMessageSerialization {
    TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc] init];
    encryptedWhisperMessage.ephemeralKey = [Cryptography generateRandomBytes:32];
    encryptedWhisperMessage.counter = [[NSNumber alloc] initWithInt:rand()% 0xffff];
    encryptedWhisperMessage.previousCounter = [[NSNumber alloc] initWithInt:rand()%0xffff];
    
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
    pushContent.body = @"Surf is up";
    NSData *serializedPushMessageContent = [pushContent serializedProtocolBuffer];
    encryptedWhisperMessage.message = serializedPushMessageContent;
    unsigned char version = 5;
    encryptedWhisperMessage.version = [NSData dataWithBytes:&version length:sizeof(version)];
    encryptedWhisperMessage.hmac = [Cryptography generateRandomBytes:8]; // just to test serialization not encryption

    
    
    
    NSData* serializedEncryptedMessage = [encryptedWhisperMessage getTextSecure_WhisperMessage];
    
    TSEncryptedWhisperMessage *deserializedEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithTextSecure_WhisperMessage:serializedEncryptedMessage]; 
    
    NSLog(@"encrypted whispermessage original vs new %@ vs. %@",encryptedWhisperMessage,deserializedEncryptedMessage);
    XCTAssertTrue([deserializedEncryptedMessage.previousCounter isEqualToNumber:encryptedWhisperMessage.previousCounter], @"previous counters unequal");
    
    XCTAssertTrue([deserializedEncryptedMessage.counter isEqualToNumber:encryptedWhisperMessage.counter], @"counters unequal");
    XCTAssertTrue([deserializedEncryptedMessage.ephemeralKey isEqualToData:encryptedWhisperMessage.ephemeralKey], @"ephemeral keys unequal; deserialization %@, encrypted %@",deserializedEncryptedMessage.ephemeralKey,encryptedWhisperMessage.ephemeralKey);
    
    
    TSPushMessageContent *deserializedPushMessageContet = [[TSPushMessageContent alloc] initWithData:deserializedEncryptedMessage.message];
    
    XCTAssertTrue([deserializedPushMessageContet.body isEqualToString:pushContent.body], @"messages not equal");
}



-(void) testPushMessageContentAttachmentSerialization {
    /*
     message PushMessageContent {
     message AttachmentPointer {
     optional fixed64 id          = 1; // this ID can be used to retrieve from server the location in the cloud of the attachment
     optional string  contentType = 2; // MIME type
     optional bytes   key         = 3; // symmetric decryption key
     }
     
     message GroupContext {
     enum Type {
     UNKNOWN = 0;
     UPDATE  = 1;
     DELIVER = 2;
     QUIT    = 3;
     }
     optional bytes             id      = 1;
     optional Type              type    = 2;
     optional string            name    = 3;
     repeated string            members = 4;
     optional AttachmentPointer avatar  = 5;
     }
     
     enum Flags {
     END_SESSION = 1;
     }
     
     optional string            body        = 1;
     repeated AttachmentPointer attachments = 2;
     optional GroupContext      group       = 3;
     optional uint32            flags       = 4;
     }
     */

    
}

-(void) testPushMessageContentGroupSerialization {
    /*
     message PushMessageContent {
     message AttachmentPointer {
     optional fixed64 id          = 1; // this ID can be used to retrieve from server the location in the cloud of the attachment
     optional string  contentType = 2; // MIME type
     optional bytes   key         = 3; // symmetric decryption key
     }
     
     message GroupContext {
     enum Type {
     UNKNOWN = 0;
     UPDATE  = 1;
     DELIVER = 2;
     QUIT    = 3;
     }
     optional bytes             id      = 1;
     optional Type              type    = 2;
     optional string            name    = 3;
     repeated string            members = 4;
     optional AttachmentPointer avatar  = 5;
     }
     
     enum Flags {
     END_SESSION = 1;
     }
     
     optional string            body        = 1;
     repeated AttachmentPointer attachments = 2;
     optional GroupContext      group       = 3;
     optional uint32            flags       = 4;
     }
     */
    
    
    
    
    
}



-(void) testObjcDateToCpp {
    NSDate* now = [NSDate date];
    uint64_t cppDate = [self.pbWrapper objcDateToCpp:now];
    NSDate *convertedNow = [self.pbWrapper cppDateToObjc:cppDate];
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
