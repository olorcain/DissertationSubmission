//
//  NewConnectionsViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/28/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "NewConnectionsViewController.h"
#import "Constants.h"
#import "MyProfile.h"
#import "Contact.h"
#import "appliedHISPAppDelegate.h"
#import "CustomButton.h"
#import "Digest32.h"
#import "MyCrypto.h"

@interface NewConnectionsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *visibleSwitch;
@property (weak, nonatomic) IBOutlet UILabel *visibleLabel;
@property (weak, nonatomic) IBOutlet UITableView *connectionsTableView;
@property (weak, nonatomic) IBOutlet CustomButton *disconnectButton;
@property (weak, nonatomic) IBOutlet CustomButton *bigButton;
@property (weak, nonatomic) IBOutlet UILabel *bigButtonLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (strong, nonatomic) appliedHISPAppDelegate *appDelegate;
@property (strong, nonatomic) MyCrypto *myCrypto;
@property (strong, nonatomic) MCBrowserViewController *browser;

@property (strong, nonatomic) NSMutableArray *peersToAdd;
@property (strong, nonatomic) NSString *myDisplayName;
@property (strong, nonatomic) NSMutableArray *connectionsArray;
@property (strong, nonatomic) NSNumber *totalInGroup;
@property (strong, nonatomic) NSNumber *totalReceived;
@property (strong, nonatomic) NSNumber *totalkAReceived;

@property (assign, nonatomic) BOOL protocolIsSHCBK;
@property (strong, nonatomic) NSMutableArray *infos;
@property (assign, nonatomic) BOOL alreadySent;
@property (assign, nonatomic) BOOL isInitiator;
@property (assign, nonatomic) BOOL inSession;

@property (strong, nonatomic) NSData *kA;
@property (strong, nonatomic) NSString *hash_kA;
@property (strong, nonatomic) NSData *hashkey;
@property (strong, nonatomic) NSData *secretkey;
@property (strong, nonatomic) NSString *hash_hashkey;
@property (strong, nonatomic) NSString *hash_secretkey;

@end

@implementation NewConnectionsViewController

- (NSMutableArray *)connectionsArray
{
    if (!_connectionsArray) {
        _connectionsArray = [[NSMutableArray alloc] init];
    }
    return _connectionsArray;
}

- (NSMutableArray *)infos
{
    if (!_infos) {
        _infos = [[NSMutableArray alloc] init];
    }
    return _infos;
}

- (NSMutableArray *)peersToAdd
{
    if (!_peersToAdd) {
        _peersToAdd = [[NSMutableArray alloc] init];
    }
    return _peersToAdd;
}

#pragma mark - UI Actions

- (IBAction)bigButtonPressed:(id)sender
{
    if ([self.bigButton.titleLabel.text isEqualToString:@"Initiate New Session"]) {
        [self initiateNewSession];
    } else if ([self.bigButton.titleLabel.text isEqualToString:@"Send encrypted keys to peers"]) {
        [self.bigButton setEnabled:NO];
        [self sendHashkeyAndEncryptedSecretKey];
    }
}

- (IBAction)toggleAdvertisingForNewSessions:(id)sender
{
    [self.appDelegate.mcHandler advertiseSelf:self.visibleSwitch.isOn
                                  forProtocol:[[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER]];
    if (self.visibleSwitch.isOn) {
        [self.visibleLabel setText:@"You are visible to an initiator.  Would you like to stop broadcasting?"];
        [self.bigButton setTitle:@"Waiting for an initiator..." forState:UIControlStateDisabled];
    } else {
        [self.visibleLabel setText:@"You are NOT visible to an initiator.  Would you like to become visible?"];
        [self.bigButton setTitle:@"Initiate New Session" forState:UIControlStateNormal];
    }
    [self.bigButton setEnabled:!self.visibleSwitch.isOn];
    [[NSUserDefaults standardUserDefaults] setBool:self.visibleSwitch.isOn
                                            forKey:ENABLE_ADVERTISER_DEFAULTS_IDENTIFIER];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)disconnect:(id)sender
{
    [self.appDelegate.mcHandler disconnect];
    [self resetProtocol];
}

- (void)initiateNewSession
{
    [self.bigButton setEnabled:NO];
    self.visibleSwitch.enabled = NO;
    self.isInitiator = YES;
    self.browser = [[self.appDelegate mcHandler] setupMCBrowserForDelegate:self andProtocol:[[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER]];
//    [[[self.appDelegate mcHandler] browser] setDelegate:self];
//    [self presentViewController:[[self.appDelegate mcHandler] browser] animated:YES completion:nil];
    [self presentViewController:self.browser animated:YES completion:nil];
}

#pragma mark - SHCBK

// SHCBK Protocol Notation
// 1. ∀A →N ∀A’ : (A, INFOA, hash(A, kA))
// 2. ∀A →N ∀A’ : (A, kA)
// 3. ∀A →E ∀A’ : digest(k*, INFOS)
//                INFOS is all INFOA
//                k* is XOR of all kA

- (void)broadcastInfosAndHashedkA
{
    self.alreadySent = YES;
    
    [self.bigButton setTitle:@"Waiting on peers..." forState:UIControlStateDisabled];
    [self.bigButton setColorYellow];
    [self.bigButton setEnabled:NO];
    
    if (!self.hash_kA) {
        [self createRandomNumbers];
    }
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] init];
    // move to Constants.h
    [messageDictionary setObject:@MC_MESSAGE_TYPE_SHCBK_HASH forKey:@"messageType"];
    [messageDictionary setObject:[self createContactInfo] forKey:@"contactInfo"];
    if (self.isInitiator) {
        NSDictionary *diffieHellmanDictionary = [self.myCrypto createDiffieHellmanInfo];
        [messageDictionary setObject:diffieHellmanDictionary forKey:@"info"];
        [messageDictionary setObject:@1 forKey:@"isInitiator"];
    } else {
        [messageDictionary setObject:[self.myCrypto returnDHPublicKey] forKey:@"info"];
        [messageDictionary setObject:@0 forKey:@"isInitiator"];
    }
    [messageDictionary setObject:self.hash_kA forKey:@"hash_kA"];
    
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
    
    if ([self.appDelegate.mcHandler broadcastDataToAllPeers:dataToSend]) {
        [self addDictionaryToINFOS:messageDictionary];
        self.statusLabel.text = [NSString stringWithFormat:@"Received info from %@/%@ peers", self.totalReceived, self.totalInGroup];
    } else {
        [self cancelProtocolWithMessage:@"error broadcasting SHCBK hashes"];
    }
    
    // in case where there are only 2 peers and this is 2nd one
    // init >> peer broadcastInfosAndHashedkA
    // peer >> init broadcastInfosAndHashedkA and broadCastkA
    if (self.totalReceived == self.totalInGroup) {
        [self broadcastkA];
    }
}

