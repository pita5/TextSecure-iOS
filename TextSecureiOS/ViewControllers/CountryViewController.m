//
//  CountryViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "CountryViewController.h"

@implementation CountryViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (!self) return nil;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *plistFile = [[NSBundle mainBundle] pathForResource:countryInfoPathInMainBundle ofType:@"plist"];
    
    self.countryDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFile];
    self.countryList = [[self.countryDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    // finally we export to a plist
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationController.navigationBarHidden =NO;
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.countryDict allKeys] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CountryViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
    NSString* countryTitle = [self.countryList objectAtIndex:indexPath.row];
    cell.textLabel.text = countryTitle;
    NSString* countryCode = [[[self.countryDict objectForKey:countryTitle] objectForKey:@"code"] lowercaseString];
    cell.imageView.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",countryCode]];
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"CountrySegue"])  {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString* countryTitle = [self.countryList objectAtIndex:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CountryChosen" object:self userInfo:[self.countryDict objectForKey:countryTitle]];
   
  }
}

@end
