//
//  AddressBookManager.m
//  AddressBookIntegration
//
//  Created by ranjit on 22/08/15.
//  Copyright © 2015 ranjit. All rights reserved.
//

#import "AddressBookManager.h"

@interface AddressBookManager()
@property (nonatomic)ABAddressBookRef iPhoneAddressBook;
@end

@implementation AddressBookManager

+ (AddressBookManager *)sharedInstance {
  static AddressBookManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[AddressBookManager alloc] init];
  });
  return sharedInstance;
}

- (id)init {
  self = [super init];
    CFErrorRef error = NULL;
    self.iPhoneAddressBook = ABAddressBookCreateWithOptions(NULL, &error);
  return self;
}

- (void)storeObject:(ABRecordRef)person :(storeObject)block {
//  ABAddressBookRef iPhoneAddressBook = ABAddressBookCreate();
  ABAddressBookAddRecord(self.iPhoneAddressBook, person, nil);
  CFRelease(person);
  block(ABAddressBookSave(self.iPhoneAddressBook, nil));
}

- (void)fetchObjects:(fetchObjects)block {
  [self getPermission:^(ABstatus status) {
    if (status == ABisAuthorized) {
      CFArrayRef people = (ABAddressBookCopyArrayOfAllPeople(self.iPhoneAddressBook));
      CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
          kCFAllocatorDefault, CFArrayGetCount(people), people);
      CFArraySortValues(peopleMutable,
                        CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                        (CFComparatorFunction)ABPersonComparePeopleByName,
                        kABPersonSortByFirstName);

      CFRelease(people);
      NSMutableArray *contacts = [NSMutableArray new];
      for (CFIndex i = 0; i < CFArrayGetCount(peopleMutable); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(peopleMutable, i);
        [contacts addObject:(__bridge id __nonnull)(record)];
      }
      CFRelease(peopleMutable);
      block(contacts, nil);
    } else {
      NSError *error = [NSError
          errorWithDomain:@"com.ABIntegration"
                     code:100
                 userInfo:@{
                   @"info" :
                       @"Error in getting a permission from Addressbook"
                 }];
      block(nil, error);
    }
  }];
}

// helper to authorize the iOS addressBook authorization

- (void)getPermission:(permission)block {
  if (ABAddressBookGetAuthorizationStatus() ==
      kABAuthorizationStatusNotDetermined) {
    ABAddressBookRequestAccessWithCompletion(
        self.iPhoneAddressBook, ^(bool granted, CFErrorRef error) {
          if (granted) {
            block(ABisAuthorized);
          } else {
            // Handle the case of denied access
            block(ABisDenied);
          }
          CFRelease(self.iPhoneAddressBook);
        });
  } else if (ABAddressBookGetAuthorizationStatus() ==
             kABAuthorizationStatusAuthorized) {
    // The user has previously given access, add the contact
    block(ABisAuthorized);
  } else if (ABAddressBookGetAuthorizationStatus() ==
             kABAuthorizationStatusDenied) {
    // The user has previously denied access
    // Send an alert telling user to change privacy setting in settings app
    block(ABisDenied);
  }
}

- (BOOL)deleteObject:(ABRecordRef)person {
 // remove it
  BOOL result = ABAddressBookRemoveRecord(self.iPhoneAddressBook, person, NULL);
  CFErrorRef *error = nil;
  ABAddressBookSave(self.iPhoneAddressBook, error);
  CFRelease(self.iPhoneAddressBook);
  return result;
}
@end
