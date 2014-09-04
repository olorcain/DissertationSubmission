//
//  MessagesViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/14/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "MessagesViewController.h"
#import "Constants.h"
#import "Message.h"
#import "appliedHISPAppDelegate.h"
#import "RNDecryptor.h"
#import "MyCrypto.h"

@interface MessagesViewController () <UITextFieldDelegate>

@property (nonatomic, strong) appliedHISPAppDelegate *appDelegate;
@property (strong, nonatomic) UIImageView *outgoingBubbleImageView;
@property (strong, nonatomic) UIImageView *incomingBubbleImageView;
@property (strong, nonatomic) NSMutableArray *messages;
@property (copy, nonatomic) NSDictionary *avatars;

@end

@implementation MessagesViewController

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                    sender:(NSString *)sender
                      date:(NSDate *)date
{
    if ([text length] && self.contact.isActive) {
        if ([self.appDelegate.mcHandler sendNewMessage:text
                                               forDate:date
                                             toContact:self.contact]) {
            [JSQSystemSoundPlayer jsq_playMessageSentSound];

            JSQMessage *message = [[JSQMessage alloc] initWithText:text sender:sender date:date];
            [self.messages addObject:message];
            [self finishSendingMessage];
        }
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    NSLog(@"Camera button pressed.");
    // TODO: Implement photo sharing
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView bubbleImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    if ([message.sender isEqualToString:self.sender]) {
        return [[UIImageView alloc] initWithImage:self.outgoingBubbleImageView.image
                                 highlightedImage:self.outgoingBubbleImageView.highlightedImage];
    }
    
    return [[UIImageView alloc] initWithImage:self.incomingBubbleImageView.image
                             highlightedImage:self.incomingBubbleImageView.highlightedImage];
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    UIImage *avatarImage = [self.avatars objectForKey:message.sender];
    return [[UIImageView alloc] initWithImage:avatarImage];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show a timestamp for every 3rd message
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
    if ([msg.sender isEqualToString:self.sender]) {
        cell.textView.textColor = [UIColor blackColor];
    }
    else {
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate
#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // for timestamp messages
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
    if ([[currentMessage sender] isEqualToString:self.sender]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage sender] isEqualToString:[currentMessage sender]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
//    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
//    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - Notification Center callbacks

-(void)didReceiveNewMessageWithNotification:(NSNotification *)notification
{
    if ([self.contact.uniqueID isEqualToString:[[notification userInfo] objectForKey:@"uniqueID"]]) {
        NSData *encryptedData = [[notification userInfo] objectForKey:@"encryptedData"];

        NSString *DHKey = [MyCrypto returnDHKeyStringFromKeychainForIdentifier:self.contact.uniqueID];
        
        NSError *decryptionError;
        NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                            withPassword:DHKey
                                                   error:&decryptionError];
        NSDictionary *dictionaryFromDecryptedData;
        if (!decryptionError) {
            dictionaryFromDecryptedData = (NSDictionary *) [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            
            self.contact.totalUnread = 0;
            [self scrollToBottomAnimated:YES];
            
            JSQMessage *newMessage = [[JSQMessage alloc] initWithText:[dictionaryFromDecryptedData objectForKey:@"text"]
                                                               sender:self.contact.firstname
                                                                 date:[dictionaryFromDecryptedData objectForKey:@"sentTime"]];
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            [self.messages addObject:newMessage];
            [self finishReceivingMessage];
        }
    }
}

- (void)didReceivePeerDisconnectedWithNotification:(NSNotification *)notification
{
    NSString *uniqueID = [[notification userInfo] objectForKey:@"uniqueID"];
    
    if ([self.contact.uniqueID isEqualToString:uniqueID]) {
        self.title = [NSString stringWithFormat:@"%@ <Disconnected>", self.title];
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.appDelegate = (appliedHISPAppDelegate *)[[UIApplication sharedApplication] delegate];

    if (self.contact.isActive) {
        self.title = self.contact.firstname;
    } else {
        self.title = [NSString stringWithFormat:@"%@ <Disconnected>", self.contact.firstname];
    }
    self.sender = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [self setupMessages];
    
    self.outgoingBubbleImageView = [JSQMessagesBubbleImageFactory
                                    outgoingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    
    self.incomingBubbleImageView = [JSQMessagesBubbleImageFactory
                                    incomingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleBlueColor]];
}

- (void)setupMessages
{
    CGFloat outgoingDiameter = self.collectionView.collectionViewLayout.outgoingAvatarViewSize.width;
    UIImage *myImage = [JSQMessagesAvatarFactory avatarWithUserInitials:@"ME"
                                                        backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                              textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                   font:[UIFont systemFontOfSize:14.0f]
                                                               diameter:outgoingDiameter];
    
    CGFloat incomingDiameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    UIImage *contactImage = [JSQMessagesAvatarFactory avatarWithImage:[UIImage imageWithData:self.contact.photo]
                                                             diameter:incomingDiameter];
    
    self.avatars = @{ self.sender : myImage,
                      self.contact.firstname : contactImage };
    
    self.messages = [[NSMutableArray alloc] init];
    
    NSString *DHkey = [MyCrypto returnDHKeyStringFromKeychainForIdentifier:self.contact.uniqueID];
    
    NSArray *sortedMessages = [self.contact.messages sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"orderingTime"
                                                                                                               ascending:YES]]];
    for (Message *message in sortedMessages) {
        
        NSError *decryptionError;
        NSData *decryptedData = [RNDecryptor decryptData:message.encryptedData
                                            withPassword:DHkey
                                                   error:&decryptionError];
        NSDictionary *dictionaryFromDecryptedData;
        
        if (decryptionError) {
            NSLog(@"Error decrypting data: %@", [decryptionError localizedDescription]);
        } else {
            dictionaryFromDecryptedData = (NSDictionary *) [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
        }
        
        [self.messages addObject:[[JSQMessage alloc] initWithText:[dictionaryFromDecryptedData objectForKey:@"text"]
                                                           sender:([message.fromMe isEqual:@YES] ? self.sender : self.contact.firstname)
                                                             date:[dictionaryFromDecryptedData objectForKey:@"sentTime"]]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = YES;
    self.contact.totalUnread = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.delegateModal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(closePressed:)];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNewMessageWithNotification:)
                                                 name:MC_DID_RECEIVE_NEW_MESSAGE_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePeerDisconnectedWithNotification:)
                                                 name:MC_DID_RECEIVE_PEER_DISCONNECTED_NOTIFICATION
                                               object:nil];
}

- (void)closePressed:(UIBarButtonItem *)sender
{
    [self.delegateModal didDismissMessagesViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_NEW_MESSAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_PEER_DISCONNECTED_NOTIFICATION object:nil];
    [super viewWillDisappear:animated];
}

@end
