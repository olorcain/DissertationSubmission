//
//  EditProfileViewController.h
//  appliedHISP
//
//  Created by Robert Larkin on 5/24/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyProfile.h"

@interface EditProfileViewController : UIViewController

@property (nonatomic, strong) MyProfile *savedProfile;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
