//
//  NSString+PhoneFormating.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/22/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (phoneFormating)

-(NSString*) prependPlus;
-(NSString*) removeAllFormattingButNumbers;

@end
