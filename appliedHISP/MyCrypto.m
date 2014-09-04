//
//  MyCrypto.m
//  appliedHISP
//
//  Created by Robert Larkin on 8/28/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "MyCrypto.h"
#import "Constants.h"
#import <CommonCrypto/CommonDigest.h>

@interface MyCrypto ()
@property (strong, nonatomic) NSNumber *dhSecretKeyValue;
@property (strong, nonatomic) NSNumber *dhPublicKeyValue;
@property (strong, nonatomic) NSNumber *generator;
@property (strong, nonatomic) NSNumber *modulus;

@end

@implementation MyCrypto

#pragma mark - Cryptographic Hash Methods

+ (NSString *)sha1HashForData:(NSData *)data
{
    uint8_t sha1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, sha1Digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", sha1Digest[i]];
    }
    
    return result;
}

+ (NSString *)md5HashForData:(NSData *)data
{
    uint8_t digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(data.bytes, data.length, digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return result;
}

#pragma mark - Asymmetric Key Cryptography

static const UInt8 publicKeyIdentifier[] = "uk.ac.ox.publickey\0";
static const UInt8 privateKeyIdentifier[] = "uk.ac.ox.privatekey\0";

+ (void)deleteAsymmetricKeys {
    NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                        length:strlen((const char *)publicKeyIdentifier)];
    NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
                                         length:strlen((const char *)privateKeyIdentifier)];
    
    
	OSStatus sanityCheck = noErr;
	NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
	NSMutableDictionary * queryPrivateKey = [[NSMutableDictionary alloc] init];
	
	// Set the public key query dictionary.
	[queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
	[queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
	[queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	
	// Set the private key query dictionary.
	[queryPrivateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
	[queryPrivateKey setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
	[queryPrivateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	
	// Delete the private key.
	sanityCheck = SecItemDelete((__bridge CFDictionaryRef)queryPrivateKey);
	
	// Delete the public key.
	sanityCheck = SecItemDelete((__bridge CFDictionaryRef)queryPublicKey);
}

+ (BOOL)createPublicPrivateKeyPair
{
    [self deleteAsymmetricKeys];
    
    // taken from Apple Developer docs
    // https://developer.apple.com/library/mac/documentation/security/conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html
    OSStatus status = noErr;
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
    
    NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                        length:strlen((const char *)publicKeyIdentifier)];
    NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
                                         length:strlen((const char *)privateKeyIdentifier)];
    
    SecKeyRef publicKey = NULL;
    SecKeyRef privateKey = NULL;
    
    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithInt:1024] forKey:(__bridge id)kSecAttrKeySizeInBits];
    
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    
    [keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];
    
    status = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
    
    if (status == noErr  && publicKey != NULL && privateKey != NULL) {
        // no longer saving the key here
//        size_t keySize = SecKeyGetBlockSize(publicKey);
//        self.publicKey = [NSData dataWithBytes:publicKey length:keySize];
    } else {
        NSLog(@"Error generating key pair.");
        return NO;
    }
    
    if(publicKey) CFRelease(publicKey);
    if(privateKey) CFRelease(privateKey);
    
    return YES;
}

+ (NSData *)getPublicKeyBits
{
	OSStatus sanityCheck = noErr;
	NSData *publicKeyBits = nil;
    
    NSData *publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                       length:strlen((const char *)publicKeyIdentifier)];
	
	NSMutableDictionary *queryPublicKey = [[NSMutableDictionary alloc] init];
    
	// Set the public key query dictionary.
	[queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
	[queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
	[queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	[queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
    
	// Get the key bits.
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)queryPublicKey, (void *)&publicKeyBits);
    
    
	if (sanityCheck != noErr)
	{
		publicKeyBits = nil;
	}
    
	return publicKeyBits;
}

+ (NSData *)getPublicKeyBitsFromPublicKeyIdentifier:(NSString *)thisPublicKeyIdentifier
{
    OSStatus sanityCheck = noErr;
    NSData *publicKeyBits = nil;
    CFTypeRef pk;
    NSMutableDictionary *queryPublicKey = [[NSMutableDictionary alloc] init];
    
    NSData *publicTag = [thisPublicKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    // Set the public key query dictionary.
    [queryPublicKey setObject:(__bridge_transfer id)kSecClassKey forKey:(__bridge_transfer id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(__bridge_transfer id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge_transfer id)kSecAttrKeyTypeRSA forKey:(__bridge_transfer id)kSecAttrKeyType];
    [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge_transfer id)kSecReturnData];
    
    // Get the key bits.
    sanityCheck = SecItemCopyMatching((__bridge_retained CFDictionaryRef)queryPublicKey, &pk);
    if (sanityCheck != noErr) {
        publicKeyBits = nil;
    } else {
        publicKeyBits = (__bridge_transfer NSData *)pk;
    }
    
    return publicKeyBits;
}

+ (void)removePeerPublicKey:(NSString *)peerName
{
	OSStatus sanityCheck = noErr;
    
	NSData * peerTag = [[NSData alloc] initWithBytes:(const void *)[peerName UTF8String] length:[peerName length]];
	NSMutableDictionary * peerPublicKeyAttr = [[NSMutableDictionary alloc] init];
	
	[peerPublicKeyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
	[peerPublicKeyAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	[peerPublicKeyAttr setObject:peerTag forKey:(__bridge id)kSecAttrApplicationTag];
	
	sanityCheck = SecItemDelete((__bridge CFDictionaryRef) peerPublicKeyAttr);
}

+ (SecKeyRef)getPublicKeyReference:(NSString*)peerName
{
    OSStatus sanityCheck = noErr;
    
    SecKeyRef pubKeyRefData = NULL;
    NSData *peerTag = [[NSData alloc] initWithBytes:(const void *)[peerName UTF8String] length:[peerName length]];
    NSMutableDictionary *peerPublicKeyAttr = [[NSMutableDictionary alloc] init];
    
    [peerPublicKeyAttr setObject:(__bridge_transfer id)kSecClassKey forKey:(__bridge_transfer id)kSecClass];
    [peerPublicKeyAttr setObject:(__bridge_transfer id)kSecAttrKeyTypeRSA forKey:(__bridge_transfer id)kSecAttrKeyType];
    [peerPublicKeyAttr setObject:peerTag forKey:(__bridge_transfer id)kSecAttrApplicationTag];
    [peerPublicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge_transfer id)kSecReturnRef];
    sanityCheck = SecItemCopyMatching((__bridge_retained CFDictionaryRef) peerPublicKeyAttr, (CFTypeRef *)&pubKeyRefData);
    
    if(pubKeyRefData){
        return pubKeyRefData;
    }else{
        return nil;
    }
}

+ (NSArray *)encryptDictionary:(NSDictionary *)dictToEncrypt withKey:(SecKeyRef)key
{
    NSData *dictionaryAsData = [NSKeyedArchiver archivedDataWithRootObject:dictToEncrypt];
    NSString *stringToEncrypt = [dictionaryAsData base64EncodedStringWithOptions:0];
    
    int len = [stringToEncrypt length];
    
    size_t cipherBufferSize = SecKeyGetBlockSize(key);
    
    NSMutableArray *dataToEncrypt = [[NSMutableArray alloc] init];
    
    // sizeof(uint8_t) doesn't work (=1), 12 does, 10 doean't, 11 does...
    int newBlockLength = cipherBufferSize-11; // for ending null char...
    if (len > newBlockLength) {
        // split into blocks
        int n = len/newBlockLength;
        for (int i=0; i<n; i++) {
            [dataToEncrypt addObject:[stringToEncrypt substringWithRange:NSMakeRange(newBlockLength*i, newBlockLength)]];
        }
        if (len%newBlockLength) {
            [dataToEncrypt addObject:[stringToEncrypt substringFromIndex:(len - len%newBlockLength)]];
        }
    } else {
        [dataToEncrypt addObject:stringToEncrypt];
    }
    
    NSMutableArray *encryptedData = [[NSMutableArray alloc] init];
    for (NSString *block in dataToEncrypt) {
        OSStatus status = noErr;
        uint8_t *plainBuffer;
        uint8_t *cipherBuffer;
        const char *cString = [block cStringUsingEncoding:NSUTF8StringEncoding];
        
        int blockLength = [block length];
        plainBuffer = (uint8_t *)calloc(cipherBufferSize, sizeof(uint8_t));
        cipherBuffer = (uint8_t *)calloc(cipherBufferSize, sizeof(uint8_t));
        strncpy( (char *)plainBuffer, cString, blockLength);
        
        size_t plainBufferSize = strlen((char *)plainBuffer);
        
        status = SecKeyEncrypt( key,
                               kSecPaddingPKCS1,
                               &plainBuffer[0],
                               plainBufferSize,
                               &cipherBuffer[0],
                               &cipherBufferSize
                               );
        // on return cipherBuffer will hold data and cipherBufferSize the size of that data
        
        [encryptedData addObject:[NSData dataWithBytes:(const void *)cipherBuffer length:cipherBufferSize]];
        
        free(plainBuffer);
        free(cipherBuffer);
    }
    //  Error handling
    
    if (key) CFRelease(key);
    
    return encryptedData;
}

+ (NSData *)decryptWithPrivateKey:(NSArray *)arrayToDecrypt
{
    OSStatus status = noErr;
    
    SecKeyRef privateKey = NULL;
    
    NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
                                         length:strlen((const char *)privateKeyIdentifier)];
    
    NSMutableDictionary *queryPrivateKey = [[NSMutableDictionary alloc] init];
    
    // Set the private key query dictionary.
    [queryPrivateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPrivateKey setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPrivateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    status = SecItemCopyMatching
    ((__bridge CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKey);
    
    NSString *decryptedString = @"";
    for (NSData *encryptedBlock in arrayToDecrypt) {
        size_t plainBufferSize = SecKeyGetBlockSize(privateKey);
        size_t cipherBufferSize = [encryptedBlock length];
        
        if (plainBufferSize < cipherBufferSize) {
            NSLog(@"Could not decrypt.  Packet too large.");
            return nil;
        }
        
        uint8_t *cipherBuffer = (uint8_t *)[encryptedBlock bytes];
        uint8_t *plainBuffer;
        plainBuffer = (uint8_t *)calloc(plainBufferSize, sizeof(uint8_t));
        
        //  Error handling
        status = SecKeyDecrypt(privateKey,
                               kSecPaddingPKCS1,
                               &cipherBuffer[0],
                               cipherBufferSize,
                               &plainBuffer[0],
                               &plainBufferSize
                               );
        
        decryptedString = [decryptedString stringByAppendingString:[NSString stringWithUTF8String:(char *)plainBuffer]];
        
        free(plainBuffer);
    }
    NSData *decryptedData = [[NSData alloc] initWithBase64EncodedString:decryptedString options:0];
    
    if(privateKey) CFRelease(privateKey);
    
    return decryptedData;
}

+ (NSData *)getPublicKeyExpFromKeyBits:(NSData *)keyBits
{
    NSData* pk = keyBits;
    if (pk == NULL) return NULL;
    
    int iterator = 0;
    
    iterator++; // TYPE - bit stream - mod + exp
    [self derEncodingGetSizeFrom:pk at:&iterator]; // Total size
    
    iterator++; // TYPE - bit stream mod
    int mod_size = [self derEncodingGetSizeFrom:pk at:&iterator];
    iterator += mod_size;
    
    iterator++; // TYPE - bit stream exp
    int exp_size = [self derEncodingGetSizeFrom:pk at:&iterator];
    
    return [pk subdataWithRange:NSMakeRange(iterator, exp_size)];
}

+ (NSData *)getPublicKeyModFromKeyBits:(NSData *)keyBits
{
    NSData* pk = keyBits;
    if (pk == NULL) return NULL;
    
    int iterator = 0;
    
    iterator++; // TYPE - bit stream - mod + exp
    [self derEncodingGetSizeFrom:pk at:&iterator]; // Total size
    
    iterator++; // TYPE - bit stream mod
    int mod_size = [self derEncodingGetSizeFrom:pk at:&iterator];
    
    return [pk subdataWithRange:NSMakeRange(iterator, mod_size)];
}

+ (int)derEncodingGetSizeFrom:(NSData*)buf at:(int*)iterator
{
    const uint8_t* data = [buf bytes];
    int itr = *iterator;
    int num_bytes = 1;
    int ret = 0;
    
    if (data[itr] > 0x80) {
        num_bytes = data[itr] - 0x80;
        itr++;
    }
    
    for (int i = 0 ; i < num_bytes; i++) ret = (ret * 0x100) + data[itr + i];
    
    *iterator = itr + num_bytes;
    return ret;
}

// modified from Apple's CrptoExercise
+ (CFTypeRef)addPeerPublicKey:(NSString *)peerName keyBits:(NSData *)publicKey
{
    [self removePeerPublicKey:peerName];
    
    CFDataRef cfdata = CFDataCreate(NULL, [publicKey bytes], [publicKey length]);
    
	OSStatus sanityCheck = noErr;
	SecKeyRef peerKeyRef = NULL;
	CFTypeRef persistPeer = NULL;
	
	NSData * peerTag = [[NSData alloc] initWithBytes:(const void *)[peerName UTF8String] length:[peerName length]];
	NSMutableDictionary * peerPublicKeyAttr = [[NSMutableDictionary alloc] init];
	
	[peerPublicKeyAttr setObject:(__bridge_transfer id)kSecClassKey forKey:(__bridge_transfer id)kSecClass];
	[peerPublicKeyAttr setObject:(__bridge_transfer id)kSecAttrKeyTypeRSA forKey:(__bridge_transfer id)kSecAttrKeyType];
	[peerPublicKeyAttr setObject:peerTag forKey:(__bridge_transfer id)kSecAttrApplicationTag];
	[peerPublicKeyAttr setObject:(__bridge_transfer id)cfdata forKey:(__bridge_transfer id)kSecValueData];
    [peerPublicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge_transfer id)kSecReturnData];
    
	
	sanityCheck = SecItemAdd((__bridge_retained CFDictionaryRef) peerPublicKeyAttr, (CFTypeRef *)&persistPeer);
	
	if (persistPeer) {
		peerKeyRef = [self getKeyRefWithPersistentKeyRef:persistPeer];
	} else {
		[peerPublicKeyAttr removeObjectForKey:(__bridge_transfer id)kSecValueData];
		[peerPublicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge_transfer id)kSecReturnRef];
		sanityCheck = SecItemCopyMatching((__bridge_retained CFDictionaryRef) peerPublicKeyAttr, (CFTypeRef *)&peerKeyRef);
	}
    
    return persistPeer;
}

// taken from Apple's CryptoExercise
+ (SecKeyRef)getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef {
	OSStatus sanityCheck = noErr;
	SecKeyRef keyRef = NULL;
	
	
	NSMutableDictionary * queryKey = [[NSMutableDictionary alloc] init];
	
	// Set the SecKeyRef query dictionary.
	[queryKey setObject:(__bridge_transfer id)persistentRef forKey:(__bridge_transfer id)kSecValuePersistentRef];
	[queryKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge_transfer id)kSecReturnRef];
	
	// Get the persistent key reference.
	sanityCheck = SecItemCopyMatching((__bridge_retained CFDictionaryRef)queryKey, (CFTypeRef *)&keyRef);
    //	[queryKey release];
	
	return keyRef;
}

#pragma mark - Keychain Methods to save and retrieve stored keys
// created from tutorial at: http://www.raywenderlich.com/6475/basic-security-in-ios-5-tutorial-part-1

+ (BOOL)addDHKeyString:(NSString *)item toKeychainForIdentifier:(NSString *)identifier
{
    return [self createKeychainValue:item forIdentifier:identifier];
}

+ (NSString *)returnDHKeyStringFromKeychainForIdentifier:(NSString *)identifier
{
    return [self keychainStringFromMatchingIdentifier:identifier];
}

+ (void)removeDHKeyStringFromKeychainForIdentifier:(NSString *)identifier
{
    [self deleteItemFromKeychainWithIdentifier:identifier];
}

+ (NSMutableDictionary *)setupSearchDirectoryForIdentifier:(NSString *)identifier {
    
    // Setup dictionary to access keychain.
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    // Specify we are using a password (rather than a certificate, internet password, etc).
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    // Uniquely identify this keychain accessor.
    [searchDictionary setObject:APP_NAME forKey:(__bridge id)kSecAttrService];
    
    // Uniquely identify the account who will be accessing the keychain.
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    
    return searchDictionary;
}

+ (NSData *)searchKeychainCopyMatchingIdentifier:(NSString *)identifier
{
    
    NSMutableDictionary *searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    // Limit search results to one.
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // Specify we want NSData/CFData returned.
    [searchDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    // Search.
    NSData *result = nil;
    CFTypeRef foundDict = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &foundDict);
    
    if (status == noErr) {
        result = (__bridge_transfer NSData *)foundDict;
    } else {
        result = nil;
    }
    
    return result;
}

+ (NSString *)keychainStringFromMatchingIdentifier:(NSString *)identifier
{
    NSData *valueData = [self searchKeychainCopyMatchingIdentifier:identifier];
    if (valueData) {
        NSString *value = [[NSString alloc] initWithData:valueData
                                                encoding:NSUTF8StringEncoding];
        return value;
    } else {
        return nil;
    }
}

+ (BOOL)createKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier
{
    
    NSMutableDictionary *dictionary = [self setupSearchDirectoryForIdentifier:identifier];
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:valueData forKey:(__bridge id)kSecValueData];
    
    // Protect the keychain entry so it's only valid when the device is unlocked.
    [dictionary setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)kSecAttrAccessible];
    
    // Add.
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    
    // If the addition was successful, return. Otherwise, attempt to update existing key or quit (return NO).
    if (status == errSecSuccess) {
        return YES;
    } else if (status == errSecDuplicateItem){
        return [self updateKeychainValue:value forIdentifier:identifier];
    } else {
        return NO;
    }
}

