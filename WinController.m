//	Copyright 2003-2011  Chad Armstrong <support@edenwaith.com>
//
//	This library is free software; you can redistribute it and/or
//	modify it under the terms of the GNU Lesser General Public
//	License as published by the Free Software Foundation; either 
//	version 2.1 of the License, or (at your option) any later version.
//
//	This library is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//	Lesser General Public License for more details.
//
//	You should have received a copy of the GNU Lesser General Public 
//	License along with this library.  If not, see <http://www.gnu.org/licenses/>.

#import "WinController.h"

@implementation WinController

// =========================================================================
// (id) init
// -------------------------------------------------------------------------
// Version: 28. January 2004
// Created: Summer 2003
// =========================================================================
- (id) init
{
    if (self = [super init])
    {
        timer = nil;
        file_list = [[NSMutableArray alloc] initWithCapacity: 10];
		
		outputString = [[NSMutableString alloc] init];
        
        [self checkOSVersion];
    }
    
    return self;
}


// =========================================================================
// (void) dealloc
// -------------------------------------------------------------------------
// Created: 18 January 2009 0:08
// Version: 18 January 2009 0:08
// =========================================================================
- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowWillCloseNotification object: window];
	
	[outputFile closeFile];
	[outputString release];
	[preferenceController release];
	[consoleController release];
	
	[super dealloc];
}

// =========================================================================
// (void) awakeFromNib
// -------------------------------------------------------------------------
// Version: 18. March 2004 2:02
// Created: Summer 2003
// =========================================================================
- (void) awakeFromNib 
{

    [window center];
    
    if ( [ [[tabView selectedTabViewItem] label] isEqual: @"Extractor"] )
    {
        [self windowShrink];
    }
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ConsoleLogOpen"] != nil)
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConsoleLogOpen"] == YES)
		{
			[self toggleConsoleLog:nil];
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowsClosing:)
												 name:NSWindowWillCloseNotification
											   object:window];
}


// =========================================================================
// (void) windowsClosing: (NSNotification *) aNotification
// -------------------------------------------------------------------------
// Save any preferences before closing down the application.
// -------------------------------------------------------------------------
// Created: 16 February 2009 20:05
// Version: 16 February 2009 20:11
// =========================================================================
- (void) windowsClosing: (NSNotification *) aNotification
{
	if (consoleController)
	{
		[[NSUserDefaults standardUserDefaults] setBool:[consoleController isVisible] forKey: @"ConsoleLogOpen"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

// =========================================================================
// (BOOL) applicationShouldTerminateAfterLastWindowClosed
// -------------------------------------------------------------------------
// Connect the File Owner (CTRL-click & drag to WinController) as the delegate.
// -------------------------------------------------------------------------
// Version: Summer 2003
// Created: Summer 2003
// =========================================================================
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication 
{
    return YES;
}

// =========================================================================
// (void) application:(NSApplication*) openFile:
// -------------------------------------------------------------------------
// This method is only called when a file is dragged-n-dropped onto the
// GUI Tar icon.  This is useful since the actions are performed slightly
// different.
// -------------------------------------------------------------------------
// Version: 28. January 2004
// Created: 20. January 2004
// =========================================================================
- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [file_list addObject: filename];
    
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.0
                         target: self
                         selector: @selector(addNewFiles:)
                         userInfo: nil
                         repeats: YES];
    }
    
    return NO;
}


// =========================================================================
// (void) addNewFiles : (NSTimer *) aTimer
// -------------------------------------------------------------------------
// Version: 28. January 2004
// Created: 27. January 2004
// =========================================================================
- (void) addNewFiles : (NSTimer *) aTimer
{
    NSString *ret_function = [[NSString alloc] init];
    
    [aTimer invalidate];
    timer = nil;
    
    ret_function = [self determineFunction];
    
    if ([ret_function isEqualToString: @"Extractor"] == YES)
    {
    
        [self switchTab: @"Extractor"];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:@"notifyExtractor" object: file_list];
        // Need to reinitalize the file_list to nothing after sending the data
        [file_list removeAllObjects];
    }
    else if ([ret_function isEqualToString: @"Compressor"] == YES)
    {
        [self switchTab:@"Compressor"];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:@"notifyCompressor" object: file_list];
        [file_list removeAllObjects];
    }
    else if ([ret_function isEqualToString:@"Mixed"] == YES)
    {
        NSBeep();
    
		// Will probably just need to use the didEndSelector function instead.
		// Look around line 315 of CController.m for other references
        [NSApp beginSheet:querySheet modalForWindow:window
                modalDelegate:self didEndSelector:NULL contextInfo:nil];       
    }
    else if ([ret_function isEqualToString:@"Unknown"] == YES)
    {
        [file_list removeAllObjects];
    }
    
	[ret_function release];
}

