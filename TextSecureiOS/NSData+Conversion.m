//
//  NSData+Conversion.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "NSData+Conversion.h"



#import "NSData+Conversion.h"

@implementation NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString {
  /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
  
  const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
  
  if (!dataBuffer)
    return [NSString string];
  
  NSUInteger          dataLength  = [self length];
  NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
  
  for (int i = 0; i < dataLength; ++i){
    [hexString appendFormat:@"%02x", dataBuffer[i]];

    //[hexString appendString:[NSString stringWithFormat:@"%02x", (unsigned long)dataBuffer[i]]];
  }
  return [NSString stringWithString:hexString];
}

@end