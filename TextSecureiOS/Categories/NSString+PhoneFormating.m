//
//  NSString+PhoneFormating.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/22/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "NSString+PhoneFormating.h"

@implementation NSString (phoneFormating)

-(NSString*) prependPlus{
    return [@"+" stringByAppendingString:self];
}

-(NSString*) removeAllFormattingButNumbers{
    return [[self componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

@end
