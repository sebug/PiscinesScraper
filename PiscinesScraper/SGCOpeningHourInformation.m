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

-(NSString*)getSimpleTextRepresentationWithDateFormatter:(NSDateFormatter *)dateFormatter {
    NSMutableString *result = [[NSMutableString alloc] init];
    if (self.date && dateFormatter) {
        [result appendString:[dateFormatter stringFromDate:self.date]];
    } else {
        [result appendString:@"Unknown date"];
    }
    [result appendString:@"\n"];
    
    if (self.locationsToOpeningHours) {
        [self.locationsToOpeningHours enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [result appendString:key];
            [result appendString:@": "];
            [result appendString: obj];
            [result appendString:@"\n"];
        }];
    }
    
    return [NSString stringWithString:result]; // freeze
}
@end
