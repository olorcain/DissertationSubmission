//
//  Contact.h
//  appliedHISP
//
//  Created by Robert Larkin on 9/3/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSDate * latestActivity;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSNumber * totalUnread;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSSet *messages;
@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