- (void)broadcastkA
{
    [self.bigButton setTitle:@"Broadcasting key..." forState:UIControlStateDisabled];
    [self.bigButton setColorYellow];
    [self.bigButton setEnabled:NO];
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] init];

    [messageDictionary setObject:@MC_MESSAGE_TYPE_SHCBK_KEY forKey:@"messageType"];
    [messageDictionary setObject:self.kA forKey:@"kA"];
    [messageDictionary setObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"uniqueID"];
    
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
    
    if (![self.appDelegate.mcHandler broadcastDataToAllPeers:dataToSend]) {
        [self cancelProtocolWithMessage:@"error broadcasting SHCBK key"];

    }
}

- (void)shcbkBroadcastRecievedWithNotification:(NSNotification *)notification
{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    
    NSDictionary *receivedDictionary = [[notification userInfo] objectForKey:@"dictionary"];
    
    if ([[receivedDictionary objectForKey:@"messageType"] isEqual:@MC_MESSAGE_TYPE_SHCBK_HASH]) {
        self.totalReceived = @([self.totalReceived intValue] +1);
        self.statusLabel.text = [NSString stringWithFormat:@"Received hashes from %@/%@ peers", self.totalReceived, self.totalInGroup];
        
        [self addDictionaryToINFOS:receivedDictionary];
        
        NSNumber *dhPublicKeyValue;
        
        NSNumber *num = [receivedDictionary objectForKey:@"isInitiator"];
        if ([num isEqualToNumber:@1]) {
            NSDictionary *dhDictionary = [receivedDictionary objectForKey:@"info"];
            [self.myCrypto generateInterimKeyFromDictionary:dhDictionary];
            dhPublicKeyValue = [dhDictionary objectForKey:@"dhPublicKeyValue"];
        } else {
            dhPublicKeyValue = [receivedDictionary objectForKey:@"info"];
        }
        
        NSDictionary *peerContactInfo = [receivedDictionary objectForKey:@"contactInfo"];
        
        NSMutableDictionary *peer = [[NSMutableDictionary alloc] init];
        [peer setObject:peerDisplayName forKey:@"displayName"];
        [peer setObject:[peerContactInfo objectForKey:@"uniqueID"] forKey:@"uniqueID"];
        [peer setObject:[receivedDictionary objectForKey:@"hash_kA"] forKey:@"hash_kA"];
        if ([peerContactInfo objectForKey:@"firstname"]) {
            [peer setObject:[peerContactInfo objectForKey:@"firstname"] forKey:@"firstname"];
        } else {
            [peer setObject:peerDisplayName forKey:@"firstname"];
        }
        if ([peerContactInfo objectForKey:@"lastname"]) {
            [peer setObject:[peerContactInfo objectForKey:@"lastname"] forKey:@"lastname"];
        } else {
            [peer setObject:@"" forKey:@"lastname"];
        }
        if ([peerContactInfo objectForKey:@"photo"]) {
            [peer setObject:[peerContactInfo objectForKey:@"photo"] forKey:@"photo"];
        } else {
            [peer setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"pna.jpg"], 100) forKey:@"photo"];
        }
        [peer setObject:dhPublicKeyValue forKey:@"dhPublicKeyValue"];
        
        [self.peersToAdd addObject:peer];
        
        if (!self.alreadySent) {
            [self createRandomNumbers];
        } else if (self.totalReceived == self.totalInGroup) {
            [self broadcastkA];
        }
    } else { // key broadcast
        self.totalkAReceived = @([self.totalkAReceived intValue] +1);
        
        self.statusLabel.text = [NSString stringWithFormat:@"Received keys from %@/%@ peers", self.totalkAReceived, self.totalInGroup];
        
        for (NSDictionary *peer in self.peersToAdd) {
            if ([[peer objectForKey:@"uniqueID"] isEqualToString:[receivedDictionary objectForKey:@"uniqueID"]]) {
                NSData *kA = [receivedDictionary objectForKey:@"kA"];
                
                NSString *kAString = [MyCrypto sha1HashForData:kA];
                
                if (![kAString isEqualToString:[peer objectForKey:@"hash_kA"]]) {
                    [self cancelProtocolWithMessage:[NSString stringWithFormat:@"Hashes do not match for user: %@", [peer objectForKey:@"displayName"]]];
                } else {
                    [peer setValue:kA forKey:@"kA"];
                    
                    if (self.totalInGroup == self.totalkAReceived) {
                        [self shcbkDigest];
                    }
                }
            }
        }
    }
}

