//
//  NSString+Conversion.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_Conversion)
#pragma mark - Base 64 Conversion

- (NSString *)base64Encoded;
@end
