//
//  MCHandler.m
//  appliedHISP
//
//  Created by Robert Larkin on 6/9/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "MCHandler.h"
#import "Constants.h"
#import "Message.h"
#import <Security/SecRandom.h>
#import "MyCrypto.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"

@interface MCHandler ()
@property (nonatomic, strong) MCPeerID *myPeerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCBrowserViewController *browser;
@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;
@end

@implementation MCHandler

- (id)init
{
    self = [super init];
    
    if (self) {
        _myPeerID = nil;
        _session = nil;
        _browser = nil;
        _advertiser = nil;
    }
    
    return self;
}

#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSDictionary *userInfo = @{@"peerID": peerID,
                           @"state" : [NSNumber numberWithInt:state]
                           };
    
    // ensures notification is posted on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_CHANGE_STATE_NOTIFICATION
                                                            object:nil
                                                          userInfo:userInfo];
    });
}


- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *dictionaryFromData = (NSDictionary *) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSNumber *messageType = [dictionaryFromData objectForKey:@"messageType"];

    switch ([messageType intValue])
    {
        case MC_MESSAGE_TYPE_SHCBK_HASH : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_SHCBK_HASH");
            
            NSDictionary *userInfo = @{@"dictionary": dictionaryFromData,
                                       @"peerID": peerID
                                       };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_SHCBK_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            break;
        }
        case MC_MESSAGE_TYPE_SHCBK_KEY : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_SHCBK_KEY");
            
            NSDictionary *userInfo = @{@"dictionary": dictionaryFromData,
                                       @"peerID": peerID
                                       };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_SHCBK_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            break;
        }
        case MC_MESSAGE_TYPE_INITIATOR_BROADCAST : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_INITIATOR_BROADCAST");
            
            NSDictionary *userInfo = @{@"dictionary": dictionaryFromData,
                                       @"peerID": peerID
                                       };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_INITIATOR_BROADCAST_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            break;
        }
        case MC_MESSAGE_TYPE_MEMBER_BROADCAST : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_MEMBER_BROADCAST");
            
            NSDictionary *userInfo = @{@"dictionary": dictionaryFromData,
                                       @"peerID": peerID
                                       };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_MEMBER_BROADCAST_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            break;
        }
        case MC_MESSAGE_TYPE_INITIATOR_INDIVDUAL_ENCRYPTION : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_INITIATOR_INDIVDUAL_ENCRYPTION");
            
            NSDictionary *userInfo = @{@"dictionary": dictionaryFromData,
                                       @"peerID": peerID
                                       };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_INDIVDUALLY_ENCRYPTED_MESSAGE_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            break;
        }
        case MC_MESSAGE_TYPE_NEW_MESSAGE : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_NEW_MESSAGE");
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
            request.predicate = nil;
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"latestActivity"
                                                                      ascending:NO
                                                                       selector:@selector(compare:)]];
            NSError *error;
            NSArray *contacts = [self.managedObjectContext executeFetchRequest:request error:&error];
            
            Contact *thisContact = nil;
            
            if (!error) {
                for (Contact *contact in contacts) {
                    if ([contact.uniqueID isEqualToString:[dictionaryFromData objectForKey:@"uniqueID"]]){
                        thisContact = contact;
                    }
                }
            } else {
                NSLog(@"Error Fetching contacts: %@", [error localizedDescription]);
            }
            
            if (thisContact) {
                NSString *DHkey = [self getKeyForContact:thisContact];
                
                NSData *encryptedData = [dictionaryFromData objectForKey:@"data"];
                
                BOOL found = NO;
                
                for (Message *message in thisContact.messages) {
                    // check if this data has already been recieved, protects against replay attacks
                    if ([message.encryptedData isEqualToData:encryptedData]) {
                        found = YES;
                    }
                }
                
                if (!found) {
                    NSError *decryptionError;
                    NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                                        withPassword:DHkey
                                                               error:&decryptionError];
                    
                    if (!decryptionError) {
                        NSDictionary *dictionaryFromDecryptedData = (NSDictionary *) [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];

                        for (Contact *contact in contacts) {
                            if ([contact.uniqueID isEqualToString:[dictionaryFromDecryptedData objectForKey:@"uniqueID"]]){
                                Message *newMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:self.managedObjectContext];
                                
                                newMessage.encryptedData = encryptedData;
                                newMessage.orderingTime = [NSDate date];
                                newMessage.read = @NO;
                                newMessage.fromMe = @NO;
                                newMessage.withContact = contact;
                                
                                contact.latestActivity = [NSDate date];
                                contact.totalUnread = @([contact.totalUnread intValue] + 1);
                                
                                NSDictionary *userInfo = @{ @"uniqueID": [dictionaryFromDecryptedData objectForKey:@"uniqueID"],
                                                            @"encryptedData": encryptedData };
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_NEW_MESSAGE_NOTIFICATION
                                                                                        object:nil
                                                                                      userInfo:userInfo];
                                });
                                
                                // TODO: +1 to application Badge Count when badges are implemented
                                break;
                            }
                        }
                        

                    

                        
                    } else {
                        NSLog(@"Error decrypting data: %@", [decryptionError localizedDescription]);
                    }
                } else {
                    NSLog(@"This message has already been recieved");
                }
            } else {
                NSLog(@"No contact found mathcing the UID.");
            }
            break;
        }
        case MC_MESSAGE_TYPE_USER_DISCONNECTED : {
            NSLog(@"got message of type: MC_MESSAGE_TYPE_USER_DISCONNECTED");
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
            request.predicate = nil;
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"latestActivity"
                                                                      ascending:NO
                                                                       selector:@selector(compare:)]];
            NSError *error;
            NSArray *contacts = [self.managedObjectContext executeFetchRequest:request error:&error];
            
            if (!error) {
                for (Contact *contact in contacts) {
                    if ([contact.uniqueID isEqualToString:[dictionaryFromData objectForKey:@"uniqueID"]]){
                        contact.isActive = NO;
                    }
                }
            }
            
            NSDictionary *userInfo = @{ @"uniqueID": [dictionaryFromData objectForKey:@"uniqueID"] };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MC_DID_RECEIVE_PEER_DISCONNECTED_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            break;
        }
        case MC_MESSAGE_TYPE_READ_RECEIPT :
            NSLog(@"got message of type: MC_MESSAGE_TYPE_READ_RECEIPT");
            // TODO: implement read reciepts in Settings and in messages UI
            break;
        default :
            NSLog(@"got message of type: unknown message type");
            break;
    }
}


- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    // unused in this application
}


- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    // unused in this application
}


- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    // unused in this application
}

#pragma mark - Network setup methods

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName
{
    self.myPeerID = nil;
    self.session = nil;
    [self.advertiser stop];
    self.advertiser = nil;
    
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    
    self.session = [[MCSession alloc] initWithPeer:self.myPeerID];
    self.session.delegate = self;
}

-(MCBrowserViewController *)setupMCBrowserForDelegate:(id)delegate andProtocol:(BOOL)useGroupHCBK
{
    self.browser = nil;

    if (useGroupHCBK) {
        self.browser = [[MCBrowserViewController alloc] initWithServiceType:MC_NETWORK_SERVICE_TYPE_GROUPHCBK session:self.session];
    } else {
        self.browser = [[MCBrowserViewController alloc] initWithServiceType:MC_NETWORK_SERVICE_TYPE_SHCBK session:self.session];
    }
    
    [self.browser setDelegate:delegate];
    
    return self.browser;
}

-(void)advertiseSelf:(BOOL)shouldAdvertise forProtocol:(BOOL)useGroupHCBK
{
    if (shouldAdvertise) {
        if (useGroupHCBK) {
            self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:MC_NETWORK_SERVICE_TYPE_GROUPHCBK
                                                               discoveryInfo:nil
                                                                     session:self.session];
        } else {
            self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:MC_NETWORK_SERVICE_TYPE_SHCBK
                                                                   discoveryInfo:nil
                                                                         session:self.session];
        }
        [self.advertiser start];
    }
    else{
        [self.advertiser stop];
        self.advertiser = nil;
    }
}

- (void)disconnect
{
    [self.session disconnect];
}

- (void)disconnectFromUser:(NSString *)displayName
{
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] init];
    NSString *uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [messageDictionary setObject:uniqueID forKey:@"uniqueID"];
    [messageDictionary setObject:@MC_MESSAGE_TYPE_USER_DISCONNECTED forKey:@"messageType"];
    
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
    
    NSArray *allPeers = self.session.connectedPeers;
    NSError *error;
    
    NSMutableArray *thisPeerArray = [[NSMutableArray alloc] init];
    
    for (MCPeerID *peer in allPeers) {
        if ([displayName isEqualToString:peer.displayName]) {
            [thisPeerArray addObject: peer];
            break;
        }
    }
    
    if ([thisPeerArray count] > 0) {
        [self.session sendData:dataToSend
                       toPeers:thisPeerArray
                      withMode:MCSessionSendDataReliable
                         error:&error];
        if (error) {
            NSLog(@"Error sending disconnect mesaage: %@", [error localizedDescription]);
        }
    }
}

