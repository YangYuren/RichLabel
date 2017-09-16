//
//  KZLinkLabel.h
//  LinkTest
//
//  Created by Yang on 2017/9/15.
//
//
#import <UIKit/UIKit.h>


// 链接类型
typedef NS_ENUM(NSInteger, KZLinkType)
{
    KZLinkTypeUserHandle,     //用户昵称  eg: @kingzwt
    KZLinkTypeHashTag,        //内容标签  eg: #hello#
    KZLinkTypeURL,            //链接地址  eg: http://www.baidu.com
    KZLinkTypePhoneNumber     //电话号码  eg: 13888888888
};

// 可用于识别的链接类型
typedef NS_OPTIONS(NSUInteger, KZLinkDetectionTypes)
{
    KZLinkDetectionTypeUserHandle  = (1 << 0),
    KZLinkDetectionTypeHashTag     = (1 << 1),
    KZLinkDetectionTypeURL         = (1 << 2),
    KZLinkDetectionTypePhoneNumber = (1 << 3),
    KZLinkDetectionTypeNone        = 0,//一个都不支持
    KZLinkDetectionTypeAll         = NSUIntegerMax
};

typedef void (^KZLinkHandler)(KZLinkType linkType, NSString *string, NSRange range);

@interface KZLinkLabel : UILabel <NSLayoutManagerDelegate>

//自定义构造方法
- (id)initWithFrame:(CGRect)frame andBackgroundColor:(UIColor *)bgColor andLinkbackgroundColor:(UIColor *)linkColor andLinkHighLightColor:(UIColor *)linkHigh andTextColor:(UIColor *)textColor andAttributeString:(NSAttributedString *)attStr andIsAutoLinkDectection:(BOOL)isAuto;

@property (nonatomic, assign, getter = isAutomaticLinkDetectionEnabled) BOOL automaticLinkDetectionEnabled;

/**
 用来存放支持哪些链接
 */
@property(nonatomic,strong)NSMutableSet * setArr;
/**
 用来存放支持哪些链接
 */
@property(nonatomic,strong)NSMutableSet * setColor;
/**
 链接选中高亮色
 */
@property (nonatomic, strong) UIColor *linkHighlightColor;

/**
 链接背景色
 */
@property (nonatomic, strong) UIColor *linkBackgroundColor;

/**
 可识别链接类型
 */
@property (nonatomic, assign) KZLinkDetectionTypes linkDetectionTypes;

/**
 点击链接类型
 */
@property (nonatomic, assign) KZLinkType linkType;

/**
 点击回调
 */
@property (nonatomic, copy) KZLinkHandler linkTapHandler;

/**
 用户连接颜色
 */
@property(nonatomic,strong) UIColor * userColor;

/**
 内容话题颜色
 */
@property(nonatomic,strong) UIColor * contentColor;

/**
 超链接颜色
 */
@property(nonatomic,strong) UIColor * urlColor;

/**
 电话号码链接颜色
 */
@property(nonatomic,strong) UIColor * phoneColor;

@end
