//
//  SGCAgendaParser.m
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 25.12.13.
//  Copyright (c) 2013 Sebastian Gfeller. All rights reserved.
//

#import "SGCAgendaParser.h"
#import "SGCLineMatch.h"

@implementation SGCAgendaParser

-(id)initWithPDFDocument:(PDFDocument *)theDocument {
    self = [super init];
    if (self) {
        _document = [theDocument copy];
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
        
        // Repeat with the monday text, so that we get outer bounds
        [self findStringAndAssignToClosest:@"Lundi" withLineMatches:lineMatches andAssignmentBlock:^(SGCLineMatch *closest, NSRect rect) {
            closest.lundiRect = rect;
        }];
        
        NSError *weekSpanError = NULL;
        NSRegularExpression *weekSpanRegularExpression =
            [NSRegularExpression
                regularExpressionWithPattern:@"semaine.*au\\s+(\\d+\\s*\\S+\\s*\\d\\d\\d\\d)"
                options:(NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionCaseInsensitive)
                error:&weekSpanError];
        
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"fr_CH"]; // Yes, we're in Geneva
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd MMMM yyyy"];
        [formatter setLocale:locale];
        
        NSDateFormatter *unifiedFormatter = [[NSDateFormatter alloc] init];
        [unifiedFormatter setDateFormat:@"yyyy-MM-dd"];
        [unifiedFormatter setLocale:locale];
        
        [lineMatches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *weekSpanError) {
            NSRect fullSemaineRect = [obj getFullSemaineRect];
            NSString *lineContent = [[firstPage selectionForRect:fullSemaineRect] string];
            
            NSTextCheckingResult *match = [weekSpanRegularExpression firstMatchInString:lineContent options:0 range:NSMakeRange(0, [lineContent length])];
            if (match) {;
                NSRange endDateRange = [match rangeAtIndex:1];
                NSString *endDateString = [lineContent substringWithRange:endDateRange];
                // the PDF generation is mean: é is actually two characters, one ´ over the e, so we'll have to remove those
                // I'll see in august how û is replaced :-/
                // Yes, the two é are not the same!!!
                endDateString = [endDateString stringByReplacingOccurrencesOfString:@"é" withString:@"é" options:0 range:NSMakeRange(0,[endDateString length])];
                
                NSDate *endDate = [formatter dateFromString: endDateString];
                
                if (endDate) {
                    NSDateComponents *weekComponentExclusive = [[NSDateComponents alloc] init];
                    weekComponentExclusive.day = -6;
                    
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDate *startDate = [calendar dateByAddingComponents:weekComponentExclusive toDate:endDate options:0];
                    
                    [obj setFromDate: startDate];
                    [obj setToDate: endDate];
                } else {
                    NSLog(@"Did not match: %@",endDateString);
                }
            }
        }];
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
        
        // now set the vernets object
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
    //[self.content writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
