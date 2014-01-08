//
//  TSProtocolBufferWrapper.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSProtocolBufferWrapper.hh"

@implementation TSProtocolBufferWrapper

#pragma mark these must be overridden by subclass
-(id) initWithData:(NSData*) buffer {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

-(const std::string) serializedProtocolBufferAsString {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

#pragma mark boilerplate serialization method
-(NSData*) serializedProtocolBuffer {
  std::string ps = [self serializedProtocolBufferAsString];
  return [NSData dataWithBytes:ps.c_str() length:ps.size()];
}

#pragma mark boilerplate conversion methods
-(uint64_t) objcDateToCpp:(NSDate*)objcDate {
  return round([objcDate timeIntervalSince1970]);
}

-(NSDate*) cppDateToObjc:(uint64_t)cppDate {
   return [NSDate dateWithTimeIntervalSince1970:[[NSNumber numberWithInteger:cppDate] doubleValue]];
}

-(const std::string) objcStringToCpp:(NSString*)objcString {
  return [objcString cStringUsingEncoding:NSASCIIStringEncoding];
}

-(NSString*) cppStringToObjc:(const std::string)cppString {
  return [NSString stringWithCString:cppString.c_str() encoding:NSASCIIStringEncoding];
}


-(const std::string) objcDataToCppString:(NSData*)objcData {
  NSString* stringFromBytes = [[NSString alloc] initWithData:objcData
                                                    encoding:NSASCIIStringEncoding];
  return [self objcStringToCpp:stringFromBytes];
}
-(NSData*) cppStringToObjcData:(const std::string)cppString {
  return [NSData dataWithBytes:cppString.c_str() length:cppString.size()];
}

-(uint32_t) objcNumberToCppUInt32:(NSNumber*)objcNumber {
  return [objcNumber unsignedLongValue];
}
-(NSNumber*) cppUInt32ToNSNumber:(uint32_t)cppInt {
  return [NSNumber numberWithUnsignedLong:cppInt];
  
}

-(uint64_t) objcNumberToCppUInt64:(NSNumber*)objcNumber {
  return [objcNumber unsignedLongLongValue];
}
-(NSNumber*) cppUInt64ToNSNumber:(uint64_t)cppInt {
  return [NSNumber numberWithUnsignedLongLong:cppInt];
  
}


@end
