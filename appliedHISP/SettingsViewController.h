//
//  SettingsViewController.h
//  appliedHISP
//
//  Created by Robert Larkin on 5/14/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController <UIAlertViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
