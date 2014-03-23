//
//  TSProtocolBufferWrapper.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#import <string>
#endif

@protocol TSProtocolBufferWrapperMethods <NSObject>
#pragma mark these must be overridden by subclass
-(id) initWithData:(NSData*) buffer;

#pragma mark boilerplate code
// raw protocol buffer
-(NSData*) serializedProtocolBuffer;
// these pre or post pend version and hmac info to serialized protocol buffer
// C++<->Objc dates

#ifdef __cplusplus
-(const std::string) serializedProtocolBufferAsString;
-(uint64_t) objcDateToCpp:(NSDate*)objcDate;
-(NSDate*) cppDateToObjc:(uint64_t)cppDate;
#endif

// C++<->Objc strings
#ifdef __cplusplus
-(const std::string) objcStringToCpp:(NSString*)objcString;
-(NSString*) cppStringToObjc:(const std::string)cppString;
-(const std::string) objcDataToCppString:(NSData*)objcData;
-(NSData*) cppStringToObjcData:(const std::string) cppString;
#endif

// C++<->Objc ints
-(uint32_t) objcNumberToCppUInt32:(NSNumber*)objcNumber;
-(NSNumber*) cppUInt32ToNSNumber:(uint32_t)cppInt;
-(uint64_t) objcNumberToCppUInt64:(NSNumber*)objcNumber;
-(NSNumber*) cppUInt64ToNSNumber:(uint64_t)cppInt;
@end

@interface TSProtocolBufferWrapper : NSObject <TSProtocolBufferWrapperMethods>
#pragma mark these must be overridden by subclass

-(id) initWithTextSecureProtocolData:(NSData*) data;
-(NSData*) getTextSecureProtocolData;


@end