#pragma mark - Message passing methods

- (BOOL)broadcastDataToAllPeers:(NSData *)dataToSend
{
    NSError *error;
    
    [self.session sendData:dataToSend
                   toPeers:self.session.connectedPeers
                  withMode:MCSessionSendDataReliable
                     error:&error];
    if (error) {
        NSLog(@"Error broadcasting to peers: %@", [error localizedDescription]);
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)sendToEachPeerDictionary:(NSMutableDictionary *)messageDictionary withDictionaryToEncrypt:(NSDictionary *)dictToEncrypt
{
    NSError *error;

    for (MCPeerID *peer in self.session.connectedPeers) {
        SecKeyRef key = [MyCrypto getPublicKeyReference:peer.displayName];
        
        NSArray *encryptedArray = [MyCrypto encryptDictionary:dictToEncrypt withKey:key];
        
        [messageDictionary setObject:encryptedArray forKey:@"group_sk_pkb"];
        
        NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
        
        NSArray *thisPeer = [[NSArray alloc] initWithObjects:peer, nil];
        [self.session sendData:dataToSend
                       toPeers:thisPeer
                      withMode:MCSessionSendDataReliable
                         error:&error];
        if (error) {
            NSLog(@"Error sending to peer, %@: %@", peer.displayName, [error localizedDescription]);
            return NO;
        }
    }
    return YES;
}

- (BOOL)sendNewMessage:(NSString *)text forDate:(NSDate *)date toContact:(Contact *)contact;
{
    NSString *DHkey = [self getKeyForContact:contact];
    
    NSString *uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSMutableDictionary *dictToEncrypt = [[NSMutableDictionary alloc] init];
    [dictToEncrypt setObject:text forKey:@"text"];
    [dictToEncrypt setObject:[NSDate date] forKey:@"sentTime"];
    [dictToEncrypt setObject:uniqueID forKey:@"uniqueID"];
    NSData *dataToEncrypt = [NSKeyedArchiver archivedDataWithRootObject:dictToEncrypt];
    
    NSError *encryptError;
    NSData *encryptedData = [RNEncryptor encryptData:dataToEncrypt
                                        withSettings:kRNCryptorAES256Settings
                                            password:DHkey
                                               error:&encryptError];
    if (encryptError) {
        NSLog(@"Encryption failure: %@", [encryptError localizedDescription]);
        return NO;
    }
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] init];
    [messageDictionary setObject:encryptedData forKey:@"data"];
    [messageDictionary setObject:@MC_MESSAGE_TYPE_NEW_MESSAGE forKey:@"messageType"];
    [messageDictionary setObject:uniqueID forKey:@"uniqueID"];
    
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
    
    BOOL result = NO;
    NSArray *allPeers = self.session.connectedPeers;
    NSMutableArray *thisPeerArray = [[NSMutableArray alloc] init];

    for (MCPeerID *peer in allPeers) {
        if ([contact.displayName isEqualToString:peer.displayName]) {
            [thisPeerArray addObject:peer];
            break;
        }
    }

    if ([thisPeerArray count] > 0) {
        NSError *error;
        [self.session sendData:dataToSend
                       toPeers:thisPeerArray
                      withMode:MCSessionSendDataReliable
                         error:&error];
        if (error) {
            NSLog(@"Error sending new message: %@", [error localizedDescription]);
        } else {
            result = YES;
            
            Message *newMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                                inManagedObjectContext:self.managedObjectContext];
            newMessage.encryptedData = encryptedData;
            newMessage.orderingTime = [NSDate date];
            newMessage.read = nil;
            newMessage.fromMe = @YES;
            newMessage.withContact = contact;
        }
    } else {
        NSLog(@"Message not sent: No matching peers could be found among connected peers");
    }
    
    return result;
}

- (NSString *)getKeyForContact:(Contact *)contact
{
    return [MyCrypto returnDHKeyStringFromKeychainForIdentifier:contact.uniqueID];
}

@end
