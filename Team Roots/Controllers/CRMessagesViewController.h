//
//  CRMessagesViewController.h
//  Common Roots
//
//  Created by Spencer Yen on 6/12/15.
//  Copyright (c) 2015 Parameter Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController/JSQMessages.h"
#import "CRCounselor.h"
#import "CRUser.h"
#import "CRConversation.h"
#import "CRConversationManager.h"
#import <BlurImageProcessor/ALDBlurImageProcessor.h>
#import <LayerKit/LayerKit.h>

#import <SDWebImage/UIImageView+WebCache.h>
#import "CRLocalNotificationView.h"

@interface CRMessagesViewController : JSQMessagesViewController <UIActionSheetDelegate, LYRQueryControllerDelegate, CRLocalNotificationViewDelegate>

@property (strong, nonatomic) CRConversation *conversation;
@property (strong, nonatomic) LYRQueryController *queryController;

@property (nonatomic, retain) CRCounselor *selectedCounselor;

@property (copy, nonatomic) NSDictionary *avatars;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end
