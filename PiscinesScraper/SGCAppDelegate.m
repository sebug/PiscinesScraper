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
    NSString *inputFilePath = @"/Users/sgfeller/Documents/Projets/PiscinesScraper/horaires-piscines-patinoires-ville-de-geneve.pdf";
    NSString *outputFilePath = @"/Users/sgfeller/Documents/Projets/PiscinesScraper/out.txt";
    PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: inputFilePath]];
    
    
    SGCAgendaParser* agendaParser = [[SGCAgendaParser alloc] initWithPDFDocument:pdfDoc];

    [agendaParser readContent];
    
    [agendaParser saveOutputToFile:outputFilePath];
}

@end
