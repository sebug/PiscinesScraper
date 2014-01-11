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

-(id)initWithPDFDocument: (PDFDocument*)theDocument;

-(void)readContent;

-(void)saveOutputToFile: (NSString*)fileName;

@end