+ (BOOL)updateKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier
{
    
    NSMutableDictionary *searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [updateDictionary setObject:valueData forKey:(__bridge id)kSecValueData];
    
    // Update.
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);
    
    if (status == errSecSuccess) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)deleteItemFromKeychainWithIdentifier:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    CFDictionaryRef dictionary = (__bridge CFDictionaryRef)searchDictionary;
    
    //Delete.
    SecItemDelete(dictionary);
}

# pragma mark - Diffie Hellman
// Diffie Hellman implementation modified from: https://github.com/benjholla/Diffie-Hellman-iOS

// Bigger the number the slower the algorithm
#define MAX_RANDOM_NUMBER 2147483648
#define MAX_PRIME_NUMBER   2147483648

// Linear Feedback Shift Registers
#define LFSR(n)    {if (n&1) n=((n^0x80000055)>>1)|0x80000000; else n>>=1;}

// Rotate32
#define ROT(x, y)  (x=(x<<y)|(x>>(32-y)))

- (NSDictionary *)createDiffieHellmanInfo
{
    NSMutableDictionary *dictToReturn = [[NSMutableDictionary alloc] init];
    
    int generator = [self generatePrimeNumber];
    int modulus = [self generatePrimeNumber];
    
    if (generator > modulus) {
        int swap = generator;
        generator = modulus;
        modulus = swap;
    }
    
    self.generator = @(generator);
    self.modulus = @(modulus);
    
    [dictToReturn setObject:self.generator forKey:@"generator"];
    [dictToReturn setObject:self.modulus forKey:@"modulus"];
    
    [self generateInterimKey];
    
    [dictToReturn setObject:self.dhPublicKeyValue forKey:@"dhPublicKeyValue"];
    
    return dictToReturn;
}