- (void)shcbkDigest
{
    NSData *kStar = self.kA;
    // ^ is XOR in C
    
    for (NSDictionary *peer in self.peersToAdd) {
        NSData *peerkA = [peer objectForKey:@"kA"];
        
        unsigned char* pBytesMykA = (unsigned char*)[kStar bytes];
        unsigned char* pBytesPeerkA   = (unsigned char*)[peerkA bytes];
        unsigned int mykAlen = [kStar length];
        unsigned int peerkAlen = [peerkA length];
        unsigned int k = mykAlen % peerkAlen;
        unsigned char c;
        
        for (int i=0; i < mykAlen; i++) {
            c = pBytesMykA[i] ^ pBytesPeerkA[k];
            pBytesMykA[i] = c;
            
            k = (++k < peerkAlen ? k : 0);
        }
    }
    
    [self computeDigestForKey:kStar];
}

#pragma mark - Group HCBK Protocol

// Group HCBK Protocol Notation
// 1. I  →N ∀B : (I, INFOI, hash(sk), hash(hk))
// 2. ∀B →N ∀A : (B, INFOB, pkB)
// 3. ∀B →E A  : committed
// 4. I  →N ∀B : hk, {G, sk}pkB
// 5. ∀A compare over →E : digest(hk, INFOS)
//               INFOS is INFOI and all INFOA

- (void)broadcastHashedKeys
{
    [self.bigButton setTitle:@"Waiting on peers..." forState:UIControlStateDisabled];
    [self.bigButton setColorYellow];
    [self.bigButton setEnabled:NO];
    
    if (!self.hash_hashkey || !self.hash_secretkey) {
        [self createRandomNumbers];
    }
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] init];
    [messageDictionary setObject:@MC_MESSAGE_TYPE_INITIATOR_BROADCAST forKey:@"messageType"];
    [messageDictionary setObject:[self createContactInfo] forKey:@"contactInfo"];
    [messageDictionary setObject:self.totalInGroup forKey:@"groupSize"];  // should I check that groupSize == connectedPeers?
    [messageDictionary setObject:[self.myCrypto createDiffieHellmanInfo] forKey:@"info"];
    [messageDictionary setObject:self.hash_secretkey forKey:@"hash_sk"];
    [messageDictionary setObject:self.hash_hashkey forKey:@"hash_hk"];
    
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
    
    if ([self.appDelegate.mcHandler broadcastDataToAllPeers:dataToSend]) {
        [self addDictionaryToINFOS:messageDictionary];
        self.statusLabel.text = [NSString stringWithFormat:@"Received info from %@/%@ peers", self.totalReceived, self.totalInGroup];
    } else {
        [self cancelProtocolWithMessage:@"Error broadcasting hashed keys from initiator."];
    }
}

- (NSMutableDictionary *)createContactInfo
{
    NSMutableDictionary *contact = [[NSMutableDictionary alloc] init];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PROFILE_IS_SET_DEFAULTS_IDENTIFIER]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MyProfile"];
        request.predicate = nil;
        request.sortDescriptors = nil;
        
        NSError *error;
        NSArray *profiles = [self.managedObjectContext executeFetchRequest:request error:&error];
        if ([profiles count]>0) {
            MyProfile *myProfile = [profiles firstObject];
            [contact setObject:myProfile.firstname forKey:@"firstname"];
            [contact setObject:myProfile.lastname forKey:@"lastname"];
            [contact setObject:myProfile.photo forKey:@"photo"];
        } else {
            [contact setObject:[[UIDevice currentDevice] name] forKey:@"firstname"];
        }
    } else {
        [contact setObject:[[UIDevice currentDevice] name] forKey:@"firstname"];
    }
    
    NSString *uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [contact setObject:uniqueID forKey:@"uniqueID"];
    
    return contact;
}

