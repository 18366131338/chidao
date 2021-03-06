//
//  MyViewController.m
//  Demo_1
//
//  Created by allen on 14-9-18.
//  Copyright (c) 2014年 itazk. All rights reserved.
//

#import "HisuntechLoginController.h"
#import "HisuntechValidateCheck.h"
#import "HisuntechMixPayViewController.h"
#import "HisuntechUserEntity.h"
#import "iProtect.h"
#import "HisuntechRegisterViewController.h"
#import "HisuntechForgetPasswordViewController.h"
#import "UPPayPlugin.h"
#import "HisunTechTools.h"
#import "HisuntechUIColor+YUColor.h"
#import "HisuntechIdCardViewController.h"
#import "HisuntechIQKeyboardManager.h"


@interface HisuntechLoginController ()<UPPayPluginDelegate,UITextFieldDelegate>
{
    float cellHeight;
    NSMutableArray *userList;
    BOOL frist;
    
    UILabel *_alertLabel;
    UIButton *_unipayBtn;
    
    
    UIView *_bgView;
    //忘记密码的弹框和背景
    UIView *_forgetBGview;
    UIView *_alertViewBg;
    
    BOOL _wasKeyboardManagerEnabled;
    CGRect _frameRect;
}

@property (nonatomic,retain) PasswordTextField *password;
@end
@implementation HisuntechLoginController
@synthesize orderName,customerName,orderSum,phoneNum,password;
@synthesize loginBt,registerBt,saveAccountBt,doneButton;
@synthesize clientOrder,navigationView;
@synthesize publicKey,randomKey;
@synthesize loginTitle;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        
        NSLog(@"%@",[self class]);
        
        NSUserDefaults *users = [NSUserDefaults standardUserDefaults];
        //userList = [users objectForKey:@"users"];
        userList = [NSMutableArray arrayWithArray:[users objectForKey:@"users"]];
        [users synchronize];
        frist = NO;
        cellHeight = 50;
        self.title = @"信联支付";  //设置标题
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.password getLength] > 0) {
        [self.password clear];
        self.password.kbdType = KeyboardTypeLowerCaseLetter;
    }
    
    HisuntechUserEntity *user = [HisuntechUserEntity Instance];
    if (user.UnionPay == YES && frist == NO) {
        [self postDownloadFromUrl];
    }
    
    _wasKeyboardManagerEnabled = [[IQKeyboardManager sharedManager] isEnabled];
    [[IQKeyboardManager sharedManager] setEnable:NO];
    
    

    
    
    
    
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[IQKeyboardManager sharedManager] setEnable:_wasKeyboardManagerEnabled];
}


-(void)createUI
{
    HisuntechUserEntity *user = [HisuntechUserEntity Instance];
    if ([user.ACTION isEqualToString:@"PAY_AGAIN"]) {
        self.money = user.TOTAL_AMOUNT;
    }
    else if([user.ACTION isEqualToString:@"MER_PAY"])
    {
        NSDictionary *tempDic = [NSJSONSerialization JSONObjectWithData:[user.REQ_DATA dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        self.money = [tempDic objectForKey:@"total_amount"];
    }
    
    //创建上面的信联图标
    UIImageView *logoImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
    logoImage.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, 64 +66);
    logoImage.image = [UIImage imageWithContentsOfFile:ResourcePath(@"login_Shandong_Logo.png")];
    logoImage.backgroundColor = [UIColor clearColor];
    [self.view addSubview:logoImage];
    //self.loginTab = [[UITableView alloc]initWithFrame:CGRectMake(10, 132 + 64, [UIScreen mainScreen].bounds.size.width - 20, self.view.frame.size.height - (64 + 80 + 132) + 80) style:UITableViewStylePlain];

    self.loginTab = [[UITableView alloc]initWithFrame:CGRectMake(10, 132 + 64, [UIScreen mainScreen].bounds.size.width - 20, self.view.frame.size.height - (64 + 80 + 132) + 80) style:UITableViewStylePlain];
    self.loginTab.scrollEnabled = NO;
    self.loginTab.delegate = self;
    self.loginTab.dataSource = self;
    self.loginTab.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.loginTab];

}
- (void)backPop{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)loginBtClick:(UIButton *)button
{
    //校验手机号
	BOOL checkPhoneNumMsg = [[[HisuntechValidateCheck alloc]init] checkMdn:self.phoneNum.text];
    if (self.phoneNum.text == nil||[@"" isEqual:self.phoneNum.text]) {
        [self toastResult:@"请输入手机号"];
        return;
    }
    if (checkPhoneNumMsg == NO){
        [self toastResult:@"手机号输入有误"];
        return;
    }
    if (self.password.text == nil ||[@"" isEqual:self.password.text]) {
        [self toastResult:@"请输入登录密码"];
        return;
    }
    if([self.password.text length] < 8 || [self.password.text length] > 16){
        [self toastResult:@"密码长度必须8~16位"];
        return;
    }
    [self getPublicKey];//获取公钥
    [phoneNum resignFirstResponder];
	[password resignFirstResponder];
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithRed:235/255.0 green:241/255.0 blue:245/255.0 alpha:1];
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    [self setLeftItemToBack];
    self.automaticallyAdjustsScrollViewInsets = NO;
    HisuntechUserEntity *user = [HisuntechUserEntity Instance];
    if(user.UnionPay== NO)
    {
        [self createUI];
    }
}


