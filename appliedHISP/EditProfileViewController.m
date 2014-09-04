//
//  EditProfileViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/24/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "EditProfileViewController.h"
#import "Constants.h"
#import "SettingsViewController.h"
#import "MyProfile.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface EditProfileViewController () <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

// set textfield delegate to self in storyboard with ctrl drag
@property (weak, nonatomic) IBOutlet UITextField *firstname;
@property (weak, nonatomic) IBOutlet UITextField *lastname;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSURL *thumbnailURL;
@property (weak, nonatomic) IBOutlet UIButton *takeNewPhotoButton;
@end

@implementation EditProfileViewController

#pragma mark - on-screen keyboard controls

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self.firstname resignFirstResponder];
    [self.lastname resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // stop using the keyboard and make it dissapear on return
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Image and ImagePicker Properties

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (IBAction)newPhoto:(id)sender
{
    UIImagePickerController *uiipc = [[UIImagePickerController alloc] init];
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    uiipc.allowsEditing = YES;
    [self presentViewController:uiipc animated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    self.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

+ (BOOL)canAddPhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
            return YES;
        }
    }
    return NO;
}

# pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadData];
    
    if (![[self class] canAddPhoto]) {
        self.takeNewPhotoButton.userInteractionEnabled = NO;
        self.takeNewPhotoButton.hidden = YES;
    }
}

- (void)loadData
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MyProfile"];
        request.predicate = nil;
        request.sortDescriptors = nil;
        
        NSError *error;
        NSArray *profiles = [self.managedObjectContext executeFetchRequest:request error:&error];

        if ([profiles count]>0) {
            self.savedProfile = [profiles firstObject];
            self.firstname.text = self.savedProfile.firstname;
            self.lastname.text = self.savedProfile.lastname;
            if (self.savedProfile.photo) {
                self.image = [UIImage imageWithData:self.savedProfile.photo];
            } else {
                self.image = [UIImage imageNamed:@"pna.jpg"];
            }
        } else if ([profiles count]==0) {
            self.savedProfile = [NSEntityDescription insertNewObjectForEntityForName:@"MyProfile" inManagedObjectContext:self.managedObjectContext];
            self.image = [UIImage imageNamed: @"pna.jpg"];
        } else {
            NSLog(@"No profiles returned");
        }
    } else {
        NSLog(@"MOC not set for EditProfileViewController");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([self inputIsOK]) {
        [self alert:@"First Name required!"];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)inputIsOK
{
    return ![[self removeLeadingAndTrailingWhitespace:self.firstname.text] length];
}

- (NSString *)removeLeadingAndTrailingWhitespace:(NSString *)string
{
    NSString *pattern = @"(?:^\\s+)|(?:\\s+$)";
    NSError* error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    return [regex stringByReplacingMatchesInString:string
                                           options:NSMatchingReportProgress
                                             range:NSMakeRange(0, [string length])
                                      withTemplate:@"$1"];
}

- (void)alert:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:@"My Profile"
                                message:message
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = sender;
        if ([button.titleLabel.text isEqualToString:@"Save"]) {
            [self saveProfile];
        }
    }

}

- (IBAction)cancel:(id)sender
{
    self.image = nil; // cleans up any temporary file
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:NULL];
}

- (void)saveProfile
{
    self.savedProfile.firstname = [self removeLeadingAndTrailingWhitespace:self.firstname.text];
    self.savedProfile.lastname = [self removeLeadingAndTrailingWhitespace:self.lastname.text];
    self.savedProfile.photo = UIImageJPEGRepresentation(self.image, 100);
}

@end
