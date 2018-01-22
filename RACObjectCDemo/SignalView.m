//
//  SignalView.m
//  RACObjectCDemo
//
//  Created by NagiYan on 2018/1/19.
//  Copyright © 2018年 NagiYan. All rights reserved.
//

#import "SignalView.h"

@implementation SignalView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self p_initSubviews];
    }
    return self;
}

- (void)p_initSubviews {
    [RACObserve(self, number) subscribeNext:^(id  _Nullable x) {
        if (self.subject) {
            // 类似 delegate 调用
            [self.subject sendNext:nil];
        }
    }];
}

@end
