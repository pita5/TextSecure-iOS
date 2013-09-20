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

/*
 Example:
 REGISTER +41791111111:
 curl -k -X POST --header "Content-Length: 0" https://gcm.textsecure.whispersystems.org/v1/accounts/sms/+41791111111
 AUTHORIZE:
 curl -k -X PUT -i -H "Authorization: Basic KzQxNzk5NjI0NDk5OjI1OTNlNWZhZTdiNzUxODYxYzcxOTE4YjRhNGU5YTE5" -H "Content-Type:application/json" --data "{\"signalingKey\" : \"Ti71M5PR63/SOnrermsyZMlrl2WrwAMD/5cH5Z/bjKEG1e3jjKzUBf1zI0bPt4ai\"}"  https://gcm.textsecure.whispersystems.org/v1/accounts/code/111111
 with 111111 being the verification code the phone number recieved by SMS
*/

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
@end