- (void)initiatorBroadcastReceivedWithNotification:(NSNotification *)notification
{
    // prevent users from dropping connection while protocol is running
    self.visibleSwitch.enabled = NO;
    
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    
    NSDictionary *receivedDictionary = [[notification userInfo] objectForKey:@"dictionary"];
    
    self.totalInGroup = [receivedDictionary objectForKey:@"groupSize"];
    self.totalReceived = @1; // for the initiator
    
    [self addDictionaryToINFOS:receivedDictionary];
    NSDictionary *dhDictionary = [receivedDictionary objectForKey:@"info"];
    [self.myCrypto generateInterimKeyFromDictionary:dhDictionary];

    self.hash_secretkey = [receivedDictionary objectForKey:@"hash_sk"];
    self.hash_hashkey = [receivedDictionary objectForKey:@"hash_hk"];

    NSDictionary *initatorContactInfo = [receivedDictionary objectForKey:@"contactInfo"];

    NSMutableDictionary *initiator = [[NSMutableDictionary alloc] init];
    [initiator setObject:peerDisplayName forKey:@"displayName"];
    [initiator setObject:[initatorContactInfo objectForKey:@"uniqueID"] forKey:@"uniqueID"];
    if ([initatorContactInfo objectForKey:@"firstname"]) {
        [initiator setObject:[initatorContactInfo objectForKey:@"firstname"] forKey:@"firstname"];
    } else {
        [initiator setObject:peerDisplayName forKey:@"firstname"];
    }
    if ([initatorContactInfo objectForKey:@"lastname"]) {
        [initiator setObject:[initatorContactInfo objectForKey:@"lastname"] forKey:@"lastname"];
    } else {
        [initiator setObject:@"" forKey:@"lastname"];
    }
    if ([initatorContactInfo objectForKey:@"photo"]) {
        [initiator setObject:[initatorContactInfo objectForKey:@"photo"] forKey:@"photo"];
    } else {
        [initiator setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"pna.jpg"], 100) forKey:@"photo"];
    }
    
    [initiator setObject:[dhDictionary objectForKey:@"dhPublicKeyValue"] forKey:@"dhPublicKeyValue"];

    [self.peersToAdd addObject:initiator];
    
    [self.bigButton setTitle:@"Replying with public key..." forState:UIControlStateDisabled];
    [self.bigButton setColorRed];
    [self.bigButton setEnabled:NO];
    
    self.statusLabel.text = [NSString stringWithFormat:@"Received info from %@/%@ peers", self.totalReceived, self.totalInGroup];
    
    [self replyWithPublicKey:nil];
}

- (IBAction)replyWithPublicKey:(id)sender
{
    [self.bigButton setColorYellow];
    [self.bigButton setTitle:@"Waiting for all peers..." forState:UIControlStateDisabled];
    [self.bigButton setEnabled:NO];
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] initWithCapacity:6];
    [messageDictionary setObject:@MC_MESSAGE_TYPE_MEMBER_BROADCAST forKey:@"messageType"];
    [messageDictionary setObject:[self.myCrypto returnDHPublicKey] forKey:@"info"];  // was created when initiatorBroadcastReceived
    [messageDictionary setObject:[self createContactInfo] forKey:@"contactInfo"];
    
    if (![MyCrypto createPublicPrivateKeyPair]) {
        [self cancelProtocolWithMessage:@"Error creaitng asymmetric keys. Canceling protcol."];
    }
    NSData *pk_bits = [MyCrypto getPublicKeyBits];
    [messageDictionary setObject:pk_bits forKey:@"publicKey"];
    
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:messageDictionary];
    
    if ([self.appDelegate.mcHandler broadcastDataToAllPeers:dataToSend]) {
        [self addDictionaryToINFOS:messageDictionary];
    } else {
        [self cancelProtocolWithMessage:@"error with private key reply."];
    }
}

- (void)memberBroadcastReceivedWithNotification:(NSNotification *)notification
{
    self.totalReceived = @(self.totalReceived.intValue + 1);
    self.statusLabel.text = [NSString stringWithFormat:@"Received info from %@/%@ peers", self.totalReceived, self.totalInGroup];
    
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    
    NSDictionary *receivedDictionary = [[notification userInfo] objectForKey:@"dictionary"];
    
    [self addDictionaryToINFOS:receivedDictionary];
    
    NSMutableDictionary *member = [[NSMutableDictionary alloc] init];
    [member setObject:peerDisplayName forKey:@"displayName"];
    NSDictionary *memberContactInfo = [receivedDictionary objectForKey:@"contactInfo"];
    [member setObject:[memberContactInfo objectForKey:@"firstname"] forKey:@"firstname"];
    [member setObject:[memberContactInfo objectForKey:@"uniqueID"] forKey:@"uniqueID"];
    if ([memberContactInfo objectForKey:@"lastname"]) {
        [member setObject:[memberContactInfo objectForKey:@"lastname"] forKey:@"lastname"];
    } else {
        [member setObject:@"" forKey:@"lastname"];
    }
    if ([memberContactInfo objectForKey:@"photo"]) {
        [member setObject:[memberContactInfo objectForKey:@"photo"] forKey:@"photo"];
    } else {
        [member setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"pna.jpg"], 100) forKey:@"photo"];
    }
    
    [member setObject:[receivedDictionary objectForKey:@"info"] forKey:@"dhPublicKeyValue"];

    if (self.isInitiator) {
        // store public keys for next broadcast
        NSData *pk = [receivedDictionary objectForKey:@"publicKey"];
        [member setObject:[MyCrypto addPeerPublicKey:peerDisplayName keyBits:pk] forKey:@"publicKeyRef"];
    }
    
    [self.peersToAdd addObject:member];
    
    if ([self.totalReceived isEqualToNumber:self.totalInGroup]) {
        if (self.isInitiator) {
            [self.bigButtonLabel setText:@"Ensure ALL peers are ready before sending keys."];
            [self.bigButtonLabel setTextColor:[UIColor redColor]];
            [self.bigButton setTitle:@"Send encrypted keys to peers" forState:UIControlStateNormal];
            [self.bigButton setColorGreen];
            [self.bigButton setEnabled:YES];
        } else {
            [self.bigButton setTitle:@"Ensure all peers are ready..." forState:UIControlStateDisabled];
        }
    }
}

