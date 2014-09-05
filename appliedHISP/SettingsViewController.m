//
//  SettingsViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/14/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "SettingsViewController.h"
#import "Constants.h"
#import "EditProfileViewController.h"
#import "WebInfoViewController.h"
#import "LTHPasscodeViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enablePasscodeSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *changePasscodeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *setTo4DigitCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *setToComplexCell;
@property (weak, nonatomic) IBOutlet UISwitch *enableReadReceiptsSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *changeSecurityProtocolCell;

@end

@implementation SettingsViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellText = [self.tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if ([cellText isEqualToString:self.changePasscodeCell.textLabel.text]) {
        [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
    } else if ([cellText isEqualToString:self.setTo4DigitCell.textLabel.text]) {
        if (![[LTHPasscodeViewController sharedUser] isSimple]) {
            [[LTHPasscodeViewController sharedUser] setIsSimple:NO
                                               inViewController:self
                                                        asModal:YES];
        }
        self.setToComplexCell.accessoryType = UITableViewCellAccessoryNone;
        self.setTo4DigitCell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if ([cellText isEqualToString:self.setToComplexCell.textLabel.text]) {
        if ([[LTHPasscodeViewController sharedUser] isSimple]) {
            [[LTHPasscodeViewController sharedUser] setIsSimple:YES
                                               inViewController:self
                                                        asModal:YES];
        }
        self.setTo4DigitCell.accessoryType = UITableViewCellAccessoryNone;
        self.setToComplexCell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if ([cellText isEqualToString:self.changeSecurityProtocolCell.textLabel.text]) {
        [[[UIAlertView alloc] initWithTitle:@"Change Protocol"
                                    message:@"The default protocol is SHCBK, select protocol to use below. More information is availble in the 'About the security protocol' section."
                                   delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Use SHCBK", @"Use Group HCBK", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    BOOL oldVal = [[NSUserDefaults standardUserDefaults] boolForKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER];
    BOOL valChanged;
    
    if ([title isEqualToString:@"Use SHCBK"])
    {
        valChanged = (oldVal == YES);
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([title isEqualToString:@"Use Group HCBK"])
    {
        valChanged = (oldVal == NO);
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:USE_GROUP_HCBK_DEFAULTS_IDENTIFIER];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (valChanged) {
        NSDictionary *userInfo = @{ @"isSHCBK": !oldVal ? @0 : @1 };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PROTOCOL_DID_CHANGE_NOTICICATION
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
}

- (IBAction)enablePasscodeSwitched:(id)sender
{
    if (self.enablePasscodeSwitch.isOn) {
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self asModal:YES];
    } else {
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self asModal:YES];
    }
}

- (IBAction)enableReadReceiptsSwitched:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:self.enableReadReceiptsSwitch.isOn
                                            forKey:READ_RECEIPTS_ENABLED_DEFAULTS_IDENTIFIER];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.enablePasscodeSwitch setOn:[LTHPasscodeViewController doesPasscodeExist] animated:YES];
    [self.enableReadReceiptsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:READ_RECEIPTS_ENABLED_DEFAULTS_IDENTIFIER]
                                animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(passcodeDidClose:)
                                                 name:PASSCODE_CLOSED_NOTIFICATION
                                               object:nil];
    
    [self resetPasscodeUI];
}

- (void)passcodeDidClose:(NSNotification *)notification;
{
    [self resetPasscodeUI];
}

- (void)resetPasscodeUI
{
    [self.enablePasscodeSwitch setOn:[LTHPasscodeViewController doesPasscodeExist] animated:YES];
    if (self.enablePasscodeSwitch.isOn) {
        [self turnOnCell:self.changePasscodeCell];
        [self turnOnCell:self.setTo4DigitCell];
        [self turnOnCell:self.setToComplexCell];
    } else {
        [self turnOffCell:self.changePasscodeCell];
        [self turnOffCell:self.setTo4DigitCell];
        [self turnOffCell:self.setToComplexCell];
    }
    if ([[LTHPasscodeViewController sharedUser] isSimple]) {
        self.setToComplexCell.accessoryType = UITableViewCellAccessoryNone;
        self.setTo4DigitCell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.setTo4DigitCell.accessoryType = UITableViewCellAccessoryNone;
        self.setToComplexCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)turnOnCell:(UITableViewCell *)cell
{
    cell.userInteractionEnabled = YES;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)turnOffCell:(UITableViewCell *)cell
{
    cell.userInteractionEnabled = NO;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:.4];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:EDIT_PROFILE_SEGUE_IDENTIFIER]) {
        EditProfileViewController *epvc = (EditProfileViewController *)segue.destinationViewController;
        epvc.managedObjectContext = self.managedObjectContext;
    } else if  ([segue.identifier isEqualToString:VIEW_WEB_CONTENT_SEGUE_IDENTIFIER]) {
//        WebInfoViewController *wvic = (WebInfoViewController *)segue.destinationViewController;
    }
}

- (IBAction)profileSaved:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[EditProfileViewController class]]) {
        EditProfileViewController *epvc = (EditProfileViewController *)segue.sourceViewController;
        
        if (epvc) {
            [[NSUserDefaults standardUserDefaults] setBool:[epvc.savedProfile.firstname length] forKey:PROFILE_IS_SET_DEFAULTS_IDENTIFIER];
            if ([epvc.savedProfile.firstname length]) {
                NSDictionary *userInfo = @{@"newProfile": epvc.savedProfile};
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:MYPROFILE_CHANGE_NOTIFICATION
                                                                        object:nil
                                                                      userInfo:userInfo];
                });
            }
        }
    }
}

- (IBAction)returnFromWebContent:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[WebInfoViewController class]]) {
        WebInfoViewController *wvic = (WebInfoViewController *)segue.sourceViewController;
        
        if (wvic) {
            // do something in future, no need now
        }

    }
}

@end
