//
//  Server.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Server.h"
#import "Cryptography.h"
#import "NSObject+SBJSON.h"
#import "Message.h"
@implementation Server
@synthesize receivedData;
@synthesize requestQueue;
@synthesize currentRequestApiType;
-(id) init {
	if(self==[super init]) {
		self.requestQueue = [[NSMutableArray alloc] init];
    // how outside world tells server to serve
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doVerifyAccount:) name:@"VerifyAccount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCreateAccount:) name:@"CreateAccount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doSendAPN:) name:@"SendAPN" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doSendMessage:) name:@"SendMessage" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doGetDirectoryLink:) name:@"GetDirectory" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doRetrieveDirectory:) name:@"RetrieveDirectory" object:nil];

	}
	return self;
}



-(NSString*) escapeRequest:(NSString*)request {
	return [[request stringByReplacingOccurrencesOfString:@" " withString:@"%20"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


-(void) pushSecureRequest:(Request*) request {
  [self.requestQueue insertObject:request atIndex:0];
  if([self.requestQueue count]==1) {
    [self doNextRequest];
  }
}

-(void) doNextRequest {
	if([self.requestQueue count] > 0) {
    Request* nextRequest=[self.requestQueue lastObject];
    self.currentRequestApiType=nextRequest.apiRequestType;
    [self serverAuthenticatedRequest:nextRequest];
	}
}

-(void) serverAuthenticatedRequest:(Request*)request {
  NSURL* requestUrl=request.httpRequestURL;
  NSData* requestData=request.httpRequestData;
  NSString* method;
  if(request.httpRequestType==POST) {
    method = @"POST";
  }
  else if(request.httpRequestType == PUT) {
    method = @"PUT";
  }
  else if (request.httpRequestType == GET) {
    method = @"GET";
  }
  else {
    method = @"POST";
  }

  NSMutableURLRequest *nsRequest = [NSMutableURLRequest requestWithURL:requestUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
  [nsRequest setHTTPMethod:method];
  if(request.httpRequestType != EMPTYPOST) {
    [nsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [nsRequest setValue:[NSString stringWithFormat:@"Basic %@",[Cryptography getAuthorizationToken]] forHTTPHeaderField:@"Authorization"];
    [nsRequest addValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];    
    if(requestData!=NULL) {
      [nsRequest setHTTPBody:requestData];
    }
  }
  else {
      [nsRequest setValue:@"0" forHTTPHeaderField:@"Content-Length"];
  }
	self.receivedData = [[NSMutableData alloc] init];
	id urlConnection = [[NSURLConnection alloc] initWithRequest:nsRequest delegate:self];
  if(urlConnection==nil) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerError" object:self];
  }
  
}






-(NSURL*) createRequestURL:(NSString*)requestStr withServer:(NSString*)server withAPI:(NSString*) api{
  NSLog(@"URL STring %@",[NSString stringWithFormat:@"%@/%@/%@",server,api,[self escapeRequest:requestStr]]);
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",server,api,[self escapeRequest:requestStr]]];
}


#pragma mark methods
- (NSData*) jsonDataFromDict:(NSDictionary*)parameters {
  NSString*  jsonRequest = [parameters JSONRepresentation];
  NSLog(@"json data %@",jsonRequest);
  return [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
}

-(void) doCreateAccount:(NSNotification*) notification {
  NSString* phoneNumber = [[notification userInfo] objectForKey:@"username"];
  NSLog(@"phone is %@",phoneNumber);
  [Cryptography storeUsernameToken:phoneNumber];
  Request* request = [[Request alloc] initWithHttpRequestType:EMPTYPOST
                                               requestUrl:[self createRequestURL:phoneNumber withServer:textSecureServer withAPI:textSecureAccountsAPI]
                                              requestData:NULL
                                              apiRequestType:CREATE_ACCOUNT];
  [self pushSecureRequest:request];
}


-(void) doVerifyAccount:(NSNotification*) notification {
  NSString* verificationCode = [[notification userInfo] objectForKey:@"verification_code"];
  [Cryptography generateAndStoreNewAccountAuthenticationToken];
  NSDictionary *parameters = [[NSDictionary alloc] initWithObjects:
                                                            [[NSArray alloc] initWithObjects:verificationCode,[Cryptography getAuthenticationToken], nil]
                                                           forKeys:[[NSArray alloc] initWithObjects:@"verificationCode",@"authenticationToken",nil]];
  
  Request* request = [[Request alloc] initWithHttpRequestType:PUT
                                               requestUrl:[self createRequestURL:[Cryptography getUsernameToken] withServer:textSecureServer withAPI:textSecureAccountsAPI]
                                              requestData:[self jsonDataFromDict:parameters]
                                               apiRequestType:VERIFY_ACCOUNT];
  [self pushSecureRequest:request];  
}


-(void) doSendAPN:(NSNotification *)notification {
  NSString* apn = [[notification userInfo] objectForKey:@"apnRegistrationId"];
  NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:apn,@"apnRegistrationId", nil];
  Request* request = [[Request alloc] initWithHttpRequestType:PUT
                                               requestUrl:[self createRequestURL:[NSString stringWithFormat:@"%@/%@",@"apn",[Cryptography getUsernameToken]] withServer:textSecureServer withAPI:textSecureAccountsAPI]
                                              requestData:[self jsonDataFromDict:parameters]
                                               apiRequestType:SEND_APN];
  [self pushSecureRequest:request];
}

-(void) doSendMessage:(NSNotification*)notification {
  Message* message = [[notification userInfo] objectForKey:@"message"];
  NSDictionary *parameters = [[NSDictionary alloc]
                              initWithObjectsAndKeys:message.destinations,@"destinations",message.text,@"messageText",message.attachments,@"attachments", nil];

  
  Request* request = [[Request alloc] initWithHttpRequestType:POST
                                               requestUrl:[self createRequestURL:@"" withServer:textSecureServer withAPI:textSecureMessagesAPI] 
                                              requestData:[self jsonDataFromDict:parameters]
                                               apiRequestType:SEND_MESSAGE];
    [self pushSecureRequest:request];
}

-(void) doGetDirectoryLink:(NSNotification*)notification {  
  Request* request = [[Request alloc] initWithHttpRequestType:GET
                                               requestUrl:[self createRequestURL:@"" withServer:textSecureServer withAPI:textSecureDirectoryAPI]
                                              requestData:NULL
                                               apiRequestType:GET_DIRECTORY_LINK];
  [self pushSecureRequest:request];
}


-(void)doRetrieveDirectory:(NSNotification*)notification {
  NSString* directoryURL = [[notification userInfo] objectForKey:@"url"];
  Request* request = [[Request alloc] initWithHttpRequestType:GET
                                               requestUrl:[NSURL URLWithString:directoryURL]
                                              requestData:NULL
                                               apiRequestType:GET_DIRECTORY];
  [self pushSecureRequest:request];
}

#pragma mark -
#pragma mark connection delegate methods
// Error handling and keeping track of when the connection finishes
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSLog(@"error %@",error);
  [self.requestQueue removeAllObjects];
  [self doNextRequest];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerError" object:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  //TODO: remove this when the server is trusted
  [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

-(void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	[self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
  NSLog(@"response %@ and len %d current request is %d",self.receivedData,[self.receivedData length],self.currentRequestApiType);
  [self.requestQueue removeLastObject];
  if (self.currentRequestApiType == GET_DIRECTORY_LINK) {
    NSError *error;
    NSDictionary* directoryInfo = [NSJSONSerialization JSONObjectWithData:self.receivedData options:kNilOptions error:&error];
    NSLog(@"bloom filter info %@",directoryInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RetrieveDirectory" object:self userInfo:directoryInfo];
  }
  else if (self.currentRequestApiType == GET_DIRECTORY) {
    
  }
  
  [self doNextRequest];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  // how server alerts outside world of success
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  NSDictionary *dic = [httpResponse allHeaderFields];
  
  NSLog(@"response status code and headers %d %@",[httpResponse statusCode],dic);
  
  if(self.currentRequestApiType == CREATE_ACCOUNT) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SentVerification" object:self];
    }
  }
  else if(self.currentRequestApiType == VERIFY_ACCOUNT) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"VerifiedPhone" object:self];
    }
    
  }
  else  if (self.currentRequestApiType == SEND_APN) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SentAPN" object:self];
    }
    
  }
  else  if (self.currentRequestApiType == SEND_MESSAGE) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessage" object:self];
    }
    
  }
  else if (self.currentRequestApiType == GET_DIRECTORY_LINK||self.currentRequestApiType == GET_DIRECTORY) {
    if([httpResponse statusCode] != 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"DirectoryRetrieveError" object:self];
    }
  }

}




@end
