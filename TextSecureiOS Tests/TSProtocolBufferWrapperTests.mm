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
#import "TSPreKeyWhisperMessage.hh"
#import "TSGroupContext.h"
#import "Constants.h"
@interface TSProtocolBufferWrapper (Test)
- (textsecure::IncomingPushMessageSignal *)deserialize:(NSData *)data;
@end



@interface TSProtocolBufferWrapperTests : XCTestCase
@property(nonatomic,strong) TSProtocolBufferWrapper* pbWrapper;
@property(nonatomic,strong) NSString* body;
@property(nonatomic,strong) NSArray* attachments;
@property(nonatomic,strong) TSGroupContext* groupContext;
@property(nonatomic,strong) NSData* ephemeral;
@property(nonatomic,strong) NSData* myNextEphemeral;
@property(nonatomic,strong) NSNumber* prevCounter;
@property(nonatomic,strong) NSNumber* counter;
@property(nonatomic,strong) NSNumber* theirPrekeyId;
@property(nonatomic,strong) NSData* version;
@property(nonatomic,strong) NSData* cipherKey;
@property(nonatomic,strong) NSData* hmacKey;
@property(nonatomic,strong) TSMessageKeys *messageKeys;
@property(nonatomic,strong) NSString* source;
@property(nonatomic,strong) NSNumber* sourceDevice;
@property(nonatomic,strong) NSDate* timestamp;

@end


@implementation TSProtocolBufferWrapperTests

- (void)setUp {
    [super setUp];
    
    // Neded for TSPushmessageContent
    _body = @"hello Hawaii";
    _attachments = nil;
    _groupContext = nil;

    // needed for TSPreKeyWhisperMessage
    _myNextEphemeral = [Cryptography generateRandomBytes:32];
    _theirPrekeyId = [NSNumber numberWithInt:1337];
    
    // needed for TSEncryptedWhisperMessage
    _ephemeral = [Cryptography generateRandomBytes:32];
    _prevCounter = [NSNumber numberWithInt:0];
    _counter = [NSNumber numberWithInt:0];
    _version = [Cryptography generateRandomBytes:1];
    
    // needed for encryption of WhisperMessage
    _cipherKey = [Cryptography generateRandomBytes:32];
    _hmacKey = [Cryptography generateRandomBytes:32];
    _messageKeys = [[TSMessageKeys alloc] initWithCipherKey:_cipherKey macKey:_hmacKey counter:[_counter intValue]];
    
    // neede for the TSMessagesignal
    _source = @"+11111111";
    _sourceDevice = [NSNumber numberWithUnsignedLong:7654321];
    _timestamp = [NSDate date];

    
    // needed for optional attachment testing
    NSData* attachment1Key = [Cryptography generateRandomBytes:32];
    NSData* attachment2Key = [Cryptography generateRandomBytes:32];
    
    TSAttachment *attachment1 = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:42] contentMIMEType:@"image/jpg" decryptionKey:attachment1Key];
    TSAttachment *attachment2 = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:35] contentMIMEType:@"video/mp4" decryptionKey:attachment2Key];
   _attachments = [NSArray arrayWithObjects:attachment1,attachment2, nil];
    

    // needed for optional group testing
    NSString* member1 = @"+12345678";
    NSString* member2 = @"+987665";
    NSString* member3 = @"+11111111";
    NSData* groupId = [Cryptography generateRandomBytes:8];
    TSAttachment *avatar = attachment1;

    _groupContext = [[TSGroupContext alloc] initWithId:groupId withType:TSUpdateGroupContext withName:@"Winter Break of Code" withMembers:@[member1,member2,member3] withAvatar:avatar];

    
    
    _pbWrapper = [[TSProtocolBufferWrapper alloc] init];
    
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


