//
//  TSProtocolBufferWrapper.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <string>

@interface TSProtocolBufferWrapper : NSObject 

-(id) initWithData:(NSData*) buffer;

-(NSData*) serializedProtocolBuffer;
-(const std::string) serializedProtocolBufferAsString;

// C++<->Objc dates
-(uint64_t) objcDateToCpp:(NSDate*)objcDate;
-(NSDate*) cppDateToObjc:(uint64_t)cppDate;

// C++<->Objc strings
-(const std::string) objcStringToCpp:(NSString*)objcString;
-(NSString*) cppStringToObjc:(const std::string)cppString;
-(const std::string) objcDataToCppString:(NSData*)objcData;
-(NSData*) cppStringToObjcData:(const std::string) cppString;

// C++<->Objc ints
-(uint32_t) objcNumberToCppUInt32:(NSNumber*)objcNumber;
-(NSNumber*) cppUInt32ToNSNumber:(uint32_t)cppInt;
-(uint64_t) objcNumberToCppUInt64:(NSNumber*)objcNumber;
-(NSNumber*) cppUInt64ToNSNumber:(uint64_t)cppInt;

@end
