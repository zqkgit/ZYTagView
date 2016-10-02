//
//  ZYTagView.m
//  ImageTag
//
//  Created by ripper on 2016/9/27.
//  Copyright © 2016年 ripper. All rights reserved.
//

#import "ZYTagView.h"
#import "UIView+zy_Frame.h"

#define kXSpace 8.0                              /** 距离父视图边界横向最小距离 */
#define kYSpace 0.0                              /** 距离俯视图边界纵向最小距离 */
#define kTagHorizontalSpace 20.0                 /** 标签左右空余距离 */
#define kTagVerticalSpace 10.0                   /** 标签上下空余距离 */
#define kPointWidth 8.0                          /** 白点直径 */
#define kPointSpace 2.0                          /** 白点和阴影尖角距离 */
#define kAngleLength (self.zy_height / 2.0 - 2)  /** 黑色阴影尖交宽度 */
#define kDeleteBtnWidth self.zy_height           /** 删除按钮宽度 */

typedef NS_ENUM(NSUInteger, ZYTagViewState) {
    ZYTagViewStateArrowLeft,
    ZYTagViewStateArrowRight,
    ZYTagViewStateArrowLeftWithDelete,
    ZYTagViewStateArrowRightWithDelete,
};

@interface ZYTagView ()

/** 状态 */
@property (nonatomic, assign) ZYTagViewState state;
/** tag信息 */
@property (nonatomic, strong) ZYTagInfo *tagInfo;
/** 拖动手势记录初始点 */
@property (nonatomic, assign) CGPoint panTmpPoint;
/** 白点中心 */
@property (nonatomic, assign, readonly) CGPoint arrowPoint;

/** 黑色背景 */
@property (nonatomic, weak) CAShapeLayer *backLayer;
/** 白点 */
@property (nonatomic, weak) CAShapeLayer *pointLayer;
/** 白点动画阴影 */
@property (nonatomic, weak) CAShapeLayer *pointShadowLayer;
/** 标题 */
@property (nonatomic, weak) UILabel *titleLabel;
/** 删除按钮 */
@property (nonatomic, weak) UIButton *deleteBtn;
/** 分割线 */
@property (nonatomic, weak) UIView *cuttingLine;

@end


@implementation ZYTagView

- (instancetype)initWithTagInfo:(ZYTagInfo *)tagInfo
{
    self = [super init];
    if (self) {
        
        self.tagInfo = tagInfo;
        //子控件
        [self createSubviews];
        //手势处理
        [self setupGesture];
    }
    return self;
}


- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    //调整UI
    [self layoutWithTitle:self.tagInfo.title superview:newSuperview];
}


#pragma mark - getter
- (CGPoint)arrowPoint
{
    CGPoint arrowPoint;
    if (self.state == ZYTagViewStateArrowLeft) {
        arrowPoint = CGPointMake(self.zy_x + kPointWidth / 2.0, self.zy_centerY);
    }else if (self.state == ZYTagViewStateArrowRight) {
        arrowPoint = CGPointMake(self.zy_right - kPointWidth / 2.0, self.zy_centerY);
    }else if (self.state == ZYTagViewStateArrowLeftWithDelete) {
        arrowPoint = CGPointMake(self.zy_x + kPointWidth / 2.0, self.zy_centerY);
    }else if(self.state == ZYTagViewStateArrowRightWithDelete) {
        arrowPoint = CGPointMake(self.zy_right - kPointWidth / 2.0, self.zy_centerY);
    }
    return arrowPoint;
}

#pragma mark - private methods
- (void)createSubviews
{
    CAShapeLayer *backLayer = [[CAShapeLayer alloc] init];
    backLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:.7].CGColor;
    [self.layer addSublayer:backLayer];
    self.backLayer = backLayer;
    
    CAShapeLayer *pointShadowLayer = [[CAShapeLayer alloc] init];
    pointShadowLayer.hidden = YES;
    pointShadowLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.3].CGColor;;
    [self.layer addSublayer:pointShadowLayer];
    self.pointShadowLayer = pointShadowLayer;

    CAShapeLayer *pointLayer = [[CAShapeLayer alloc] init];
    pointLayer.backgroundColor =[UIColor whiteColor].CGColor;
    [self.layer addSublayer:pointLayer];
    self.pointLayer = pointLayer;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteBtn addTarget:self action:@selector(clickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
    [deleteBtn setImage:[UIImage imageNamed:@"X"] forState:UIControlStateNormal];
    [self addSubview:deleteBtn];
    self.deleteBtn = deleteBtn;
    
    UIView *cuttingLine = [[UIView alloc] init];
    cuttingLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.5];
    [self addSubview:cuttingLine];
    self.cuttingLine = cuttingLine;
}

