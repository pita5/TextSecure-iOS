//
//  CryptographyDatabase.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMDatabase.h"

@interface CryptographyDatabase : NSObject
@property (nonatomic,strong) FMDatabase *database;

@end
