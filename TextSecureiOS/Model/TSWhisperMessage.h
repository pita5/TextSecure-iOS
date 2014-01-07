//
//  TSWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSMessage.h"
@interface TSWhisperMessage : NSObject
@property (nonatomic,strong) NSData* message;

-(TSMessage*) getTSMessage;
-(id) initWithBuffer:(NSData*) buffer;
@end
