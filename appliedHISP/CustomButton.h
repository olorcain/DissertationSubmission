//
//  CustomButton.h
//  appliedHISP
//
//  Created by Robert Larkin on 8/30/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//
//  Created from tutorial at: http://www.raywenderlich.com/33330/core-graphics-tutorial-glossy-buttons
//

#import <UIKit/UIKit.h>

@interface CustomButton : UIButton

@property (nonatomic, assign) CGFloat hue;
@property (nonatomic, assign) CGFloat saturation;
@property (nonatomic, assign) CGFloat brightness;

- (void)setColorRed;
- (void)setColorGreen;
- (void)setColorYellow;
- (void)setColorBlue;
- (void)setColorGrey;

@end