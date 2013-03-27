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
-(void) doCreateAccount:(NSString*) phoneNumber {
  self.currentRequest = CREATE_ACCOUNT;
  [self serverPost:[self createRequestURL:phoneNumber withServer:textSecureServer withAPI:textSecureAccountsAPI]];
}


-(NSData*) createVerifyNSData:(NSString*)verificationCode {
  self.currentRequest = VERIFY_ACCOUNT;
  NSDictionary *verifyAccount = [[NSDictionary alloc] initWithObjects:
                                 [[NSArray alloc] initWithObjects:verificationCode,[Cryptography generateAndStoreNewAccountAuthenticationToken], nil]
                                 forKeys:[[NSArray alloc] initWithObjects:@"verificationCode",@"authenticationToken",nil]
                                    ];

  NSString*  jsonRequest = [verifyAccount JSONRepresentation];
  return [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
}

-(void) doVerifyAccount:(NSString*) phoneNumber verificationCode:(NSString *)verificationCode {
  // TODO: this isn't ever returning 200... :(.... 
  [self serverPut:[self createRequestURL:phoneNumber withServer:textSecureServer withAPI:textSecureAccountsAPI] withData:[self createVerifyNSData:verificationCode]];
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


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
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
}




@end
