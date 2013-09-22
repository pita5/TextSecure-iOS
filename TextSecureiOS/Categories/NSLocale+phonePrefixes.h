//
//  NSLocale+phonePrefixes.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/22/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberUtil.h"

@interface NSLocale (phonePrefixes)

+(NSString*) currentCountryPhonePrefix;

+(NSString*) localizedCodeNameForPhonePrefix:(NSString*)prefix;


@end
