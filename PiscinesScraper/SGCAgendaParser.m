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
    
    NSRect bounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];
    
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
            NSArray *sortedByDistance = [lineMatches sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                SGCLineMatch *m1 = obj1;
                SGCLineMatch *m2 = obj2;
                CGFloat distance1 = m1.semaineRect.origin.y - boundsOnFirstPage.origin.y;
                CGFloat distance2 = m2.semaineRect.origin.y - boundsOnFirstPage.origin.y;
                if (abs((int)(distance1) < abs((int)distance2))) {
                    return NSOrderedAscending;
                } else if (abs((int)distance1) > abs((int)distance2)) {
                    return NSOrderedDescending;
                } else {
                    return NSOrderedSame;
                }
            }];
            // line matches will always have at least one item because of the outer check
            SGCLineMatch *closest = [sortedByDistance objectAtIndex:0];
            
            // now set the vernets object
            closest.vernetsRect = boundsOnFirstPage;
            NSLog(@"Semaine: %f, Vernets: %f", closest.semaineRect.origin.y, closest.vernetsRect.origin.y);
        }];
    }
}

-(void)saveOutputToFile:(NSString *)fileName {
    //[self.content writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
