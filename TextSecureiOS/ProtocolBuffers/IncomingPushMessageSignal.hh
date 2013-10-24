//
//  IncomingPushMessageSignal.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IncomingPushMessageSignal : NSObject
- (NSData *)getDataForIncomingPushMessageSignal:(textsecure::IncomingPushMessageSignal *)incomingPushMessage;
- (textsecure::IncomingPushMessageSignal *)getIncomingPushMessageSignalForData:(NSData *)data;
- (void)prettyPrint:(textsecure::IncomingPushMessageSignal *)incomingPushMessage;
@end