- (void)generateInterimKeyFromDictionary:(NSDictionary *)dhDictionary
{
    self.generator = [dhDictionary objectForKey:@"generator"];
    self.modulus = [dhDictionary objectForKey:@"modulus"];
    
    [self generateInterimKey];
}


- (void)generateInterimKey
{
    self.dhSecretKeyValue = @([self generateRandomNumber] % MAX_RANDOM_NUMBER);
    self.dhPublicKeyValue = @([self powermod:[self.generator intValue] power:[self.dhSecretKeyValue intValue] modulus:[self.modulus intValue]]);
}

- (NSNumber *)computeSharedDHKeyForPublicKey:(NSNumber *)dhPublicKeyValue
{
    return @([self powermod:[dhPublicKeyValue intValue] power:[self.dhSecretKeyValue intValue] modulus:[self.modulus intValue]]);
}

- (NSNumber *)returnDHPublicKey
{
    return self.dhPublicKeyValue;
}

- (NSNumber *)returnDHSecretKey
{
    return self.dhSecretKeyValue;
}

- (void)cleanUpDiffieHellmanInfo
{
    self.dhSecretKeyValue = nil;
    self.dhPublicKeyValue = nil;
    self.generator = nil;
    self.modulus = nil;
}

- (int) generatePrimeNumber
{
	
	int result = [self generateRandomNumber] % MAX_PRIME_NUMBER;
	
	//ensure it is an odd number
	if ((result & 1) == 0) {
		result += 1;
	}
	
	// keep incrementally checking odd numbers until we find
	// an integer of high probablity of primality
	while (true) {
		if([self millerRabinPrimalityTest:result trials:5] == YES){
			//printf("\n%d - PRIME", result);
			return result;
		}
		else {
			//printf("\n%d - COMPOSITE", result);
			result += 2;
		}
	}
}