- (void)setupGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:pan];
    
    UILongPressGestureRecognizer *lop = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:lop];
}

- (void)layoutWithTitle:(NSString *)title superview:(UIView *)superview
{
    //调整label的大小
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleLabel sizeToFit];
    self.titleLabel.zy_width += kTagHorizontalSpace;
    self.titleLabel.zy_height += kTagVerticalSpace;
    
    //调整子控件UI
    ZYTagViewState state = self.state;
    if (!CGPointEqualToPoint(self.tagInfo.point, CGPointZero)) {
        //如果有point则利用point
        if (self.tagInfo.point.x < superview.zy_width / 2.0) {
            state = ZYTagViewStateArrowLeft;
        }else{
            state = ZYTagViewStateArrowRight;
        }
        [self layoutSubviewsWithState:state arrowPoint:self.tagInfo.point];
    }else{
        //没有point利用位置比例
        CGFloat x = superview.zy_width * self.tagInfo.proportion.x;
        CGFloat y = superview.zy_height * self.tagInfo.proportion.y;
        if (self.tagInfo.proportion.x < 0.5) {
            state = ZYTagViewStateArrowLeft;
        }else{
            state = ZYTagViewStateArrowRight;
        }
        [self layoutSubviewsWithState:state arrowPoint:CGPointMake(x, y)];
    }
    
    //处理特殊初始点情况
    if (state == ZYTagViewStateArrowLeft) {
        if (self.zy_x < kXSpace) {
            self.zy_x = kXSpace;
        }
    }else{
        if (self.zy_x > superview.zy_width - kXSpace - self.zy_width) {
            self.zy_x = superview.zy_width - kXSpace - self.zy_width;
        }
    }
    if (self.zy_y < kYSpace) {
        self.zy_y = kYSpace;
    }else if (self.zy_y > (superview.zy_height - kYSpace - self.zy_height)){
        self.zy_y = superview.zy_height - kYSpace - self.zy_height;
    }
    
    //更新tag信息
    [self updateLocationInfoWithSuperview:superview];
}

- (void)layoutSubviewsWithState:(ZYTagViewState)state arrowPoint:(CGPoint)arrowPoint
{
    self.state = state;

    //利用事务关闭隐式动画
    [CATransaction setDisableActions:YES];

    UIBezierPath *backPath = [UIBezierPath bezierPath];
    self.pointLayer.bounds = CGRectMake(0, 0, kPointWidth, kPointWidth);
    self.pointLayer.cornerRadius = kPointWidth / 2.0;
    self.zy_height = self.titleLabel.zy_height;
    self.zy_centerY = arrowPoint.y;
    self.titleLabel.zy_y = 0;

    
    if (state == ZYTagViewStateArrowLeft || state == ZYTagViewStateArrowRight) {
        //无关闭按钮
        self.zy_width = self.titleLabel.zy_width + kAngleLength + kPointWidth + kPointSpace;
        //隐藏关闭及分割线
        self.deleteBtn.hidden = YES;
        self.cuttingLine.hidden = YES;
    }else{
        //有关闭按钮
        self.zy_width = self.titleLabel.zy_width + kAngleLength + kPointWidth + kPointSpace +kDeleteBtnWidth;
        //关闭按钮
        self.deleteBtn.hidden = NO;
        self.cuttingLine.hidden = NO;
    }

    if (state == ZYTagViewStateArrowLeft || state == ZYTagViewStateArrowLeftWithDelete) {
        //根据字调整控件大小
        self.zy_x = arrowPoint.x - kPointWidth / 2.0;
        //背景
        [backPath moveToPoint:CGPointMake(kPointWidth + kPointSpace, self.zy_height / 2.0)];
        [backPath addLineToPoint:CGPointMake(kPointWidth + kPointSpace + kAngleLength, 0)];
        [backPath addLineToPoint:CGPointMake(self.zy_width, 0)];
        [backPath addLineToPoint:CGPointMake(self.zy_width, self.zy_height)];
        [backPath addLineToPoint:CGPointMake(kPointWidth + kPointSpace + kAngleLength, self.zy_height)];
        [backPath closePath];
        //点
        self.pointLayer.position = CGPointMake(kPointWidth / 2.0, self.zy_height / 2.0);
        //标签
        self.titleLabel.zy_x = kPointWidth + kAngleLength;

        if (state == ZYTagViewStateArrowLeftWithDelete) {
            //关闭
            self.deleteBtn.frame = CGRectMake(self.zy_width - kDeleteBtnWidth, 0, kDeleteBtnWidth, kDeleteBtnWidth);
            self.cuttingLine.frame = CGRectMake(self.deleteBtn.zy_x - 0.5, 0, 0.5, self.zy_height);
        }
        
    }else if(state == ZYTagViewStateArrowRight || state == ZYTagViewStateArrowRightWithDelete) {
        //根据字调整控件大小
        self.zy_right = arrowPoint.x + kPointWidth / 2.0;
        //背景
        [backPath moveToPoint:CGPointMake(self.zy_width - kPointWidth - kPointSpace, self.zy_height / 2.0)];
        [backPath addLineToPoint:CGPointMake(self.zy_width - kAngleLength - kPointWidth - kPointSpace, self.zy_height)];
        [backPath addLineToPoint:CGPointMake(0, self.zy_height)];
        [backPath addLineToPoint:CGPointMake(0, 0)];
        [backPath addLineToPoint:CGPointMake(self.zy_width - kAngleLength - kPointWidth - kPointSpace, 0)];
        [backPath closePath];
        //点
        self.pointLayer.position = CGPointMake(self.zy_width - kPointWidth / 2.0, self.zy_height / 2.0);

        if (state == ZYTagViewStateArrowRight) {
            //标签
            self.titleLabel.zy_x = 0;
        }else{
            //标签
            self.titleLabel.zy_x = kDeleteBtnWidth;
            //关闭
            self.deleteBtn.frame = CGRectMake(0, 0, kDeleteBtnWidth, kDeleteBtnWidth);
            self.cuttingLine.frame = CGRectMake(self.deleteBtn.zy_right + 0.5, 0, 0.5, self.zy_height);
        }
    }
    
    self.backLayer.path = backPath.CGPath;
    self.pointShadowLayer.bounds = self.pointLayer.bounds;
    self.pointShadowLayer.position = self.pointLayer.position;
    self.pointShadowLayer.cornerRadius = self.pointLayer.cornerRadius;

    [CATransaction setDisableActions:NO];
}

