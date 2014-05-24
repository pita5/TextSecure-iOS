//
//  TSVerifyIdentityViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSVerifyIdentityViewController.h"
#import "TSUserKeysDatabase.h"
#import "TSPresentIdentityQRCodeViewController.h"
#import "NSData+Conversion.h"


@interface TSVerifyIdentityViewController ()

@end

@implementation TSVerifyIdentityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title =  self.contact.name;
    self.theirIdentity.text = [self getFingerprintForDisplay:[self getTheirIdentityKey] ];
    self.myIdentity.text = [self getFingerprintForDisplay:[self getMyIdentityKey]];
    [self displayVerificationStatus];
}


-(void) displayVerificationStatus {
    self.identityVerifiedLabel.text = self.contact.identityKeyIsVerified ? @"Identity Verified" : @"Identity Not Verified";
}
-(NSData*) getMyIdentityKey {
    return [[TSUserKeysDatabase identityKey] publicKey];
}


-(NSData*) getTheirIdentityKey {
    return self.contact.identityKey;
}


-(NSString*) getFingerprintForDisplay:(NSData*)identityKey {
    // idea here is to insert a space every two characters. there is probably a cleverer/more native way to do this.

    NSString* fingerprint = [[TSKeyManager getFingerprintFromIdentityKey:identityKey] hexadecimalString];
    __block NSString*  formattedFingerprint = @"";
  
  
    [fingerprint enumerateSubstringsInRange:NSMakeRange(0, [fingerprint length])
                                 options:NSStringEnumerationByComposedCharacterSequences
                              usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         if (substringRange.location % 2 != 0 && substringRange.location != [fingerprint length]-1) {
             substring = [substring stringByAppendingString:@" "];
         }
         formattedFingerprint = [formattedFingerprint stringByAppendingString:substring];
     }];
    return formattedFingerprint;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [segue.destinationViewController setIdentityKey:[self getMyIdentityKey]];
    if([[segue identifier] isEqualToString:@"GetMyKeyScannedSegue"]){
        [segue.destinationViewController setIdentityKey:[self getMyIdentityKey]];
    }
    else if([[segue identifier] isEqualToString:@"ScanTheirKeySegue"]){
            [segue.destinationViewController setIdentityKey:[self getTheirIdentityKey]];
    }
    
}


-(IBAction)markManuallyVerified:(id)sender {
    self.contact.identityKeyIsVerified = YES;
    [self.contact save];
    [self displayVerificationStatus];
}


@end