- (int) generateRandomNumber
{
	return (arc4random() % MAX_RANDOM_NUMBER);
}

- (BOOL) millerRabinPass:(int)a modulus:(int)n
{
	int d = n - 1;
	int s = [self numTrailingZeros:d];
	
	d >>= s;
	int aPow = [self powermod:a power:d modulus:n];
	if (aPow == 1) {
		return YES;
	}
	for (int i = 0; i < s - 1; i++) {
		if (aPow == n - 1) {
			return YES;
		}
		aPow = [self powermod:aPow power:2 modulus:n];
	}
	if (aPow == n - 1) {
		return YES;
	}
	return NO;
}

- (int) numTrailingZeros:(int)n
{
	int tmp = n;
	int result = 0;
	for(int i=0; i<32; i++){
		if((tmp & 1) == 0){
			result++;
			tmp = tmp >> 1;
		} else {
			break;
		}
	}
	return result;
}

- (int) powermod:(int)base power:(int)power modulus:(int)modulus
{
	long long result = 1;
	for (int i = 31; i >= 0; i--) {
		result = (result*result) % modulus;
		if ((power & (1 << i)) != 0) {
			result = (result*base) % modulus;
		}
	}
	return (int)result;
}

// 5 is a reasonably high amount of trials even for large primes
- (BOOL) millerRabinPrimalityTest:(int)n trials:(int)trials
{
	if (n <= 1) {
		return NO;
	}
	else if (n == 2) {
		return YES;
	}
	else if ([self millerRabinPass:2 modulus:n] && (n <= 7 || [self millerRabinPass:7 modulus:n]) && (n <= 61 || [self millerRabinPass:61 modulus:n])) {
		return YES;
	}
	else {
		return NO;
	}
}

@end
