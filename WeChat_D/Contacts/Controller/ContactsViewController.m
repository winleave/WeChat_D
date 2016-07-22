//
//  ContactsViewController.m
//  WeChat_Djp
//
//  Created by tztddong on 16/7/8.
//  Copyright © 2016年 dongjiangpeng. All rights reserved.
//

#import "ContactsViewController.h"
#import "AddFriendController.h"
#import "ChatDetailViewController.h"
#import "AgreeFriendViewController.h"

#define CellID @"contactTableViewCell"

@interface ContactsViewController ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>
/** 好友列表 */
@property(nonatomic,strong) NSMutableArray *dataArray;
/** 好友列表View */
@property(nonatomic,strong) UITableView *contactTableView;
/** 搜索框 */
@property(nonatomic,strong) UISearchBar *searchBar;
/** 第一组列表 */
@property(nonatomic,strong) NSArray *topDataArray;
/** 新好友请求 */
@property(nonatomic,strong) NSMutableArray *newFriendDataArray;
/** 新好友个数 */
@property(nonatomic,strong)UILabel *friendUnreadLabel;
@end

@implementation ContactsViewController
- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = NO;
    
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
}

- (NSArray *)topDataArray{
    
    if (!_topDataArray) {
        
        _topDataArray = @[@"新的朋友",@"群聊",@"公众号"];
    }
    return _topDataArray;
}

- (NSMutableArray *)dataArray{
    
    if (!_dataArray) {
        
        _dataArray = [NSMutableArray array];
        
    }
    return _dataArray;
}

- (NSMutableArray *)newFriendDataArray{
    
    if (!_newFriendDataArray) {
        _newFriendDataArray = [NSMutableArray array];
    }
    return _newFriendDataArray;
}

- (UILabel *)friendUnreadLabel{
    
    if (!_friendUnreadLabel) {
        _friendUnreadLabel = [[UILabel alloc]initWithFrame:CGRectMake(KWIDTH-KMARGIN-2*KMARGIN, 44/2-KMARGIN, 2*KMARGIN, 2*KMARGIN)];
        _friendUnreadLabel.textAlignment = NSTextAlignmentCenter;
        _friendUnreadLabel.layer.cornerRadius = KMARGIN;
        _friendUnreadLabel.layer.masksToBounds = YES;
        _friendUnreadLabel.backgroundColor = [UIColor redColor];
        _friendUnreadLabel.textColor = [UIColor whiteColor];
        _friendUnreadLabel.font = FONTSIZE(13);
        _friendUnreadLabel.hidden = YES;
    }
    return _friendUnreadLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //添加 加号
    UIBarButtonItem *rightitem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFriend)];
    self.navigationItem.rightBarButtonItem = rightitem;
    
    //搜索框
    UISearchBar *searchBar = [[UISearchBar alloc]init];
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.placeholder = @"搜索";
    searchBar.delegate = self;
    searchBar.layer.cornerRadius = 5;
    searchBar.layer.masksToBounds = YES;
    [self.view addSubview:searchBar];
    self.searchBar = searchBar;
    [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(KNAVHEIGHT);
        make.left.right.offset(0);
        make.height.equalTo(@44);
    }];
    
    self.contactTableView = [[UITableView alloc]init];
    self.contactTableView.delegate = self;
    self.contactTableView.dataSource = self;
    [self.contactTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellID];
    self.contactTableView.tableFooterView = [[UIView alloc]init];
    [self.view addSubview:self.contactTableView];
    [self.contactTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.offset(0);
        make.top.equalTo(self.searchBar.mas_bottom);
    }];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loginChange) name:LOGINCHANGE object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(delectFriend) name:DELECTFRIENDSUEESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(agreenFriendNoti) name:ADDFRIENDSUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(autoLogin) name:AUTOLOGINSUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(newFriendRequest:) name:NEWFRIENDREQUEST object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(newFriendRequestResult) name:NEWFRIENDREQUESTRESULT object:nil];
}

