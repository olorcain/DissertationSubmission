//
//  NewConnectionsViewController.h
//  appliedHISP
//
//  Created by Robert Larkin on 5/28/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "RandomNumberViewController.h"

@interface NewConnectionsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MCBrowserViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
