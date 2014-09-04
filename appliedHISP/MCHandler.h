//
//  MCHandler.h
//  appliedHISP
//
//  Created by Robert Larkin on 6/9/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <CoreData/CoreData.h>
#import "Contact.h"

@interface MCHandler : NSObject <MCSessionDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName;
-(MCBrowserViewController *)setupMCBrowserForDelegate:(id)delegate andProtocol:(BOOL)useGroupHCBK;
-(void)advertiseSelf:(BOOL)shouldAdvertise forProtocol:(BOOL)useGroupHCBK;
-(void)disconnect;
-(void)disconnectFromUser:(NSString *)displayName;
-(BOOL)sendNewMessage:(NSString *)text forDate:(NSDate *)date toContact:(Contact *)contact;
-(NSString *)getKeyForContact:(Contact *)contact;
-(BOOL)broadcastDataToAllPeers:(NSData *)dataToSend;
-(BOOL)sendToEachPeerDictionary:(NSMutableDictionary *)messageDictionary withDictionaryToEncrypt:(NSDictionary *)dictToEncrypt;

@end
