//
//  KZLinkLabel.m
//  LinkTest
//
//  Created by Yang on 2017/9/15.
//
//

#import "KZLinkLabel.h"

@interface KZLinkLabel()

@property (nonatomic, retain) NSLayoutManager *layoutManager;

@property (nonatomic, retain) NSTextContainer *textContainer;

@property (nonatomic, retain) NSTextStorage *textStorage;

@property (nonatomic, copy) NSArray *linkRanges;

@property (nonatomic, assign) BOOL isTouchMoved;

@property (nonatomic, assign) NSRange selectedRange;

@property (nonatomic, assign)CGPoint prePoint;

@end

@implementation KZLinkLabel

@synthesize userColor = _userColor;
@synthesize urlColor = _urlColor;
@synthesize contentColor = _contentColor;
@synthesize phoneColor = _phoneColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        [self setupTextSystem];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self setupTextSystem];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame andBackgroundColor:(UIColor *)bgColor andLinkbackgroundColor:(UIColor *)linkColor andLinkHighLightColor:(UIColor *)linkHigh andTextColor:(UIColor *)textColor andAttributeString:(NSAttributedString *)attStr andIsAutoLinkDectection:(BOOL)isAuto{
    self = [super initWithFrame:frame];
    if(self){
        [self setupTextSystem];
        self.automaticLinkDetectionEnabled = isAuto;
        self.backgroundColor = bgColor;//正常背景色
        self.linkBackgroundColor = linkColor;// 选中link的背景色
        self.linkHighlightColor = linkHigh;//链接高亮颜色
        
        self.textColor = textColor;//普通文本背景色
        self.numberOfLines = 0;//自动换行
        self.lineBreakMode = NSLineBreakByTruncatingTail;//换行模式

        self.attributedText = attStr;//赋值富文本
    }
    return self;
}

- (void)setupTextSystem
{
    self.textContainer = [[NSTextContainer alloc] init];
    self.textContainer.lineFragmentPadding = 0;
    self.textContainer.maximumNumberOfLines = 0;//self.numberOfLines;
    self.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;//self.lineBreakMode;
    self.textContainer.size = self.frame.size;
    
    self.layoutManager = [[NSLayoutManager alloc] init];
    self.layoutManager.delegate = self;
    [self.layoutManager addTextContainer:self.textContainer];
    
    [self.textContainer setLayoutManager:self.layoutManager];
    
    self.userInteractionEnabled = YES;
    
    _automaticLinkDetectionEnabled = YES;
    
    //NSLog(@"%ld",_linkDetectionTypes);
    //_linkDetectionTypes = KZLinkDetectionTypeAll;//支持所有
    
    self.linkBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    self.linkHighlightColor = [UIColor redColor];
    
    [self updateTextStoreWithText];
}
#pragma mark --- 重写系统方法
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.textContainer.size = self.bounds.size;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.textContainer.size = self.bounds.size;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    [super setNumberOfLines:numberOfLines];
    self.textContainer.maximumNumberOfLines = numberOfLines;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                         attributes:[self attributesFromProperties]];
    [self updateTextStoreWithAttributedString:attributedText];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    NSMutableAttributedString *mutableAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedText];
    [mutableAttributeString addAttributes:[self attributesFromProperties] range:NSMakeRange(0, mutableAttributeString.length)];
    [self updateTextStoreWithAttributedString:mutableAttributeString];
}
#pragma mark ---  布局子控件
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textContainer.size = self.bounds.size;
}

- (void)setAutomaticLinkDetectionEnabled:(BOOL)decorating
{
    _automaticLinkDetectionEnabled = decorating;
    [self updateTextStoreWithText];
}

- (void)setLinkDetectionTypes:(KZLinkDetectionTypes)linkDetectionTypes
{
    _linkDetectionTypes = linkDetectionTypes;
    [self updateTextStoreWithText];
}

- (void)setLinkBackgroundColor:(UIColor *)linkBackgroundColor
{
    _linkBackgroundColor = linkBackgroundColor;
    [self updateTextStoreWithText];
}
- (void)setLinkHighlightColor:(UIColor *)linkHighlightColor
{
    _linkHighlightColor = linkHighlightColor;
    [self updateTextStoreWithText];
}

#pragma mark --- privateMethods
/*
 * linkType : 链接类型
 * range    : 链接区域
 * link     : 链接文本
 * return 返回点击的链接字典包含一个range
 */
