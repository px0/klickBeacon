//
//  KBMWebViewViewController.m
//  KlickBacon
//
//  Created by Maximilian Gerlach on 3/30/2014.
//  Copyright (c) 2014 Klick. All rights reserved.
//

#import "KBMWebViewViewController.h"

@interface KBMWebViewViewController ()

@end

@implementation KBMWebViewViewController


- (void)dismissViewController
{
	if (![self.presentedViewController isBeingDismissed])
	{
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.webview loadRequest:[NSURLRequest requestWithURL:self.url]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"%@", request);
	
	return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"%@", [error description]);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
