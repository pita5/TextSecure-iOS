//
//  TSSubmitMessageRequest.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 11/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
@class TSContact;
@interface TSSubmitMessageRequest : TSRequest
-(TSRequest*) initWithRecipient:(TSContact*) contact message:(NSString*) messageBody ;
@end
