//
//  Message.h
//  appliedHISP
//
//  Created by Robert Larkin on 9/2/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * fromMe;
@property (nonatomic, retain) NSDate * orderingTime;
@property (nonatomic, retain) NSData * encryptedData;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) Contact *withContact;

@end
