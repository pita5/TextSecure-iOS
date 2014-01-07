//
//  PreKeyWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "PreKeyWhisperMessage.hh"
@implementation PreKeyWhisperMessage

// Serialize WhisperMessage to NSData.
+ (NSData *)getDataForPreKeyWhisperMessage:(textsecure::PreKeyWhisperMessage *)preKeyWhisperMessage {
  std::string ps = preKeyWhisperMessage->SerializeAsString();
  return [NSData dataWithBytes:ps.c_str() length:ps.size()];
}

// De-serialize PreKeyWhisperMessage from an NSData object.
+ (textsecure::PreKeyWhisperMessage *)getPreKeyWhisperMessageForData:(NSData *)data {
  int len = [data length];
  char raw[len];
  textsecure::PreKeyWhisperMessage *preKeyWhisperMessage = new textsecure::PreKeyWhisperMessage;
  [data getBytes:raw length:len];
  preKeyWhisperMessage->ParseFromArray(raw, len);
  return preKeyWhisperMessage;
}


+ (NSData *)createSerializedPreKeyWhisperMessage:(TSPreKeyWhisperMessage*) message {
#warning untested
//  optional uint32 preKeyId    = 1;
//  optional bytes  baseKey     = 2;
//  optional bytes  identityKey = 3;
//  optional bytes  message     = 4;
  textsecure::PreKeyWhisperMessage *preKeyWhisperMessage = new textsecure::PreKeyWhisperMessage();
  uint32_t cppPreKeyId = [message.preKeyId unsignedLongValue];

  const std::string cppBaseKey([message.baseKey cStringUsingEncoding:NSASCIIStringEncoding]);
  const std::string cppIdentityKey([message.identityKey cStringUsingEncoding:NSASCIIStringEncoding]);
  const std::string cppMessage([message.message cStringUsingEncoding:NSASCIIStringEncoding]);
  preKeyWhisperMessage->set_prekeyid(cppPreKeyId);
  preKeyWhisperMessage->set_basekey(cppBaseKey);
  preKeyWhisperMessage->set_identitykey(cppIdentityKey);
  preKeyWhisperMessage->set_message(cppMessage);
  NSData *serializedPreKeyWhisperMessage = [PreKeyWhisperMessage getDataForPreKeyWhisperMessage:preKeyWhisperMessage];
  delete preKeyWhisperMessage;
  return serializedPreKeyWhisperMessage;
}

+(TSPreKeyWhisperMessage*)getTSPreKeyWhisperMessageForPreKeyWhisperMessage:(textsecure::PreKeyWhisperMessage *)preKeyWhisperMessage {
#warning untested
  
  uint32_t cppPreKeyId = preKeyWhisperMessage->prekeyid();
  const std::string cppBaseKey = preKeyWhisperMessage->basekey();
  const std::string cppIdentityKey=preKeyWhisperMessage->identitykey();
  const std::string cppMessage=preKeyWhisperMessage->message();

  
  TSPreKeyWhisperMessage *tsPreKeyWhisperMessage = [[TSPreKeyWhisperMessage alloc] init];
  
  tsPreKeyWhisperMessage.preKeyId = [NSNumber numberWithUnsignedLong:cppPreKeyId];
  tsPreKeyWhisperMessage.baseKey =  [NSString stringWithCString:cppBaseKey.c_str() encoding:NSASCIIStringEncoding];
  tsPreKeyWhisperMessage.identityKey = [NSString stringWithCString:cppIdentityKey.c_str() encoding:NSASCIIStringEncoding];
  tsPreKeyWhisperMessage.message = [NSString stringWithCString:cppMessage.c_str() encoding:NSASCIIStringEncoding];
  
  return tsPreKeyWhisperMessage;
  
  
}

@end
