//
//  ViewController.m
//  AngelServer
//
//  Created by lby on 16/12/29.
//  Copyright © 2016年 lby. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#define KClientNum 3 // 客户端个数
#define KSendCount 200 // 连发次数
@interface ViewController ()<GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UITextField *portF;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;
@property (weak, nonatomic) IBOutlet UITextView *showContentMessageTV;
@property (nonatomic, strong) NSTimer *checkTimer; // 检测心跳计时器
@property (nonatomic, strong) GCDAsyncSocket *serverSocket; // 服务器socket(开放端口,监听客户端socket的链接)
@property (nonatomic, copy) NSMutableArray *clientSockets; // 保存客户端socket
@property (nonatomic, copy) NSMutableDictionary *clientPhoneTimeDicts; // 客户端标识和心跳接收时间的字典
@property (nonatomic, assign) double maxNum; // 最大延迟值
@property (nonatomic, assign) double minNum; // 最小延迟值
@property (nonatomic, assign) int count; // 客户端读取到时间点返回给服务器的次数
@property (nonatomic, assign) int i; // 发送的测试次数
// 延迟差的时间范围
@property (nonatomic, assign) int delayCount60; // 延迟60以内
@property (nonatomic, assign) int delayCount100; // 延迟60 - 100
@property (nonatomic, assign) int delayCount200; // 延迟100 - 200
@property (nonatomic, assign) int delayCountUp200; // 延迟200以上
@property (nonatomic, assign) double startCreateTime; // 开始创建
@property (nonatomic, assign) double createdTime; // 创建完成
@property (nonatomic, assign) double openPortTime; // 开启端口
@property (nonatomic, assign) double openedTime; // 成功开启
@property (nonatomic, assign) double startSendTime; // 开始发送
@property (nonatomic, copy) NSString *sentTime; //发送成功
@property (nonatomic, strong) NSTimer *sendTimer; // 发送计时器
// 服务器到客户端一次收发的时间范围
@property (nonatomic, assign) int range50; // 50以内
@property (nonatomic, assign) int range100; // 100以内
@property (nonatomic, assign) int range200; // 200以内
@property (nonatomic, assign) int rangeUp200;// 200以上
@property (nonatomic, assign) int iSend; //连发的次数 200

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 准备创建服务器socket的时间
    NSString *time1 = [self getCurrentSecond];
    NSLog(@"准备创建服务器socket:%@",time1);
    self.startCreateTime = [self strToDouble:time1];
    self.serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    // 完成创建
    NSString *time2 = [self getCurrentSecond];
    NSLog(@"服务器socket创建完成:%@",time2);
    self.createdTime = [self strToDouble:time2];
    
    NSLog(@"服务器创建socket耗时%.0f毫秒",(self.createdTime - self.startCreateTime) * 1000);
    self.messageTF.text = @"1381222333$1,1$13812223335";
}

- (IBAction)startNotice:(id)sender
{
    // 准备开启端口
    NSString *time3 = [self getCurrentSecond];
    NSLog(@"准备开启端口:%@",time3);
    self.openPortTime = [self strToDouble:time3];
    NSError *error = nil;
    BOOL result = [self.serverSocket acceptOnPort:self.portF.text.integerValue error:&error];
    if (result && error == nil)
    {
        NSString *time4 = [self getCurrentSecond];
        NSLog(@"已经开启端口:%@",time4);
        self.openedTime = [self strToDouble:time4];
        // 已经开启端口
        NSLog(@"开启端口耗时%.0f毫秒",(self.openedTime - self.openPortTime) * 1000);
        [self showMessageWithStr:@"开启成功"];
    }
    else
    {
        [self showMessageWithStr:@"已经开启"];
    }
}

- (void)addTimer
{
//    NSLog(@"定时器开启的时间%@",[self getCurrentSecond]);
    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(checkLongConnect) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.checkTimer forMode:NSRunLoopCommonModes];
}
// 长连接
- (void)checkLongConnect
{
//    NSLog(@"长连接开始检测的时间:%@",[self getCurrentSecond]);
    NSLog(@"长连接调用%s",__func__);
    NSLog(@"长连接字典clientPhoneTimeDicts:%@",self.clientPhoneTimeDicts);
    [self.clientPhoneTimeDicts enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop)
    {
        NSString *currentTimeStr = [self getCurrentTime];
        // 延迟超过2秒判断断开
        if (([currentTimeStr doubleValue] - [obj doubleValue]) > 2.0)
        {
//            NSLog(@"断开客户端socket时间%@",[self getCurrentSecond]);
            [self showMessageWithStr:[NSString stringWithFormat:@"%@已经断开,连接时差%f",key,[currentTimeStr doubleValue] - [obj doubleValue]]];
//            [self showMessageWithStr:[NSString stringWithFormat:@"移除%@",key]];
            [self.clientPhoneTimeDicts removeObjectForKey:key];
        }
        else
        {
            [self showMessageWithStr:[NSString stringWithFormat:@"%@处于连接状态,连接时差%f",key,[currentTimeStr doubleValue] - [obj doubleValue]]];
        }
    }];
}

