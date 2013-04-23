//
//  ConsoleController.h
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

#import <Cocoa/Cocoa.h>

@interface ConsoleController : NSWindowController
{
	IBOutlet NSTextView	 	*textView;			// NSTextView in Console Log
	IBOutlet NSTextView		*searchTextView;	// Special view for the search results
	IBOutlet id				searchFieldView;
	IBOutlet id				consoleTabView;
	
	NSSearchField *searchField;
	
	id consoleWindow;
	id consoleToolbar;
}

- (BOOL) isVisible;
- (IBAction) clearConsole: (id) sender;
- (void) openConsoleLogPanel;
- (void) closeConsoleLogPanel: (NSNotification *) aNotification;
- (void) writeToConsole: (NSString *) string;
- (void) saveLogToFile;
- (IBAction) searchText: (id) sender;

@end