- (void)changeLocationWithGestureState:(UIGestureRecognizerState)gestureState locationPoint:(CGPoint)point
{
    
    if (self.state == ZYTagViewStateArrowLeft) {
        CGFloat referenceX = point.x;
        if (referenceX < kXSpace) {
            self.zy_x = kXSpace;
        }else if (referenceX > self.superview.zy_width - kXSpace - self.zy_width - kDeleteBtnWidth){
            
            if (referenceX < self.superview.zy_width - kXSpace - kPointWidth) {
                self.zy_x = referenceX;
            }else{
                self.zy_x = self.superview.zy_width - kXSpace - kPointWidth;
            }
            //翻转
            if (gestureState == UIGestureRecognizerStateEnded) {
                [self layoutSubviewsWithState:ZYTagViewStateArrowRight arrowPoint:CGPointMake(self.zy_x + kPointWidth/2.0, self.zy_centerY)];
            }
        }else{
            self.zy_x = referenceX;
        }
        
    }else{
        CGFloat referenceX = point.x;

        if (referenceX < kXSpace + kDeleteBtnWidth) {
            if (referenceX < kXSpace + kPointWidth - self.zy_width) {
                self.zy_x = kXSpace + kPointWidth - self.zy_width;
            }else{
                if (referenceX > self.superview.zy_width - kXSpace - self.zy_width) {
                    //兼容标签比父视图还宽的情况
                    self.zy_right = self.superview.zy_width - kXSpace;
                }else{
                    self.zy_x = referenceX;
                }
            }
            //翻转
            if (gestureState == UIGestureRecognizerStateEnded) {
                [self layoutSubviewsWithState:ZYTagViewStateArrowLeft arrowPoint:CGPointMake(self.zy_right - kPointWidth/2.0, self.zy_centerY)];
            }
            
        }else if (referenceX > self.superview.zy_width - kXSpace - self.zy_width) {
            self.zy_x = self.superview.zy_width - kXSpace - self.zy_width;
        }else{
            self.zy_x = referenceX;
        }
    }
    
    CGFloat referenceY = point.y;
    if (referenceY < kYSpace) {
        self.zy_y = kYSpace;
    }else if (referenceY > (self.superview.zy_height - kYSpace - self.zy_height)){
        self.zy_y = self.superview.zy_height - kYSpace - self.zy_height;
    }else{
        self.zy_y = referenceY;
    }

    //更新tag信息
    if (gestureState == UIGestureRecognizerStateEnded) {
        [self updateLocationInfoWithSuperview:self.superview];
    }
}