- (void)sendHashkeyAndEncryptedSecretKey
{
    [self.bigButtonLabel setText:@""];
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] init];
    [messageDictionary setObject:@MC_MESSAGE_TYPE_INITIATOR_INDIVDUAL_ENCRYPTION forKey:@"messageType"];
    [messageDictionary setObject:self.hashkey forKey:@"hashKey"];
    
    NSMutableDictionary *dictToEncrypt = [[NSMutableDictionary alloc] initWithCapacity:2];
    [dictToEncrypt setObject:[self getPeerGroup] forKey:@"group"];
    [dictToEncrypt setObject:self.secretkey forKey:@"secretKey"];
    
    if ([self.appDelegate.mcHandler sendToEachPeerDictionary:messageDictionary
                                     withDictionaryToEncrypt:dictToEncrypt]) {
        [self groupHCBKDigest];
    } else {
        [self cancelProtocolWithMessage:@"error sending encrypted keys."];
    }
}

- (NSArray *)getPeerGroup
{
    NSMutableArray *unsortedArray = [[NSMutableArray alloc] init];
    [unsortedArray addObject:self.myDisplayName];
    
    for (NSDictionary *peer in self.peersToAdd) {
        [unsortedArray addObject:[peer objectForKey:@"displayName"]];
    }
    
    return [unsortedArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)individuallyEncryptedMessageReceivedWithNotification:(NSNotification *)notification
{
    NSDictionary *receivedDictionary = [[notification userInfo] objectForKey:@"dictionary"];
    
    if ([self groupAndKeysMatchForDictionary:receivedDictionary]) {
        [self groupHCBKDigest];
    } else {
        [self cancelProtocolWithMessage:@"Hash or secret key from initiator does not match."];
    }
}

- (BOOL)groupAndKeysMatchForDictionary:(NSDictionary *)receivedDictionary
{
    BOOL result = NO;
    
    NSData *receivedHashKey = [receivedDictionary objectForKey:@"hashKey"];
    NSString *computedHashkeyString = [MyCrypto sha1HashForData:receivedHashKey];
    
    if (![computedHashkeyString isEqualToString:self.hash_hashkey]) {
        return NO;
    }
    
    NSArray *encryptedArray = [receivedDictionary objectForKey:@"group_sk_pkb"];
    NSData *decryptedData = [MyCrypto decryptWithPrivateKey:encryptedArray];
    NSDictionary *decryptedDictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
    
    NSArray *receivedGroup = [decryptedDictionary objectForKey:@"group"];
    
    if (![receivedGroup isEqualToArray:[self getPeerGroup]]) {
        return NO;
    }
    
    NSData *receivedSecretKey = [decryptedDictionary objectForKey:@"secretKey"];
    NSString *computedSecretkeyString = [MyCrypto sha1HashForData:receivedSecretKey];
    
    if ([computedSecretkeyString isEqualToString:self.hash_secretkey]) {
        self.secretkey = [decryptedDictionary objectForKey:@"secretKey"];
        result = YES;
    }
    return result;
}

- (void)groupHCBKDigest
{
    [self computeDigestForKey:self.secretkey];
}

#pragma mark - Digest methods

- (void)addDictionaryToINFOS:(NSDictionary *)dictionary
{
    for (NSString *key in [dictionary allKeys]) {
        [self.infos addObject:[NSString stringWithFormat:@" %@: %@", key, [dictionary objectForKey:key]]];
        NSLog(@"%@: %@", key, [dictionary objectForKey:key]);
    }
}

- (void)computeDigestForKey:(NSData *)key
{
    NSArray *sortedArray = [self.infos sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *stringToHash = [[sortedArray valueForKey:@"description"] componentsJoinedByString:@""];
    
    // INFOS is hashed before digesting because the digest is much more computationally expensive
    // and no entropy is lost by hashing first to a more manageable size
    NSString *stringToDigest = [MyCrypto sha1HashForData:[stringToHash dataUsingEncoding:NSUTF8StringEncoding]];
    
    const char *input = [stringToDigest UTF8String];
    int len = [stringToDigest length];
    const char *cckey = (const char *)[key bytes];
    
    unsigned int result = digestInputWithKey(input, len, cckey);
    
    NSArray *customDictionary = @[@"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9",
                                  @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H",
                                  @"J", @"K", @"L", @"M", @"N", @"P", @"Q", @"R",
                                  @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z" ];
    
    NSString *output = @"";
    NSString *randomOutput1 = @"";
    NSString *randomOutput2 = @"";
    
    //    bit shift and mask & with all 0's but last 6...
    unsigned int mask = 0x0000001F;
    for (int offset = 5; offset > -1; offset--) {
        unsigned int ch = (result >> (offset*5 + 2)) & mask;
        output = [output stringByAppendingString:[customDictionary objectAtIndex:ch]];
        randomOutput1 = [randomOutput1 stringByAppendingString:[customDictionary objectAtIndex:arc4random_uniform([customDictionary count])]];
        randomOutput2 = [randomOutput2 stringByAppendingString:[customDictionary objectAtIndex:arc4random_uniform([customDictionary count])]];
        if (offset == 3) {
            output = [output stringByAppendingString:@"-"];
            randomOutput1 = [randomOutput1 stringByAppendingString:@"-"];
            randomOutput2 = [randomOutput2 stringByAppendingString:@"-"];
        }
    }
    output = [output stringByAppendingString:@"-"];
    randomOutput1 = [randomOutput1 stringByAppendingString:@"-"];
    randomOutput2 = [randomOutput2 stringByAppendingString:@"-"];
    output = [output stringByAppendingString:[customDictionary objectAtIndex:(result & 0x00000003)]];
    // guarantees last digits are not equal
    int index = arc4random_uniform(14) + 4; // random int between 4 and 17
    randomOutput1 = [randomOutput1 stringByAppendingString:[customDictionary objectAtIndex:index]];
    index = arc4random_uniform(14) + 18; // random int between 18 and 31
    randomOutput2 = [randomOutput2 stringByAppendingString:[customDictionary objectAtIndex:index]];
    
    NSArray *randomSeeeding = @[output, randomOutput1, randomOutput2];
    int randomLocation = arc4random_uniform([randomSeeeding count]);
    
    NSString *firstSelection = randomSeeeding[randomLocation];
    NSString *secondSelection = randomSeeeding[(randomLocation + 1)%[randomSeeeding count]];
    NSString *thirdSelection = randomSeeeding[(randomLocation + 2)%[randomSeeeding count]];
    
    [[[UIAlertView alloc] initWithTitle:output
                                message:@"If the digest above matches ALL of the others, then select it below?"
                               delegate:self
                      cancelButtonTitle:nil
                      otherButtonTitles:firstSelection, secondSelection, thirdSelection, @"Digests do not match", nil] show]; // need to randomize
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:alertView.title]) {
        [self saveNewPeers];
        [self.visibleSwitch setOn:NO animated:YES];
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:ENABLE_ADVERTISER_DEFAULTS_IDENTIFIER];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.appDelegate.mcHandler advertiseSelf:NO forProtocol:[[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER]];
        // would want to create new session here for message passing to handle new connections on top of existing ones...
        [self resetProtocol];
        [self.tabBarController setSelectedIndex:CONTACTS_TAB];
    } else {
        [self.appDelegate.mcHandler disconnect];
        [self resetProtocol];
    }
}

