//
//  Request.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Request : NSObject
@property (nonatomic) int httpRequestType;
@property (nonatomic,strong) NSURL* httpRequestURL;
@property (nonatomic,strong) NSData* httpRequestData;
@property (nonatomic) int apiRequestType;
-(id) initWithHttpRequestType:(int)hpRequestType requestUrl:(NSURL*)requestUrl requestData:(NSData*)requestData apiRequestType:(int)aiRequestType;
@end
