//
//  MessagesDatabase.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "MessagesDatabase.h"
#import "FilePath.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "Message.h"
#import "Cryptography.h"


static MessagesDatabase *SharedMessagesDatabase = nil;
@implementation MessagesDatabase



-(id) init {
  @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"must be initialized with password" userInfo:nil];
  
}

+(void) setupDatabaseWithPassword:(NSString*) userPassword{
  if (!SharedMessagesDatabase) {
    // first in app launch cycle
    SharedMessagesDatabase = [[MessagesDatabase alloc] initWithPassword:userPassword] ;
  }
}

+(id) database {
  if (!SharedMessagesDatabase) {
    @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"database must be accessed with password first" userInfo:nil];
  }
  return SharedMessagesDatabase;
  
}


-(id) initWithPassword:(NSString*) password {
	if(self==[super init]) {
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:@"messages.db"]];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
      NSData * key = [Cryptography getMasterSecretKey:password];
      if(key!=nil) {
        BOOL success = [db setKeyWithData:key];
        if(!success) {
          @throw [NSException exceptionWithName:@"unable to encrypt" reason:@"this shouldn't happen" userInfo:nil];
          
        }
        
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (source TEXT, text TEXT, destination TEXT, timestamp DATETIME DEFAULT current_timestamp)"];
      }
    }];
    // TODO: we will need a more complicated schema, including handling of message threads, multiple desintations, attachments, multiple attachments,
    // We also need to encrypt entries, using AES.
	}
	return self;
}


-(void) addMessage:(Message*)message {

  [self.dbQueue inDatabase:^(FMDatabase *db) {
     [db executeUpdate:@"INSERT INTO messages (source,text,destination) VALUES (?, ?, ?)",
            message.source,
            message.text,
               [message.destinations objectAtIndex:0]];
    [db commit];
  }];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"DatabaseUpdated" object:self];

}


-(NSArray*) getMessages {
  NSMutableArray* messages = [[NSMutableArray alloc] init];
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:@"SELECT * FROM messages"];
    while([rs next]){
      Message* message = [[Message alloc] initWithText:[rs stringForColumn:@"text"]
                                         messageSource:[rs stringForColumn:@"source"]
                                   messageDestinations:[[NSArray alloc] initWithObjects:[rs stringForColumn:@"destination"], nil]
                                    messageAttachments:[[NSArray alloc] init]
                                      messageTimestamp:[rs dateForColumn:@"timestamp"]];
      [messages addObject:message];
    }
  }];
  return messages;
}




@end