-(void) testCompareAndroidSerialization {

    // Neded for TSPushmessageContent
    NSString* body = @"hello Hawaii";
    
    // needed for TSEncryptedWhisperMessage
    const unsigned char zero32Bytes[] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    const unsigned char zeroByte[] = {0x00};

    NSData* zero32Data = [NSData dataWithBytes:zero32Bytes length:sizeof(zero32Bytes)];
    NSData* zero1Data = [NSData dataWithBytes:zeroByte length:sizeof(zeroByte)];
    NSData *ephemeral =  zero32Data;
    NSNumber *prevCounter = [NSNumber numberWithInt:0];
    NSNumber* counter = [NSNumber numberWithInt:0];
    NSData* version = zero1Data;
    NSNumber* theirPrekeyId = [NSNumber numberWithInt:0];
    
    // needed for encryption of WhisperMessage
    NSData* cipherKey = zero32Data;
    
    
    // Stuffing into objective c
    TSPushMessageContent* pushContent = [[TSPushMessageContent alloc] initWithBody:body withAttachments:nil  withGroupContext:nil];
    
    TSEncryptedWhisperMessage* tsEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:ephemeral previousCounter:prevCounter counter:counter encryptedPushMessageContent:[pushContent getTextSecureProtocolData] forVersion:version HMACKey:cipherKey];
    TSPreKeyWhisperMessage* tsPreKeyWhisperMessage = [TSPreKeyWhisperMessage constructFirstMessageWithEncryptedPushMessageContent:[pushContent getTextSecureProtocolData] theirPrekeyId:theirPrekeyId myCurrentEphemeral:ephemeral myNextEphemeral:ephemeral forVersion:version withHMACKey:cipherKey];
    
    
    NSString* base64SerializediOSTSPushMessageContentCurrent = [[pushContent getTextSecureProtocolData] base64EncodedStringWithOptions:0];

    NSString* base64SerializediOSTSEncryptedWhisperMessageCurrent = [[tsEncryptedMessage getTextSecureProtocolData] base64EncodedStringWithOptions:0];
    NSString* base64SerializediOSTSPreKeyWhisperMessageCurrent = [[tsPreKeyWhisperMessage getTextSecureProtocolData] base64EncodedStringWithOptions:0];
    
    XCTAssertTrue([base64SerializediOSTSEncryptedWhisperMessageCurrent isEqualToString:[tsPreKeyWhisperMessage.message base64EncodedStringWithOptions:0]]);

    
     NSLog(@"%@",base64SerializediOSTSPushMessageContentCurrent);
     NSLog(@"%@",base64SerializediOSTSEncryptedWhisperMessageCurrent);
     NSLog(@"%@",base64SerializediOSTSPreKeyWhisperMessageCurrent);
    
    
    //    // gives for iOS currently
    //    NSString* base64SerializediOSTSPushMessageContentCurrent = @"CgxoZWxsbyBIYXdhaWk=";
    //    NSString* base64SerializediOSTSEncryptedWhisperMessageCurrent = @"AAohBQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAYACIOCgxoZWxsbyBIYXdhaWncdNiDCuAuow==";
    //    NSString* base64SerializediOSTSPreKeyWhisperMessageCurrent = @"AAgAEiEFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaACJAAAohBQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAYACIOCgxoZWxsbyBIYXdhaWncdNiDCuAuow==";
    
    
    
    // Droid gives us for equavalent data/ephemeral etc.
    NSString* base64SerializedDroidTSPushMessageContentCurrent = @"CgxoZWxsbyBIYXdhaWk=";
    NSString* base64SerializedDroidTSEncryptedWhisperMessageCurrent = @"CiAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAGAAiDgoMaGVsbG8gSGF3YWlp";
    NSString* base64SerializedDroidTSPreKeyWhisperMessageCurrent = @"CAASIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGiAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACI2CiAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAGAAiDgoMaGVsbG8gSGF3YWlpKAA=";


    XCTAssertTrue([base64SerializediOSTSPushMessageContentCurrent isEqualToString:base64SerializedDroidTSPushMessageContentCurrent], @"push messages PBs not equal ios %@ droid %@",base64SerializediOSTSPushMessageContentCurrent,base64SerializedDroidTSPushMessageContentCurrent);
    XCTAssertTrue([base64SerializediOSTSEncryptedWhisperMessageCurrent isEqualToString:base64SerializedDroidTSEncryptedWhisperMessageCurrent], @"encrypted message PBs not equal ios %@ droid %@",base64SerializediOSTSEncryptedWhisperMessageCurrent,base64SerializedDroidTSEncryptedWhisperMessageCurrent);
    XCTAssertTrue([base64SerializediOSTSPreKeyWhisperMessageCurrent isEqualToString:base64SerializedDroidTSPreKeyWhisperMessageCurrent], @"prekey messages PBs not equal ios %@ droid %@",base64SerializediOSTSPreKeyWhisperMessageCurrent,base64SerializedDroidTSPreKeyWhisperMessageCurrent);
}

