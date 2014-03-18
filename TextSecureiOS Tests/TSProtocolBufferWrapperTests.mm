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
#import "TSMessageSignal.h"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSPushMessageContent.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSGroupContext.h"
#import "Constants.h"
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
    XCTAssertTrue([deserializedPushContent.attachments count]==0, @"deserialization has attachments when there should be none");

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
    
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
    pushContent.body = @"Surf is up";
    
    NSData* attachment1Key = [Cryptography generateRandomBytes:32];
    NSData* attachment2Key = [Cryptography generateRandomBytes:32];

    TSAttachment *attachment1 = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:42] contentMIMEType:@"image/jpg" decryptionKey:attachment1Key];
    TSAttachment *attachment2 = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:35] contentMIMEType:@"video/mp4" decryptionKey:attachment2Key];
    pushContent.attachments = [NSArray arrayWithObjects:attachment1,attachment2, nil];
    
    
    NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");

    // TODO: this is currently failing meaning attachments don't make it through deserialization process
    XCTAssertTrue([deserializedPushContent.attachments count]==2, @"deserialization doesn't have the right number of attachments, actually has %d",[deserializedPushContent.attachments count]);

    TSAttachment *attachment1Deserialized = [deserializedPushContent.attachments objectAtIndex:0];
    TSAttachment *attachment2Deserialized = [deserializedPushContent.attachments objectAtIndex:1];

    
    XCTAssertTrue([attachment1Deserialized.attachmentId isEqualToNumber:attachment1.attachmentId], @"deserialized ids do not match for attachment 1");
    XCTAssertTrue([attachment2Deserialized.attachmentId isEqualToNumber:attachment2.attachmentId], @"deserialized ids do not match for attachment 2");

    XCTAssertTrue(attachment1Deserialized.attachmentType == attachment1.attachmentType, @"deserialized ids do not match for attachment 1");
    XCTAssertTrue(attachment1Deserialized.attachmentType == attachment1.attachmentType, @"deserialized ids do not match for attachment 2");

    XCTAssertTrue([attachment1Deserialized.attachmentDecryptionKey isEqualToData:attachment1.attachmentDecryptionKey], @"deserialized ids do not match for attachment 1");
    XCTAssertTrue([attachment2Deserialized.attachmentDecryptionKey isEqualToData:attachment2.attachmentDecryptionKey], @"deserialized ids do not match for attachment 2");

    
}

-(void) testPushMessageContentGroupSerialization {
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] init];
    pushContent.body = @"Surf is up";

    
    NSString* member1 = @"12345678";
    NSString* member2 = @"987665";
    NSString* member3 = @"11111111";
    NSData* avatarKey = [Cryptography generateRandomBytes:32];
    NSData* groupId = [Cryptography generateRandomBytes:8];
    TSAttachment *avatar = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:42] contentMIMEType:@"image/jpg" decryptionKey:avatarKey];

    
    
    TSGroupContext *groupContext = [[TSGroupContext alloc] initWithId:groupId withType:TSUpdateGroupContext withName:@"Winter Break of Code" withMembers:[NSArray arrayWithObjects:member1,member2,member3, nil] withAvatar:avatar];
    pushContent.groupContext = groupContext;
    
    NSData *serializedMessageContent = [pushContent serializedProtocolBuffer];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
    XCTAssertTrue(deserializedPushContent.groupContext!=nil, @"deserialization doesn't give us a group, at all");
    
    TSGroupContext *groupContextDeserialized = deserializedPushContent.groupContext;
    XCTAssertTrue([groupContextDeserialized.gid isEqualToData:groupContext.gid],@"deserialized group id doesn't match original");
    XCTAssertTrue(groupContextDeserialized.type==groupContext.type,@"deserialized group type doesn't match original");
    XCTAssertTrue([groupContextDeserialized.members count]==3,@"deserialized group doesn't have same number of members as original");

    
    XCTAssertTrue([[groupContextDeserialized.members objectAtIndex:0] isEqualToString:member1],@"deserialized group member 1 not the same as original");
    XCTAssertTrue([[groupContextDeserialized.members objectAtIndex:1] isEqualToString:member2],@"deserialized group member 1 not the same as original");
    XCTAssertTrue([[groupContextDeserialized.members objectAtIndex:2] isEqualToString:member3],@"deserialized group member 1 not the same as original");

    
    TSAttachment *groupContextAvatarDeserialized = deserializedPushContent.groupContext.avatar;
    XCTAssertTrue([groupContextAvatarDeserialized.attachmentId isEqualToNumber:avatar.attachmentId], @"deserialized ids do not match for avatar");
    XCTAssertTrue(groupContextAvatarDeserialized.attachmentType == avatar.attachmentType, @"deserialized ids do not match for avatar");
    XCTAssertTrue([groupContextAvatarDeserialized.attachmentDecryptionKey isEqualToData:avatar.attachmentDecryptionKey], @"deserialized ids do not match for avatar");
    
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
