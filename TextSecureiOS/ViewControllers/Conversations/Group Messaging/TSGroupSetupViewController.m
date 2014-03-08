//
//  TSGroupSetupViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSGroupSetupViewController.h"
#import "ComposeMessageViewController.h"
#import "TextSecureViewController.h"
#import "TSThread.h"
@interface TSGroupSetupViewController ()

@end

@implementation TSGroupSetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction) setGroupPhotoPressed:(UIButton *)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo or Video",@"Choose Existing", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerController *imagePicker =  [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    
    imagePicker.mediaTypes =  @[(NSString *) kUTTypeImage];
    
    imagePicker.allowsEditing = NO;
    
    switch (buttonIndex) {
        case 0:
            imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
            break;
        case 1:
            imagePicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        case 2:
            // cancel
            return;
        default:
            break;
    }
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if([[textField.text stringByReplacingCharactersInRange:range withString:string] length]>0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;

    }
    return YES;
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self.groupPhoto setImage:image forState:UIControlStateNormal];
    self.groupPhoto.layer.cornerRadius =self.groupPhoto.bounds.size.width/1.6;
    self.groupPhoto.layer.masksToBounds = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(IBAction)next {
    [[((UINavigationController*)self.navigationController.presentingViewController) topViewController] performSegueWithIdentifier:@"ComposeMessageSegue" sender:self];
    [self dismissViewControllerAnimated:YES completion:nil];

}



@end
