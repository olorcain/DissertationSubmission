//
//  MyProfile.h
//  appliedHISP
//
//  Created by Robert Larkin on 9/2/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MyProfile : NSManagedObject

@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSData * photo;

@end
