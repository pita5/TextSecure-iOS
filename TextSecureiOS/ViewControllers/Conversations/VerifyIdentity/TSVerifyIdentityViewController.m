//
//  TSVerifyIdentityViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSVerifyIdentityViewController.h"
#import "TSUserKeysDatabase.h"
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
    self.title = @"Verify Identity";

    self.theirIdentity.text = [self formatIdentityKeyForDisplay:[[self getTheirIdentityKey] hexadecimalString]];
    self.myIdentity.text = [self formatIdentityKeyForDisplay:[[self getMyIdentityKey] hexadecimalString]];


}

-(NSData*) getMyIdentityKey {
    return [[TSUserKeysDatabase identityKey] publicKey];
}


-(NSData*) getTheirIdentityKey {
    return self.contact.identityKey;
}


-(NSString*) formatIdentityKeyForDisplay:(NSString*)identityKey {
    // idea here is to insert a space every two characters. there is probably a cleverer/more native way to do this.
    
    __block NSString*  formattedIdentityKey = @"";
    [identityKey enumerateSubstringsInRange:NSMakeRange(0, [identityKey length])
                                 options:NSStringEnumerationByComposedCharacterSequences
                              usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         if (substringRange.location % 2 != 0 && substringRange.location != [identityKey length]-1) {
             substring = [substring stringByAppendingString:@" "];
         }
         formattedIdentityKey = [formattedIdentityKey stringByAppendingString:substring];
     }];
    return formattedIdentityKey;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
