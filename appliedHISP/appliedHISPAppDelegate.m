//
//  appliedHISPAppDelegate.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/14/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "appliedHISPAppDelegate.h"
#import "Constants.h"
#import "LTHPasscodeViewController.h"
#import "NewConnectionsViewController.h"
#import "ContactsViewController.h"
#import "SettingsViewController.h"

@interface appliedHISPAppDelegate() <LTHPasscodeViewControllerDelegate>
@property (nonatomic, strong) UIManagedDocument *document;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation appliedHISPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.mcHandler = [[MCHandler alloc] init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                     inDomains:NSUserDomainMask] firstObject];
    NSString *documentName = @"MyDatabase";
    NSURL *url = [documentsDirectory URLByAppendingPathComponent:documentName];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url];

    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [self.document openWithCompletionHandler:^(BOOL success) {
            // this call is asynchronous, anything inside (setting managedObjectContext) will happen after views load
            if (success) {
                [self documentIsReady];
            } else {
                NSLog(@"Could not open document at %@", url);
            }
        }];
    } else {
        [self.document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            // asynchronous, see comment above
            if (success) {
                [self documentIsReady];
            } else {
                NSLog(@"Could not create document at %@", url);
            }
        }];
    }
    
    [self setTabBarIndex];

    return YES;
}

- (void)documentIsReady
{
    if (self.document.documentState == UIDocumentStateNormal) {
        self.managedObjectContext = self.document.managedObjectContext;
        
        self.mcHandler.managedObjectContext = self.document.managedObjectContext;
        
        UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
        
        NewConnectionsViewController *newConnectionsVC = [[tabBarController viewControllers] objectAtIndex:NEW_CONNECTIONS_TAB];
        newConnectionsVC.managedObjectContext = self.managedObjectContext;
        
        UINavigationController *navigationController = [[tabBarController viewControllers] objectAtIndex:CONTACTS_TAB];
        ContactsViewController *contactsVC = (ContactsViewController *)navigationController.topViewController;
        contactsVC.managedObjectContext = self.managedObjectContext;
        
        SettingsViewController *settingsVC = [[tabBarController viewControllers] objectAtIndex:SETTINGS_TAB];
        settingsVC.managedObjectContext = self.managedObjectContext;
    } else {
        NSLog(@"Could not set context, document is in state %u", self.document.documentState);
    }
    // other documentStates:
    // UIDocumentStateClosed (1 << 0) - haven't opened or created
    // UIDocumentStateInConflict (1 << 1) - some other device changed it via iCloud
    // UIDocumentSavingError (1 << 2) - succes == NO in completionHandler
    // UIDocumentStateEditingDisabled (1 << 3) - temporary situation, try again
}

- (void)setTabBarIndex
{
    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PROFILE_IS_SET_DEFAULTS_IDENTIFIER]) {
        tabBar.selectedIndex = SETTINGS_TAB;
        [[[UIAlertView alloc] initWithTitle:@"Edit my profile"
                                    message:@"Please create a profile to begin using the application. Profile must include a first name."
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"OK", nil] show];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:CONTACTS_DO_EXIST_DEFAULTS_IDENTIFIER]) {
        tabBar.selectedIndex = CONTACTS_TAB;
    } else {
        tabBar.selectedIndex = NEW_CONNECTIONS_TAB;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // opens Passcode dialog if enabled
    [LTHPasscodeViewController sharedUser].delegate = self;
    [LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 3;
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        if ([LTHPasscodeViewController didPasscodeTimerEnd]) {
            [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO
                                                                     withLogout:NO
                                                                 andLogoutTitle:nil];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

# pragma mark - LTHPasscodeViewController Delegate methods -

- (void)passcodeViewControllerWillClose {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PASSCODE_CLOSED_NOTIFICATION
                                                            object:nil
                                                          userInfo:nil];
    });
}

- (void)maxNumberOfFailedAttemptsReached {
    // for testing, this just deletes a forgotten passcode
    // final version will need a more definitive solution
    // according to Apple Technical Q&A QA1561:
    // "There is no API provided for gracefully terminating an iOS application."
    // calling exit(0) will close app, but is against Apple policy
    // perhaps deleting the database then the passcode is appropriate, else the passcode is an oracle
    [LTHPasscodeViewController deletePasscodeAndClose];
}

- (void)passcodeWasEnteredSuccessfully {
//	NSLog(@"Passcode Was Entered Successfully");
}

- (void)logoutButtonWasPressed {
//	NSLog(@"Logout Button Was Pressed");
}

@end
