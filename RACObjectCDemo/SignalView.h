//
//  SignalView.h
//  RACObjectCDemo
//
//  Created by NagiYan on 2018/1/19.
//  Copyright © 2018年 NagiYan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC.h>

@interface SignalView : UIView

// 用来代替delegate
@property (nonatomic, strong)RACSubject* subject;

@property (nonatomic, assign)NSInteger number;

@end
