/* CController */

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
#import "NSFileManager+Utils.h"


@interface CController : NSObject
{
    IBOutlet NSButton 		*addFileButton;
	IBOutlet NSButton		*removeFileButton;
    IBOutlet NSButton		*compress_button;
    IBOutlet NSTableView 	*table;
    IBOutlet NSPopUpButton	*compression_type;
    
    IBOutlet id				window;
    IBOutlet id				compressionSheet;
    
    IBOutlet NSProgressIndicator *compressionIndicator;
	
    NSFileManager			*fm;
    
    NSString				*application_path;
    NSMutableString			*archive_name;
	NSMutableString			*tempPath;
    
    NSMutableArray			*file_list;
    NSMutableArray  		*records;  
    NSTask					*compress_task; 
	NSPipe					*cPipe;
	NSFileHandle			*cHandle;
    
    BOOL					is_archive;
    BOOL					quitWhenFinished;
    BOOL					was_canceled;
    
    NSSavePanel				*savePanel;
    
    NSUserDefaults			*prefs;
	
    int						os_version;	// Operating System version (i.e. 1000 = 10.0.0)	
}

- (BOOL) resignFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) performKeyEquivalent: (NSEvent *) event;

- (NSDictionary *) createRecord: (id) obj;
- (BOOL) recordsContainsObject: (id) object;
- (IBAction) addFileToList : (id) sender;
- (IBAction) removeFileFromList : (id) sender;
- (void) deleteAllRecords;
- (void) deleteSelectedRecords;
- (IBAction) clearAllRecords: (id) sender;
- (IBAction) deselectAllRecords: (id) sender;

- (IBAction) setCompressionType: (id) sender;
- (void) validateArchiveName: (NSString *) compression_type_string;

- (IBAction) compress : (id) sender;
- (void) compressIt: (NSString *)fileType;
- (void) outputCompressorData: (NSFileHandle *) handle;

- (IBAction) cancelCompression: (id) sender;
- (void) savePanelDidEnd: (NSSavePanel *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo;
- (void) archiveFiles;

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification;
- (int)numberOfRowsInTableView:(NSTableView*)table;
- (id)tableView:(NSTableView*)table objectValueForTableColumn:(NSTableColumn*)col row:(int)rowIndex;
- (NSDragOperation) tableView: (NSTableView *)tv validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) op;
- (BOOL) tableView: (NSTableView *) tv acceptDrop: (id <NSDraggingInfo>)info row:(int) row dropOperation: (NSTableViewDropOperation) op;

- (void) startCompressor: (NSNotification *)aNotification;
- (void) doneCompressing: (NSNotification *)aNotification;

- (void) checkOSVersion;

@end