- (void)saveNewPeers
{
    if ([self.peersToAdd count]>0) {
        for (NSDictionary *contact in self.peersToAdd) {
            
            Contact *newContact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.managedObjectContext];
            
            newContact.displayName = [contact valueForKey:@"displayName"];
            newContact.uniqueID = [contact valueForKey:@"uniqueID"];
            newContact.firstname = [contact valueForKey:@"firstname"];
            newContact.lastname = [contact valueForKey:@"lastname"];
            newContact.isActive = @YES;
            newContact.latestActivity = [NSDate date];
            newContact.photo = [contact valueForKey:@"photo"];

            NSNumber *dhPublicKeyValue = [contact valueForKey:@"dhPublicKeyValue"];
            NSNumber *sharedKey = [self.myCrypto computeSharedDHKeyForPublicKey:dhPublicKeyValue];
            
            NSData *data = [[sharedKey stringValue] dataUsingEncoding:NSUTF8StringEncoding];
            
            NSString *output = [MyCrypto md5HashForData:data];

            [MyCrypto addDHKeyString:output toKeychainForIdentifier:newContact.uniqueID];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_CONTACT_ADDED_NOTIFICATION
                                                            object:nil
                                                          userInfo:nil];
    }
}

#pragma mark - Methods to set and reset UI and protocols