-(void) testPrekeyWhisperMessageSerialization {
    /* TODO: debug this test. as iOS->iOS, Droid->iOS, iOS->Droid first sends now work clearly the PreKeyWhisperMessage protocol buffer serialization isn't all bad. but the  // this is crashing // line is well, crashing here. Probably an issue with the test itself
     (inna hurry) but should be massaged to pass */
    // Stuffing into objective c
    TSPushMessageContent* pushContent = [[TSPushMessageContent alloc] initWithBody:_body withAttachments:nil  withGroupContext:nil];
    NSData* encryptedContent = [Cryptography encryptCTRMode:[pushContent getTextSecureProtocolData] withKeys:_messageKeys];
    
    TSEncryptedWhisperMessage* tsEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:_ephemeral previousCounter:_prevCounter counter:_counter encryptedPushMessageContent:encryptedContent forVersion:_version HMACKey:_cipherKey];
    
    TSPreKeyWhisperMessage *tsPreKeyWhisperMessage = [TSPreKeyWhisperMessage constructFirstMessageWithEncryptedPushMessageContent:[tsEncryptedMessage getTextSecureProtocolData] theirPrekeyId:_theirPrekeyId myCurrentEphemeral:_ephemeral myNextEphemeral:_myNextEphemeral forVersion:_version withHMACKey:_cipherKey];

    
    
    NSData* serializedPreKeyMessage = [tsPreKeyWhisperMessage getTextSecureProtocolData];

    TSPreKeyWhisperMessage* deserializedPreKeyMessage = [[TSPreKeyWhisperMessage alloc] initWithTextSecureProtocolData:serializedPreKeyMessage]; //  this is crashing
    XCTAssertTrue([deserializedPreKeyMessage.version isEqualToData:tsPreKeyWhisperMessage.version],@"versions not equal: deserialized: %@, original %@",deserializedPreKeyMessage.version ,tsPreKeyWhisperMessage.version);
    XCTAssertTrue([deserializedPreKeyMessage.preKeyId isEqualToNumber:tsPreKeyWhisperMessage.preKeyId],@"preKeyIds not equal: deserialized: %@, original %@",deserializedPreKeyMessage.preKeyId ,tsPreKeyWhisperMessage.preKeyId);
    XCTAssertTrue([deserializedPreKeyMessage.baseKey isEqualToData:tsPreKeyWhisperMessage.baseKey],@"base keys not equal: deserialized: %@, original %@", deserializedPreKeyMessage.baseKey,tsPreKeyWhisperMessage.baseKey);
    XCTAssertTrue([deserializedPreKeyMessage.identityKey isEqualToData:tsPreKeyWhisperMessage.identityKey],@"identity keys not equal: deserialized: %@, original %@", deserializedPreKeyMessage.identityKey,tsPreKeyWhisperMessage.identityKey);

    
    XCTAssertTrue([deserializedPreKeyMessage.message isEqualToData:encryptedContent],@"encrypted push message content %@ not equal to deserialized version %@",encryptedContent,deserializedPreKeyMessage.message);
    NSData* decryptedPushMessageContentData = [Cryptography decryptCTRMode:deserializedPreKeyMessage.message withKeys:_messageKeys];
    XCTAssertTrue([decryptedPushMessageContentData isEqualToData:[pushContent getTextSecureProtocolData]],@"decrypted push message content %@ not equal to original decrypted version %@",decryptedPushMessageContentData,[pushContent getTextSecureProtocolData]);
    TSEncryptedWhisperMessage* deserializedEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithData:decryptedPushMessageContentData];
    XCTAssertTrue([deserializedEncryptedMessage.previousCounter isEqualToNumber:tsEncryptedMessage.previousCounter], @"previous counters unequal");
    XCTAssertTrue([deserializedEncryptedMessage.counter isEqualToNumber:tsEncryptedMessage.counter], @"counters unequal");
    XCTAssertTrue([deserializedEncryptedMessage.ephemeralKey isEqualToData:tsEncryptedMessage.ephemeralKey], @"ephemeral keys unequal; deserialization %@, encrypted %@",deserializedEncryptedMessage.ephemeralKey,tsEncryptedMessage.ephemeralKey);
    
    
    NSData *decryptedSerializedPushMessageContent = [Cryptography decryptCTRMode:deserializedEncryptedMessage.message withKeys:_messageKeys];
    TSPushMessageContent *deserializedPushMessageContent = [[TSPushMessageContent alloc] initWithData:decryptedSerializedPushMessageContent];
    
    XCTAssertTrue([deserializedPushMessageContent.body isEqualToString:pushContent.body], @"messages not equal derialized %@, original %@",deserializedPushMessageContent.body,pushContent.body);
}

