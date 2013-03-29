//
//  MessagesDatabase.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "MessagesDatabase.h"
#import "FilePath.h"
@implementation MessagesDatabase
@synthesize database;

-(id) init {
	if(self==[super init]) {
		self.database = [FMDatabase databaseWithPath:
                     [FilePath pathInDocumentsDirectory:@"messages.db"]];
    if (![self.database open]) {
      NSLog(@"Could not open message db.");
      return nil;
    }
    [self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (source TEXT, text TEXT, destination TEXT,timestamp DATETIME DEFAULT current_timestamp)"];
    // Later we will need a more complicated schema, including handling of message threads, multiple desintations, attachments, multiple attachments,
	}
	return self;
}


-(BOOL) addMessage:(Message*)message {
  BOOL success=[self.database executeUpdate:@"INSERT INTO messages (source,text,destination) VALUES (?, ?, ?)",
            message.source,
            message.text,
            [message.destinations objectAtIndex:0]];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"DatabaseUpdated" object:self];
  return success;

}


-(NSArray*) getMessages {
  NSMutableArray* messages = [[NSMutableArray alloc] init];

  FMResultSet  *rs = [self.database executeQuery:@"SELECT * FROM messages"];

  NSLog(@"results %@",rs);
	while([rs next]){
    Message* message = [[Message alloc] initWithText:[rs stringForColumn:@"text"]
                                       messageSource:[rs stringForColumn:@"source"]
                                  messageDestinations:[[NSArray alloc] initWithObjects:[rs stringForColumn:@"destination"], nil]
                                  messageAttachments:[[NSArray alloc] init]
                                    messageTimestamp:[rs dateForColumn:@"timestamp"]];
    ;
    [messages addObject:message];
  }
  return messages;
}




@end
