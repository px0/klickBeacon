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
    [self dismissViewControllerAnimated:YES completion:nil];
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
