//
//  CRFTCounselorViewController.m
//  Team Roots
//
//  Created by Spencer Yen on 11/22/15.
//  Copyright © 2015 Parameter Labs. All rights reserved.
//

#import "CRFTCounselorViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "CRConversationManager.h"
#import "CRConversationsViewController.h"
#import "UIColor+Team_Roots.h"

#define PARSE_COUNSELORS_CLASS_NAME @"User"

@interface CRFTCounselorViewController ()

@property IBOutlet UITableView *counselorsTableView;
@property CRConversation *conversationToLoad;

@end

@implementation CRFTCounselorViewController {
    int numStudentCounselors;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.counselorsTableView.estimatedRowHeight = 100.0;
    self.counselorsTableView.rowHeight = UITableViewAutomaticDimension;
    [self.counselorsTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.counselorsTableView setSeparatorColor:[UIColor colorWithRed:200.0/255.f green:199.0/255.f blue:204.0/255.f alpha:1.f]];
    [self.counselorsTableView setSeparatorInset:UIEdgeInsetsZero];
    
    PFQuery *query = [PFUser query];
    [query orderByAscending:@"isAvailible"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for(int i = 0; i < objects.count; i++){
                [objects[i] objectForKey:@"Name"];
            }
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadObjects];
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        self.parseClassName = PARSE_COUNSELORS_CLASS_NAME;
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
        self.objectsPerPage = 150;
        self.sections = [NSMutableDictionary dictionary];
        self.sectionToTypeMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFUser query];
    
    if (self.pullToRefreshEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query orderByDescending:@"isAvailible"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    return query;
}

- (NSString *)companyForSection:(NSInteger)section {
    return [self.sectionToTypeMap objectForKey:[NSNumber numberWithInt:(int)section]];
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    [self.sections removeAllObjects];
    [self.sectionToTypeMap removeAllObjects];
    
    NSInteger section = 0;
    NSInteger rowIndex = 0;
    int studentCount = 0;
    for (PFObject *object in self.objects) {
        NSString *counselorType = [object objectForKey:@"counselorType"];
        NSMutableArray *objectsInSection = [self.sections objectForKey:counselorType];
        if([counselorType intValue] == 0) {
            studentCount++;
        }
        if (!objectsInSection) {
            objectsInSection = [NSMutableArray array];
            
            // this is the first time we see this type - increment the section index
            [self.sectionToTypeMap setObject:counselorType forKey:[NSNumber numberWithInt:(int)section++]];
        }
        [objectsInSection addObject:[NSNumber numberWithInt:(int)rowIndex++]];
        [self.sections setObject:objectsInSection forKey:counselorType];
    }
    numStudentCounselors = studentCount;
    [self.counselorsTableView reloadData];
}


- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSString *company = [self companyForSection:indexPath.section];
    
    NSArray *rowIndecesInSection = [self.sections objectForKey:company];
    NSNumber *rowIndex = [rowIndecesInSection objectAtIndex:indexPath.row];
    return [self.objects objectAtIndex:[rowIndex intValue]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *company = [self companyForSection:section];
    NSArray *rowIndecesInSection = [self.sections objectForKey:company];
    return rowIndecesInSection.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *company = [self companyForSection:section];
    return company;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
    [view setBackgroundColor:[UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.f]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, tableView.frame.size.width, 18)];
    [label setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:15]];
    [label setTextColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]];
    NSString *company = [self companyForSection:section];
    if([company isEqualToString:@"0"]) {
        [label setText:@"Peer Counselors"];
    } else {
        [label setText:@"School Counselors"];
    }
    [view addSubview:label];
    return view;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    PFObject *selectedObject = [self objectAtIndexPath:indexPath];
#warning  the schoolname is done by the current users school
    CRCounselor *counselor = [[CRCounselor alloc] initWithID:selectedObject.objectId avatarString:[selectedObject objectForKey:@"photoURL"] name:[selectedObject objectForKey:@"name"] bio:[selectedObject objectForKey:@"bio"] schoolID:[selectedObject objectForKey:@"schoolID"] schoolName:[CRAuthenticationManager schoolName]];
    [[CRConversationManager sharedInstance] newConversationWithCounselor:counselor client:[CRConversationManager layerClient] completionBlock:^(CRConversation *conversation, NSError *error) {
        self.conversationToLoad = conversation;
        [self performSegueWithIdentifier:@"ModalConversationsToChat" sender:self];
    }];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *conciergeCellIdentifier = @"CounselorCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:conciergeCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:conciergeCellIdentifier];
    }
    
    UILabel *nameLabel = (UILabel*) [cell viewWithTag:101];
    nameLabel.text = [object objectForKey:@"name"];
    nameLabel.adjustsFontSizeToFitWidth = YES;
    
    UILabel *bioLabel = (UILabel*) [cell viewWithTag:102];
    bioLabel.numberOfLines = 0;
    NSString *bioString = [object objectForKey:@"bio"];
    bioLabel.text = bioString;
    
    UIImageView *avatarImageView = (UIImageView*) [cell viewWithTag:100];
    avatarImageView.clipsToBounds = YES;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2;
    [avatarImageView sd_setImageWithURL:[NSURL URLWithString:[object objectForKey:@"photoURL"]] placeholderImage:[UIImage imageNamed:@"placeholderIcon.png"]];
    
    UILabel *onlineLabel = (UILabel *)[cell viewWithTag:103];
    if([object objectForKey:@"isAvailible"]){
        onlineLabel.text = @"● Offline";
        onlineLabel.textColor = [UIColor redColor];
        //temp removed cause weird bugs
        //        nameLabel.alpha = 0.3;
        //        bioLabel.alpha = 0.3;
        //        avatarImageView.alpha = 0.3;
    } else {
        onlineLabel.text = @"● Online";
        onlineLabel.textColor = [UIColor teamRootsGreen];
    }
    
    return cell;
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ModalConversationsToChat"] && self.conversationToLoad) {
        UINavigationController *navController = [segue destinationViewController];
        if([([navController viewControllers][0]) isKindOfClass:[CRConversationsViewController class]]) {
                CRConversationsViewController *conversationVC = (CRConversationsViewController *)([navController viewControllers][0]);
                conversationVC.receivedConversationToLoad = self.conversationToLoad;
        }
    } else {
#warning  todo error handling
    }
}


@end
