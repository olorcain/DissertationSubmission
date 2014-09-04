//
//  RandomNumberViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 8/1/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "RandomNumberViewController.h"

@interface RandomNumberViewController ()

@property (assign, nonatomic) int counter;
@property (assign, nonatomic) unsigned char hashkeyChar;
@property (strong, nonatomic) NSMutableData *hashkeyData;
@property (assign, nonatomic) unsigned char secretkeyChar;
@property (strong, nonatomic) NSMutableData *secretkeyData;
@property (assign, nonatomic) unsigned char kAChar;
@property (strong, nonatomic) NSMutableData *kAData;

@end

@implementation RandomNumberViewController

#define OUTPUT_LENGTH 160

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    [self saveCGPoint:touchPoint];
    
//    NSLog(@"Touches began, x: %f y: %f", touchPoint.x, touchPoint.y);
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    [self saveCGPoint:touchPoint];

//    NSLog(@"Touches moved, x: %f y: %f", touchPoint.x, touchPoint.y);
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    [self saveCGPoint:touchPoint];
    
//    NSLog(@"Touches ended, x: %f y: %f", touchPoint.x, touchPoint.y);
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    [self saveCGPoint:touchPoint];

//    NSLog(@"Touches cancelled, x: %f y: %f", touchPoint.x, touchPoint.y);
}

- (void)saveCGPoint:(CGPoint)point
{
    if (self.isSHCBK && self.counter<OUTPUT_LENGTH/2) {
        self.kAChar = self.kAChar << 1;
        int x = point.x;
        unsigned int lsb_x = x % 2;
        self.kAChar = self.kAChar | lsb_x;
        
        self.kAChar = self.kAChar << 1;
        int y = point.y;
        unsigned int lsb_y = y % 2;
        self.kAChar = self.kAChar | lsb_y;
        
        if ((self.counter+1)%4==0) { // 2 bits processed for every action
            unsigned char array[1] = {self.kAChar};
            [self.kAData appendBytes:array length:sizeof(unsigned char)];
            self.kAChar = 0;
        }
    } else if (self.isSHCBK && self.counter==OUTPUT_LENGTH/2) {
        if (self.isTesting) {
            [self.delegate processReturnedTestingData:self.kAData];
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            [self.delegate processSHCBKkA:self.kAData];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else if (!self.isSHCBK && self.counter<OUTPUT_LENGTH) {
        self.hashkeyChar = self.hashkeyChar << 1;
        int x = point.x;
        unsigned int lsb_x = x % 2;
        self.hashkeyChar = self.hashkeyChar | lsb_x;
        
        self.secretkeyChar = self.secretkeyChar << 1;
        int y = point.y;
        unsigned int lsb_y = y % 2;
        self.secretkeyChar = self.secretkeyChar | lsb_y;
        
        if ((self.counter+1)%8==0) {
            unsigned char array1[1] = {self.hashkeyChar};
            [self.hashkeyData appendBytes:array1 length:sizeof(unsigned char)];
            self.hashkeyChar = 0;
            
            unsigned char array2[1] = {self.secretkeyChar};
            [self.secretkeyData appendBytes:array2 length:sizeof(unsigned char)];
            self.secretkeyChar = 0;
        }
    } else if (!self.isSHCBK && self.counter==OUTPUT_LENGTH) {
        if (self.isTesting) {
            [self.delegate processReturnedTestingData:self.hashkeyData];
            [self.delegate processReturnedTestingData:self.secretkeyData];
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            [self.delegate processGroupHCBKhashKey:self.hashkeyData andSecretKey:self.secretkeyData];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    self.counter++;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.counter = 0;
    
    self.hashkeyChar = 0;
    self.hashkeyData = [[NSMutableData alloc] init];
    
    self.secretkeyChar = 0;
    self.secretkeyData = [[NSMutableData alloc] init];
    
    self.kAChar = 0;
    self.kAData = [[NSMutableData alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
