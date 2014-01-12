//
//  SGCAgendaParser.m
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 25.12.13.
//  Copyright (c) 2013 Sebastian Gfeller. All rights reserved.
//

#import "SGCAgendaParser.h"
#import "SGCLineMatch.h"
#import "SGCOpeningHourInformation.h"
#include <math.h>

@implementation SGCAgendaParser

-(id)initWithPDFDocument:(PDFDocument *)theDocument {
    self = [super init];
    if (self) {
        _document = [theDocument copy];
        _weekdayNames = [NSArray arrayWithObjects:@"Lundi",@"Mardi",@"Mercredi",@"Jeudi",@"Vendredi",@"Samedi",@"Dimanche", nil];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"fr_CH"]; // Yes, we're in Geneva
        _documentFormatter = [[NSDateFormatter alloc] init];
        [_documentFormatter setDateFormat:@"dd MMMM yyyy"];
        [_documentFormatter setLocale:locale];
        _universalFormatter = [[NSDateFormatter alloc] init];
        [_universalFormatter setDateFormat:@"yyyy-MM-dd"];
        [_universalFormatter setLocale:locale];
    }
    return self;
}

-(void)readContent {
    if (self.document == NULL) {
        NSException *e = [NSException
                          exceptionWithName:@"NoDocumentPresentException" reason:@"You have not specified a PDF document" userInfo:nil];
        @throw e;
    }
    PDFPage *firstPage = [self.document pageAtIndex:0];
    
//    NSRect bounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];
    
    NSMutableArray *lineMatches = [[NSMutableArray alloc] init];
    
    [[self.document findString:@"semaine" withOptions:NSCaseInsensitiveSearch] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        // Try to log the line
        NSRect boundsOnFirstPage = [obj boundsForPage:firstPage];
        SGCLineMatch *lineMatch = [[SGCLineMatch alloc] init];
        lineMatch.semaineRect = boundsOnFirstPage;
        [lineMatches addObject:lineMatch];
    }];
    
    if (lineMatches.count > 0) {
        // Now add the closest entry for "Piscine des Vernets" to the line match
        [[self.document findString:@"Piscine des Vernets" withOptions:NSCaseInsensitiveSearch] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSRect boundsOnFirstPage = [obj boundsForPage:firstPage];
            // Find the minimal element in the line matches
            NSArray *sortedByDistance = [SGCAgendaParser sortLineMatchArrayByWeekElement:lineMatches byVerticalDistanceToPosition:boundsOnFirstPage.origin.y];
            
            // line matches will always have at least one item because of the outer check
            SGCLineMatch *closest = [sortedByDistance objectAtIndex:0];
            
            // now set the vernets object
            closest.vernetsRect = boundsOnFirstPage; // we could assert here that vernetsRect was not set before
        }];
        
        [self findStringAndAssignToClosest:@"Piscine des Vernets" withLineMatches:lineMatches andAssignmentBlock:^(SGCLineMatch *closest, NSRect rect) {
            closest.vernetsRect = rect;
        }];
        
        [self findStringAndAssignToClosest:@"Piscine de Varemb" withLineMatches:lineMatches andAssignmentBlock:^(SGCLineMatch *closest, NSRect rect) {
            closest.varembeRect = rect;
        }];
        
        // Repeat with the weekday texts for outer bounds
        [self.weekdayNames enumerateObjectsUsingBlock:^(id weekday, NSUInteger idx, BOOL *stop) {
            [self findStringAndAssignToClosest:weekday withLineMatches:lineMatches andAssignmentBlock:^(SGCLineMatch *closest, NSRect rect) {
                closest.weekdayRects[idx] = rect;
            }];
        }];
        
        [lineMatches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *weekSpanError) {
            NSRect fullSemaineRect = [obj getFullSemaineRect];
            NSString *lineContent = [[firstPage selectionForRect:fullSemaineRect] string];
            
            NSDate *endDate = [self extractWeekSpanEndDateFromLineContent:lineContent];
            if (endDate) {
                NSDateComponents *weekComponentExclusive = [[NSDateComponents alloc] init];
                weekComponentExclusive.day = -6;
                
                NSCalendar *calendar = [NSCalendar currentCalendar];
                NSDate *startDate = [calendar dateByAddingComponents:weekComponentExclusive toDate:endDate options:0];
                
                [obj setFromDate: startDate];
                [obj setToDate: endDate];
            }
        }];
        
        // Finally, match the opening hours for Vernets
        int downwardSlack = 5;
        int rightAdditionalSlack = 15;
        int *slacksToTry = malloc(sizeof(int) * 5);
        slacksToTry[0] = 0;
        slacksToTry[1] = 5;
        slacksToTry[2] = 10;
        slacksToTry[3] = 20;
        slacksToTry[4] = 30;
        
        [lineMatches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SGCLineMatch *lineMatch = obj;
            for (int i = 0; i < 7; i += 1) {
                NSRect weekdayRect = lineMatch.weekdayRects[i];

                for (int j = 0; j < 5; j += 1) {
                    int slack = slacksToTry[j];
                    NSRect valueRect = NSMakeRect(floorf(weekdayRect.origin.x - slack), floorf(lineMatch.vernetsRect.origin.y - downwardSlack), ceilf(weekdayRect.size.width + slack + rightAdditionalSlack), ceilf(lineMatch.vernetsRect.size.height + slack));
                    
                    NSString *valueContent = [[firstPage selectionForRect:valueRect] string];
                    if (valueContent != NULL && [valueContent length] > 0) {
                        [lineMatch setOpeningHoursForWeekDayIndex:i withText:valueContent withLocationName:@"Vernets"];
                        break;
                    }
                }
            }
        }];
        
        // And Varembé
        [lineMatches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SGCLineMatch *lineMatch = obj;
            for (int i = 0; i < 7; i += 1) {
                NSRect weekdayRect = lineMatch.weekdayRects[i];
                
                for (int j = 0; j < 5; j += 1) {
                    int slack = slacksToTry[j];
                    NSRect valueRect = NSMakeRect(floorf(weekdayRect.origin.x - slack), floorf(lineMatch.varembeRect.origin.y - downwardSlack), ceilf(weekdayRect.size.width + slack + rightAdditionalSlack), ceilf(lineMatch.varembeRect.size.height + slack));
                    
                    NSString *valueContent = [[firstPage selectionForRect:valueRect] string];
                    if (valueContent != NULL && [valueContent length] > 0) {
                        [lineMatch setOpeningHoursForWeekDayIndex:i withText:valueContent withLocationName:@"Varembé"];
                        break;
                    }
                }
            }
        }];
        
        free(slacksToTry);
        slacksToTry = NULL;
        
        // Ok, now store the parsed results in a flattened array
        self.openingHours = [[NSMutableArray alloc] init];
        [lineMatches enumerateObjectsUsingBlock:^(id lmOuter, NSUInteger idx, BOOL *stop) {
            SGCLineMatch *lineMatch = lmOuter;
            [lineMatch.openingHourInformations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self.openingHours addObject:obj];
            }];
        }];
    }
}

