//
//  SGCLineMatch.m
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 11.01.14.
//  Copyright (c) 2014 Sebastian Gfeller. All rights reserved.
//

#import "SGCLineMatch.h"
#import "SGCOpeningHourInformation.h"

@implementation SGCLineMatch

-(id)init {
    self = [super init];
    if (self) {
        _weekdayRects = malloc(sizeof(NSRect) * 7);
        _openingHourInformations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(NSRect)getFullSemaineRect {
    
    CGFloat vernetsTopPoint = self.vernetsRect.origin.y + self.vernetsRect.size.height;
    
    NSRect result;
    result.origin.x = 0;
    result.origin.y =  vernetsTopPoint; // From just above the next line
    result.size.width = self.weekdayRects[0].origin.x - self.semaineRect.origin.x;
    
    CGFloat semaineTopPoint = self.semaineRect.origin.y + self.semaineRect.size.height;
    CGFloat lundiTopPoint = self.weekdayRects[0].origin.y + self.weekdayRects[0].size.height;
    
    if (semaineTopPoint > lundiTopPoint) {
        result.size.height = semaineTopPoint - vernetsTopPoint;
    } else {
        result.size.height = lundiTopPoint - vernetsTopPoint;
    }
    
    return result;
}

-(void)setOpeningHoursForWeekDayIndex:(int)idx withText:(NSString *)openingHoursText withLocationName:(NSString *)locationName {
    // Strip faulty characters
    NSString *cleanedOpeningHours = [openingHoursText stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    // First, find the date
    NSDateComponents *dayComponents = [[NSDateComponents alloc] init];
    dayComponents.day = idx;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *dateToSet = [calendar dateByAddingComponents:dayComponents toDate:self.fromDate options:0];
    
    // use string keys into the dictionary
    SGCOpeningHourInformation *info = [self.openingHourInformations objectForKey:[NSNumber numberWithInt:idx]];
    if (info == NULL) {
        info = [[SGCOpeningHourInformation alloc] init];
        info.date = dateToSet;
        [self.openingHourInformations setObject:info forKeyedSubscript:[NSNumber numberWithInt:idx]];
    }
    [info setOpeningHour:cleanedOpeningHours forLocation:locationName];
}
@end
