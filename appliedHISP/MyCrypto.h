//
//  MyCrypto.h
//  appliedHISP
//
//  Created by Robert Larkin on 8/28/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyCrypto : NSObject

+ (NSString *)sha1HashForData:(NSData *)data;
+ (NSString *)md5HashForData:(NSData *)data;
- (NSDictionary *)createDiffieHellmanInfo;
- (void)generateInterimKeyFromDictionary:(NSDictionary *)dhDictionary;
- (NSNumber *)computeSharedDHKeyForPublicKey:(NSNumber *)dhPublicKeyValue;
- (NSNumber *)returnDHPublicKey;
- (void)cleanUpDiffieHellmanInfo;
+ (BOOL)createPublicPrivateKeyPair;
+ (NSData *)getPublicKeyBits;
+ (NSData *)getPublicKeyExpFromKeyBits:(NSData *)keyBits;
+ (NSData *)getPublicKeyModFromKeyBits:(NSData *)keyBits;
+ (NSData *)getPublicKeyBitsFromPublicKeyIdentifier:(NSString *)thisPublicKeyIdentifier;
+ (void)removePeerPublicKey:(NSString *)peerName;
+ (CFTypeRef)addPeerPublicKey:(NSString *)peerName keyBits:(NSData *)publicKey;
+ (SecKeyRef)getPublicKeyReference:(NSString*)peerName;
+ (NSArray *)encryptDictionary:(NSDictionary *)dictToEncrypt withKey:(SecKeyRef)key;
+ (NSData *)decryptWithPrivateKey:(NSArray *)arrayToDecrypt;
+ (BOOL)addDHKeyString:(NSString *)item toKeychainForIdentifier:(NSString *)identifier;
+ (NSString *)returnDHKeyStringFromKeychainForIdentifier:(NSString *)identifier;
+ (void)removeDHKeyStringFromKeychainForIdentifier:(NSString *)identifier;

@end
