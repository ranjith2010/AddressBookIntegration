//
//  AddressBookInterface.h
//  AddressBookIntegration
//
//  Created by ranjit on 22/08/15.
//  Copyright © 2015 ranjit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

typedef enum
{
    ABisAuthorized,
    ABisDenied,
    ABisNotDetermined
}ABstatus;

typedef void(^storeObject)(BOOL result);
typedef void(^fetchObjects)(NSArray *objects, NSError *error);
typedef void(^permission)(ABstatus status);

@protocol AddressBookInterface <NSObject>

// CRUD Operations.
- (void)storeObject:(ABRecordRef)person :(storeObject)block;
- (void)fetchObjects:(fetchObjects)block;
- (BOOL)deleteObject:(ABRecordRef)person;

@end
