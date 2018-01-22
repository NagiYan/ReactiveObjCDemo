//
//  ViewController.m
//  RACObjectCDemo
//
//  Created by NagiYan on 2018/1/19.
//  Copyright © 2018年 NagiYan. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <ReactiveObjC.h>
#import "SignalView.h"

@interface ViewController ()
@property (nonatomic, assign)NSInteger count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _count = 0;
    [self p_initUI];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)p_initUI {
    UIButton* btnSignal = [UIButton new];
    [self.view addSubview:btnSignal];
    btnSignal.selected = NO;
    btnSignal.backgroundColor = [UIColor blueColor];
    [btnSignal mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.height.mas_equalTo(100);
    }];
    // 1 无需编写selector函数，直接在创建控件的地方编写事件响应逻辑
    [[btnSignal rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        btnSignal.selected = !btnSignal.selected;
        self.count++;
        if (self.count == 5) {
            [self p_func];
        }
        btnSignal.backgroundColor = btnSignal.selected ? [UIColor redColor] : [UIColor blueColor];
    }];
    
    SignalView* vView = [SignalView new];
    [self.view addSubview:vView];
    [vView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnSignal.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        make.width.height.equalTo(@50);
    }];
    vView.layer.cornerRadius = 0;
    vView.layer.masksToBounds = YES;
    
    // 2 直接绑定两个同类属性
    RAC(vView, backgroundColor) = RACObserve(btnSignal, backgroundColor);
    
    // 3 将一种属性转换为另外一种属性来绑定
    RAC(vView.layer, cornerRadius) = [RACObserve(btnSignal, selected) map:^id _Nullable(id  _Nullable value) {
        if ([value boolValue]) {
            return @(25);
        }
        else
            return @(0);
    }];
    
    UILabel* lblText = [UILabel new];
    [self.view addSubview:lblText];
    lblText.textAlignment = NSTextAlignmentCenter;
    [lblText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(vView.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        make.width.height.equalTo(@50);
    }];
    lblText.textColor = [UIColor blackColor];
    
    // 4 使用过滤，使得一个属性满足一定条件才触发指定操作
    [[RACObserve(self, count) filter:^BOOL(id  _Nullable value) {
        return [value integerValue]%2 == 0;
    }] subscribeNext:^(id  _Nullable x) {
        lblText.text = [NSString stringWithFormat:@"%@", x];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"rac_signal" object:nil userInfo:nil];
    }];

    // 5 利用信号实现广播
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"rac_signal" object:nil] subscribeNext:^(NSNotification* x) {
        lblText.textColor = self.count%4==0?[UIColor blackColor]:[UIColor redColor];
    }];
    
    // 6 将函数调用转化成信号
    [[self rac_signalForSelector:@selector(p_func)] subscribeNext:^(RACTuple * _Nullable x) {
        lblText.font = [UIFont systemFontOfSize:40];
    }];
    
    // 7 定时器信号
    __block CGFloat begin = 0.01;
    RACDisposable* subscriber = [[RACSignal interval:0.1 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(id x) {
        btnSignal.backgroundColor = [UIColor colorWithWhite:1 - begin alpha:1.0];
        begin = begin + 0.01;
        if (begin >= 1)
            begin = 0.01;
    }];
    
    // 8 节流，信号触发一定时间后没有信号才最终触发响应
    UIButton* btnSignalT = [UIButton new];
    [self.view addSubview:btnSignalT];
    btnSignalT.backgroundColor = [UIColor blackColor];
    [btnSignalT mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-150);
        make.width.height.mas_equalTo(60);
    }];
    [[[btnSignalT rac_signalForControlEvents:UIControlEventTouchUpInside] throttle:1.5] subscribeNext:^(__kindof UIControl * _Nullable x) {
        self.count++;
        lblText.text = [NSString stringWithFormat:@"%ld", self.count];
        begin = 0.01;
        // 为了触发delegate
        vView.number = 0;
        // 7.1 结束定时器信号
        [subscriber dispose];
    }];
    
    // 9 用于代替delegate
    vView.subject = [RACSubject new];
    [vView.subject subscribeNext:^(id  _Nullable x) {
        lblText.font = [UIFont systemFontOfSize:20];
    }];
    
    // 10 信号特性
    __block id<RACSubscriber> sb;
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        static int a = 1;
        [subscriber sendNext:@(a++)];
        sb = subscriber;
        //[subscriber sendCompleted];
        return nil;
    }];
    [signalA subscribeNext:^(id x) {
        NSLog(@"第一个订阅者%@",x);
    }];
    [signalA subscribeNext:^(id x) {
        NSLog(@"第二个订阅者%@",x);
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@20];
        return nil;
    }];
    
    // 11 合并信号,任何一个信号发送数据，都能监听到.
    RACSignal *mergeSignal = [signalA merge:signalB];
    [mergeSignal subscribeNext:^(id x) {
        NSLog(@"合并信号%@",x);
    }];
    
    // 12 压缩信号A，信号B
    RACSignal *zipSignal = [signalA zipWith:signalB];
    [zipSignal subscribeNext:^(id x) {
        NSLog(@"压缩信号%@",x);
    }];
    
    [sb sendNext:@(9)];
    
    RACSignal *reduceSignalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        return nil;
    }];
    RACSignal *reduceSignalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@2];
        return nil;
    }];
    // 13 聚合
    // 常见的用法，（先组合在聚合）。combineLatest:(id<NSFastEnumeration>)signals reduce:(id (^)())reduceBlock
    // reduce中的block简介:
    // reduceblcok中的参数，有多少信号组合，reduceblcok就有多少参数，每个参数就是之前信号发出的内容
    // reduceblcok的返回值：聚合信号之后的内容。
    RACSignal *reduceSignal = [RACSignal combineLatest:@[reduceSignalA,reduceSignalB] reduce:^id(NSNumber *num1 ,NSNumber *num2){
        return [NSString stringWithFormat:@"%@ %@",num1,num2];
    }];
    
    [reduceSignal subscribeNext:^(id x) {
        NSLog(@"reduce %@",x);
    }];
    
    // 合并
    
    // 组合
    
    
    // 压缩
    //[self p_enum];
}