-(void)signIn
{
    HisuntechRegisterViewController *rvc = [[HisuntechRegisterViewController alloc]init];
    [self.navigationController pushViewController:rvc animated:YES];
}

#pragma mark -获取公钥
-(void)getPublicKey{
    //上行参数
    NSDictionary *requestDict = [HisuntechBuildJsonString getPublicKeyJsonString];
    //请求服务器 获取公钥
    [self requestServer:requestDict requestType:APP_CODE_PublicKey codeType:1];
}

#pragma mark -获取随机因子
-(void) getRandomKey{
    //上行参数
    NSDictionary *requestDict = [HisuntechBuildJsonString getRandomKeyJsonString];
    //请求服务器 获取公钥
    [self requestServer:requestDict requestType:APP_CODE_RandomKey codeType:4];
}
#pragma mark -登录
-(void)login{
    //上行参数
    NSDictionary *requestDict = [HisuntechBuildJsonString getLoginJsonString:self.phoneNum.text email:@"" psw:loginPwd];
    //请求服务器 获取公钥
    [self requestServer:requestDict requestType:APP_CODE_UserLogin codeType:9];
}

#pragma mark -请求服务器成功
-(void)resquestSuccess:(id)response{
    NSError *error;
    NSData * dataResponse = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&error];
    NSDictionary *dictJson = [NSJSONSerialization JSONObjectWithData:dataResponse options:NSJSONReadingMutableLeaves error:&error];
    //获取公钥
    if (codeType==1) {
        if ([@"MCA00000" isEqual:[dictJson objectForKey:@"RSP_CD"] ] ) {
            
        
            NSString *newPub = [dictJson objectForKey:@"PUBKEY"];
            [[NSUserDefaults standardUserDefaults]setObject:[dictJson objectForKey:@"PUBKEY"] forKey:@"PUBKEY"];
            NSString *oldPub = [[NSUserDefaults standardUserDefaults]objectForKey:@"PUBKEY"];
            if ([newPub isEqualToString:oldPub]) {
            }else{
                [[NSUserDefaults standardUserDefaults]setObject:[dictJson objectForKey:@"PUBKEY"] forKey:@"PUBKEY"];
                [[NSUserDefaults standardUserDefaults]synchronize];
            }
            [HisuntechUserEntity Instance].pubKey = [dictJson objectForKey:@"PUBKEY"];
            self.password.encryptionPlatformPublicKey = [HisuntechUserEntity Instance].pubKey;

#pragma mark -获取公钥成功之后获取随机因子
            [self getRandomKey];
        }else{
            [self toastResult:[dictJson objectForKey:@"RSP_MSG"]];
        }
        return;
    }
    //获取随机因子
    if (codeType == 4) {
        if ([@"MCA00000" isEqual:[dictJson objectForKey:@"RSP_CD"] ] ) {
            //得到服务器时间之后，进行登录
           
            loginPwd = [self.password getValue:[NSString stringWithFormat:@"%@000",[dictJson objectForKey:@"SYSTM"]]];
            
#pragma mark -获取随机因子成功之后进行登录
            [self login];
        }else{
            [self toastResult:[dictJson objectForKey:@"RSP_MSG"]];
        }
        return;
    }
    //登录
    if (codeType==9) {
        if ([@"MCA00000" isEqual:[dictJson objectForKey:@"RSP_CD"] ] ) {
            
            if (hadLoginBlock) {
                hadLoginBlock(YES);
            }
            
            
            
            NSString *serverTime = [dictJson objectForKey:@"SERTM"];//服务器时间
            NSString *balance = [dictJson objectForKey:@"DRW_BAL"];//账户余额
            NSString *userName = [dictJson objectForKey:@"USRCNM"];//用户真实姓名
            NSString *nowPhoneNum = [dictJson objectForKey:@"MBLNO"];//用户手机号
            NSString *realName = [dictJson objectForKey:@"RELFLG"];//实名认证状态
            [HisuntechUserEntity Instance].userId = self.phoneNum.text;
            [HisuntechUserEntity Instance].userNo = [dictJson objectForKey:@"USRNO"];//用户名
            [HisuntechUserEntity Instance].drwBal = [dictJson objectForKey:@"DRW_BAL"];//账户余额
            [HisuntechUserEntity Instance].userNm = [dictJson objectForKey:@"USRCNM"];//用户真实姓名
            [HisuntechUserEntity Instance].userId = [dictJson objectForKey:@"MBLNO"];//用户手机号
            [HisuntechUserEntity Instance].relFlg = [dictJson objectForKey:@"RELFLG"];//实名认证状态
            NSString *userNo = [dictJson objectForKey:@"USRNO"];//内部用户号
            NSString *changeDate = [dictJson objectForKey:@"MAX_CHARGE_DT"];//资金变动时间
            
            HisuntechMixPayViewController *mixPayViewController = [[HisuntechMixPayViewController alloc] init];
            
            [mixPayViewController judeOtherAccountBack:^(BOOL backBool) {
                if (backBool) {
                    self.phoneNum.text = @"";
                }
            }];
            
            
            mixPayViewController.dic = @{@"SERTM": serverTime,@"DRW_BAL":balance,@"USRCNM":userName,@"MBLNO":nowPhoneNum,@"RELFLG":realName,@"USRNO":userNo,@"MAX_CHARGE_DT":changeDate,@"USRID":self.phoneNum.text};
            
            [self.navigationController pushViewController:mixPayViewController animated:NO];
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
            //[[NSUserDefaults standardUserDefaults] setObject:[UserEntity Instance].userId forKey:currentLoginPhoneNumber];
            [def setObject:[HisuntechUserEntity Instance].userNo forKey:@"USRNO"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            NSDictionary *user = @{@"user":self.phoneNum.text};
            [userList removeAllObjects];
            [userList addObject:user];
            NSUserDefaults *users = [NSUserDefaults standardUserDefaults];
            [users setObject:userList forKey:@"users"];
            [users synchronize];
        }else{
            [self toastResult:[dictJson objectForKey:@"RSP_MSG"]];
        }
        return;
    }
    
    if (codeType == 68) {
//        NSLog(@"下单放回的字典 %@",dictJson);
        if ([[dictJson objectForKey:@"RSP_CD"] isEqualToString:@"MCA00000"]) {
            
            _bankTN = [dictJson objectForKey:@"BANK_TN_NO"];
            
            //调用银联支付
            [UPPayPlugin startPay:_bankTN mode:@"01" viewController:self delegate:self];
            //这里
            frist = YES;
        } else {
            [self toastResult:[dictJson objectForKey:@"RSP_MSG"]];
        }
        return;
    }
}

