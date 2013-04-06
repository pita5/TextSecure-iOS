//
//  FilePath.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "FilePath.h"

@implementation FilePath
+ (NSString *)applicationDocumentsDirectory {
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
  return basePath;
}



+ (NSString*)pathInDocumentsDirectory:(NSString*) fileBasename {
  return  [NSString stringWithFormat:@"%@/%@",[FilePath applicationDocumentsDirectory],fileBasename];
}

+ (NSString*)pathInBundleDirectory:(NSString*) fileBasename {
  return  [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],fileBasename];
}

@end