-(NSDate*)extractWeekSpanEndDateFromLineContent:(NSString*)lineContent {
    NSError *weekSpanError = NULL;
    NSRegularExpression *weekSpanRegularExpression =
    [NSRegularExpression
     regularExpressionWithPattern:@"semaine.*au\\s+(\\d+\\s*\\S+\\s*\\d\\d\\d\\d)"
     options:(NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionCaseInsensitive)
     error:&weekSpanError];
    NSTextCheckingResult *match = [weekSpanRegularExpression firstMatchInString:lineContent options:0 range:NSMakeRange(0, [lineContent length])];
    if (match) {
        NSRange endDateRange = [match rangeAtIndex:1];
        NSString *endDateString = [lineContent substringWithRange:endDateRange];
        // the PDF generation is mean: é is actually two characters, one ´ over the e, so we'll have to remove those
        // I'll see in august how û is replaced :-/
        // Yes, the two é are not the same!!!
        endDateString = [endDateString stringByReplacingOccurrencesOfString:@"é" withString:@"é" options:0 range:NSMakeRange(0,[endDateString length])];
        
        return [self.documentFormatter dateFromString: endDateString];
    } else {
        return NULL;
    }
}

-(void)findStringAndAssignToClosest:(NSString*)searchString withLineMatches:(NSArray*)lineMatchArray andAssignmentBlock:(void (^)(SGCLineMatch* closest, NSRect rect))assignmentBlock {
    PDFPage *firstPage = [self.document pageAtIndex:0];
    [[self.document findString:searchString withOptions:NSCaseInsensitiveSearch] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRect boundsOnFirstPage = [obj boundsForPage:firstPage];
        // Find the minimal element in the line matches
        NSArray *sortedByDistance = [SGCAgendaParser sortLineMatchArrayByWeekElement:lineMatchArray byVerticalDistanceToPosition:boundsOnFirstPage.origin.y];
        
        // line matches will always have at least one item because of the outer check
        SGCLineMatch *closest = [sortedByDistance objectAtIndex:0];
        
        // now set the object
        assignmentBlock(closest,boundsOnFirstPage);
    }];
}

// Sorts the array of SGCLineMatches by the semaine element
+(NSArray*)sortLineMatchArrayByWeekElement:(NSArray*)array byVerticalDistanceToPosition:(CGFloat)yPosition {
    return [array sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        SGCLineMatch *m1 = obj1;
        SGCLineMatch *m2 = obj2;
        CGFloat distance1 = m1.semaineRect.origin.y - yPosition;
        CGFloat distance2 = m2.semaineRect.origin.y - yPosition;
        return [SGCAgendaParser compareDistance:distance1 withDistance:distance2];

    }];
}

+(NSComparisonResult)compareDistance:(CGFloat)firstDistance withDistance:(CGFloat)secondDistance {
    if (abs((int)firstDistance) < abs((int)secondDistance)) {
        return NSOrderedAscending;
    } else if (abs((int)firstDistance) > abs((int)secondDistance)) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

-(void)saveOutputToFile:(NSString *)fileName {
    if (self.openingHours == NULL) {
        NSException *e = [NSException
                          exceptionWithName:@"OpeningHoursNotReadYetException" reason:@"You have not yet read the opening hours." userInfo:nil];
        @throw e;
    }
    
    [self.openingHours sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        SGCOpeningHourInformation *oh1 = obj1;
        SGCOpeningHourInformation *oh2 = obj2;
        
        return [oh1.date compare: oh2.date];
    }];
    
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    
    [self.openingHours enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *item = [obj getSimpleTextRepresentationWithDateFormatter: self.universalFormatter];
        if (item) {
            [lines addObject:item];
        }
    }];
    
    NSString *fileContent = [lines componentsJoinedByString:@"\n"];
    NSError *writeError;
    [fileContent writeToFile:fileName atomically:NO encoding:NSUTF8StringEncoding error:&writeError];
    if (writeError) {
        NSLog(@"%@", [writeError description]);
    }
}

@end
