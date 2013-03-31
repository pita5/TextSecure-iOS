//
//  Message.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
// TODO: rename/refactor... apparently can cause conflict with system name
@interface Message : NSObject
@property (nonatomic,strong) NSString* source;
@property (nonatomic,strong) NSArray* destinations;
@property (nonatomic,strong) NSString* text;
@property (nonatomic,strong) NSArray* attachments;
@property (nonatomic,strong) NSDate* timestamp;
-(id)initWithText:(NSString*)messageText messageSource:(NSString*) messageSource messageDestinations:(NSArray*)messageDestinations  messageAttachments:(NSArray*) messageAttachments messageTimestamp:(NSDate*)messageTimestamp;
@end
