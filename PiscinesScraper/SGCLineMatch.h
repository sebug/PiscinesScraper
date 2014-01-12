//
//  SGCLineMatch.h
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 11.01.14.
//  Copyright (c) 2014 Sebastian Gfeller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGCLineMatch : NSObject

// rectangles in the PDF
@property NSRect semaineRect;
@property NSRect *weekdayRects;
@property NSRect vernetsRect;
@property NSRect varembeRect;

@property (copy) NSDate *fromDate;
@property (copy) NSDate *toDate;

@property NSMutableDictionary *openingHourInformations;

-(NSRect)getFullSemaineRect;

-(void)setOpeningHoursForWeekDayIndex:(int)idx withText:(NSString*)openingHoursText withLocationName:(NSString*)locationName;

@end