-(void) testMessageSignalSerializationNoAttachmentsNoGroup {
    
    
    // Stuffing into objective c
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] initWithBody:_body withAttachments:nil  withGroupContext:nil];
    NSData* encryptedContent = [Cryptography encryptCTRMode:[pushContent getTextSecureProtocolData] withKeys:_messageKeys];

    TSEncryptedWhisperMessage *tsEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:_ephemeral previousCounter:_prevCounter counter:_counter encryptedPushMessageContent:encryptedContent forVersion:_version HMACKey:_cipherKey];
    TSMessageSignal* messageSignal = [[TSMessageSignal alloc] initWithMessage:tsEncryptedMessage withContentType:TSEncryptedWhisperMessageType withSource:_source withSourceDevice:_sourceDevice withTimestamp:_timestamp];

    
    NSData *serializedMessageSignal = [messageSignal getTextSecureProtocolData];
    TSMessageSignal* deserializedMessageSignal = [[TSMessageSignal alloc] initWithTextSecureProtocolData:serializedMessageSignal];
    
    XCTAssertTrue(messageSignal.contentType == deserializedMessageSignal.contentType,@"TSMessageSignal contentType unequal after serialization");
    XCTAssertTrue([messageSignal.sourceDevice isEqualToNumber:deserializedMessageSignal.sourceDevice],@"TSMessageSignal sourceDevice unequal after serialization");
    XCTAssertTrue([messageSignal.source isEqualToString:deserializedMessageSignal.source],@"TSMessageSignal source unequal after serialization");

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString* nowString = [dateFormatter stringFromDate:messageSignal.timestamp];
    NSString* convertedNowString  = [dateFormatter stringFromDate:deserializedMessageSignal.timestamp];
    
    XCTAssertTrue([nowString isEqualToString:convertedNowString],@"TSMessageSignal dates unequal after serialization");
    
    
    
    TSEncryptedWhisperMessage *deserializedEncryptedMessage = (TSEncryptedWhisperMessage*)deserializedMessageSignal.message;
    
    NSData *decryptedSerializedPushMessageContent = [Cryptography decryptCTRMode:deserializedEncryptedMessage.message withKeys:_messageKeys];
    TSPushMessageContent *deserializedPushMessageContent = [[TSPushMessageContent alloc] initWithData:decryptedSerializedPushMessageContent];
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushMessageContent.body],@"TSMessageSignal message unequal after serialization");
}



-(void)testPushMessageContentBodySerialization {
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] initWithBody:_body withAttachments:nil withGroupContext:nil];

    NSData *serializedMessageContent = [pushContent getTextSecureProtocolData];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
    XCTAssertTrue([deserializedPushContent.attachments count]==0, @"deserialization has attachments when there should be none");

}


