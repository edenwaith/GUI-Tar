//  EController.h
//  GUI Tar Version 1.2.4
//
//  Created by admin on 17 June 2003.
//  Copyright (c) 2003 - 2011 Edenwaith. All rights reserved.
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
#import "WinController.h"

@interface EController : NSObject
{
    IBOutlet NSTextField			*fileField;	// text field containing compressed file name
    IBOutlet NSTextField			*dirField;	// text field containing directory name 
    IBOutlet NSButton				*UTButton;	// Extract button
    IBOutlet NSProgressIndicator	*extractionIndicator;
    IBOutlet id						extractionSheet;
    IBOutlet NSButton				*eCancelButton;
    IBOutlet id						e_window;
    IBOutlet NSTextField			*progress_msg; // Message displaying current file extracted
    
    NSTask							*untar;	// new task to run tar 
    NSFileManager					*fm;
    NSMutableArray					*file_list;
    NSMutableDictionary				*dict;
	NSMutableString					*directory;
	NSPipe							*ePipe;
	NSFileHandle					*eHandle;	

    int								os_version;	// Operating System version (i.e. 1000 = 10.0.0)
    
    BOOL quitWhenFinished;		// boolean value to indicate to close program when done
    BOOL beepWhenFinished;		// value to determine whether or not to beep when task is finished
    BOOL tempSuspendQuit;
    BOOL pauseTaskRelease;
    BOOL wasCanceled;
    
}

// happy, fun filled prototypes -----------------------------------------------------------

// drag, drop, & launch functions
//- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
//- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

// other wonderful functions which uncompress and get files
- (NSString *) fileNameString: (NSString *) filename;
- (IBAction)getFile: (id)sender;
- (IBAction)getDir: (id)sender;
- (IBAction)extract: (id)sender;
- (IBAction) cancelExtraction: (id)sender;
- (void) unTarIt;
- (void) outputExtractorData: (NSFileHandle *) handle;
- (NSString *) fileNameWithoutExtension: (NSString *) filename;
- (void) setWorkingDirectory: (BOOL) isArchive;
- (BOOL) isArchive: (NSString *) filename;
- (void) startExtractor: (NSNotification *)aNotification;
- (void)doneTarring: (NSNotification *)aNotification;
- (void) checkOSVersion;

@end
