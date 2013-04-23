//
//  ConsoleController.m
//  GUI Tar
//
//  Created by Chad Armstrong on 1/17/09.
//  Copyright 2009 Edenwaith. All rights reserved.
//
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

#import "ConsoleController.h"
#import "WinController.h"

@implementation ConsoleController

- (id) init
{
	self = [super initWithWindowNibName: @"Console"];
	
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowWillCloseNotification object: consoleWindow];
	[super dealloc];
}

- (void) windowDidLoad
{
}


// =========================================================================
// (void) awakeFromNib
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 18 January 2009 0:42
// Version: 21 January 2011 21:10
// =========================================================================
- (void) awakeFromNib
{
	consoleToolbar = [[[NSToolbar alloc] initWithIdentifier:@"consoleToolbar"] autorelease];
	[consoleToolbar setDelegate:self];
    [consoleToolbar setAllowsUserCustomization:YES];
    [consoleToolbar setAutosavesConfiguration:YES];
	[consoleToolbar setSizeMode:NSToolbarSizeModeDefault];
	[consoleToolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	
	[consoleWindow setToolbar:consoleToolbar];
//	[[self window] setShowsToolbarButton:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(closeConsoleLogPanel:)
										  name:NSWindowWillCloseNotification
										  object:consoleWindow];
	
	// Do not allow the text fields to be editable (they are selectable, however)
	[textView setEditable: NO];
	[searchTextView setEditable: NO];
	
	// Load in console log data
	if ([[NSFileManager defaultManager] fileExistsAtPath: [@"~/Library/Logs/GUITar.log" stringByExpandingTildeInPath]] == YES)
	{
		NSString *consoleTextString = [[NSString alloc] initWithContentsOfFile:[@"~/Library/Logs/GUITar.log" stringByExpandingTildeInPath]];
		
		[textView setEditable:YES];
		[textView insertText: consoleTextString];
		[textView setEditable:NO];
		
		// This should scroll to the end of the console, but doesn't seem to be perfect...
		[textView scrollRangeToVisible: NSMakeRange([[textView string] length], 0)];
		
		[consoleTextString release];
	}
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"ConsoleLogPosition"] != nil)
	{
		NSRect consolePosition = NSRectFromString ([[NSUserDefaults standardUserDefaults] objectForKey: @"ConsoleLogPosition"]);
		
		[consoleWindow setFrame: consolePosition display: YES];
	}
}

#pragma mark -
#pragma mark Toolbar Methods

// =========================================================================
// (NSToolbarItem *) toolbar: (NSToolbar *) toolbar ...
// -------------------------------------------------------------------------
// http://www.macdevcenter.com/pub/a/mac/2002/03/15/cocoa.html?page=3
// http://developer.apple.com/documentation/Cocoa/Conceptual/SearchFields/Articles/MenuTemplate.html
// http://developer.apple.com/documentation/Cocoa/Conceptual/SearchFields/Articles/MenuTemplate.html#//apple_ref/doc/uid/20002245-BABFIBIA
// http://developer.apple.com/samplecode/SearchField/listing3.html
// -------------------------------------------------------------------------
// Created: 18 January 2009 15:20
// Version: 5 March 2009 23:05
// =========================================================================
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:@"Clear"] ) 
    {
        [item setLabel:@"Clear"];
        [item setToolTip: @"Clear Log"];
		[item setPaletteLabel:[item label]];
		[item setImage:[NSImage imageNamed:@"Clear"]];
		[item setTarget:self];
		[item setAction:@selector(clearConsole:)];
    }
	else if ([itemIdentifier isEqual: @"SearchField"]) 
	{
		[item setLabel:@"Search"];
		[item setPaletteLabel:@"Search"];
		[item setToolTip:@"Search Your Document"];
		searchField = [[[NSSearchField alloc] init] autorelease];
		[searchField setAction:@selector(searchText:)];
		[[searchField cell] setSendsWholeSearchString: NO];
		[item setView:searchField];
		[item setMinSize:NSMakeSize(100,NSHeight([searchFieldView frame]))];
		[item setMaxSize:NSMakeSize(200,NSHeight([searchFieldView frame]))];
		
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle: @"Search Menu"] autorelease];
		NSMenuItem *item;

		item = [[[NSMenuItem alloc] initWithTitle:@"Recent Searches"
										   action:NULL
									keyEquivalent:@""] autorelease];
		[item setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item atIndex:0];
		
		item = [[[NSMenuItem alloc] initWithTitle:@"Recents"
										   action:NULL
									keyEquivalent:@""] autorelease];
		[item setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item atIndex:1];

		item = [NSMenuItem separatorItem];
		[item setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item atIndex:2];
		
		item = [[[NSMenuItem alloc] initWithTitle: @"Clear" action: NULL keyEquivalent: @""] autorelease];
		[item setTag: NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem: item atIndex: 3];		
		
		item = [[[NSMenuItem alloc] initWithTitle:@"No recent searches"
										   action:NULL
									keyEquivalent:@""] autorelease];
		[item setTag:NSSearchFieldNoRecentsMenuItemTag];
		[cellMenu insertItem:item atIndex:4];		
		
		id searchCell = [searchField cell];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	return [item autorelease];
}

// Created: 18 January 2009 15:20
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: @"Clear",
			@"SearchField",
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarPrintItemIdentifier,
			NSToolbarSeparatorItemIdentifier,
			nil];
}

// Created: 18 January 2009 15:20
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: @"Clear", 
			NSToolbarFlexibleSpaceItemIdentifier,
			@"SearchField",	nil];
}

