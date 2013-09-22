//
//  NSLocale+phonePrefixes.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/22/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "NSLocale+phonePrefixes.h"

@implementation NSLocale (phonePrefixes)

+(NSString*) currentCountryPhonePrefix{
    NSLocale *locale = [self currentLocale];
    NSString *isoCode = [locale objectForKey:NSLocaleCountryCode];
    return [self phonePrefixFromISOCode:isoCode];
}

+(NSString*) phonePrefixFromISOCode:(NSString*)isoCode{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    return [[NSString alloc] initWithFormat:@"%u",(unsigned int)[phoneUtil getCountryCodeForRegion:isoCode]];
}

+(NSString*) localizedCodeNameForPhonePrefix:(NSString*)prefix{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    return [[NBPhoneNumberUtil sharedInstance] getRegionCodeForCountryCode:[[formatter numberFromString:prefix] unsignedLongValue]];
}

@end
