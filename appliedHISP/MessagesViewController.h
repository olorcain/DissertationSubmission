//
//  MessagesViewController.h
//  appliedHISP
//
//  Created by Robert Larkin on 5/14/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Contact.h"
#import "JSQMessages.h"

@class MessagesViewController;

@protocol MessagesViewControllerDelegate <NSObject>
- (void)didDismissMessagesViewController:(MessagesViewController *)vc;
@end

@interface MessagesViewController : JSQMessagesViewController

@property (strong, nonatomic) Contact *contact;
@property (weak, nonatomic) id<MessagesViewControllerDelegate> delegateModal;

@end
