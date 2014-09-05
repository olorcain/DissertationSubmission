//
//  WebInfoViewController.m
//  appliedHISP
//
//  Created by Robert Larkin on 5/25/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//

#import "WebInfoViewController.h"

@interface WebInfoViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stop;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *reload;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goForward;
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;

@end

@implementation WebInfoViewController

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
    
    self.webView.scalesPageToFit = YES;
    [self loadPageForString:@"http://www.cs.ox.ac.uk/hcbk/"];
}

- (void)loadPageForString:(NSString *)request
{
    NSURL *url = [NSURL URLWithString:request];
    if(!url.scheme)
    {
        NSString* modifiedURLString = [NSString stringWithFormat:@"http://%@", request];
        url = [NSURL URLWithString:modifiedURLString];
    }
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:urlRequest];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.webView.delegate = nil;
    [self.webView stopLoading];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateTitle:(UIWebView*)webView
{
    self.pageTitle.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];;
}

- (void)updateButtons
{
    self.goForward.enabled = self.webView.canGoForward;
    self.goBack.enabled = self.webView.canGoBack;
    self.stop.enabled = self.webView.loading;
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSString *errorString = [error localizedDescription];
    NSString *errorTitle = [NSString stringWithFormat:@"Error (%d)", error.code];
    UIAlertView *errorView =
    [[UIAlertView alloc] initWithTitle:errorTitle
                               message:errorString delegate:self cancelButtonTitle:nil
                     otherButtonTitles:@"OK", nil];
    [errorView show];
    [self updateButtons];
}

#pragma mark - Web View Delegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self updateButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    [self updateTitle:webView];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

@end
