//
//  SGCAgendaParser.h
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 25.12.13.
//  Copyright (c) 2013 Sebastian Gfeller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface SGCAgendaParser : NSObject

@property (readonly) PDFDocument *document;

@property NSArray *weekdayNames;

// the date format in the document: 11 janvier 2014
@property NSDateFormatter *documentFormatter;

// The universal date format: 2014-01-11
@property NSDateFormatter *universalFormatter;

@property NSMutableArray *openingHours;

-(id)initWithPDFDocument: (PDFDocument*)theDocument;

-(void)readContent;

-(void)saveOutputToFile: (NSString*)fileName;

@end
