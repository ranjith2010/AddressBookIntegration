//
//  AddressBookManager.h
//  AddressBookIntegration
//
//  Created by ranjit on 22/08/15.
//  Copyright © 2015 ranjit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddressBookInterface.h"

@interface AddressBookManager : NSObject<AddressBookInterface>

+ (AddressBookManager*)sharedInstance;

@end
