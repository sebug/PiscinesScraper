//
//  SGCAppDelegate.m
//  PiscinesScraper
//
//  Created by Sebastian Gfeller on 25.12.13.
//  Copyright (c) 2013 Sebastian Gfeller. All rights reserved.
//

#import "SGCAppDelegate.h"
#import "SGCAgendaParser.h"
#import "SGCLineMatch.h"
#import <Quartz/Quartz.h>

@implementation SGCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *inputURL = @"http://www.ville-geneve.ch/fileadmin/public/Departement_3/sport/horaires-piscines-patinoires-ville-de-geneve.pdf";
    
    PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL URLWithString:inputURL]];
    
    SGCAgendaParser* agendaParser = [[SGCAgendaParser alloc] initWithPDFDocument:pdfDoc];
    
    SGCOpeningHourInformation *info = [agendaParser openingHoursToday];
    
    NSLog(@"%@", [info getSimpleTextRepresentationWithDateFormatter:agendaParser.universalFormatter]);
}

@end
