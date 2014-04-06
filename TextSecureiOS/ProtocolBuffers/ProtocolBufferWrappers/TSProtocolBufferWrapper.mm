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

-(instancetype) initWithTextSecureProtocolData:(NSData*) data {
    throw [NSException exceptionWithName:NSInternalInconsistencyException
                                  reason:[NSString stringWithFormat:@"'abstract method' must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                userInfo:nil];
}
-(NSData*) getTextSecureProtocolData {
    throw [NSException exceptionWithName:NSInternalInconsistencyException
                                  reason:[NSString stringWithFormat:@"'abstract method' must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                userInfo:nil];
}





#pragma mark protected methods

-(const std::string) serializedProtocolBufferAsString {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"'abstract method' must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(id) initWithData:(NSData*) buffer{
    NSAssert(@"Must be overriden in subclasses!", @"initWithData: needs to be implemented in ProtocolBufferWrapper's subclasses");
    return nil;
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
    const char* cstring = [objcString cStringUsingEncoding:NSASCIIStringEncoding];
    const std::string stringFromBytes(cstring);
    return stringFromBytes;
}

-(NSString*) cppStringToObjc:(const std::string)cppString {
    return [NSString stringWithCString:cppString.c_str() encoding:NSASCIIStringEncoding];
}

-(const std::string) objcDataToCppString:(NSData*)objcData {
    int len = [objcData length];
    char raw[len];
    [objcData getBytes:raw length:len];
    const std::string stringFromBytes(raw, len);
    return stringFromBytes;
}

-(NSData*) cppStringToObjcData:(const std::string)cppString {
    return [NSData dataWithBytes:cppString.data() length:cppString.size()];
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
