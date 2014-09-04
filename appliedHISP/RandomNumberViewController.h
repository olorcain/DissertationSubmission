//
//  RandomNumberViewController.h
//  appliedHISP
//
//  Created by Robert Larkin on 8/1/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RandomNumberDelegate <NSObject>
- (void)processSHCBKkA:(NSData *)kA;
- (void)processGroupHCBKhashKey:(NSData *)hashKey andSecretKey:(NSData *)secretKey;
- (void)processReturnedTestingData:(NSData *)testingData;
@end

@interface RandomNumberViewController : UIViewController

@property id<RandomNumberDelegate>delegate;

@property (nonatomic, assign) BOOL isSHCBK;
@property (assign, nonatomic) BOOL isTesting;

@end