#pragma mark 登陆成功的通知
- (void)loginChange{
    
    [self getContactListFromServer];
}
#pragma mark 删除好友通知
- (void)delectFriend{
    
    [self getContactListFromServer];
}
#pragma mark 添加好友成功 主动添加收到
- (void)agreenFriendNoti{
    
    [self getContactListFromServer];
}
#pragma mark 自动登录成功
- (void)autoLogin{
    
    [self getContactListFromServer];
}
#pragma mark 新好友请求
- (void)newFriendRequest:(NSNotification *)notification{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
    [dict setObject:@0 forKey:@"isAgree"]; //添加一个值判断是都查看 或者是否同意或者拒绝 0未处理 1已同意 2已拒绝
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"NewFriendArray"]];
    [arr addObject:dict];
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:@"NewFriendArray"];
    [self.newFriendDataArray addObject:dict];
    [self getContactListFromServer];
}
#pragma mark 好友请求处理的通知
- (void)newFriendRequestResult{
    [self getContactListFromServer];
}
//添加好友按钮的点击
- (void)addFriend{
    
    AddFriendController *friendCtrl = [[AddFriendController alloc]init];
    self.tabBarController.tabBar.hidden = YES;
    [self.navigationController pushViewController:friendCtrl animated:YES];
}

#pragma mark 代理/数据源
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 1) {
        return self.dataArray.count;
    }
    return self.topDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = [self.topDataArray objectAtIndex:indexPath.row];
            cell.imageView.image = [UIImage imageNamed:@"Tabar_mine"];
            if (indexPath.row == 0) {
                
                [cell.contentView addSubview:self.friendUnreadLabel];
            }
            break;
        case 1:
            cell.textLabel.text = [self.dataArray objectAtIndex:indexPath.row];
            cell.imageView.image = [UIImage imageNamed:@"Tabar_mine"];
            break;
        default:
            break;
    }
    cell.selectionStyle = UITableViewCellAccessoryNone;
    return cell;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (section == 1) {
        return @"好友列表";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 1) {
        return 3*KMARGIN;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 2*KMARGIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            AgreeFriendViewController *agreeCtrl = [[AgreeFriendViewController alloc]init];
            agreeCtrl.dataArray = self.newFriendDataArray;
            [self.navigationController pushViewController:agreeCtrl animated:YES];
        }else{
            return;
        }
    }else if (indexPath.section == 1){
        ChatDetailViewController *chatCtrl = [[ChatDetailViewController alloc]init];
        chatCtrl.title = [self.dataArray objectAtIndex:indexPath.row];
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:chatCtrl animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    [SVProgressHUD show];
    [[EMClient sharedClient].contactManager asyncDeleteContact:[self.dataArray objectAtIndex:indexPath.row] success:^{
        [SVProgressHUD showSuccessWithStatus:@"删除成功"];
        [self.dataArray removeObjectAtIndex:indexPath.row];
        [self.contactTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } failure:^(EMError *aError) {
        [SVProgressHUD showSuccessWithStatus:@"删除失败"];
    }];
    
}
#pragma mark titleForDeleteConfirmationButtonForRowAtIndexPath
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

#pragma mark 从服务器获取好友列表
- (void)getContactListFromServer{
    
    [self.newFriendDataArray removeAllObjects];
    NSArray *arr = [[NSUserDefaults standardUserDefaults] objectForKey:@"NewFriendArray"];
    [self.newFriendDataArray addObjectsFromArray:arr];
    
    NSInteger newFriCount = 0;
    for (NSDictionary *dict in self.newFriendDataArray) {
        if (![[dict objectForKey:@"isAgree"] integerValue]) {
            newFriCount++;
        }
    }
    if (newFriCount) {
        self.friendUnreadLabel.hidden = NO;
        self.friendUnreadLabel.text = [NSString stringWithFormat:@"%zd",newFriCount];
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%zd",newFriCount];
    }else{
        self.friendUnreadLabel.hidden = YES;
        self.tabBarItem.badgeValue = nil;
    }
    [self.dataArray removeAllObjects];
    //从服务器获取所有的好友列表
    [[EMClient sharedClient].contactManager asyncGetContactsFromServer:^(NSArray *aList) {
        [self.dataArray addObjectsFromArray:aList];
        [self.contactTableView reloadData];
    } failure:^(EMError *aError) {
        //若获取失败则从本地获取好友列表
        [self.dataArray addObjectsFromArray:[[EMClient sharedClient].contactManager getContactsFromDB]];
        [self.contactTableView reloadData];
    }];
}

- (void)dealloc{
    //移除通知
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:LOGINCHANGE object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:DELECTFRIENDSUEESS object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:ADDFRIENDSUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AUTOLOGINSUCCESS object:nil];
}
@end