//#pragma mark 银联支付回调
-(void)UPPayPluginResult:(NSString *)result
{
    [self toastResult:result];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

//判断是否登录过的 回调方法
-(void)judgeTheUserWhetherLoginBlock:(void (^)(BOOL))LoginBlock
{
    hadLoginBlock = LoginBlock;
}




/**
 *  请求服务器失败
 */
-(void)resquestFail:(id)response{
    if (codeType==1||codeType==4||codeType==9) {
        [self toastResult:@"请检查您当前网络"];
        return;
    }
}
/**
 *  触摸隐藏输入法
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [phoneNum resignFirstResponder];
    phoneNum.keyboardType = UIKeyboardTypeNumberPad;
    [password resignFirstResponder];
}
/**
 *  提示框
 *
 *  @param toastMsg 提示内容
 */
-(void)toastResult:(NSString *) toastMsg{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:toastMsg
                          message:nil
                          delegate:self
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil];
    [alert show];
}
#pragma mark 忘记密码
-(void)findPassword
{
//    NSLog(@"忘记密码");

    
    [self createForgetPayPassWordUI];
}

#pragma mark 信联支付界面

- (void)payButton{
    
    [self postDownloadFromUrl];
    
//    NSLog(@"银联支付");
//    //签名的网络请求
//    NSString *param = [self requestReqData];
//    NSString *requestStr = [NSString stringWithFormat:@"%@?srcData=%@",signURL,param];//获取签名
//    NSLog(@"requestStr = %@",requestStr);
//    NSString *string = [requestStr stringByAddingPercentEscapesUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
//    NSURL *url = [NSURL URLWithString:string];
//    NSLog(@"url = %@",url);
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    NSError *error = nil;
//    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
//    NSString *dataStr = [[NSString alloc] initWithData:data encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
//    NSData *requestData =[dataStr dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableLeaves error:nil];
//    
//    
//    if (dict && error == nil) {
//        //进行下单验签
//        _merchantCert = [dict objectForKeyedSubscript:@"merchant_cert"];
//        _signData = [dict objectForKeyedSubscript:@"sign_data"];
//        NSLog(@"签名返回字典%@",dict);
//        [self postDownloadFromUrl];//下单验签
//        
//    }else if (dict == nil && error == nil)
//    {
//        [self alertViewWithStr:@"签名请求成功没有返回值!!!!!!!" andContentStr:nil];
//    }else if (error)
//    {
//        [self alertViewWithStr:@"请求失败" andContentStr:[NSString stringWithFormat:@"%@",error]];
//    }
}