- (IBAction)randomSend
{
    NSLog(@"");
    int x = arc4random_uniform(5) + 1;
    NSLog(@"随机数:%d",x);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(x * 1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendMessage:nil];
        self.sentTime = [self getCurrentSecond];
        NSLog(@"服务器已经发送数据:%@",self.sentTime);
        NSLog(@"服务器发送耗时%.0f毫秒",([self strToDouble:self.sentTime] - self.startSendTime) * 1000);
    });
}

// socket是保存的客户端socket, 表示给这个socket客户端发送消息
- (IBAction)sendMessage:(id)sender
{
    self.count = KClientNum;
    self.i++;
    NSLog(@"第%d次比较------------",self.i);
    NSString *time5 = [self getCurrentSecond];
    NSLog(@"服务器准备发送数据:%@",time5);
    self.startSendTime = [self strToDouble:time5];
    // 服务器准备发送数据
    NSString *allMes = [NSString stringWithFormat:@"ab%@",self.messageTF.text];
    
    NSData *data = [allMes dataUsingEncoding:NSUTF8StringEncoding];
    // 包装成二进制
    
    for (int i = 0; i < self.clientSockets.count; i++)
    {
        [self.clientSockets[i] writeData:data withTimeout:-1 tag:0];
    }
}

// 信息展示
- (void)showMessageWithStr:(NSString *)str
{
//    self.showContentMessageTV.text = [self.showContentMessageTV.text stringByAppendingFormat:@"%@\n", str];
    self.showContentMessageTV.text = str;
}

#pragma mark - 服务器socketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(nonnull GCDAsyncSocket *)newSocket
{
//    NSLog(@"连接上新的客户端的时间:%@",[self getCurrentSecond]);
    // 保存客户端的socket
    [self.clientSockets addObject: newSocket];
    
//    [self addTimer];
    
    [self showMessageWithStr:@"连接成功"];
//    [self showMessageWithStr:[NSString stringWithFormat:@"客户端的地址: %@ -------端口: %d", newSocket.connectedHost, newSocket.connectedPort]];
    
    [newSocket readDataWithTimeout:- 1 tag:0];
    
}

// 收到消息(sock指客户端的Socket)
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
//    NSString *time7 = [self getCurrentSecond];
//    NSLog(@"服务器收到数据:%@",time7);
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showMessageWithStr:text];
//    NSLog(@"%@",text);
    
    // 处理前缀为ab的字符串
    NSArray *messageArr = [text componentsSeparatedByString:@"ab"];
    for (int i = 1; i < messageArr.count; i++)
    {
        //        NSLog(@"处理的数据%@",messageArr[i]);
        [self dealMessageArr:messageArr[i]];
        [self showMessageWithStr:messageArr[i]];
    }
    
    [sock readDataWithTimeout:- 1 tag:0];
}

