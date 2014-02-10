//
//  TSContact.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/20/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSContact : NSObject

@property (nonatomic, strong) NSNumber *userABID;
@property (nonatomic, strong) NSString *relay;
@property (nonatomic, strong) NSString *registeredID;
@property (nonatomic, assign) BOOL supportsSMS;
@property (nonatomic, strong) NSString *nextKey;
@property (nonatomic, strong) NSString *identityKey;
@property (nonatomic) BOOL identityKeyIsVerified;
- (NSString*) name;
-(void) save;

-(id) initWithRegisteredID:(NSString*)registeredID;
- (NSString*) labelForRegisteredNumber;
@end