//MARK:下单验签
- (void)postDownloadFromUrl {
    
    NSString *data = [HisuntechUserEntity Instance].REQ_DATA;
    NSString *cert = [HisuntechUserEntity Instance].REQ_CERT;
    NSString *sign = [HisuntechUserEntity Instance].REQ_SIGN;
    NSString *chaert = [HisuntechUserEntity Instance].CHARSET;
    NSString *signType = [HisuntechUserEntity Instance].SIGN_TYPE;
    
    //上行参数
    NSDictionary *requestDict = [HisuntechBuildJsonString getBankPayWithCharset:chaert req_data:data req_cert:cert req_sign:sign sign_type:signType];
//    NSLog(@"下单上传参数 requestDict = %@",requestDict);
    [self requestServer:requestDict requestType:APP_CODE_MakeOrder codeType:68];
}

//MARK:拼接字典
- (NSDictionary *)buildMessage:(NSArray *)Key value:(NSArray *)Value
{
    if (Key == nil||([Key count] == 0)) {
        return nil;
    }
    NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
    
    if(Key != nil){
        for (int i=0;i<[Key count];i++ ) {
            [tmp setValue:[Value objectAtIndex:i] forKey:[Key objectAtIndex:i]];
            
        }
    }
    
    return tmp;
}

#pragma mark 账户选择响应事件
-(void)chooseUser:(UIButton*)btn
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    cellHeight= 50;
    [self.loginTab reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    self.openBtn.selected = NO;
    
    self.phoneNum.text = [userList[btn.tag] objectForKey:@"user"];
    self.password.text = [userList[btn.tag] objectForKey:@"password"];
}

