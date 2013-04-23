/* WinController */

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
#import "PreferenceController.h"
#import "ConsoleController.h"
#include "unistd.h"	// for sleep()

@interface WinController : NSObject
{
    IBOutlet id 	tabView;
    IBOutlet id 	window;
    IBOutlet id		querySheet;
	IBOutlet NSMenuItem		*consoleLogMenu;
    
    NSTimer			*timer;
    NSMutableArray	*file_list;
	
	NSFileHandle	*outputFile;
	
	NSMutableString	*outputString;
    
    int				os_version;	// Operating System version (i.e. 1000 = 10.0.0)
    
	PreferenceController	*preferenceController;
	ConsoleController		*consoleController;
}

- (void) windowsClosing: (NSNotification *) aNotification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (void) addNewFiles : (NSTimer *) aTimer;
- (NSString *) determineFunction;
- (IBAction) goToFunction: (id) sender;

- (void) switchTab: (NSString *) theFunction;
- (void) tabView:(NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem;
- (void) windowShrink;
- (void) windowGrow;

- (void) checkOSVersion;
- (IBAction) goToProductPage : (id) sender;
- (IBAction) goToFeedbackPage: (id) sender;
- (IBAction) openHelp: (id) sender;

- (IBAction) showPreferencePanel: (id) sender;
- (IBAction) toggleConsoleLog: (id) sender;
- (void) consoleLogClosed;
- (void) directLogOutput: (NSString *) outputString;
- (void) saveLogFile;

@end