- (void)resetProtocol
{
    self.inSession = NO;
    for (NSDictionary *contact in self.peersToAdd) {
        [MyCrypto removePeerPublicKey:[contact valueForKey:@"displayName"]];
    }
    [self.myCrypto cleanUpDiffieHellmanInfo];
    
    [self.peersToAdd removeAllObjects];
    self.totalInGroup = @0;
    self.totalReceived = @0;
    self.totalkAReceived = @0;
    self.statusLabel.text = [NSString stringWithFormat:@"Received info from %@/%@ peers", self.totalReceived, self.totalInGroup];
    [self.infos removeAllObjects];
    self.isInitiator = NO;
    self.hashkey = nil;
    self.secretkey = nil;
    self.kA = nil;
    self.alreadySent = NO;

    [self.bigButtonLabel setText:@""];
    [self.bigButton setColorBlue];
    [self.visibleSwitch setEnabled:YES];
    if (self.visibleSwitch.isOn) {
        [self.visibleLabel setText:@"You are visible to an initiator.  Would you like to stop broadcasting?"];
        [self.bigButton setTitle:@"Waiting for an initiator..." forState:UIControlStateDisabled];
    } else {
        [self.visibleLabel setText:@"You are NOT visible to an initiator.  Would you like to become visible?"];
        [self.bigButton setTitle:@"Initiate New Session" forState:UIControlStateNormal];
    }
    [self.bigButton setEnabled:!self.visibleSwitch.isOn];
    
    [self.appDelegate.mcHandler advertiseSelf:self.visibleSwitch.isOn
                                  forProtocol:[[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER]];
    
    [self.disconnectButton setEnabled:NO];
    
    [self.connectionsArray removeAllObjects];
    [self.connectionsTableView reloadData];
    
    // check if protocol changed while in session...
    if (self.protocolIsSHCBK == [[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER]) {
        self.protocolIsSHCBK = !self.protocolIsSHCBK;
        [self subscribeToNotificationsForProtocol];
    }
}

- (void)cancelProtocol
{
    [self.appDelegate.mcHandler disconnect];
    [self resetProtocol];
}

- (void)cancelProtocolWithMessage:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:@"There was a problem with the protocol:"
                                message:message
                               delegate:self
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
    [self.appDelegate.mcHandler disconnect];
    [self resetProtocol];
}

- (void)subscribeToNotificationsForProtocol
{
    if (self.protocolIsSHCBK) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_INITIATOR_BROADCAST_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_MEMBER_BROADCAST_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_INDIVDUALLY_ENCRYPTED_MESSAGE_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(shcbkBroadcastRecievedWithNotification:)
                                                     name:MC_DID_RECEIVE_SHCBK_NOTIFICATION
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MC_DID_RECEIVE_SHCBK_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(initiatorBroadcastReceivedWithNotification:)
                                                     name:MC_DID_RECEIVE_INITIATOR_BROADCAST_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(memberBroadcastReceivedWithNotification:)
                                                     name:MC_DID_RECEIVE_MEMBER_BROADCAST_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(individuallyEncryptedMessageReceivedWithNotification:)
                                                     name:MC_DID_RECEIVE_INDIVDUALLY_ENCRYPTED_MESSAGE_NOTIFICATION
                                                   object:nil];
    }
}

#pragma mark - MCBrowserViewControllerDelegate Methods

// optional - do if taking multiple sessions to weed out transmitting peers already connected.
//- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
//{
//    
//}

-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [self.browser dismissViewControllerAnimated:YES
                                     completion:^{[self createRandomNumbers];}];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [self.browser dismissViewControllerAnimated:YES completion:nil];
    
    [self resetProtocol];
}

#pragma mark - Random Number Generation

- (void)createRandomNumbers
{
    if (self.protocolIsSHCBK) {
        size_t size = 20;
        //        uint8_t* kABytes = (uint8_t *)calloc(size, sizeof(uint8_t));
        uint8_t* kABytes = malloc(size);
        
        int error = SecRandomCopyBytes (kSecRandomDefault, size, kABytes);
        
        if (!error) {
            NSData *kAdata = [NSData dataWithBytes:(const void *)kABytes length:size];
            [self processSHCBKkA:kAdata];
        } else {
            [self cancelProtocolWithMessage:@"Error creating random number."];
        }
        
        free(kABytes);
        
    } else { // use GroupHCBK
        size_t size = 20;
        uint8_t* hashkeyBytes = malloc(size);
        uint8_t* secretkeyBytes = malloc(size);
        
        int error1 = SecRandomCopyBytes (kSecRandomDefault, size, hashkeyBytes);
        int error2 = SecRandomCopyBytes (kSecRandomDefault, size, secretkeyBytes);
        
        if (!error1 && !error2) {
            NSData *hashkeyData = [NSData dataWithBytes:(const void *)hashkeyBytes length:size];
            NSData *secretkeyData = [NSData dataWithBytes:(const void *)secretkeyBytes length:size];
            [self processGroupHCBKhashKey:hashkeyData andSecretKey:secretkeyData];
        } else {
            [self cancelProtocolWithMessage:@"Error creating random numbers."];
        }
        
        free(hashkeyBytes);
        free(secretkeyBytes);
    }
}

- (void)processSHCBKkA:(NSData *)kA
{
    self.kA = kA;
    self.hash_kA = [MyCrypto sha1HashForData:self.kA];
    
    [self broadcastInfosAndHashedkA];
}