#pragma mark 打开抽屉
-(void)openUserLists
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    self.openBtn.selected = !self.openBtn.selected;
//    NSLog(@"%d",self.openBtn.selected);
    if (self.openBtn.selected) {
        cellHeight = 50 + userList.count *50;
        [self.loginTab reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.openBtn.selected = YES;
    }
    else
    {
        cellHeight= 50;
        [self.loginTab reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.openBtn.selected = NO;
    }
}

#pragma mark tableView代理
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == 2) {
        return self.view.frame.size.height - (64 + 80 + 132);
    }
    else
    return 40;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loginCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"loginCell"];
    }
    for (id temp in cell.contentView.subviews) {
        [temp removeFromSuperview];
    }
    
    if (indexPath.row == 0) {
        cell.tag = 10;
        cell.layer.borderColor = [UIColor grayColor].CGColor;
        cell.layer.borderWidth = 1;
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(42, 10, 0.5, 20)];
        line.backgroundColor = [UIColor grayColor];
        [cell.contentView addSubview:line];
        
        UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, 15, 20)];
        icon.center = CGPointMake(20, 20);
        icon.contentMode = UIViewContentModeScaleAspectFill;
        NSString * imagePath = ResourcePath(@"Login_UserName_btn.png") ;
        icon.image = [UIImage imageWithContentsOfFile:imagePath];
        [cell.contentView addSubview:icon];
        
        self.phoneNum = [[UITextField alloc]initWithFrame:CGRectMake(55, 4, [UIScreen mainScreen].bounds.size.width - 110,30)];
        self.phoneNum.backgroundColor = [UIColor whiteColor];
        self.phoneNum.delegate = self;
        self.phoneNum.placeholder = @"请输入登录账号";
        if (userList.count) {
            
            //如果 通过 其他账户过来的 需要清空 用户名
            if (self.clearUserNameBool) {
                self.phoneNum.text = @"";
            }else
            {
                self.phoneNum.text = [userList[userList.count -1] objectForKey:@"user"];
            }
            
        }
        self.phoneNum.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.phoneNum.keyboardType = UIKeyboardTypeNumberPad;
        [cell.contentView addSubview:self.phoneNum];
        
        
        //去掉 输入登录账号位置下拉显示去掉
        self.openBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.openBtn.frame = CGRectMake(0, 0, 14, 8);
        self.openBtn.center = CGPointMake(280, 20);
        imagePath = ResourcePath(@"pull_down_btn.png");
        [self.openBtn setBackgroundImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = ResourcePath(@"pull_up_btn.png");
        [self.openBtn setBackgroundImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        [self.openBtn addTarget:self action:@selector(openUserLists) forControlEvents:UIControlEventTouchUpInside];
//        [cell.contentView addSubview:self.openBtn];
        for (int i = 0; i< userList.count; i++) {
            UILabel *userLab = [[UILabel alloc]initWithFrame: CGRectMake(55, 50+i, 220, 50)];
            userLab.textColor =[UIColor colorWithRed:0.741 green:0.738 blue:0.785 alpha:1.000];
            userLab.text =[userList[i] objectForKey:@"user"];
            
            UIButton *btn = [UIButton
                              buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(55, 50+i, 220, 40);
            [btn addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = i;
            [cell.contentView addSubview:userLab];
            [cell.contentView addSubview:btn];
        }
    }
    if (indexPath.row == 1) {
        
        cell.tag = 11;
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(42, 10, 0.5, 20)];
        line.backgroundColor = [UIColor grayColor];
        [cell.contentView addSubview:line];
        
        cell.layer.borderColor = [UIColor grayColor].CGColor;
        cell.layer.borderWidth = 1;
        
        UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, 15, 20)];
        icon.center =CGPointMake(20, 20);
        icon.contentMode = UIViewContentModeScaleAspectFill;
        NSString * imagePath = ResourcePath(@"Login_Password_btn.png") ;
        icon.image = [UIImage imageWithContentsOfFile:imagePath];
        [cell.contentView addSubview:icon];
        
        self.password = [[PasswordTextField alloc]initWithFrame:CGRectMake(55, 0,[UIScreen mainScreen].bounds.size.width - 110, 38) usingPasswordKeyboard:YES];
        self.password.backgroundColor = [UIColor whiteColor];
        self.password.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.password.kbdRandom = YES;
        self.password.delegate = self;
        self.password.encryptType = E_SDHS_DUAL_PLATFORM;
        self.password.accepts = @"^(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z]+$";
        self.password.placeholder = @"请输入密码";
        [cell.contentView addSubview:self.password];
    
    }
    if (indexPath.row == 2) {
        cell.backgroundColor =[UIColor colorWithRed:235/255.0 green:241/255.0 blue:245/255.0 alpha:1];
        UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        loginBtn.frame = CGRectMake(0, 80, 300, 40);
        [loginBtn setBackgroundColor: [UIColor colorWithHexString:@"#41b880" withAlpha:1]];
        [loginBtn setTitle:@"用户登录" forState:UIControlStateNormal];
        loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        loginBtn.layer.cornerRadius = 6;
        loginBtn.clipsToBounds = YES;
        [loginBtn addTarget:self action:@selector(loginBtClick:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:loginBtn];
        
        //64 165 231
        UILabel *find = [[UILabel alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - (110), 40, 110, 40)];
        find.userInteractionEnabled = YES;
        find.textColor = [UIColor blackColor];
        find.text = @"忘记密码?";
        find.font = [UIFont boldSystemFontOfSize:17];
        [cell.contentView addSubview:find];
        
        UILabel *payLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 40, 110, 40)];
        payLabel.userInteractionEnabled = YES;
        payLabel.textColor = [UIColor colorWithRed:64/255.0 green:165/255.0 blue:231/255.0 alpha:1];
        NSDictionary *dicOne = @{NSUnderlineStyleAttributeName:@1,NSForegroundColorAttributeName:[UIColor colorWithRed:0/255.0 green:172/255.0 blue:131/255.0 alpha:1],NSFontAttributeName:[UIFont boldSystemFontOfSize:17]};
        
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:@"手机快速注册" attributes:dicOne];
        payLabel.attributedText = attString;
        payLabel.textAlignment = NSTextAlignmentLeft;
        [cell.contentView addSubview:payLabel];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(signIn)];
        [payLabel addGestureRecognizer:tap];
        
        
        UIButton *findPassword = [UIButton buttonWithType:UIButtonTypeSystem];
        findPassword.frame = CGRectMake(200, 40, 110, 40);
        [findPassword addTarget:self action:@selector(findPassword) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:findPassword];
        
        HisuntechUserEntity *user = [HisuntechUserEntity Instance];
        
        _alertLabel  = [[UILabel alloc] initWithFrame:CGRectMake(10, 125, [UIScreen mainScreen].bounds.size.width - 20, 30)];
        
        if (user.Mixture) {
            _alertLabel.hidden = NO;
        }else
        {
            _alertLabel.hidden = YES;
        }
        
        _alertLabel.textColor = [UIColor lightGrayColor];
        _alertLabel.text = @"若您没有信联账号,请选择";
        [cell.contentView addSubview:_alertLabel];
        
        _unipayBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _unipayBtn.frame = CGRectMake(0, 160,300, 40);
        
        if (user.Mixture) {
            _unipayBtn.hidden = NO;
        }else
        {
            _unipayBtn.hidden = YES;
        }
        _unipayBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [_unipayBtn setTitle:@"银行卡支付" forState:UIControlStateNormal];
        [_unipayBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_unipayBtn setBackgroundColor:[UIColor colorWithHexString:@"#41b880" withAlpha:1]];
        _unipayBtn.layer.cornerRadius = 6;
        _unipayBtn.clipsToBounds = YES;
        [_unipayBtn addTarget:self action:@selector(unipayClick) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:_unipayBtn];
    }
    cell.clipsToBounds = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
