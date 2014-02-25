//
//  NSString+Conversion.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "NSString+Conversion.h"

//
//  NSData+Conversion.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//
@implementation NSString (NSString_Conversion)

#pragma mark - Base 64 Conversion
- (NSString *)base64Encoded {
    return [[self dataUsingEncoding: NSASCIIStringEncoding] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (NSString *)unformattedPhoneNumber {
  NSCharacterSet *toExclude = [NSCharacterSet characterSetWithCharactersInString:@"/.()- "];
  return [[self componentsSeparatedByCharactersInSet:toExclude] componentsJoinedByString: @""];
}


@end