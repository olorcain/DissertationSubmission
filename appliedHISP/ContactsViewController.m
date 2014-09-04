//
//  ContactsViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/27/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "ContactsViewController.h"
#import "Constants.h"
#import "Contact.h"
#import "MyCrypto.h"
#import "MessagesViewController.h"
#import "appliedHISPAppDelegate.h"

@interface ContactsViewController ()
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (strong, nonatomic) NSIndexPath *itemToRemove;
@property (nonatomic, strong) appliedHISPAppDelegate *appDelegate;
@end

@implementation ContactsViewController

#pragma mark - Table View Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        rows = [sectionInfo numberOfObjects];
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Contact Cell"
                                                            forIndexPath:indexPath];
    Contact *contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstname, contact.lastname];
    if (contact.isActive) {
        cell.textLabel.textColor = [UIColor blackColor];
        if ([contact.totalUnread intValue] > 0) {
            cell.detailTextLabel.textColor = [UIColor blueColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"New Messages - %@ unread", contact.totalUnread];
        } else {
            cell.detailTextLabel.textColor = [UIColor greenColor];
            cell.detailTextLabel.text = @"Active";
        }
    } else {
        cell.textLabel.textColor = [UIColor redColor];
        cell.detailTextLabel.textColor = [UIColor redColor];
        if ([contact.totalUnread intValue] > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Disconnected - %@ unread", contact.totalUnread];
        } else {
            cell.detailTextLabel.text = @"Disconnected";
        }
    }
    
    if (contact.photo) {
        cell.imageView.image = [UIImage imageWithData:contact.photo];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"pna.jpg"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.itemToRemove = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Remove Contact"
                                    message:@"Removing the contact will also discontinue all future messages from the contact. Continue?"
                                   delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:@"YES", @"NO", nil] show];
        [tableView reloadData];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"YES"])
    {
        Contact *contactToRemove = [self.fetchedResultsController objectAtIndexPath:self.itemToRemove];
        [MyCrypto removeDHKeyStringFromKeychainForIdentifier:contactToRemove.uniqueID];
        [self.appDelegate.mcHandler disconnectFromUser:contactToRemove.displayName];
        
        NSManagedObject *objToDelete = (NSManagedObject *)[self.fetchedResultsController objectAtIndexPath:self.itemToRemove];
        [self.fetchedResultsController.managedObjectContext deleteObject:objToDelete];
        [self performFetch];
    }
    else if([title isEqualToString:@"NO"])
    {
//        NSLog(@"NO was selected.");
    }
    self.itemToRemove = nil; // reset the path for next delete
}

#pragma mark - Fetched Results Controller Methods

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    [self setupFetchedResultsController];
    self.fetchedResultsController.delegate = self;
}

- (void)setupFetchedResultsController
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    if (context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
        request.predicate = nil;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"latestActivity"
                                                                  ascending:NO
                                                                   selector:@selector(compare:)]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}

- (void)performFetch
{
    if (self.fetchedResultsController) {
        NSError *error;
        BOOL success = [self.fetchedResultsController performFetch:&error];
        if (!success) NSLog(@"[%@ %@] performFetch: failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    }
    [self.contactsTableView reloadData];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            [self performFetch];
        } else {
            [self.contactsTableView reloadData];
        }
    }
}

#pragma mark - Notification Center Callbacks

- (void)performFetchForNotification:(NSNotification *)notification
{
    [self performFetch];
}

#pragma mark - View Contoller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.appDelegate = (appliedHISPAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.contactsTableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performFetchForNotification:)
                                                 name:NEW_CONTACT_ADDED_NOTIFICATION
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performFetchForNotification:)
                                                 name:MC_DID_RECEIVE_NEW_MESSAGE_NOTIFICATION
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performFetchForNotification:)
                                                 name:MC_DID_RECEIVE_PEER_DISCONNECTED_NOTIFICATION
                                               object:nil];
    [self performFetch];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEW_CONTACT_ADDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_NEW_MESSAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_PEER_DISCONNECTED_NOTIFICATION object:nil];
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessagesViewController *vc = [MessagesViewController messagesViewController];
    vc.delegateModal = self;
    Contact *contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    vc.contact = contact;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

#pragma mark - MessagesViewController Delegate Methods

- (void)didDismissMessagesViewController:(MessagesViewController *)vc
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
