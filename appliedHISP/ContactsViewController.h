//
//  ContactsViewController.h
//  appliedHISP
//
//  Created by Robert Larkin on 5/27/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MessagesViewController.h"

@interface ContactsViewController : UIViewController <NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource,MessagesViewControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
