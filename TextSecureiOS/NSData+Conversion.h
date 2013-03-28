//
//  NSData+Conversion.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString;
- (NSString *)base64EncodedString;
+ (NSData *)dataByBase64DecodingString:(NSString *)decode;
@end