// =========================================================================
// (NSString *) determineFunction
// -------------------------------------------------------------------------
// Try and determine if the dropped files are to be expanded from an archive
// or compressed form, of if the files are to be compressed and/or archived.
// -------------------------------------------------------------------------
// Version: 9 August 2006 21:40
// Created: 28. January 2004
// =========================================================================
- (NSString *) determineFunction
{
    NSArray *file_types = [NSArray arrayWithObjects:@"tar", @"svgz", @"gz", @"tgz", @"z", @"Z", @"taz", @"tbz", @"tbz2", @"bz", @"bz2", @"zip", @"rar", @"7z", nil];
    int fl_count 	= [file_list count];
    int archive_count	= 0;
    int i = 0;
    
    for (i = 0; i < fl_count; i++)
    {
        if ([file_types containsObject: [[file_list objectAtIndex: i] pathExtension]] == YES)
        {
            archive_count++;
        }
    }
    
    if (archive_count == fl_count)
    {
        return @"Extractor";
    }
    else if (archive_count > 0)
    {
        return @"Mixed";
    }
    else if (archive_count == 0)
    {
        return @"Compressor";
    }
    else
    {
        return @"Unkown";
    }
    
    return @"Unknown";
}


// =========================================================================
// (IBAction) goToFunction: (id) sender
// -------------------------------------------------------------------------
// This function is called after the user selects an option from the 
// querySheet (Extract or Compress).
// -------------------------------------------------------------------------
// Version: 15. February 2004
// Created: 15. February 2004 20:04
// =========================================================================
- (IBAction) goToFunction: (id) sender
{    
    [querySheet orderOut:nil];
    [NSApp endSheet: querySheet];
    
    if ([[sender title] isEqual: @"Extract"])
    {
        [self switchTab: @"Extractor"];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:@"notifyExtractor" object: file_list];    
    }
    else if ([[sender title] isEqual: @"Compress"])
    {
        [self switchTab:@"Compressor"];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:@"notifyCompressor" object: file_list];    
    }
    else // Error!  Should never reach this point
    {
        NSBeep();
        NSRunAlertPanel(@"Error", @"There was an unexpected error.  Please report this problem to support@edenwaith.com", @"OK", nil, nil);
    }
    
    [file_list removeAllObjects];
    
}

#pragma mark -

// =========================================================================
// (void) switchTab: (NSString *) theFunction
// -------------------------------------------------------------------------
// When the tab is switched, tabView is called to grow or shrink the window
// -------------------------------------------------------------------------
// Version: 28. January 2004 21:39
// Created: 28. January 2004 21:39
// =========================================================================
- (void) switchTab: (NSString *) theFunction
{
    if ( [[[tabView selectedTabViewItem] label] isEqual: @"Extractor"] && [theFunction isEqual: @"Compressor"] )	// switch to Compressor
    {
        [tabView selectTabViewItemAtIndex: 1];
    }
    else if ( [[[tabView selectedTabViewItem] label] isEqual: @"Compressor"] && [theFunction isEqual: @"Extractor"] )	// switch to Extractor
    {
        [tabView selectTabViewItemAtIndex: 0];
    }
}


// =========================================================================
// (void) tabView: (NSTabView *)tabView didSelectTabViewItem: ...
// -------------------------------------------------------------------------
// Version: Summer 2003
// Created: Summer 2003
// =========================================================================
- (void) tabView:(NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{    
    if ( [[tabViewItem label] isEqual: @"Extractor"])
    {
        [self windowShrink];
    }
    else if ( [[tabViewItem label] isEqual: @"Compressor"] )
    {
        [self windowGrow];
    }
}


// =========================================================================
// (void) windowShrink
// -------------------------------------------------------------------------
// The NSTabView needs to be springy to the internal windows to move properly
// All other objects need to be springy to the outside bottom of the window
// -------------------------------------------------------------------------
// Version: Summer 2003
// Created: Summer 2003
// =========================================================================
- (void) windowShrink
{
    NSRect aFrame = [window frame];
    
    aFrame.origin.y 	+= 147;
    aFrame.size.height 	-= 147;
    
    [window setFrame:NSMakeRect(aFrame.origin.x, aFrame.origin.y, aFrame.size.width, aFrame.size.height) display: YES animate: YES];
}


// =========================================================================
// (void) windowGrow
// -------------------------------------------------------------------------
// Version: Summer 2003
// Created: Summer 2003
// =========================================================================
- (void) windowGrow
{
    NSRect aFrame = [window frame];
    
    aFrame.origin.y 	-= 147;
    aFrame.size.height 	+= 147;
    
    [window setFrame:NSMakeRect(aFrame.origin.x, aFrame.origin.y, aFrame.size.width, aFrame.size.height) display: YES animate: YES];
}


// =========================================================================
// (void) checkOSVersion
// -------------------------------------------------------------------------
// Check for the Mac OS version for Mac OS 10.0 through 10.6
// http://developer.apple.com/library/mac/#releasenotes/Cocoa/AppKit.html
// Unused system info code:
// NSString *aString = [[NSProcessInfo processInfo] operatingSystemVersionString];
// NSLog(@"Version: %@", aString);
// -------------------------------------------------------------------------
// Created: 22 September 2004 19:12
// Version: 21 January 2011 20:46
// =========================================================================
- (void) checkOSVersion
{
    if ( floor(NSAppKitVersionNumber) <= 577 )
    {
        os_version = 1000;
    }
    else if ( floor(NSAppKitVersionNumber) <= 620 )
    {
        os_version = 1010;
    }
    else if ( floor(NSAppKitVersionNumber) <= 663)
    {
        os_version = 1020;
    }
    else if ( floor(NSAppKitVersionNumber) <= 743) 
    {
        os_version = 1030;
    }
	else if ( floor(NSAppKitVersionNumber) <= 824)
	{
        os_version = 1040;
    }
	else if ( floor(NSAppKitVersionNumber) <= 949)
	{
		os_version = 1050;
	}
	else
	{
		os_version = 1060;
	}
}

// =========================================================================
// (IBAction) goToProductPage: (id) sender
// -------------------------------------------------------------------------
// Version: 8. February 2004 2:32
// Created: 8. February 2004 2:32
// =========================================================================
- (IBAction) goToProductPage: (id) sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.edenwaith.com/products/guitar/"]];
}


