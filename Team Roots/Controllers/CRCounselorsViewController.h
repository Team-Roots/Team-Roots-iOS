//
//  CRCounselorsViewController.h
//  Common Roots
//
//  Created by Spencer Yen on 1/17/15.
//  Copyright (c) 2015 Parameter Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "CRConversation.h"
#import "CRCounselor.h"

@protocol CRCounselorsViewControllerDelegate;

@interface CRCounselorsViewController : PFQueryTableViewController 

@property (nonatomic, retain) NSMutableDictionary *sections;
@property (nonatomic, retain) NSMutableDictionary *sectionToTypeMap;
@property (nonatomic, retain) NSMutableDictionary *companies;

@property (nonatomic, weak) id <CRCounselorsViewControllerDelegate> delegate;

@property (nonatomic, retain) CRCounselor *selectedCounselor;

- (IBAction)close:(id)sender;

@end

@protocol CRCounselorsViewControllerDelegate <NSObject>
- (void)counselorsViewControllerDismissedWithConversation:(CRConversation *)conversation;
@end
