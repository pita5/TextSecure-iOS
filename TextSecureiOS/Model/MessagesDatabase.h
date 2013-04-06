//
//  MessagesDatabase.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "Message.h"

@interface MessagesDatabase : NSObject
@property (nonatomic,strong) FMDatabase *database;
-(BOOL) addMessage:(Message*)message;
-(NSArray*) getMessages;
@end
