//
//  ownSlider.h
//  My Audio Type
//
//  Created by okamoto on 09.11.16.
//  Copyright (c) 2016 okamoto. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef enum {
    AudioRecordMode = 0,
    AudioSetTrimMode,
    AudioPlayMode,
    
} ownSliderDisplayMode;

#define BJRANGESLIDER_THUMB_SIZE 0.0

@interface ownSlider : UIControl{
    UIImageView *slider;
    UIImageView *progressImage;
    UIImageView *rangeImage;
    
    CGFloat minValue;
    CGFloat maxValue;
    CGFloat currentProgressValue;
    
    CGFloat leftValue;
    CGFloat rightValue;
}
@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat maxValue;
@property (nonatomic, assign) CGFloat currentProgressValue;

@property (nonatomic, assign) CGFloat leftValue;
@property (nonatomic, assign) CGFloat rightValue;

@property (nonatomic, assign) BOOL showThumbs;
@property (nonatomic, assign) BOOL showProgress;
@property (nonatomic, assign) BOOL showRange;

- (void)setDisplayMode:(ownSliderDisplayMode)mode;


@end
