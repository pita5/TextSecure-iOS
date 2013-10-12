//
//  MessagesDatabase.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Message;
@class FMDatabaseQueue;
@class FMDatabase;
@interface MessagesDatabase : NSObject
@property (nonatomic,strong) FMDatabaseQueue *dbQueue;
-(void) addMessage:(Message*)message;
-(NSArray*) getMessages;
@end
