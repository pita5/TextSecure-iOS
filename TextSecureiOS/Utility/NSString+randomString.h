//
//  NSString+randomString.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 23/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (randomString)

+ (NSString*)genRandStringLength:(int)len;

@end
