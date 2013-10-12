//
//  CryptographyDatabase.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "CryptographyDatabase.h"
#import "FilePath.h"

@implementation CryptographyDatabase
-(id) init {
	if(self==[super init]) {
    self.database = [FMDatabase databaseWithPath:
                     [FilePath pathInDocumentsDirectory:@"cryptography.db"]];
    if (![self.database open]) {
      return nil;
    }
    [self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (source TEXT, text TEXT, destination TEXT, timestamp DATETIME DEFAULT current_timestamp)"];
    // TODO: we will need a more complicated schema, including handling of message threads, multiple desintations, attachments, multiple attachments,
    // We also need to encrypt entries, using AES.
	}
	return self;
}

@end
