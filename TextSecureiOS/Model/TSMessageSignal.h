//
//  TSMessageSignal.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSMessageSignal : NSObject
@property (nonatomic,strong) TSContentType contentType;
@property (nonatomic,strong) NSString* source;
@property (nonatomic,strong) NSArray *destinations;
@property (nonatomic,strong) NSDate *timestamp;
@property (nonatomic,strong) TSWhisperMessage *message;
-(id) initWithBuffer:(NSData*) buffer;
@end