- (NSDictionary *)getLinkAtLocation:(CGPoint)location
{
    // Do nothing if we have no text
    if (self.textStorage.string.length == 0)
    {
        return nil;
    }
    
    // Work out the offset of the text in the view
    CGPoint textOffset;
    NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];
    textOffset = [self calcTextOffsetForGlyphRange:glyphRange];
    
    // Get the touch location and use text offset to convert to text cotainer coords
    location.x -= textOffset.x;
    location.y -= textOffset.y;
    
    NSUInteger touchedChar = [self.layoutManager glyphIndexForPoint:location inTextContainer:self.textContainer];
    
    // If the touch is in white space after the last glyph on the line we don't
    // count it as a hit on the text
    NSRange lineRange;
    CGRect lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:touchedChar effectiveRange:&lineRange];
    if (CGRectContainsPoint(lineRect, location) == NO)
    {
        return nil;
    }
    
    // Find the word that was touched and call the detection block
    for (NSDictionary *dictionary in self.linkRanges)
    {
        NSRange range = [[dictionary objectForKey:@"range"] rangeValue];
        
        if ((touchedChar >= range.location) && touchedChar < (range.location + range.length))
        {
            return dictionary;
        }
    }
    
    return nil;
}
//更新NSStoreText中属性字符串
- (void)updateTextStoreWithText
{
    if (self.attributedText)
    {
        NSMutableAttributedString *mutableAttributeString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        [mutableAttributeString addAttributes:[self attributesFromProperties] range:NSMakeRange(0, mutableAttributeString.length)];
        [self updateTextStoreWithAttributedString:mutableAttributeString];
    }
    else if (self.text)
    {
        [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:self.text attributes:[self attributesFromProperties]]];
    }
    else
    {
        [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:@"" attributes:[self attributesFromProperties]]];
    }
    [self setNeedsDisplay];
}

- (void)updateTextStoreWithAttributedString:(NSAttributedString *)attributedString
{
    
    if (attributedString.length != 0){//修正字符串换行
        attributedString = [KZLinkLabel sanitizeAttributedString:attributedString];
    }
    if (self.isAutomaticLinkDetectionEnabled && (attributedString.length != 0)) {
        //获取所有类型的属性字符串
        self.linkRanges = [self getRangesForLinks:attributedString];
        //对所有属性字符串进行拼接
        attributedString = [self addLinkAttributesToAttributedString:attributedString linkRanges:self.linkRanges];
    } else {
        self.linkRanges = nil;
    }
    
    if (self.textStorage) {
        [self.textStorage setAttributedString:attributedString];
    } else {
        self.textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
        [self.textStorage addLayoutManager:self.layoutManager];
        [self.layoutManager setTextStorage:self.textStorage];
    }
}
/*
 * 链接文本属性
 */
- (NSAttributedString *)addLinkAttributesToAttributedString:(NSAttributedString *)string linkRanges:(NSArray *)linkRanges{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];//
    for (NSDictionary *dictionary in linkRanges)
    {
        NSRange range = [[dictionary objectForKey:@"range"] rangeValue];
        attributes[NSForegroundColorAttributeName] = (UIColor *)[dictionary objectForKey:@"textColor"];
        
        [attributedString addAttributes:attributes range:range];
    }
    //这个方法调用了3次
    return attributedString;
}

/*
 * 普通文本属性
 */
- (NSDictionary *)attributesFromProperties
{
    //阴影属性
    NSShadow *shadow = [[NSShadow alloc] init];
    if (self.shadowColor){
        shadow.shadowColor = self.shadowColor;
        shadow.shadowOffset = self.shadowOffset;
    } else {
        shadow.shadowOffset = CGSizeMake(0, -1);
        shadow.shadowColor = nil;
    }
    
    //颜色属性
    UIColor *color = self.textColor;
    if (!self.isEnabled){
        color = [UIColor lightGrayColor];
    } else if (self.isHighlighted) {
        color = self.highlightedTextColor;
    }
    
    //段落属性
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = self.textAlignment;
    
    //属性字典
    NSDictionary *attributes = @{
                                    NSFontAttributeName : self.font,
                                    NSForegroundColorAttributeName : color,
                                    NSShadowAttributeName : shadow,
                                    NSParagraphStyleAttributeName : paragraph
                                };
    return attributes;
}
/*
 * 修正换行模式
 */
