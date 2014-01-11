//
//  SGCLineMatch.m
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 11.01.14.
//  Copyright (c) 2014 Sebastian Gfeller. All rights reserved.
//

#import "SGCLineMatch.h"

@implementation SGCLineMatch

-(NSRect)getFullSemaineRect {
    
    CGFloat vernetsTopPoint = self.vernetsRect.origin.y + self.vernetsRect.size.height;
    
    NSRect result;
    result.origin.x = 0;
    result.origin.y =  vernetsTopPoint; // From just above the next line
    result.size.width = self.lundiRect.origin.x - self.semaineRect.origin.x;
    
    CGFloat semaineTopPoint = self.semaineRect.origin.y + self.semaineRect.size.height;
    CGFloat lundiTopPoint = self.lundiRect.origin.y + self.lundiRect.size.height;
    
    if (semaineTopPoint > lundiTopPoint) {
        result.size.height = semaineTopPoint - vernetsTopPoint;
    } else {
        result.size.height = lundiTopPoint - vernetsTopPoint;
    }
    
    return result;
}

@end
