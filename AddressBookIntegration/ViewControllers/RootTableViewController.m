//
//  RootTableViewController.m
//  AddressBookIntegration
//
//  Created by ranjit on 22/08/15.
//  Copyright © 2015 ranjit. All rights reserved.
//

#import "RootTableViewController.h"
#import "AddressBookInterface.h"
#import "AddressBookManager.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "MBProgressHUD.h"

@interface RootTableViewController () <ABNewPersonViewControllerDelegate,
                                       ABPersonViewControllerDelegate>

@property(nonatomic, strong) NSArray *dataSource;
@property(nonatomic, strong) AddressBookManager *abBroker;
@property(nonatomic) ABPeoplePickerNavigationController *navigationForNewPerson;

@end

@implementation RootTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self pr_initialSetup];
}

- (void)pr_initialSetup {
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.tableView addSubview:self.refreshControl];
  [self.refreshControl addTarget:self
                          action:@selector(fetchAll)
                forControlEvents:UIControlEventValueChanged];
  UIBarButtonItem *rightBarbuttonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                           target:self
                           action:@selector(addContact:)];
  self.navigationItem.rightBarButtonItem = rightBarbuttonItem;
  self.abBroker = [AddressBookManager sharedInstance];
  [self fetchAll];
}

- (void)fetchAll {
  [self.abBroker fetchObjects:^(NSArray *objects, NSError *error) {
    [self.refreshControl endRefreshing];
    if (objects && objects.count) {
      self.dataSource = nil;
      self.dataSource = objects;
      [self.tableView reloadData];
    } else {
      UIAlertView *alertView =
          [[UIAlertView alloc] initWithTitle:@"Error"
                                     message:error.userInfo[@"info"]
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
      [alertView show];
    }
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"cell"
                                      forIndexPath:indexPath];
  ABRecordRef abRecord =
      (__bridge ABRecordRef)([self.dataSource objectAtIndex:indexPath.row]);
  CFTypeRef generalCFObject =
      ABRecordCopyValue(abRecord, kABPersonFirstNameProperty);
  cell.textLabel.text = (__bridge NSString *)generalCFObject;
  CFRelease(generalCFObject);
  ABMutableMultiValueRef phonesRef =
      ABRecordCopyValue(abRecord, kABPersonPhoneProperty);
  if (ABMultiValueGetCount(phonesRef) > 0) {
    CFStringRef currentPhoneValue = ABMultiValueCopyValueAtIndex(phonesRef, 0);
    cell.detailTextLabel.text = (__bridge NSString *)currentPhoneValue;
    CFRelease(currentPhoneValue);
  } else {
    cell.detailTextLabel.text = @"";
  }
  CFRelease(phonesRef);
  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ABRecordRef person =
      (__bridge ABRecordRef)([self.dataSource objectAtIndex:indexPath.row]);
  [self displayContactInfo:person];
}

- (void)displayContactInfo:(ABRecordRef)person {
  ABPersonViewController *personController =
      [[ABPersonViewController alloc] init];
  [personController setDisplayedPerson:person];
  [personController setPersonViewDelegate:self];
  personController.addressBook = ABAddressBookCreate();
  personController.displayedProperties = [NSArray
      arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty], nil];
  personController.allowsEditing = YES;
  [self.navigationController pushViewController:personController animated:YES];
}

- (void)addContact:(id)sender {
  ABNewPersonViewController *newPersonController =
      [ABNewPersonViewController new];
  self.navigationForNewPerson = [[ABPeoplePickerNavigationController alloc]
      initWithRootViewController:newPersonController];
  [newPersonController setNewPersonViewDelegate:self];
  [self presentViewController:self.navigationForNewPerson
                     animated:YES
                   completion:nil];
}

- (BOOL)personViewController:(ABPersonViewController *)personView
    shouldPerformDefaultActionForPerson:(ABRecordRef)person
                               property:(ABPropertyID)property
                             identifier:
                                 (ABMultiValueIdentifier)identifierForValue {
  // This is where you pass the selected contact property elsewhere in your
  // program
  [[self navigationController] dismissModalViewControllerAnimated:YES];
  return NO;
}

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView
       didCompleteWithNewPerson:(ABRecordRef)person {
  if (person != nil) {
    [MBProgressHUD showHUDAddedTo:newPersonView.view animated:YES];
    [[AddressBookManager sharedInstance]
        storeObject:
             person:^(BOOL result) {
               [MBProgressHUD hideHUDForView:newPersonView.view animated:YES];
               if (result) {
                 NSLog(@"contact added");
               } else {
                 NSLog(@"contact failed to add");
               }
               [self dismissViewControllerAnimated:YES completion:nil];
             }];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  // Return NO if you do not want the specified item to be editable.
  return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source
    ABRecordRef person =
        (__bridge ABRecordRef)([self.dataSource objectAtIndex:indexPath.row]);
    if ([self.abBroker deleteObject:person]) {
      NSLog(@"contact deleted successfully");
      NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataSource];
      [array removeObjectAtIndex:indexPath.row];
      self.dataSource = array;
      [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                            withRowAnimation:UITableViewRowAnimationFade];
    } else {
      NSLog(@"contact failed to delete!");
    }
  }
}

@end