// 处理前缀为Link的字符串
- (void)dealMessageArr:(NSString *)getMessage
{
    if([getMessage hasPrefix:@"Link"])
    {
        NSLog(@"%@",getMessage);
    }
    //测试
    else if([getMessage hasPrefix:@"time"])
    {
        NSLog(@"%@",[getMessage substringFromIndex:5]);
        // 客户端接收分钟转数值
        NSString *clientRecieveMmStr = [getMessage substringWithRange:NSMakeRange(getMessage.length - 9, 2)];
        double clientReceiveMm = clientRecieveMmStr.doubleValue * 60;
        
        // 客户端接收秒转数值
        NSString *clientRecieveSsStr = [getMessage substringWithRange:NSMakeRange(getMessage.length - 6, 6)];
        double clientReceiveSs = clientRecieveSsStr.doubleValue;
        
        // 客户端接收时间
        double clientReceiveTime = clientReceiveMm + clientReceiveSs;
        
        //获取客户端设备名
        NSString *clientName = [getMessage substringWithRange:NSMakeRange(8, 8)];
        
        // 服务器发送分
        NSString *serverSentMmStr = [self.sentTime substringWithRange:NSMakeRange([self.sentTime length] - 9, 2)];
        double serverSendMm = serverSentMmStr.doubleValue * 60;
        
        // 服务器发送秒
        NSString *serverSentSsStr = [self.sentTime substringWithRange:NSMakeRange([self.sentTime length] - 6, 6)];
        double serverSendSs = serverSentSsStr.doubleValue;
        
        // 服务器发送时间
        double serverSentTime = serverSendMm + serverSendSs;
        
        // 一次完整收发时间 (sentTime发送时间)
        double duringTime = clientReceiveTime - serverSentTime;
        int duringTimeInt = duringTime * 1000;
        NSLog(@"设备:%@从服务器到客户端一次完整收发耗时%.0f毫秒",clientName,1000 * duringTime);
        if (duringTimeInt <= 50)
        {
            self.range50 ++;
//            NSLog(@"0 - 50次数:%d",duringTimeInt);
        }
        else if(duringTimeInt <= 100)
        {
            self.range100 ++;
//            NSLog(@"50 - 100次数:%d",duringTimeInt);
        }
        else if(duringTimeInt <= 200)
        {
            self.range200 ++;
//            NSLog(@"100 - 200次数:%d",duringTimeInt);
        }
        else
        {
            self.rangeUp200 ++;
//            NSLog(@"200以上:%d",duringTimeInt);
        }
        // 第一次客户端返回时
        if (self.count == KClientNum)
        {
            self.maxNum = clientReceiveTime;
            self.minNum = clientReceiveTime;
        }
        else
        {
            if (clientReceiveTime > self.maxNum)
            {
                self.maxNum = clientReceiveTime;
            }
            if (clientReceiveTime < self.minNum)
            {
                self.minNum = clientReceiveTime;
            }
//            NSLog(@"最大值:%.3f",self.maxNum);
//            NSLog(@"最小值:%.3f",self.minNum);
//
            if (self.count == 1)
            {
                double compareValue = 1000.0 * (self.maxNum - self.minNum);
                NSLog(@"差值:%.0f毫秒",compareValue);
//                int numberMs = IOSNum - 1;
                if (compareValue <= 60)
                {
                    self.delayCount60 ++;
                }
                else if (compareValue <= 100)
                {
                    self.delayCount100 ++;
                }
                else if (compareValue <= 200)
                {
                    self.delayCount200 ++;
                }
                else
                {
                    self.delayCountUp200 ++;
                }
                if (self.i == KSendCount)
                {
                    NSLog(@"延迟差在60毫秒以内的个数:%d,占比:%.2f%%",self.delayCount60,self.delayCount60 / 1.0 / KSendCount * 100);
                    NSLog(@"延迟差在60 - 100毫秒以内的个数:%d,占比:%.2f%%",self.delayCount100,self.delayCount100 / 1.0 / KSendCount * 100);
                    NSLog(@"延迟差在100 - 200毫秒以内的个数:%d,占比:%.2f%%",self.delayCount200,self.delayCount200 / 1.0 / KSendCount * 100);
                    NSLog(@"延迟差在200毫秒以上的次数:%d,占比:%.2f%%",self.delayCountUp200,self.delayCountUp200 / 1.0 / KSendCount * 100);
                }
                // 连发次数递增
                self.iSend ++;
                if (self.iSend < KSendCount)
                {
                    [self randomSend];
                }
                if (self.iSend == KSendCount)
                {
                    // 所有客户端总发送次数
                    double sumNum = 1.0 * KClientNum * KSendCount;
                    NSLog(@"0 - 50以内的个数:%d,占比:%.2f%%",self.range50,self.range50 / sumNum * 100);
                    NSLog(@"50 - 100以内的个数:%d,占比:%.2f%%",self.range100,self.range100 / sumNum * 100);
                    NSLog(@"100 - 200以内的个数:%d,占比:%.2f%%",self.range200,self.range200 / sumNum * 100);
                    NSLog(@"200以上的个数:%d,占比:%.2f%%",self.rangeUp200,self.rangeUp200 / sumNum * 100);
                }
            }
        }
        // 客户端返回次数递减
        self.count --;
    }
    else
    {
        if (self.clientPhoneTimeDicts.count == 0)
        {
            [self.checkTimer invalidate];
            [self.clientPhoneTimeDicts setObject:[self getCurrentTime] forKey:getMessage];
            [self addTimer];
//            NSLog(@"第一次添加的字典clientPhoneTimeDicts:%@",self.clientPhoneTimeDicts);
        }
        else
        {
            [self.clientPhoneTimeDicts enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [self.clientPhoneTimeDicts setObject:[self getCurrentTime] forKey:getMessage];
//                            NSLog(@"添加的字典clientPhoneTimeDicts:%@",self.clientPhoneTimeDicts);
            }];
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (NSMutableArray *)clientSockets
{
    if (_clientSockets == nil) {
        _clientSockets = [NSMutableArray array];
    }
    return _clientSockets;
}

- (NSMutableDictionary *)clientPhoneTimeDicts
{
    if (_clientPhoneTimeDicts == nil)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        _clientPhoneTimeDicts = dict;
    }
    return _clientPhoneTimeDicts;
}
- (NSString *)getCurrentTime
{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTime = [date timeIntervalSince1970];
    NSString *currentTimeStr = [NSString stringWithFormat:@"%.0f", currentTime];
    return currentTimeStr;
}

- (NSString *)getCurrentSecond
{
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //    df.dateFormat = @"yyyy/MM/dd HH:mm:ss.SSS";
    df.dateFormat = @"HH:mm:ss.SSS";
    NSString *str = [df stringFromDate:date];
    return str;
}

// 字符串转double
- (double)strToDouble:(NSString *)str
{
    return [[str substringWithRange:NSMakeRange(str.length - 6, 6)] doubleValue];
}

@end