- (void)updateLocationInfoWithSuperview:(UIView *)superview
{
    if (superview == nil) {
        //被移除的时候也会调用 willMoveToSuperview
        return;
    }
    //更新point
    if (self.state == ZYTagViewStateArrowLeft || self.state == ZYTagViewStateArrowLeftWithDelete) {
        self.tagInfo.point = CGPointMake(self.zy_x + kPointWidth / 2, self.zy_y + self.zy_height / 2.0);
    }else{
        self.tagInfo.point = CGPointMake(self.zy_right - kPointWidth / 2, self.zy_y + self.zy_height / 2.0);
    }
    //更新proportion
    if (superview.zy_width > 0 && superview.zy_height > 0) {
        self.tagInfo.proportion = ZYPositionProportionMake(self.tagInfo.point.x / superview.zy_width, self.tagInfo.point.y / superview.zy_height);
    }
}

#pragma mark - event response
- (void)handleTapGesture:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded) {
        [self switchDeleteState];
        [self.superview bringSubviewToFront:self];
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan
{
    CGPoint panPoint = [pan locationInView:self.superview];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self hiddenDeleteBtn];
            [self.superview bringSubviewToFront:self];
            self.panTmpPoint = [pan locationInView:self];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [self changeLocationWithGestureState:UIGestureRecognizerStateChanged
                                      locationPoint:CGPointMake(panPoint.x - self.panTmpPoint.x, panPoint.y - self.panTmpPoint.y)];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self changeLocationWithGestureState:UIGestureRecognizerStateEnded
                                      locationPoint:CGPointMake(panPoint.x - self.panTmpPoint.x, panPoint.y - self.panTmpPoint.y)];
            self.panTmpPoint = CGPointZero;
        }
            break;
        default:
            break;
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)lop
{
    if (lop.state == UIGestureRecognizerStateBegan) {
        [self showDeleteBtn];
        [self.superview bringSubviewToFront:self];
    }
}

- (void)clickDeleteBtn
{
    [self removeFromSuperview];
}

#pragma mark - public methods
- (void)updateTitle:(NSString *)title
{
    [self layoutWithTitle:title superview:self.superview];
}

- (void)showAnimationWithRepeatCount:(float)repeatCount
{
    CAKeyframeAnimation *cka = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    cka.values =   @[@0.7, @1.32, @1,   @1];
    cka.keyTimes = @[@0.0, @0.3,  @0.3, @1];
    cka.repeatCount = repeatCount;
    cka.duration = 1.8;
    [self.pointLayer addAnimation:cka forKey:@"cka"];
    
    CAKeyframeAnimation *cka2 = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    cka2.values =   @[@0.7, @0.9, @0.9, @3.5,  @0.9,  @3.5];
    cka2.keyTimes = @[@0.0, @0.3, @0.3, @0.65, @0.65, @1];
    cka2.repeatCount = repeatCount;
    cka2.duration = 1.8;
    self.pointShadowLayer.hidden = NO;
    [self.pointShadowLayer addAnimation:cka2 forKey:@"cka2"];
}

- (void)removeAnimation
{
    [self.pointLayer removeAnimationForKey:@"cka"];
    [self.pointShadowLayer removeAnimationForKey:@"cka2"];
    self.pointShadowLayer.hidden = YES;
}

- (void)showDeleteBtn
{
    if (self.state == ZYTagViewStateArrowLeft) {
        [self layoutSubviewsWithState:ZYTagViewStateArrowLeftWithDelete arrowPoint:self.arrowPoint];
    }else if (self.state == ZYTagViewStateArrowRight) {
        [self layoutSubviewsWithState:ZYTagViewStateArrowRightWithDelete arrowPoint:self.arrowPoint];
    }
}

- (void)hiddenDeleteBtn
{
    if (self.state == ZYTagViewStateArrowLeftWithDelete) {
        [self layoutSubviewsWithState:ZYTagViewStateArrowLeft arrowPoint:self.arrowPoint];
    }else if(self.state == ZYTagViewStateArrowRightWithDelete) {
        [self layoutSubviewsWithState:ZYTagViewStateArrowRight arrowPoint:self.arrowPoint];
    }
}

- (void)switchDeleteState
{
    if (self.state == ZYTagViewStateArrowLeft || self.state == ZYTagViewStateArrowRight) {
        [self showDeleteBtn];
    }else {
        [self hiddenDeleteBtn];
    }
}

@end
