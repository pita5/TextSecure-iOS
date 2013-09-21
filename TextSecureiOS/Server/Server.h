//
//  Server.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "Request.h"


@interface Server : NSObject {
	
}
@property (nonatomic,strong) NSMutableData *receivedData;
@property (nonatomic,strong) NSMutableArray *requestQueue;
@property (nonatomic,strong) NSString *number;
@property (nonatomic) int currentRequestApiType;
#pragma mark -
#pragma mark server request queue methods
-(void) doNextRequest;
-(void) pushSecureRequest:(Request*) request;

-(NSURL*) createRequestURL:(NSString*)requestStr withServer:(NSString*)server withAPI:(NSString*) api;
-(void) serverAuthenticatedRequest:(Request*)request;

#pragma mark -
#pragma mark TextSecure verbs
- (NSData*) jsonDataFromDict:(NSDictionary*)parameters;
-(void) doCreateAccount:(NSNotification*) notification;
-(void) doVerifyAccount:(NSNotification*) notification;
-(void) doSendAPN:(NSNotification *)notification;
-(void) doGetDirectoryLink:(NSNotification*)notification;
-(void) doRetrieveDirectory:(NSNotification*)notification;

#pragma mark -
#pragma mark connection delegate methods
-(void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

#pragma mark -
#pragma mark certificate verification
- (NSData*)getCertificateData;
@end
