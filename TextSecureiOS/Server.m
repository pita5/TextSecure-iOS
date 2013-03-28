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
@implementation Server
@synthesize receivedData;
@synthesize requestQueue;
@synthesize currentRequest;
-(id) init {
	if(self==[super init]) {
		self.requestQueue = [[NSMutableArray alloc] init];
    // how outside world tells server to serve
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doVerifyAccount:) name:@"VerifyAccount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCreateAccount:) name:@"CreateAccount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doSendAPN:) name:@"SendAPN" object:nil];
    
	}
	return self;
}

-(void) doNextRequest {
	if([self.requestQueue count] > 0) {
		id request = [self.requestQueue lastObject];
		[self serverPost:request];
	}
}

-(NSString*) escapeRequest:(NSString*)request {
	return [[request stringByReplacingOccurrencesOfString:@" " withString:@"%20"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


-(void) pushSecureRequest:(NSString*) request {
  NSURL* requestUrl = [self createRequestURL:request withServer:textSecureServer withAPI:textSecureAccountsAPI];
  [self.requestQueue insertObject:requestUrl atIndex:0];
  if([self.requestQueue count]==1) {
    [self doNextRequest];
  }
}


-(void) serverPut:(NSURL*)requestUrl withData:(NSData*)requestData{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
	[request setHTTPMethod:@"PUT"];  
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:[NSString stringWithFormat:@"Basic %@",[Cryptography getAuthenticationToken]] forHTTPHeaderField:@"Authorization"];
  [request addValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
  [request setHTTPBody:requestData];
	self.receivedData = [[NSMutableData alloc] init];
	id urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if(urlConnection==nil) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerError" object:self];
  }
}

-(void) serverPost:(NSURL*)requestUrl {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	self.receivedData = [[NSMutableData alloc] init];
	id urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
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
  return [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
}

-(void) doCreateAccount:(NSNotification*) notification {
  self.currentRequest = CREATE_ACCOUNT;
  NSString* phoneNumber = [[notification userInfo] objectForKey:@"username"];
  [Cryptography storeUsernameToken:phoneNumber];
  [self serverPost:[self createRequestURL:phoneNumber withServer:textSecureServer withAPI:textSecureAccountsAPI]];
}


-(void) doVerifyAccount:(NSNotification*) notification {
  self.currentRequest = VERIFY_ACCOUNT;
  NSString* verificationCode = [[notification userInfo] objectForKey:@"verification_code"];
  [Cryptography generateAndStoreNewAccountAuthenticationToken];
  NSDictionary *parameters = [[NSDictionary alloc] initWithObjects:
                                                            [[NSArray alloc] initWithObjects:verificationCode,[Cryptography getAuthenticationToken], nil]
                                                           forKeys:[[NSArray alloc] initWithObjects:@"verificationCode",@"authenticationToken",nil]];
  [self serverPut:[self createRequestURL:[Cryptography getUsernameToken] withServer:textSecureServer withAPI:textSecureAccountsAPI] withData:[self jsonDataFromDict:parameters]];
}


-(void) doSendAPN:(NSString *)apn {
  self.currentRequest = SEND_APN;
  NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:apn,@"apnRegistrationId", nil];
  [self serverPut:[self createRequestURL:[NSString stringWithFormat:@"%@/%@",@"apn",[Cryptography getUsernameToken]] withServer:textSecureServer withAPI:textSecureAccountsAPI] withData:[self jsonDataFromDict:parameters]];
}



#pragma mark -
#pragma mark connection delegate methods
// Error handling and keeping track of when the connection finishes
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [self.requestQueue removeAllObjects];
  [self doNextRequest];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerError" object:self];
}


-(void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	[self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
  NSLog(@"response %@ and len %d",self.receivedData,[self.receivedData length]);

  [self.requestQueue removeLastObject];
  [self doNextRequest];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  // how server alerts outside world of success
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  NSDictionary *dic = [httpResponse allHeaderFields];
  
  NSLog(@"response status code and headers %d %@",[httpResponse statusCode],dic);
  if(self.currentRequest == CREATE_ACCOUNT) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SentVerification" object:self];
    }
  }
  else if(self.currentRequest == VERIFY_ACCOUNT) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"VerifiedPhone" object:self];
    }
    
  }
  else  if (self.currentRequest == SEND_APN) {
    if([httpResponse statusCode] == 200){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SentAPN" object:self];
    }
    
  }
}




@end