-(void)unipayClick
{
    [self postDownloadFromUrl];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    
   
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        [UIView animateWithDuration:0.3f animations:^{
            _frameRect = self.view.frame;
            self.view.frame =CGRectMake(0, -70, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }];
    }
    
    
    
    UIView *cell =textField.superview;
    UIView *fatherCell = cell.superview;
    fatherCell.layer.borderWidth = 1;
    fatherCell.layer.borderColor = [UIColor colorWithHexString:@"#41b886" withAlpha:1].CGColor;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
     if ([UIScreen mainScreen].bounds.size.height == 480) {
         [UIView animateWithDuration:0.3f animations:^{
             self.view.frame = _frameRect;
         }];
     }
    
    UIView *cell =textField.superview;
    UIView *fatherCell = cell.superview;
    fatherCell.layer.borderWidth = 1;
    fatherCell.layer.borderColor = [UIColor grayColor].CGColor;
    
    if ([textField isKindOfClass:[self.password class]]) {
        
        if (self.password.verify != 0) {
            [self toastResult:@"请输入由字母数字组成的密码！"];
            [self.password clear];
            return;
        }
        
    }
}



- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand(time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}



-(void)createForgetPayPassWordUI
{
                //选择重置密码的方式
                [UIView animateWithDuration:0.3f animations:^{
    
                    if (_forgetBGview) {
                        [_forgetBGview removeFromSuperview];
                    }
                    
                    if (_alertViewBg) {
                        [_alertViewBg removeFromSuperview];
                    }
                    
                    //背景实例化
                    _forgetBGview = [[UIView alloc] initWithFrame:self.view.bounds];
                    _forgetBGview.backgroundColor = [UIColor grayColor];
                    _forgetBGview.alpha=0.8;
                    
                    [self.view addSubview:_forgetBGview];
                    
                    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(BGTapCLick)];
                    [_forgetBGview addGestureRecognizer:tap];
                    
                    //弹框背景 Ipout_frame_Gray
                    _alertViewBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250,120)];
                    _alertViewBg.backgroundColor = [UIColor whiteColor];
                    _alertViewBg.userInteractionEnabled = YES;
                    _alertViewBg.layer.cornerRadius = 5;
                    _alertViewBg.clipsToBounds = YES;
                    _alertViewBg.center = CGPointMake(_forgetBGview.bounds.size.width/2, _forgetBGview.bounds.size.height/2);
                    [self.view addSubview:_alertViewBg];
                    
                    //创建上面的提示
                    UILabel *titleLabel =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, _alertViewBg.frame.size.width - 20, 40)];
                    titleLabel.textAlignment = NSTextAlignmentCenter;
                    titleLabel.font = [UIFont boldSystemFontOfSize:16];
                    titleLabel.adjustsFontSizeToFitWidth = YES;
                    titleLabel.text = @"选择重置密码方式";
                    titleLabel.shadowColor = [UIColor blackColor];
                    titleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
                    titleLabel.textColor = [UIColor grayColor];
                    titleLabel.center = CGPointMake(_alertViewBg.frame.size.width/2, 20);
                    [_alertViewBg addSubview:titleLabel];
                    
                    //创建 两种找回密码的方式
                    NSArray *titleArr = @[@"   通过身份证重置",@"   通过密保问题重置"];
                    for (int i = 0; i<titleArr.count; i++) {
                        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.origin.y +titleLabel.frame.size.height + i*(35),  _alertViewBg.frame.size.width - 20, 30)];
                        label.text = titleArr[i];
                        label.userInteractionEnabled = YES;
                        label.textColor = [UIColor whiteColor];
                        label.layer.cornerRadius = 5;
                        label.clipsToBounds = YES;
                        label.backgroundColor = [UIColor colorWithRed:0 green:192/255.0 blue:131/255.0 alpha:1];
                        label.font = [UIFont boldSystemFontOfSize:15];
                        [_alertViewBg addSubview:label];
                        
                        
                        UIImageView *rightImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,10, 20)];
                        rightImage.image = [UIImage imageWithContentsOfFile:ResourcePath(@"PWD_bnt.png")];
                        rightImage.center = CGPointMake( _alertViewBg.frame.size.width - 40, label.frame.origin.y + label.frame.size.height/2);
                        [_alertViewBg addSubview:rightImage];
                        
                        if (i == 0) {
                            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapClickTop)];
                             [label addGestureRecognizer:tap];
                        }else
                        {
                            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapClickNormal)];
                            [label addGestureRecognizer:tap];
                        }
                       
                        
                    }
    
                }];
}

