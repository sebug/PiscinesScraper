//
//  SGCOpeningHourInformation.m
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 12.01.14.
//  Copyright (c) 2014 Sebastian Gfeller. All rights reserved.
//

#import "SGCOpeningHourInformation.h"

@implementation SGCOpeningHourInformation

-(id)init {
    self = [super init];
    if (self) {
        _locationsToOpeningHours = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)setOpeningHour:(NSString *)openingHourText forLocation:(NSString *)location {
    [self.locationsToOpeningHours setValue:openingHourText forKey:location];
}
@end
