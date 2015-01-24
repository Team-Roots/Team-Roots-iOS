//
//  CRCounselorsViewController.m
//  Common Roots
//
//  Created by Spencer Yen on 1/17/15.
//  Copyright (c) 2015 Parameter Labs. All rights reserved.
//

#import "CRCounselorsViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define PARSE_CONCIERGE_CLASS_NAME @"Counselors"

@interface CRCounselorsViewController ()

@end

@implementation CRCounselorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @"Concierge";
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    PFQuery *query = [PFQuery queryWithClassName:@"mentors"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for(int i = 0; i < objects.count; i++){
                [objects[i] objectForKey:@"name"];
                
            }
        } else {
            // Log details of the failure
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
        self.pullToRefreshEnabled = NO;
        self.paginationEnabled = NO;
        self.objectsPerPage = 150;
        self.sections = [NSMutableDictionary dictionary];
        self.sectionToTypeMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:PARSE_CONCIERGE_CLASS_NAME];
    
    // If Pull To Refresh is enabled, query against the network by default.
    if (self.pullToRefreshEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    // Order by type
    [query orderByAscending:@"isAdult"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    return query;
}

- (NSString *)companyForSection:(NSInteger)section {
    return [self.sectionToTypeMap objectForKey:[NSNumber numberWithInt:section]];
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
    
    [self.sections removeAllObjects];
    [self.sectionToTypeMap removeAllObjects];
    
    NSInteger section = 0;
    NSInteger rowIndex = 0;
    for (PFObject *object in self.objects) {
        NSString *counselorType = [object objectForKey:@"counselorType"];
        NSMutableArray *objectsInSection = [self.sections objectForKey:counselorType];
        if (!objectsInSection) {
            objectsInSection = [NSMutableArray array];
            
            // this is the first time we see this company - increment the section index
            [self.sectionToTypeMap setObject:counselorType forKey:[NSNumber numberWithInt:section++]];
        }
        
        [objectsInSection addObject:[NSNumber numberWithInt:rowIndex++]];
        [self.sections setObject:objectsInSection forKey:counselorType];
    }
    [self.tableView reloadData];
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
    return 30.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
    [view setBackgroundColor:[UIColor grayColor]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, tableView.frame.size.width, 18)];
    [label setFont:[UIFont fontWithName:@"OpenSans-Bold" size:16]];
    [label setTextColor:[UIColor whiteColor]];
    NSString *company = [self companyForSection:section];
    [label setText:company];
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    PFObject *selectedObject = [self objectAtIndexPath:indexPath];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *conciergeCellIdentifier = @"ConciergeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:conciergeCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:conciergeCellIdentifier];
    }
    
    UILabel *nameLabel = (UILabel*) [cell viewWithTag:101];
    nameLabel.text = [object objectForKey:@"Name"];
    
    UILabel *bioLabel = (UILabel*) [cell viewWithTag:102];
    NSString *bioString = [object objectForKey:@"Bio"];
    bioLabel.text = bioString;
    
    CGSize constraint = CGSizeMake(self.view.frame.size.width-70, MAXFLOAT);
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[UIFont fontWithName:@"OpenSans" size:15.0] forKey:NSFontAttributeName];
    CGRect textsize = [bioString boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    bioLabel.frame = CGRectMake(57,27,self.view.frame.size.width-70, textsize.size.height);
    [bioLabel sizeToFit];
    
    UIImageView *avatarImageView = (UIImageView*) [cell viewWithTag:100];
    avatarImageView.clipsToBounds = YES;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2;
    [avatarImageView sd_setImageWithURL:[NSURL URLWithString:[object objectForKey:@"Photo_URL"]] placeholderImage:[UIImage imageNamed:@"placeholderIcon.png"]];
    
    return cell;
}

@end