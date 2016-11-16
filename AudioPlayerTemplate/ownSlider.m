//
//  ownSlider.m
//  My Audio Type
//
//  Created by okamoto on 09.11.16.
//  Copyright (c) 2016 okamoto. All rights reserved.
//


#import "ownSlider.h"
#import "AppDelegate.h"

@implementation ownSlider

@dynamic minValue, maxValue, currentProgressValue;
@dynamic leftValue, rightValue;
@dynamic showProgress, showRange;

- (void)setLeftValue:(CGFloat)newValue {
    if (newValue < minValue)
        newValue = minValue;
    
    if (newValue > rightValue)
        newValue = rightValue;
    
    leftValue = newValue;
    
    [self setNeedsLayout];
}

- (void)setRightValue:(CGFloat)newValue {
    if (newValue > maxValue)
        newValue = maxValue;
    
    if (newValue < leftValue)
        newValue = leftValue;
    
    rightValue = newValue;
    
    [self setNeedsLayout];
}

- (void)setCurrentProgressValue:(CGFloat)newValue {
    if (newValue > maxValue)
        newValue = maxValue;
    
    if (newValue < minValue)
        newValue = minValue;
    
    currentProgressValue = newValue;
    
    [self setNeedsLayout];
}

- (void)setMinValue:(CGFloat)newValue {
    minValue = newValue;
    
    if (leftValue < minValue)
        leftValue = minValue;
    
    if (rightValue < minValue)
        rightValue = minValue;
    
    [self setNeedsLayout];
}

- (void)setMaxValue:(CGFloat)newValue {
    maxValue = newValue;
    
    if (leftValue > maxValue)
        leftValue = maxValue;
    
    if (rightValue > maxValue)
        rightValue = maxValue;
    
    [self setNeedsLayout];
}

- (CGFloat)minValue {
    return minValue;
}

- (CGFloat)maxValue {
    return maxValue;
}

- (CGFloat)currentProgressValue {
    return currentProgressValue;
}

- (CGFloat)leftValue {
    return leftValue;
}

- (CGFloat)rightValue {
    return rightValue;
}

- (void)setShowProgress:(BOOL)showProgress {
    progressImage.hidden = !showProgress;
}

- (BOOL)showProgress {
    return !progressImage.hidden;
}

- (void)setShowRange:(BOOL)showRange {
    rangeImage.hidden = !showRange;
}

- (BOOL)showRange {
    return !rangeImage.hidden;
}


- (void)setup {
    if (maxValue == 0.0) {
        NSNumber * tt = [[NSNumber alloc]initWithFloat: 100];
        maxValue = [tt intValue]  ;
        

    }
    
    leftValue = minValue;
    rightValue = maxValue;
    
    slider = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"BJRangeSliderEmpty.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4]];
    [self addSubview:slider];
    
    rangeImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"BJRangeSliderEmpty.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4]];
//    [self addSubview:rangeImage];
    
    progressImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"BJRangeSliderBlue.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4]];
    [self addSubview:progressImage];
    
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    
    CGFloat availableWidth = self.frame.size.width;// - BJRANGESLIDER_THUMB_SIZE;
    CGFloat inset = 0; //BJRANGESLIDER_THUMB_SIZE / 2;
    
    CGFloat range = maxValue - minValue;
    
    CGFloat left = floorf((leftValue - minValue) / range * availableWidth);
//    CGFloat left = leftValue;
    CGFloat right = floorf((rightValue - minValue) / range * availableWidth);
//    CGFloat right = rightValue;
    
    if (isnan(left)) {
        left = 0;
    }
    
    if (isnan(right)) {
        right = 0;
    }
    
    slider.frame = CGRectMake(inset, self.frame.size.height / 2 - 5, availableWidth, 10);
    
//    CGFloat rangeWidth = right - left;
    if ([self showRange]) {
        rangeImage.frame = CGRectMake(inset + left, self.frame.size.height / 2 - 5, range, 10);
    }
    
    if ([self showProgress]) {
        CGFloat progressWidth = floorf(leftValue / rightValue * availableWidth);
        if (isnan(progressWidth)) {
            progressWidth = 0;
        }
        
//        progressImage.frame = CGRectMake(inset + left, self.frame.size.height / 2 - 5, progressWidth, 10);//
        progressImage.frame = CGRectMake(0, self.frame.size.height / 2 - 5, progressWidth, 10);
    }
}


- (void)setDisplayMode:(ownSliderDisplayMode)mode {
    switch (mode) {
        case AudioRecordMode:
            self.showThumbs = NO;
            self.showRange = NO;
            self.showProgress = YES;
            progressImage.image = [[UIImage imageNamed:@"BJRangeSliderRed.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4];
            break;
            
        case AudioSetTrimMode:
            self.showThumbs = YES;
            self.showRange = YES;
            self.showProgress = NO;
            break;
            
        case AudioPlayMode:
            self.showThumbs = NO;
            self.showRange = YES;
            self.showProgress = YES;
            progressImage.image = [[UIImage imageNamed:@"BJRangeSliderGreen.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:4];
        default:
            break;
    }
    
    [self setNeedsLayout];
}



@end
