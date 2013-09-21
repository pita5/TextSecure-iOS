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


// Evaluate trust: https://developer.apple.com/library/mac/documentation/security/conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html#//apple_ref/doc/uid/TP40001358-CH208-SW10

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
    [self getCertificateData];
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
	
	NSMutableURLRequest *nsRequest = [NSMutableURLRequest requestWithURL:requestUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
	if(request.httpRequestType!=DOWNLOAD) {
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
	}
	self.receivedData = [[NSMutableData alloc] init];
	id urlConnection = [[NSURLConnection alloc] initWithRequest:nsRequest delegate:self];
	if(urlConnection==nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerError" object:self];
	}	
}

-(NSURL*) createRequestURL:(NSString*)requestStr withServer:(NSString*)server withAPI:(NSString*) api{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",server,api,[self escapeRequest:requestStr]]];
}





#pragma mark methods
- (NSData*) jsonDataFromDict:(NSDictionary*)parameters {
	NSError *error = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
	if (error) {
		DLog(@"The dictionary, %@, could not be serialized. Finished with error : %@", parameters, error);
		return nil;
	} else {
		return data;
	}
}

-(void) doCreateAccount:(NSNotification*) notification {
  NSString* phoneNumber = [[notification userInfo] objectForKey:@"username"];
  NSString* transport = [[notification userInfo] objectForKey:@"transport"];

  [Cryptography storeUsernameToken:phoneNumber];
  Request* request = [[Request alloc] initWithHttpRequestType:EMPTYPOST
                                               requestUrl:[self createRequestURL:[NSString stringWithFormat:@"%@/%@",transport,phoneNumber] withServer:textSecureServer withAPI:textSecureAccountsAPI]
                                              requestData:NULL
                                              apiRequestType:CREATE_ACCOUNT];
  [self pushSecureRequest:request];

}

-(void) doVerifyAccount:(NSNotification*) notification {
	NSString* verificationCode = [[notification userInfo] objectForKey:@"verification_code"];
	[Cryptography generateAndStoreNewAccountAuthenticationToken];
  [Cryptography generateAndStoreNewSignalingKeyToken];
	NSDictionary *parameters = [[NSDictionary alloc] initWithObjects:
								[[NSArray alloc] initWithObjects:[Cryptography getSignalingKeyToken], nil]
															 forKeys:[[NSArray alloc] initWithObjects:@"signalingKey",nil]];
	Request* request = [[Request alloc] initWithHttpRequestType:PUT
                                                   requestUrl:[self createRequestURL:[NSString stringWithFormat:@"code/%@",verificationCode] withServer:textSecureServer withAPI:textSecureAccountsAPI]
													requestData:[self jsonDataFromDict:parameters]
												 apiRequestType:VERIFY_ACCOUNT];
	[self pushSecureRequest:request];
}

-(void) doSendAPN:(NSNotification *)notification {
	NSString* apn = [[notification userInfo] objectForKey:@"apnRegistrationId"];
	NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:apn,@"apnRegistrationId", nil];
	Request* request = [[Request alloc] initWithHttpRequestType:PUT
													 requestUrl:[self createRequestURL:@"apn" withServer:textSecureServer withAPI:textSecureAccountsAPI]
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
	Request* request = [[Request alloc] initWithHttpRequestType:DOWNLOAD
													 requestUrl:[NSURL URLWithString:directoryURL]
													requestData:NULL
												 apiRequestType:GET_DIRECTORY];
	[self pushSecureRequest:request];
}

#pragma mark - Connection delegate SSL authentication delegate 
/* we are using our own trust anchor instead of a CA trust anchor.  So we need to make an SSL connection where we verify against our CA */
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (NSData*)getCertificateData {
  SecCertificateRef whisperCert = nil;
  NSString *whisperCertPath = [[NSBundle mainBundle]
                               pathForResource:@"whisperca" ofType:@"crt"]; // in DER format
  NSData *certData = [[NSData alloc]
                      initWithContentsOfFile:whisperCertPath];
#ifdef DEBUG
  CFDataRef whisperCertData = (__bridge CFDataRef)certData;
  whisperCert = SecCertificateCreateWithData(NULL, whisperCertData);
  CFStringRef certSummary = SecCertificateCopySubjectSummary(whisperCert);
  NSString* summaryString = [[NSString alloc]
                             initWithString:(__bridge NSString *)certSummary];
  NSLog(@"whisper cert summary string %@",summaryString);
#endif
  return certData;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  if ([[[challenge protectionSpace] authenticationMethod] isEqualToString: NSURLAuthenticationMethodServerTrust]){
    do {
      SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
      if (serverTrust == nil) {
        break; // failed
      }
      
      OSStatus status = SecTrustEvaluate(serverTrust, NULL);
      if (!(errSecSuccess == status)) {
        break; // failed
      }
      SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
      if (serverCertificate == nil) {
        break; // failed
      }
      
      CFDataRef serverCertificateData = SecCertificateCopyData(serverCertificate);
      if (serverCertificateData == nil) {
        break; // failed
      }
      const UInt8* const data = CFDataGetBytePtr(serverCertificateData);
      const CFIndex size = CFDataGetLength(serverCertificateData);
      NSData* server_cert = [NSData dataWithBytes:data length:(NSUInteger)size];
      CFRelease(serverCertificateData);
      
      NSData* my_cert = [self getCertificateData];
      
      if (server_cert == nil || my_cert == nil) {
        break; // failed
      }
      
      const BOOL equal = [server_cert isEqualToData:my_cert];
      if (!equal) {
        break; // failed
      }
      
      // Athentication succeeded:
      return [[challenge sender] useCredential:[NSURLCredential credentialForTrust:serverTrust]
                    forAuthenticationChallenge:challenge];
    } while (0);
    
    // Authentication failed:
    // TODOUI: error code
    return [[challenge sender] cancelAuthenticationChallenge:challenge];
  }
}

#pragma mark - Connection delegate methods
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self.requestQueue removeAllObjects];
	[self doNextRequest];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerError" object:self];
}


-(void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	[self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	[self.requestQueue removeLastObject];
	if (self.currentRequestApiType == GET_DIRECTORY_LINK||self.currentRequestApiType == GET_DIRECTORY) {
		NSError *error;
		if(self.currentRequestApiType==GET_DIRECTORY_LINK) {
			NSDictionary* directoryInfo = [NSJSONSerialization JSONObjectWithData:self.receivedData options:kNilOptions error:&error];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDirectoryInfo" object:self userInfo:directoryInfo];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RetrieveDirectory" object:self userInfo:directoryInfo];
		}
		else {
			NSDictionary* directoryInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.receivedData,@"directory",nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDirectory" object:self userInfo:directoryInfo];
			
		}
	}
	
	[self doNextRequest];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// how server alerts outside world of success
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
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