-(void)labelTapClickTop
{
    
    HisuntechForgetPasswordViewController *fpvc = [[HisuntechForgetPasswordViewController alloc]init];
    
    [_forgetBGview removeFromSuperview];
    [_alertViewBg removeFromSuperview];
    
    [self.navigationController pushViewController:fpvc animated:YES];
    
    NSUserDefaults *selectSta = [NSUserDefaults standardUserDefaults];
    [selectSta setValue:@"0" forKey:@"selectStatus"];
    
    
}

-(void)labelTapClickNormal
{
    HisuntechForgetPasswordViewController *fpvc = [[HisuntechForgetPasswordViewController alloc]init];
    
    [_forgetBGview removeFromSuperview];
    [_alertViewBg removeFromSuperview];
    
    [self.navigationController pushViewController:fpvc animated:YES];
    NSUserDefaults *selectSta = [NSUserDefaults standardUserDefaults];
    [selectSta setValue:@"1" forKey:@"selectStatus"];
}


-(void)BGTapCLick
{
    [_forgetBGview removeFromSuperview];
    [_alertViewBg removeFromSuperview];
}


-(void)dealloc
{
    
    NSLog(@"%@  释放",[self class]);
    
    if (_alertViewBg) {
        [_alertViewBg removeFromSuperview];
    }
    if (_forgetBGview) {
        [_forgetBGview removeFromSuperview];
    }
    
    if (_bgView) {
        [_bgView removeFromSuperview];
    }
    
    frist = NO;
}

@end