+ (NSAttributedString *)sanitizeAttributedString:(NSAttributedString *)attributedString
{
    NSRange range;
    NSParagraphStyle *paragraphStyle = [attributedString attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&range];
    
    if (paragraphStyle == nil)
    {
        return attributedString;
    }
    
    // Remove the line breaks
    NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
    mutableParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    // Apply new style
    NSMutableAttributedString *restyled = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    [restyled addAttribute:NSParagraphStyleAttributeName value:mutableParagraphStyle range:NSMakeRange(0, restyled.length)];
    
    return restyled;
}

/*
 * 可扩展部分,不同的Link类型
 */
- (NSArray *)getRangesForLinks:(NSAttributedString *)text
{
    NSMutableArray *rangesForLinks = [[NSMutableArray alloc] init];
    //用户昵称
    if (self.linkDetectionTypes & KZLinkDetectionTypeUserHandle)
    {
        [rangesForLinks addObjectsFromArray:[self getRangesForUserHandles:text.string]];
    }
    //内容标签
    if (self.linkDetectionTypes & KZLinkDetectionTypeHashTag)
    {
        [rangesForLinks addObjectsFromArray:[self getRangesForHashTags:text.string]];
    }
    //链接地址
    if (self.linkDetectionTypes & KZLinkDetectionTypeURL)
    {
        [rangesForLinks addObjectsFromArray:[self getRangesForURLs:self.attributedText]];
    }
    //电话号码
    if (self.linkDetectionTypes & KZLinkDetectionTypePhoneNumber)
    {
        [rangesForLinks addObjectsFromArray:[self getRangesForPhoneNumbers:text.string]];
    }
    //可扩展选项
    
    return rangesForLinks;
}
/*
 * 所有用户昵称
 */
- (NSArray *)getRangesForUserHandles:(NSString *)text
{
    NSMutableArray *rangesForUserHandles = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"@[^,，：:\\s@]+"
                                                                      options:0
                                                                        error:&error];
    NSArray *matches = [regex matchesInString:text
                                      options:0
                                        range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        NSString *matchString = [text substringWithRange:matchRange];
        
        [rangesForUserHandles addObject:@{
                                           @"linkType" : @(KZLinkTypeUserHandle),
                                           @"range"    : [NSValue valueWithRange:matchRange],
                                           @"link"     : matchString,
                                           @"textColor" : self.userColor
                                         }];
    }
    return rangesForUserHandles;
}
/*
 * 所有内容标签
 */
- (NSArray *)getRangesForHashTags:(NSString *)text
{
    NSMutableArray *rangesForHashTags = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"#[^#]+#"
                                                                      options:0
                                                                        error:&error];
    NSArray *matches = [regex matchesInString:text
                                      options:0
                                        range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        NSString *matchString = [text substringWithRange:matchRange];
        
        [rangesForHashTags addObject:@{
                                        @"linkType" : @(KZLinkTypeHashTag),
                                        @"range"    : [NSValue valueWithRange:matchRange],
                                        @"link"     : matchString,
                                        @"textColor" : self.contentColor
                                      }];
    }
    return rangesForHashTags;
}
/*
 * 所有链接地址
 */
- (NSArray *)getRangesForURLs:(NSAttributedString *)text
{
    NSMutableArray *rangesForURLs = [[NSMutableArray alloc] init];;
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:&error];
    
    NSString *plainText = text.string;
    NSArray *matches = [detector matchesInString:plainText
                                         options:0
                                           range:NSMakeRange(0, text.length)];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        
        NSString *realURL = [text attribute:NSLinkAttributeName
                                    atIndex:matchRange.location
                             effectiveRange:nil];
        if (realURL == nil){
            realURL = [plainText substringWithRange:matchRange];
        }
        
        if ([match resultType] == NSTextCheckingTypeLink){
            [rangesForURLs addObject:@{
                                        @"linkType" : @(KZLinkTypeURL),
                                        @"range"    : [NSValue valueWithRange:matchRange],
                                        @"link"     : realURL,
                                        @"textColor" : self.urlColor
                                      }];
        }
    }
    return rangesForURLs;
}
/*
 * 所有电话号码
 */
