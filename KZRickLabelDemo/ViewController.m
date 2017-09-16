//
//  ViewController.m
//  KZRickLabelDemo
//
//  Created by Yang on 2017/9/15.
//
//
#import "ViewController.h"
#import "KZLinkLabel.h"
#import "NSAttributedString+Emotion.h"
#define kScreenHeight         [UIScreen mainScreen].bounds.size.height
#define kScreenWidth          [UIScreen mainScreen].bounds.size.width

@interface ViewController () <UIActionSheetDelegate>

@property (nonatomic,strong) NSDictionary *selectedLinkDic;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *emojiString = @"http://www.hao123.com [偷笑]你好啊我的歌哈哈哈 #还好睡吧# @图鸭科技,@杨师傅 你好哈哈哈哈你呢咳咳咳13866904438";
    
    UIFont *font = [UIFont systemFontOfSize:16];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    NSAttributedString *attributedString  = [[NSAttributedString alloc] initWithString:emojiString attributes:attributes];
    //NSAttributedString *attributedString = [NSAttributedString emotionAttributedStringFrom:emojiString attributes:attributes];//可以解析表情
    //得到属性字符串的宽高
    CGRect attributeRect = [attributedString boundsWithSize:CGSizeMake(kScreenWidth - 30,CGFLOAT_MAX)];
    
    //设置富文本Label
    KZLinkLabel *kzLabel = [[KZLinkLabel alloc] initWithFrame:CGRectMake(15, 40, kScreenWidth - 30, attributeRect.size.height) andBackgroundColor:[UIColor clearColor] andLinkbackgroundColor:[UIColor clearColor] andLinkHighLightColor:[UIColor yellowColor] andTextColor:[UIColor blackColor] andAttributeString:attributedString andIsAutoLinkDectection:YES];
    
    kzLabel.setArr = [NSMutableSet setWithObjects:@"@",@"call",@"#",@"url", nil];
    kzLabel.userColor = [UIColor redColor];//@*** 的颜色
    kzLabel.phoneColor = [UIColor colorWithWhite:0.7 alpha:0.5];//电话号码颜色
    kzLabel.contentColor = [UIColor colorWithWhite:0 alpha:0.6];//内容颜色
    kzLabel.urlColor = [UIColor purpleColor];// 超链接颜色
    
    
    [kzLabel sizeToFit];
    
    //处理回调block
    kzLabel.linkTapHandler = ^(KZLinkType linkType, NSString *string, NSRange range) {
        UIAlertView * view = [[UIAlertView alloc] initWithTitle:@"提示" message:string delegate:self
                                              cancelButtonTitle:@"取消显示" otherButtonTitles: nil ];
        [view show];
    };
    
    [self.view addSubview:kzLabel];
    
    
    
    
    
}
@end
