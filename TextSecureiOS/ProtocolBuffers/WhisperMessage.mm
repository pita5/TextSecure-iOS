//
//  WhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "WhisperMessage.hh"

@implementation WhisperMessage


// Serialize WhisperMessage to NSData.
+ (NSData *)getDataForWhisperMessage:(textsecure::WhisperMessage *)whisperMessage {
  std::string ps = whisperMessage->SerializeAsString();
  return [NSData dataWithBytes:ps.c_str() length:ps.size()];
}

// De-serialize WhisperMessage from an NSData object.
+ (textsecure::WhisperMessage *)getWhisperMessageForData:(NSData *)data {
  int len = [data length];
  char raw[len];
  textsecure::WhisperMessage *whisperMessage = new textsecure::WhisperMessage;
  [data getBytes:raw length:len];
  whisperMessage->ParseFromArray(raw, len);
  return whisperMessage;
}


+ (NSData *)createSerializedWhisperMessage:(TSEncryptedWhisperMessage*) message {
#warning untested
//  optional bytes  ephemeralKey    = 1;
//  optional uint32 counter         = 2;
//  optional uint32 previousCounter = 3;
//  optional bytes  ciphertext      = 4;
  textsecure::WhisperMessage *whisperMessage = new textsecure::WhisperMessage();
  const std::string cppEphemeralKey([message.ephemeralKey cStringUsingEncoding:NSASCIIStringEncoding]);

  uint32_t cppCounter = [message.counter unsignedLongValue];
  uint32_t cppPreviousCounter = [message.previousCounter unsignedLongValue];
  const std::string cppCipherText([message.message cStringUsingEncoding:NSASCIIStringEncoding]);
  
  
  
  whisperMessage->set_ephemeralkey(cppEphemeralKey);
  whisperMessage->set_counter(cppCounter);
  whisperMessage->set_previouscounter(cppPreviousCounter);
  whisperMessage->set_ciphertext(cppCipherText);
  NSData *serializedWhisperMessage = [WhisperMessage getDataForWhisperMessage:whisperMessage];
  delete whisperMessage;
  return serializedWhisperMessage;
  
}
+(TSEncryptedWhisperMessage*)getTSWhisperMessageForWhisperMessage:(textsecure::WhisperMessage *)whisperMessage {
#warning untested
  const std::string cppEphemeralKey = whisperMessage->ephemeralkey();
  uint32_t cppCounter = whisperMessage->counter();
  uint32_t cppPreviousCounter = whisperMessage->previouscounter();
  const std::string cppCiphertext = whisperMessage->ciphertext();
  TSEncryptedWhisperMessage *tsWhisperMessage = [[TSEncryptedWhisperMessage alloc] init];
  
  tsWhisperMessage.ephemeralKey = [NSString stringWithCString:cppEphemeralKey.c_str() encoding:NSASCIIStringEncoding];
  tsWhisperMessage.counter = [NSNumber numberWithUnsignedLong:cppCounter];
  tsWhisperMessage.previousCounter = [NSNumber numberWithUnsignedLong:cppPreviousCounter];
  tsWhisperMessage.ciphertext = [NSString stringWithCString:cppCiphertext.c_str() encoding:NSASCIIStringEncoding];
  
  return tsWhisperMessage;
  

}




@end
