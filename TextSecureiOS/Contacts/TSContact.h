//
//  TSContact.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/20/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSContact : NSObject

@property (nonatomic, copy) NSNumber *userABID;
@property (nonatomic, copy) NSString *relay;
@property (nonatomic, copy) NSString *registeredId;
@property (nonatomic, assign) BOOL supportsSMS;
- (NSString*) name;

@end