- (NSArray *)getRangesForPhoneNumbers:(NSString *)text
{
    NSMutableArray *rangesForPhoneNumbers = [[NSMutableArray alloc] init];;
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    
    NSArray *matches = [detector matchesInString:text
                                         options:0
                                           range:NSMakeRange(0, text.length)];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        NSString *matchString = [text substringWithRange:matchRange];
        
        if ([match resultType] == NSTextCheckingTypePhoneNumber){
            [rangesForPhoneNumbers addObject:@{
                                                 @"linkType" : @(KZLinkTypePhoneNumber),
                                                 @"range"    : [NSValue valueWithRange:matchRange],
                                                 @"link"     : matchString,
                                                 @"textColor" : self.phoneColor
                                              }];
        }
    }
    return rangesForPhoneNumbers;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Layout and Rendering
/*
 * 绘制文本相关方法
 */
- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    // Use our text container to calculate the bounds required. First save our
    // current text container setup
    CGSize savedTextContainerSize = self.textContainer.size;
    NSInteger savedTextContainerNumberOfLines = self.textContainer.maximumNumberOfLines;
    
    // Apply the new potential bounds and number of lines
    self.textContainer.size = bounds.size;
    self.textContainer.maximumNumberOfLines = numberOfLines;
    
    // Measure the text with the new state
    CGRect textBounds;
    @try
    {
        NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];
        textBounds = [self.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
        
        // Position the bounds and round up the size for good measure
        textBounds.origin = bounds.origin;
        textBounds.size.width = ceilf(textBounds.size.width);
        textBounds.size.height = ceilf(textBounds.size.height);
    }
    @finally
    {
        // Restore the old container state before we exit under any circumstances
        self.textContainer.size = savedTextContainerSize;
        self.textContainer.maximumNumberOfLines = savedTextContainerNumberOfLines;
    }
    return textBounds;
}

- (void)drawTextInRect:(CGRect)rect
{
    // Calculate the offset of the text in the view
    CGPoint textOffset;
    NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];
    textOffset = [self calcTextOffsetForGlyphRange:glyphRange];
    
    // Drawing code
    [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOffset];
    [self.layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:textOffset];
}