#pragma mark -

// =========================================================================
// (BOOL) isVisible
// -------------------------------------------------------------------------
// Return if the console window is visible or not
// -------------------------------------------------------------------------
// Created: 18 January 2009
// Version: 18 January 2009
// =========================================================================
- (BOOL) isVisible
{
	return ([consoleWindow isVisible]);
}


// =========================================================================
// (IBAction) clearConsole: (id) sender
// -------------------------------------------------------------------------
// Clear the console and save out blank data to the GUI Tar log file
// -------------------------------------------------------------------------
// Created: 18 January 2009 15:27
// Version: 26 January 2009 21:41
// =========================================================================
- (IBAction) clearConsole: (id) sender
{
	NSRange theEnd = NSMakeRange(0, [[textView string] length]);
	
    [textView replaceCharactersInRange: theEnd withString: @""];
    theEnd.location = 0;
    [textView scrollRangeToVisible: theEnd];
	
	[[textView string] writeToFile:[@"~/Library/Logs/GUITar.log" stringByExpandingTildeInPath]	atomically:YES];

}


// =========================================================================
// (void) openConsoleLogPanel
// -------------------------------------------------------------------------
// Open the console log window, position it, and set its size
// -------------------------------------------------------------------------
// Created: 14 February 2009 19:04
// Version: 14 February 2009 19:04
// =========================================================================
- (void) openConsoleLogPanel
{
	[consoleWindow orderFront: nil];
}


// =========================================================================
// (void) closeConsoleLogPanel: (NSNotification *) aNotification
// -------------------------------------------------------------------------
// When the console log panel has closed, this notification sets the
// consoleLogMenu to be in an off state (no check mark next to it), and
// save the position and size since there is an oddity where the Autosave
// doesn't work with the Console Log
// -------------------------------------------------------------------------
// Created: 25 January 2009 14:33
// Version: 16 February 2009 20:13
// =========================================================================
- (void) closeConsoleLogPanel: (NSNotification *) aNotification
{
	[[NSUserDefaults standardUserDefaults] setObject: NSStringFromRect( NSMakeRect([consoleWindow frame].origin.x, [consoleWindow frame].origin.y, [consoleWindow frame].size.width, [consoleWindow frame].size.height)) forKey:@"ConsoleLogPosition"];
	[[NSUserDefaults standardUserDefaults] synchronize];	// Force the defaults to update
	
	[[NSApp delegate] consoleLogClosed];
}


// =========================================================================
// (void) writeToConsole: (NSString *) string
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 8 February 2009 19:47
// Version: 8 February 2009 19:47
// =========================================================================
- (void) writeToConsole: (NSString *) string
{
	NSRange theEnd = NSMakeRange([[textView string] length], 0);
	      
	[textView replaceCharactersInRange: theEnd withString: string];
	theEnd.location += [string length];
	[textView scrollRangeToVisible: theEnd];
}


// =========================================================================
// - (void) saveLogToFile
// -------------------------------------------------------------------------
// Created: 10 February 2009 20:08
// Version: 10 February 2009 20:08
// =========================================================================
- (void) saveLogToFile
{
	[ [textView string] writeToFile:[@"~/Library/Logs/GUITar.log" stringByExpandingTildeInPath]	atomically:YES];
}


// =========================================================================
// - (IBAction) searchText: (id) sender
// -------------------------------------------------------------------------
// Search through the console log and display the results
// -------------------------------------------------------------------------
// Created: 15 February 2009 16:30
// Version: 15 February 2009 19:11
// =========================================================================
- (IBAction) searchText: (id) sender
{
	NSString *searchString = [sender stringValue];
	
	if ((searchString != nil) && (![searchString isEqualToString:@""]))
	{
		// Get original text and put into an NSString or NSArray
		// Iterate through the log string/array.  Add each "line" into a string
		// Put the search result string into the text view
		// Thought: Could NSPredicate also be used to search?
		
		NSArray *originalLog = [[textView string] componentsSeparatedByString:@"\n"];
		NSMutableString *searchResults = [[NSMutableString alloc] init];

		[consoleTabView selectTabViewItemAtIndex: 1];
		
		for (int i = 0; i < [originalLog count]; i++)
		{
			if ([[originalLog objectAtIndex: i] rangeOfString: searchString options:NSCaseInsensitiveSearch].location != NSNotFound)
			{
				[searchResults appendString: [originalLog objectAtIndex: i]];
				[searchResults appendString: @"\n"]; // append a new line character after each result
			}
		}
		
		if ([searchResults isEqualToString: @""])  // No results found
		{
			[searchTextView setEditable:YES];
			NSRange theEnd = NSMakeRange(0, [[searchTextView string] length]);
			
			[searchTextView replaceCharactersInRange: theEnd withString: @""];
			theEnd.location = 0;
			[searchTextView scrollRangeToVisible: theEnd];
			[searchTextView setEditable:NO];
		}
		else
		{
			[searchTextView setEditable:YES];
			NSRange theEnd = NSMakeRange(0, [[searchTextView string] length]);
				
			[searchTextView replaceCharactersInRange: theEnd withString: searchResults];
			theEnd.location = 0;
			[searchTextView scrollRangeToVisible: theEnd];
			[searchTextView setEditable:NO];
		}
		
		[searchResults release];
	}
	else // Otherwise, Cancel button was pressed, display original log
	{
		[consoleTabView selectTabViewItemAtIndex: 0];
	}
}

@end