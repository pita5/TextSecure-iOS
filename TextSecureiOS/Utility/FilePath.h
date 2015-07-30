//
//  FilePath.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilePath : NSObject

+ (NSString *)applicationDocumentsDirectory;
+ (NSString*)pathInDocumentsDirectory:(NSString*) fileBasename;
+ (NSString*)pathInBundleDirectory:(NSString*) fileBasename;
@end