- (void)p_func {
    
}

- (void)p_enum {
    NSMutableArray* array = [NSMutableArray new];
    for (int i = 0; i < 100000; ++i) {
        [array addObject:@(i)];
    }
    UInt64 recordTimeS = [[NSDate date] timeIntervalSince1970]*1000000;
    // 1
    for (int i = 0; i < array.count; ++i) {
        
    }
    UInt64 recordTimeE1 = [[NSDate date] timeIntervalSince1970]*1000000;
    NSLog(@"1 %llu", recordTimeE1 - recordTimeS);
    // 2
    for (NSNumber* item in array) {
        
    }
    UInt64 recordTimeE2 = [[NSDate date] timeIntervalSince1970]*1000000;
    NSLog(@"2 %llu", recordTimeE2 - recordTimeE1);
    // 3
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
    }];
    UInt64 recordTimeE3 = [[NSDate date] timeIntervalSince1970]*1000000;
    NSLog(@"3 %llu", recordTimeE3 - recordTimeE2);
    // 4
    NSEnumerator *enumerator = [array objectEnumerator];
    id obj = nil;
    while(obj = [enumerator nextObject]){
        
    }
    UInt64 recordTimeE4 = [[NSDate date] timeIntervalSince1970]*1000000;
    NSLog(@"4 %llu", recordTimeE4 - recordTimeE3);
    // 5
    [array.rac_sequence.signal subscribeNext:^(id x) {

    }];
    UInt64 recordTimeE5 = [[NSDate date] timeIntervalSince1970]*1000000;
    NSLog(@"5 %llu", recordTimeE5 - recordTimeE4);
}

@end
