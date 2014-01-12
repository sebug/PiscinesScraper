//
//  SGCOpeningHourInformation.h
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 12.01.14.
//  Copyright (c) 2014 Sebastian Gfeller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGCOpeningHourInformation : NSObject

@property NSDate *date;

@property (readonly) NSMutableDictionary *locationsToOpeningHours;

-(void)setOpeningHour:(NSString*)openingHourText forLocation:(NSString*)location;

@end