// Returns the XY offset of the range of glyphs from the view's origin
- (CGPoint)calcTextOffsetForGlyphRange:(NSRange)glyphRange
{
    CGPoint textOffset = CGPointZero;
    
    CGRect textBounds = [self.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
    CGFloat paddingHeight = (self.bounds.size.height - textBounds.size.height) / 2.0f;
    if (paddingHeight > 0)
    {
        textOffset.y = paddingHeight;
    }
    
    return textOffset;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Layout manager delegate
/*
 * 链接是否换行
 */
-(BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
{
    for (NSDictionary *dictionary in self.linkRanges)
    {
        NSRange range = [[dictionary objectForKey:@"range"] rangeValue];
        KZLinkType linkType = [[dictionary objectForKey:@"linkType"] integerValue];
        if (linkType == KZLinkTypeURL) {
            if ((charIndex > range.location) && charIndex <= (range.location + range.length)) {
                return NO;
            }
        }
    }
    return YES;
    
}
/*
 * 触摸事件
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isTouchMoved = NO;
    
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    self.prePoint = touchLocation;//存储第一次点击点  判断是否移动
//    NSLog(@"bengin:%lf--->...--->%lf",touchLocation.x,touchLocation.y);
    NSDictionary *touchedLink = [self getLinkAtLocation:touchLocation];
    
    if (touchedLink){
        self.linkType = (KZLinkType)[[touchedLink objectForKey:@"linkType"] intValue];
        self.selectedRange = [[touchedLink objectForKey:@"range"] rangeValue];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    //NSLog(@"%lf--->...--->%lf",touchLocation.x,touchLocation.y);
    if(touchLocation.x != self.prePoint.x || touchLocation.y != self.prePoint.y){
        self.isTouchMoved = YES;//说明移动了
    }
    self.prePoint = touchLocation;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //如果拖动手指的话就不识别
    if (self.isTouchMoved) {
        self.selectedRange = NSMakeRange(0, 0);
        return;
    }
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    NSDictionary *touchedLink = [self getLinkAtLocation:touchLocation];
    
    if (touchedLink){
        NSRange range = [[touchedLink objectForKey:@"range"] rangeValue];
        NSString *touchedSubstring = [touchedLink objectForKey:@"link"];
        self.linkType = (KZLinkType)[[touchedLink objectForKey:@"linkType"] intValue];
        self.linkTapHandler(self.linkType, touchedSubstring, range);
    } else {
        [super touchesBegan:touches withEvent:event];
    }
    self.selectedRange = NSMakeRange(0, 0);
}

#pragma mark --- lazy

- (void)setSelectedRange:(NSRange)range
{
    //删除之前选中的链接属性
    if (self.selectedRange.length && !NSEqualRanges(self.selectedRange, range)) {
        [self.textStorage removeAttribute:NSBackgroundColorAttributeName
                                    range:self.selectedRange];
        /*
         KZLinkTypeUserHandle,     //用户昵称  eg: @kingzwt
         KZLinkTypeHashTag,        //内容标签  eg: #hello#
         KZLinkTypeURL,            //链接地址  eg: http://www.baidu.com
         KZLinkTypePhoneNumber     //电话号码  eg: 13888888888
         */
        if(self.linkType == KZLinkTypeUserHandle){
            [self.textStorage addAttribute:NSForegroundColorAttributeName value:self.userColor range:self.selectedRange];
        }else if(self.linkType == KZLinkTypeHashTag){
            [self.textStorage addAttribute:NSForegroundColorAttributeName value:self.contentColor range:self.selectedRange];
        }else if(self.linkType == KZLinkTypeURL){
            [self.textStorage addAttribute:NSForegroundColorAttributeName value:self.urlColor range:self.selectedRange];
        }else{
            [self.textStorage addAttribute:NSForegroundColorAttributeName value:self.phoneColor range:self.selectedRange];
        }
    }
    
    //选中链接绘制新颜色
    if (range.length) {
        [self.textStorage addAttribute:NSBackgroundColorAttributeName//设置选中背景色
                                 value:self.linkBackgroundColor
                                 range:range];
        [self.textStorage addAttribute:NSForegroundColorAttributeName//设置选中link的高亮色
                                 value:self.linkHighlightColor
                                 range:range];
    }
    _selectedRange = range;
    [self setNeedsDisplay];
}
/*
 KZLinkDetectionTypeUserHandle  = (1 << 0),
 KZLinkDetectionTypeHashTag     = (1 << 1),
 KZLinkDetectionTypeURL         = (1 << 2),
 KZLinkDetectionTypePhoneNumber = (1 << 3),
 KZLinkDetectionTypeNone        = 0,//一个都不支持
 KZLinkDetectionTypeAll         = NSUIntegerMax
 */
//重写set方法
-(void)setSetArr:(NSMutableSet *)setArr{
    for (NSString * str in setArr) {
        if([str isEqualToString:@"@"]){
            self.linkDetectionTypes += KZLinkDetectionTypeUserHandle;
        }else if([str isEqualToString:@"#"]){
            self.linkDetectionTypes += KZLinkDetectionTypeHashTag;
        }else if([str isEqualToString:@"call"]){
            self.linkDetectionTypes += KZLinkDetectionTypePhoneNumber;
        }else if([str isEqualToString:@"url"]){
            self.linkDetectionTypes += KZLinkDetectionTypeURL;
        }else{
            //用来扩展
        }
    }
}

-(UIColor *)userColor{
    if(!_userColor){
        _userColor = [UIColor blueColor];
    }
    return _userColor;
}
-(UIColor *)contentColor{
    if(!_contentColor){
        _contentColor = [UIColor blueColor];
    }
    return _contentColor;
}
-(UIColor *)urlColor{
    if(!_urlColor){
        _urlColor = [UIColor blueColor];
    }
    return _urlColor;
}
-(UIColor *)phoneColor{
    if(!_phoneColor){
        _phoneColor = [UIColor blueColor];
    }
    return _phoneColor;
}
-(void)setUserColor:(UIColor *)userColor{
    _userColor = userColor;
    [self updateTextStoreWithText];//更新字符串属性
}
-(void)setUrlColor:(UIColor *)urlColor{
    _urlColor = urlColor;
    [self updateTextStoreWithText];
}
-(void)setPhoneColor:(UIColor *)phoneColor{
    _phoneColor = phoneColor;
    [self updateTextStoreWithText];
}
-(void)setContentColor:(UIColor *)contentColor{
    _contentColor = contentColor;
    [self updateTextStoreWithText];
}


@end