-(void)testEncryptedWhisperMessageSerializationNoAttachmentsNoGroup {
    
    // Stuffing into objective c
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] initWithBody:_body withAttachments:nil  withGroupContext:nil];
    NSData* encryptedContent = [Cryptography encryptCTRMode:[pushContent getTextSecureProtocolData] withKeys:_messageKeys];
    
    TSEncryptedWhisperMessage *tsEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:_ephemeral previousCounter:_prevCounter counter:_counter encryptedPushMessageContent:encryptedContent forVersion:_version HMACKey:_cipherKey];

    
    NSData* serializedEncryptedMessage = [tsEncryptedMessage getTextSecureProtocolData];
    
    TSEncryptedWhisperMessage *deserializedEncryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithTextSecureProtocolData:serializedEncryptedMessage];
    
    NSLog(@"encrypted whispermessage original vs new %@ vs. %@",tsEncryptedMessage,deserializedEncryptedMessage);
    XCTAssertTrue([deserializedEncryptedMessage.previousCounter isEqualToNumber:tsEncryptedMessage.previousCounter], @"previous counters unequal");
    
    XCTAssertTrue([deserializedEncryptedMessage.counter isEqualToNumber:tsEncryptedMessage.counter], @"counters unequal");
    XCTAssertTrue([deserializedEncryptedMessage.ephemeralKey isEqualToData:tsEncryptedMessage.ephemeralKey], @"ephemeral keys unequal; deserialization %@, encrypted %@",deserializedEncryptedMessage.ephemeralKey,tsEncryptedMessage.ephemeralKey);
    
    
    NSData *decryptedSerializedPushMessageContent = [Cryptography decryptCTRMode:deserializedEncryptedMessage.message withKeys:_messageKeys];
    TSPushMessageContent *deserializedPushMessageContent = [[TSPushMessageContent alloc] initWithData:decryptedSerializedPushMessageContent];
    
    XCTAssertTrue([deserializedPushMessageContent.body isEqualToString:pushContent.body], @"messages not equal");
}



-(void) testPushMessageContentAttachmentSerializationDynamic {
    
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] initWithBody:_body withAttachments:_attachments withGroupContext:nil];
    

    
    NSData *serializedMessageContent = [pushContent getTextSecureProtocolData];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");

    XCTAssertTrue([deserializedPushContent.attachments count]==2, @"deserialization doesn't have the right number of attachments, actually has %lu",(unsigned long)[deserializedPushContent.attachments count]);

    TSAttachment *attachment1 = [pushContent.attachments objectAtIndex:0];
    TSAttachment *attachment2 = [pushContent.attachments objectAtIndex:1];

    
    TSAttachment *attachment1Deserialized = [deserializedPushContent.attachments objectAtIndex:0];
    TSAttachment *attachment2Deserialized = [deserializedPushContent.attachments objectAtIndex:1];

    
    
    XCTAssertTrue([attachment1Deserialized.attachmentId isEqualToNumber:attachment1.attachmentId], @"deserialized ids do not match for attachment 1");
    XCTAssertTrue([attachment2Deserialized.attachmentId isEqualToNumber:attachment2.attachmentId], @"deserialized ids do not match for attachment 2");

    XCTAssertTrue(attachment1Deserialized.attachmentType == attachment1.attachmentType, @"deserialized ids do not match for attachment 1");
    XCTAssertTrue(attachment2Deserialized.attachmentType == attachment2.attachmentType, @"deserialized ids do not match for attachment 2");

    XCTAssertTrue([attachment1Deserialized.attachmentDecryptionKey isEqualToData:attachment1.attachmentDecryptionKey], @"deserialized ids do not match for attachment 1 deserialized %@ serialized %@",attachment1Deserialized.attachmentDecryptionKey,attachment1.attachmentDecryptionKey);
    XCTAssertTrue([attachment2Deserialized.attachmentDecryptionKey isEqualToData:attachment2.attachmentDecryptionKey], @"deserialized ids do not match for attachment 2 deserialized %@ serialized %@",attachment2Deserialized.attachmentDecryptionKey,attachment2.attachmentDecryptionKey);

    
}