- (void)processGroupHCBKhashKey:(NSData *)hashKey andSecretKey:(NSData *)secretKey
{
    self.hashkey = hashKey;
    self.hash_hashkey = [MyCrypto sha1HashForData:self.hashkey];
    
    self.secretkey = secretKey;
    self.hash_secretkey = [MyCrypto sha1HashForData:self.secretkey];
    
    [self broadcastHashedKeys];
}

#pragma mark - View Controller Lifecylce

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self initialMCNetworkSetup];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // done in storyboard
    //    [self.connectionsTableView setDelegate:self];
    //    [self.connectionsTableView setDataSource:self];
    
    [self.disconnectButton setColorRed];
    [self.bigButton setColorGreen];
    
    [self.visibleSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:ENABLE_ADVERTISER_DEFAULTS_IDENTIFIER] animated:NO];

    self.appDelegate = (appliedHISPAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[self.appDelegate mcHandler] setupPeerAndSessionWithDisplayName:[UIDevice currentDevice].name];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidChangeStateWithNotification:)
                                                 name:MC_DID_CHANGE_STATE_NOTIFICATION
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(protocolDidChangeWithNotification:)
                                                 name:PROTOCOL_DID_CHANGE_NOTICICATION
                                               object:nil];
    
    self.myCrypto = [[MyCrypto alloc] init];
    
    self.protocolIsSHCBK = ![[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER];
    [self subscribeToNotificationsForProtocol];
    
    [self resetProtocol];
}

- (void)peerDidChangeStateWithNotification:(NSNotification *)notification
{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    MCSessionState state = [[[notification userInfo] objectForKey:@"state"] intValue];
    
    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            self.inSession = YES;
            [self.disconnectButton setEnabled:YES];

            [self.connectionsArray addObject:peerDisplayName];
            self.totalInGroup = @([self.connectionsArray count]);
            self.statusLabel.text = [NSString stringWithFormat:@"Total in group: %@", self.totalInGroup];
        
            [self.connectionsTableView reloadData];
        }
        else if (state == MCSessionStateNotConnected) {
            if ([self.connectionsArray count] > 0) {
                NSInteger indexOfPeer = [self.connectionsArray indexOfObject:peerDisplayName];
                if (indexOfPeer != NSNotFound) {
                    // if a peer drops out before protocol is finished, cancel the protocol
                    [self cancelProtocolWithMessage:@"A member dropped out of the protocol before it was finished."];
                }
            }
        }
    }
}

- (void)protocolDidChangeWithNotification:(NSNotification *)notification
{
    if (!self.inSession) {
        NSNumber *num = [[notification userInfo] objectForKey:@"isSHCBK"];
        if (num) {
            self.protocolIsSHCBK = YES;
        } else {
            self.protocolIsSHCBK = NO;
        }
        [self subscribeToNotificationsForProtocol];
    }
}

- (void)initialMCNetworkSetup
{
    NSString *name = @"";
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PROFILE_IS_SET_DEFAULTS_IDENTIFIER]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MyProfile"];
        request.predicate = nil;
        request.sortDescriptors = nil;
        
        NSError *error;
        NSArray *profiles = [self.managedObjectContext executeFetchRequest:request error:&error];
        if ([profiles count]>0) {
            MyProfile *myProfile = [profiles firstObject];
            name = [self getNameFromProfile:myProfile];
        } else {
            name = [[UIDevice currentDevice] name];
        }
    } else {
        name = [[UIDevice currentDevice] name];
    }
    
    [self setupMCNetworkWithDisplayName:name];
    
    // register for any future changes to the displayName
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myProfileDidChangeWithNotification:)
                                                 name:MYPROFILE_CHANGE_NOTIFICATION
                                               object:nil];
}

- (void)myProfileDidChangeWithNotification:(NSNotification *)notification
{
    MyProfile *newProfile = [[notification userInfo] objectForKey:@"newProfile"];
    [self setupMCNetworkWithDisplayName:[self getNameFromProfile:newProfile]];
    if (self.inSession) {
        [self cancelProtocolWithMessage:@"Canceled protocol, my info was changed while protocol was running"];
    }
}

- (NSString *)getNameFromProfile:(MyProfile *)myProfile
{
    if ([myProfile.lastname length]>0) {
        return [NSString stringWithFormat:@"%@ %@", myProfile.firstname, myProfile.lastname];
    } else if ([myProfile.firstname length]>0) {
        return [NSString stringWithFormat:@"%@", myProfile.firstname];
    } else {
        return [[UIDevice currentDevice] name];
    }
}

- (void)setupMCNetworkWithDisplayName:(NSString *)displayName
{
    self.myDisplayName = displayName;
    
    [self.appDelegate.mcHandler setupPeerAndSessionWithDisplayName:displayName];
    [self.appDelegate.mcHandler advertiseSelf:self.visibleSwitch.isOn
                                  forProtocol:[[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.connectionsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    }
    
    cell.textLabel.text = [self.connectionsArray objectAtIndex:indexPath.row];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

// TODO: delete before final release, used to test individual elements in debugging
- (IBAction)tempButtonPressed:(id)sender
{
    NSLog(@"tempButton pressed");

}

@end
