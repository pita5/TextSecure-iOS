//
//  NSData+TSKeyVersion.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 17/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (TSKeyVersion)

- (NSData*)prependVersionByte;

@end