// =========================================================================
// (IBAction) goToFeedbackPage: (id) sender
// -------------------------------------------------------------------------
// Version: 6 August 2006 17:28
// Created: 16. February 2004 7:50
// =========================================================================
- (IBAction) goToFeedbackPage: (id) sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"mailto:support@edenwaith.com?Subject=GUI%20Tar%20Feedback"]];
}

// =========================================================================
// (IBAction) openHelp: (id) sender
// -------------------------------------------------------------------------
// The Help system contents are too large for Mac OS 10.1's Help Viewer to
// handle, so a web browser is opened to view the Help files for Mac OS 10.1
// -------------------------------------------------------------------------
// Version: 31. January 2005 21:10
// Created: 31. January 2005 21:10
// =========================================================================
- (IBAction) openHelp: (id) sender
{
    if (os_version >= 1020)
    {    
        [NSApp showHelp: self];
    }
    else
    {
        [[NSWorkspace sharedWorkspace] openURL: [NSURL fileURLWithPath:[[[NSBundle mainBundle] pathForResource:@"Help" ofType:@""]  stringByAppendingString: @"/index.html"] ] ];
    }
}

#pragma mark -

// =========================================================================
// (IBAction) showPreferencePanel: (id) sender
// -------------------------------------------------------------------------
// Stub method.  Not currently used.
// -------------------------------------------------------------------------
// Created: 13 June 2008 21:09
// Version: 13 June 2008 21:09
// =========================================================================
- (IBAction) showPreferencePanel: (id) sender
{
	if (!preferenceController)
	{
		preferenceController = [[PreferenceController alloc] init];
	}
	
	[preferenceController showWindow: self];
}


// =========================================================================
// (IBAction) toggleConsoleLog: (id) sender
// -------------------------------------------------------------------------
// Created: 17 January 2009 23:30
// Version: 18 January 2009 0:20
// =========================================================================
- (IBAction) toggleConsoleLog: (id) sender
{
	if (!consoleController)
	{
		consoleController = [[ConsoleController alloc] init];
	}
	
	if ([consoleController isVisible] == NO)
	{
		[consoleLogMenu setTitle: NSLocalizedString(@"Hide Console Log", nil)];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"ConsoleLogOpen"];
		[consoleController showWindow: self];
		[consoleController openConsoleLogPanel];
	}
	else
	{
		[consoleLogMenu setTitle: NSLocalizedString(@"Show Console Log", nil)];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"ConsoleLogOpen"];		
		[consoleController close];
	}
}

// =========================================================================
// (void) consoleLogClosed
// -------------------------------------------------------------------------
// Created: 21 January 2009 22:16
// Version: 21 January 2009 22:16
// =========================================================================
- (void) consoleLogClosed
{
	[consoleLogMenu setTitle: NSLocalizedString(@"Show Console Log", nil)];
}


// =========================================================================
// (void) directLogOutput: (NSString *) string
// -------------------------------------------------------------------------
// Write log output to either the Console Log (if it has been loaded), or
// write the data out to the GUITar.log file.
// -------------------------------------------------------------------------
// Created: 6 February 2009 22:47
// Version: 3 March 2009 20:52
// =========================================================================
- (void) directLogOutput: (NSString *) string
{
	if (!consoleController)
	{
		[outputString appendString: string];
	}
	else
	{
		[consoleController writeToConsole: string];
	}
}


// =========================================================================
// (void) saveLogFile
// -------------------------------------------------------------------------
// Created: 10 February 2009 20:11
// Version: 10 February 2009 20:11
// =========================================================================
- (void) saveLogFile
{
	if (!consoleController)
	{
		outputFile = [NSFileHandle fileHandleForUpdatingAtPath: [@"~/Library/Logs/GUITar.log" stringByExpandingTildeInPath]];
		[outputFile seekToEndOfFile];
		[outputFile writeData: [outputString dataUsingEncoding: NSUTF8StringEncoding]];
	}
	else
	{
		[consoleController saveLogToFile];
	}
}

@end