-(void) testPushMessageContentAttachmentSerializationStatic {
    unsigned char testkey = 7;
    NSData* attachment1Key = [NSData dataWithBytes:&testkey length:sizeof(testkey)];

    TSAttachment *attachment1 = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:42] contentMIMEType:@"image/jpg" decryptionKey:attachment1Key];
    TSMessage *message = [[TSMessage alloc] initWithSenderId:@"1234" recipientId:@"1234567" date:[[NSDate alloc] init] content:@"Surf is up" attachements:@[attachment1] groupId:nil];
    NSData *serializedMessageContent = [TSPushMessageContent serializedPushMessageContentForMessage:message withGroupContect:nil];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([message.content isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
    XCTAssertTrue([deserializedPushContent.attachments count]==1, @"deserialization doesn't have the right number of attachments, actually has %lu",(unsigned long)[deserializedPushContent.attachments count]);
    
    TSAttachment *attachment1Deserialized = [deserializedPushContent.attachments objectAtIndex:0];
    
    
    XCTAssertTrue([attachment1Deserialized.attachmentId isEqualToNumber:attachment1.attachmentId], @"deserialized ids do not match for attachment 1");
    
    XCTAssertTrue(attachment1Deserialized.attachmentType == attachment1.attachmentType, @"deserialized ids do not match for attachment 1");

    // TODO: this is currently failing meaning attachments don't make it through deserialization process
    XCTAssertTrue([attachment1Deserialized.attachmentDecryptionKey isEqualToData:attachment1.attachmentDecryptionKey], @"deserialized ids do not match for attachment 1 deserialized %@ serialized %@",attachment1Deserialized.attachmentDecryptionKey,attachment1.attachmentDecryptionKey);
    
    
}


-(void) testPushMessageContentGroupSerializationDynamic {
    TSPushMessageContent *pushContent = [[TSPushMessageContent alloc] initWithBody:_body withAttachments:nil withGroupContext:_groupContext];
    
    NSData *serializedMessageContent = [pushContent getTextSecureProtocolData];
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([pushContent.body isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
    XCTAssertTrue(deserializedPushContent.groupContext!=nil, @"deserialization doesn't give us a group, at all");
    
    TSGroupContext *groupContextDeserialized = deserializedPushContent.groupContext;
    XCTAssertTrue([groupContextDeserialized.gid isEqualToData:_groupContext.gid],@"deserialized group id doesn't match original");
    XCTAssertTrue(groupContextDeserialized.type==_groupContext.type,@"deserialized group type doesn't match original");
    XCTAssertTrue([groupContextDeserialized.members count]==3,@"deserialized group doesn't have same number of members as original");

    for(NSUInteger i=0; i<3; i++) {
        XCTAssertTrue([[groupContextDeserialized.members objectAtIndex:i] isEqualToString:[pushContent.groupContext.members objectAtIndex:i]],@"deserialized group member %d not the same as original",i);
    }
    
    TSAttachment *groupContextAvatarDeserialized = deserializedPushContent.groupContext.avatar;
    XCTAssertTrue([groupContextAvatarDeserialized.attachmentId isEqualToNumber:pushContent.groupContext.avatar.attachmentId], @"deserialized ids do not match for avatar");
    XCTAssertTrue(groupContextAvatarDeserialized.attachmentType == pushContent.groupContext.avatar.attachmentType, @"deserialized ids do not match for avatar");
    XCTAssertTrue([groupContextAvatarDeserialized.attachmentDecryptionKey isEqualToData:pushContent.groupContext.avatar.attachmentDecryptionKey], @"deserialized ids do not match for avatar");
    
}



-(void) testPushMessageContentGroupSerializationStatic {
    
    NSString* member1 = @"12345678";
    NSString* member2 = @"987665";
    NSString* member3 = @"11111111";
    NSData* avatarKey = [Cryptography generateRandomBytes:32];
    NSData* groupId = [Cryptography generateRandomBytes:8];
    TSAttachment *avatar = [[TSAttachment alloc] initWithAttachmentId:[NSNumber numberWithInt:42] contentMIMEType:@"image/jpg" decryptionKey:avatarKey];
    
    
    
    TSGroupContext *groupContext = [[TSGroupContext alloc] initWithId:groupId withType:TSUpdateGroupContext withName:@"Winter Break of Code" withMembers:[NSArray arrayWithObjects:member1,member2,member3, nil] withAvatar:avatar];
    

    TSMessage *message = [[TSMessage alloc] initWithSenderId:@"1234" recipientId:@"1234567" date:[[NSDate alloc] init] content:@"Surf is up" attachements:nil groupId:nil];
    NSData *serializedMessageContent = [TSPushMessageContent serializedPushMessageContentForMessage:message withGroupContect:groupContext];

    
    TSPushMessageContent *deserializedPushContent = [[TSPushMessageContent alloc] initWithData:serializedMessageContent];
    
    XCTAssertTrue([message.content isEqualToString:deserializedPushContent.body], @"Push message content serialization/deserialization failed");
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
