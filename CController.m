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


// REMEMBER!!: To get the data to appear properly in the table, you need
// to connect the dataSource and delegate to the controller (CController).
// Otherwise, nothing will appear in the table.

// Allow Multiple Selections is a box which is checked in IB

// To fix the precompiled header errors: sudo fixPrecomps -all

/*  To compress a file, use this command: tar -cpvzf new_file.tgz filename(s)
 *  c : create new archive
 *  p : preserve file data such as user/group id, creation time, permissions
 *  z : compress using gzip (Z uses compress instead of gzip)
 *  for more info about tar, type: man tar
 *
 */

/* To create a disk image:
 * hdiutil create -imagekey zlib-level=9 -srcfolder '/Users/admin/Programs/MyApp/' '/Users/admin/Programs/MyApp/../MyApp.dmg' -puppetstrings  -fs HFS+ -volname 'MyApp'
 * Other tips
 * Mac OS X Hints: http://www.macosxhints.com/article.php?story=20050731011849803
 * Disk Image Plug-in: http://www.macupdate.com/info.php/id/18276
 */

#import "CController.h"

// =========================================================================
// @implementation NSTableView (KeyEvents)
// -------------------------------------------------------------------------
// NSTableView category to handle the delete key event
// -------------------------------------------------------------------------
// Created: 17. March 2004 1:15
// Version: 17. March 2004 1:33
// =========================================================================
@implementation NSTableView (KeyEvents)

- (void) keyDown: (NSEvent *) event
{
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    unsigned int flags = [event modifierFlags];
    
    // NSDeleteFunctionKey activates a flag, so flags will equal 8388608.
    // NSDelteCharacter is just the standard backspace (reverse delete) key.
    if (key == NSDeleteFunctionKey || (key == NSDeleteCharacter && flags == 0))
    {
        [[self delegate] deleteSelectedRecords];
    }   
    else
    {
        [super keyDown: event];
    }
}

@end


// =========================================================================
// @implementation CController
// =========================================================================

@implementation CController

// =========================================================================
// (id) init
// -------------------------------------------------------------------------
// Version: 23 February 2009 20:00
// =========================================================================
- (id) init
{
    if (self = [super init])
    {
		fm				 = [NSFileManager defaultManager];
        records			 = [[NSMutableArray alloc] init];
        compress_task 	 = [[NSTask alloc] init];
        compress_task 	 = nil;
        archive_name 	 = [[NSMutableString alloc] init];
		tempPath		 = [[NSMutableString alloc] init];
        application_path = [[NSBundle mainBundle] bundlePath];
        is_archive		 = NO;
        quitWhenFinished = NO;
        was_canceled	 = NO;
        
        file_list = [[NSMutableArray alloc] initWithCapacity: 10];
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
            selector:@selector(startCompressor:) 
            name:@"notifyCompressor" 
            object:nil];

        // Set up the preferences for compressor.  This may be a temporary
        // solution for right now until a more unified solution is created.
        // Perhaps [NSUserDefaults standardUserDefaults] can be used?
        // Prefs are loaded in the awakeFromNib
        prefs = [[NSUserDefaults standardUserDefaults] retain];

    }
	
	[self checkOSVersion];
    
    return self;
}

// =========================================================================
// (void) dealloc
// -------------------------------------------------------------------------
// Version: 23 February 2009 20:00
// =========================================================================
- (void) dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: @"notifyCompressor" object: nil];
       
	[archive_name release];
	[tempPath release];
	
	if (compress_task != nil)
	{
		[compress_task release];
		compress_task = nil;
	}

    [super dealloc];
}

// =========================================================================
// (void) awakeFromNib
// -------------------------------------------------------------------------
// Version: 20 February 2009 20:47
// =========================================================================
- (void) awakeFromNib
{
	NSArray *compressionFileTypes = [NSArray arrayWithObjects:@"7z", @"bz2", @"gz", @"tar", @"tbz", @"tgz", @"Z", @"zip", nil];
	NSData *textAsData = [prefs objectForKey: @"Compression Type"];
	
    [table registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];

    if ([prefs objectForKey: @"Compression Type"] != nil && ( [compressionFileTypes containsObject: [NSUnarchiver unarchiveObjectWithData:textAsData]] == YES ) )
    {
        [compression_type selectItemWithTitle: [NSUnarchiver unarchiveObjectWithData:textAsData]];
    }
    else
    {
        [compression_type selectItemWithTitle: @"tgz"];
    }
}

// =========================================================================
// (BOOL) resignFirstResponder
// -------------------------------------------------------------------------
// This method is used in conjunction with becomeFirstResponder and
// performKeyEquivalent so other key strokes can be recognized.
// -------------------------------------------------------------------------
// Version: 7. February 2004 17:35
// Created: 7. February 2004 17:35
// =========================================================================
- (BOOL) resignFirstResponder
{
    return YES;
}

// =========================================================================
// (BOOL) becomeFirstResponder
// -------------------------------------------------------------------------
// This method is used in conjunction with resignFirstResponder and
// performKeyEquivalent so other key strokes can be recognized.
// -------------------------------------------------------------------------
// Version: 7. February 2004 17:35
// Created: 7. February 2004 17:35
// =========================================================================
- (BOOL) becomeFirstResponder
{
    return YES;
}

// =========================================================================
// (BOOL) performKeyEquivalent: (NSEvent*) event
// -------------------------------------------------------------------------
// This method is used in conjunction with resignFirstResponder and
// becomeFirstResponder so other key strokes can be recognized.
// Anything else, and this method will return a NO and let the normal
// built in handlers deal with other key events.
// NOTE: This doesn't seem to work just yet.
// =========================================================================
- (BOOL) performKeyEquivalent: (NSEvent *) event
{
    unsigned int flags;
    
    flags = [event modifierFlags];
       
    // if ([input isEqual: @"="] && (flags & NSCommandKeyMask))
    if (NSDeleteFunctionKey && (flags & NSCommandKeyMask))
    {
        return YES;
    }
    else // otherwise, let the default handlers deal with key events
    {
        return NO;
    }
}

#pragma mark -

// =========================================================================
// (NSDictionary *) createRecord: (id) obj
// -------------------------------------------------------------------------
// Created: 1 February 2009 1:45
// Version: 1 February 2009 1:45
// =========================================================================
- (NSDictionary *) createRecord: (id) obj
{
	NSMutableDictionary *record = [[NSMutableDictionary alloc] init];

    [record setObject: obj forKey:@"FileName"];
	[record setObject:[fm formatFileSize: [fm fileSize:obj]] forKey:@"FileSize"];
    
    [record autorelease];
    return record;
}

// =========================================================================
// (BOOL) recordsContainsObject: (id) object
// -------------------------------------------------------------------------
// Created: 3 March 2009 22:15
// Version: 3 March 2009 22:15
// =========================================================================
- (BOOL) recordsContainsObject: (id) object
{
	for (int i = 0; i < [records count]; i++)
	{
		if ([[[records objectAtIndex: i] objectForKey: @"FileName"] isEqual: object] == YES)
		{
			return (YES);
		}
	}
	
	return (NO);
}

// =========================================================================
// (IBAction) addFileToList : (id) sender
// -------------------------------------------------------------------------
// Version: 1 February 2009 1:40
// =========================================================================
- (IBAction) addFileToList : (id) sender
{
    NSMutableArray 	*temp_array  	= [[NSMutableArray alloc] init];
    int 		i 		= 0;
    
	NSOpenPanel *open_panel = [NSOpenPanel openPanel];
	int result = 0;
	
	[open_panel setCanChooseDirectories: YES];
	[open_panel setCanChooseFiles: YES];
	[open_panel setAllowsMultipleSelection: YES];

	// NSHomeDirectory()
	result = [open_panel runModalForDirectory:nil file:nil types:nil];
	
	if (result == NSOKButton)
	{
		// use setArray instead of this: temp_array = [open_panel filenames]
		// If setArray isn't used, the program will crash on subsequent uses
		// of the Open Panel.
		[temp_array setArray: [open_panel filenames]];
		
		for (i = 0; i < [temp_array count]; i++)
		{
			if ([self recordsContainsObject: [temp_array objectAtIndex: i]] == NO)
			{
				[records addObject: [self createRecord: [temp_array objectAtIndex: i]]];
				[table reloadData];
				[table scrollRowToVisible: [records count]-1];
			}
		}
	}
    
    [temp_array release];
}


// =========================================================================
// (IBAction) removeFileFromList : (id) sender
// -------------------------------------------------------------------------
// Created: 13 September 2007 21:07
// Version: 13 September 2007 21:07
// =========================================================================
- (IBAction) removeFileFromList : (id) sender
{
    NSEnumerator 	*enumerator;
    NSNumber		*index;
    NSMutableArray 	*temp_array  	= [[NSMutableArray alloc] init];
    id				tempObject;
 
	if ( [table numberOfSelectedRows] <= 0 )
	{
		NSBeep();
	}
	else 
	{
		enumerator = [table selectedRowEnumerator];
	
		while ( (index = [enumerator nextObject]) ) 
		{
			tempObject = [records objectAtIndex:[index intValue]];
			[temp_array addObject:tempObject];
		}

		[records removeObjectsInArray:temp_array];
		
		[table deselectAll:self];
	
		[table reloadData];
	}
    
    [temp_array release];    
}


// =========================================================================
// (void) deleteSelectedRecords
// -------------------------------------------------------------------------
// Version: 17. March 2004 1:20
// Created: 17. March 2004 1:20
// =========================================================================
- (void) deleteSelectedRecords
{
    NSEnumerator *enumerator 	= [table selectedRowEnumerator];
    NSMutableArray *temp_array  = [[NSMutableArray alloc] init];
    NSNumber *index;
    id tempObject = nil;
        
    while ( (index = [enumerator nextObject]) ) 
    {
        tempObject = [records objectAtIndex:[index intValue]];
        [temp_array addObject:tempObject];
    }
 
    [records removeObjectsInArray:temp_array];
            
    [table deselectAll:self];
        
    [table reloadData];
    
    [temp_array release];
}

// =========================================================================
// (void) deleteAllRecords
// =========================================================================
- (void) deleteAllRecords
{
    int num = [records count];
    int i = 0;
    
	for (i = num - 1; i >= 0; i--)
	{
		[records removeObjectAtIndex:i];
	}

    [table reloadData];
}

// =========================================================================
// (IBAction) clearAllRecords: (id) sender
// -------------------------------------------------------------------------
// Version: 4. December 2004 22:03
// Created: 4. December 2004 22:03
// -------------------------------------------------------------------------
// Called from the Clear All menu to remove all listings from the 
// Compressor files table.
// =========================================================================
- (IBAction) clearAllRecords: (id) sender
{
    [self deleteAllRecords];
}

// =========================================================================
// (IBAction) deselectAllRecords: (id) sender
// -------------------------------------------------------------------------
// Version: 23. February 2004 11:58
// Created: 23. February 2004 11:58
// =========================================================================
- (IBAction) deselectAllRecords: (id) sender
{
    [table deselectAll:self];
}

#pragma mark -

// =========================================================================
// (IBAction) setCompressionType: (id) sender
// -------------------------------------------------------------------------
// Version: 6. April 2005 21:53
// Created: 6. April 2005 21:53
// =========================================================================
- (IBAction) setCompressionType: (id) sender
{
    NSData *textAsData = [NSArchiver archivedDataWithRootObject: [compression_type titleOfSelectedItem]];
    [prefs setObject:textAsData forKey: @"Compression Type"];
}

// =========================================================================
// (void) validateArchiveName: (NSString *) compression_type
// -------------------------------------------------------------------------
// Version: 15. February 2004 23:24
// Created: 15. February 2004 23:24
// =========================================================================
- (void) validateArchiveName: (NSString *) compression_type_string
{
    if ([[archive_name pathExtension] isEqual: compression_type_string] == NO)
    {
        if ([compression_type_string isEqual: @"tar"] == YES ||
            [compression_type_string isEqual: @"zip"] == YES)
        {
            [archive_name appendString: @"."];
            [archive_name appendString: compression_type_string];
        }
        else if ([compression_type_string isEqual: @"tgz"] == YES)
        {
            if ([[archive_name pathExtension] isEqual: @"tar"] == YES)
            {
                [archive_name appendString: @".gz"];
            }
            else if ( ([[archive_name pathExtension] isEqual: @"gz"] == NO) ||
                ([[[archive_name stringByDeletingPathExtension] pathExtension] isEqual: @"tar"] == NO) )
            {
                [archive_name appendString: @"."];
                [archive_name appendString: compression_type_string];
            }
        }
    }
}

#pragma mark -

// =========================================================================
// (IBAction) compress: (id) sender
// -------------------------------------------------------------------------
// Version: 11 September 2009 22:37
// =========================================================================
- (IBAction) compress : (id) sender
{
    int ret_val;
    NSMutableString *temp_archive_name = [[NSMutableString alloc] init];
    
    if ([records count] > 0)
    {
        // Move this to code after the Compress button has been clicked
        [[NSNotificationCenter defaultCenter] addObserver: self 
            selector:@selector(doneCompressing:) 
            name:NSTaskDidTerminateNotification 
            object:compress_task];
    
        if ( ([[[compression_type selectedItem] title] isEqual: @"7z"]) ||
			 ([[[compression_type selectedItem] title] isEqual: @"tbz"]) ||
			 ([[[compression_type selectedItem] title] isEqual: @"tgz"]) || 
             ([[[compression_type selectedItem] title] isEqual: @"tar"]) ||
             ([[[compression_type selectedItem] title] isEqual: @"zip"]) )
        {
            if ([records count] == 1)
            {
                // If there is just one file like /Users/Joe/Letter.txt, then
                // remove the extension and directory paths to leave just Letter
                [temp_archive_name setString: [[[[[records objectAtIndex: 0] valueForKey: @"FileName"] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString: @"."]];
            }
            else
            {
                [temp_archive_name setString: @"Untitled."];
            }
            
            savePanel = [NSSavePanel savePanel];
            [savePanel setTitle:@"Compress"];

			ret_val = [savePanel runModalForDirectory:nil file: [temp_archive_name stringByAppendingString: [[compression_type selectedItem] title]]];

			if (NSFileHandlingPanelOKButton == ret_val)
			{
				[archive_name setString: [savePanel filename]];
				[self validateArchiveName: [[compression_type selectedItem] title]];
				[self archiveFiles];     
			}          
        }
        else // should be gz, bz2, or Z
        {
            [self compressIt: [[compression_type selectedItem] title] ];
        }
    }
    else
    {
        NSBeep();
        NSRunAlertPanel(@"No files selected", @"No files have been selected to compress and archive.", @"OK", nil, nil);
    }
}

// =========================================================================
// (void) compressIt: (NSString *)fileType
// -------------------------------------------------------------------------
// Created: 14. August 2003
// Version: 16 February 2009 15:15
// =========================================================================
- (void) compressIt: (NSString *)fileType
{
    NSMutableArray *args = [[NSMutableArray alloc] init];
    BOOL run_task = YES;
//	int i = 0; // If C99 compliance is not on, declare i here.
	
	compress_task = [[NSTask alloc] init];
	
	for (int i = 0; i < [records count]; i++)
	{
		BOOL isDir;
		
		// check for bundled files, i.e. .app, .rtfd, etc.
		// Do not add directories or bundles
		if ( !([fm fileExistsAtPath: [[records objectAtIndex: i] valueForKey: @"FileName"] isDirectory:&isDir] && isDir) &&
			(![[NSWorkspace sharedWorkspace] isFilePackageAtPath: [[records objectAtIndex: i] valueForKey: @"FileName"]]) )
		{
			[args addObject: [[records objectAtIndex: i] valueForKey: @"FileName"]];
		}
	}   

	if ([args count] <= 0)
	{
		// Have this option if someone tries to compress only folders/bundles, which cannot be compressed by themselves.
		run_task = NO;
		NSBeep();
		NSRunAlertPanel(@"Cannot compress folders", @"No files are available to compress.", @"OK", nil, nil);
	}
    else if ( [fileType isEqual: @"gz"] )
    {
        [compress_task setLaunchPath:@"/usr/bin/gzip"];
        [args insertObject: @"-fv9" atIndex: 0]; // 'f' forces compression
        [compress_task setArguments: args];
    }
    else if ( [fileType isEqual: @"bz2"] )
    {
        if ([[NSFileManager defaultManager] isExecutableFileAtPath: @"/usr/bin/bzip2"] == YES)
        {
            [compress_task setLaunchPath:@"/usr/bin/bzip2"];
            [args insertObject: @"-fv9" atIndex: 0]; // 'f' forces compression
            [compress_task setArguments: args];
        }
        else
        {
            run_task = NO;
            NSBeep();
            NSRunAlertPanel(@"Cannot compress", @"The bzip2 utility was not found on your system.", @"OK", nil, nil);
        }
    }
	else if ( [fileType isEqual: @"Z"] )	// UNIX compress
	{
		[compress_task setLaunchPath:@"/usr/bin/compress"];
        [args insertObject: @"-fv" atIndex: 0]; // 'f' forces compression
        [compress_task setArguments: args];
	}

    if (run_task == YES)
    {
		cPipe = [[NSPipe alloc] init];
		
		[compress_task setStandardOutput: cPipe];
		[compress_task setStandardError: cPipe];
		cHandle = [cPipe fileHandleForReading];
		
		[[NSApp delegate] directLogOutput: @"=== Compressing files ===\n"];
		
        [compress_task launch];
    
        [NSApp beginSheet:compressionSheet modalForWindow:window
            modalDelegate:self didEndSelector:NULL contextInfo:nil];
        [compressionIndicator startAnimation: self];
        
		[NSThread detachNewThreadSelector: @selector(outputCompressorData:) toTarget: self withObject: cHandle];
		
        [self deleteAllRecords];
    }
    
    [args release];
}


// =========================================================================
// (void) outputData: (NSFileHandle *) handle
// -------------------------------------------------------------------------
// Direct the output data sent from the task to the console log
// -------------------------------------------------------------------------
// Created: February 2009
// Version: 10 February 2009 21:16
// =========================================================================
- (void) outputCompressorData: (NSFileHandle *) handle
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *data;
	
    while ([data=[handle availableData] length])
    {
        NSString *string = [[NSString alloc] initWithData:data encoding: NSASCIIStringEncoding];
		
		[[NSApp delegate] directLogOutput: string];
        
        [string release];
    }
	
	[[NSApp delegate] directLogOutput: @"\n"];
	
	// Save log data to file
	[[NSApp delegate] saveLogFile];
	
    [pool release];
	
	[NSThread exit]; // exit the thread, of course
}

#pragma mark -

// =========================================================================
// (IBAction) cancelCompression : (id) sender
// -------------------------------------------------------------------------
// Version: 13. February 2004
// Created: 11. January 2004
// =========================================================================
- (IBAction) cancelCompression : (id) sender
{
    [compress_task terminate];
    was_canceled = YES;
    [compressionIndicator stopAnimation: self];
    [compressionSheet orderOut:nil];
    [NSApp endSheet:compressionSheet];
}


// =========================================================================
// (void) savePanelDidEnd
// -------------------------------------------------------------------------
// Called after the save panel is closed when creating an archive
// -------------------------------------------------------------------------
// Created: 20. June 2003
// Version: 24. January 2004
// =========================================================================
- (void) savePanelDidEnd: (NSSavePanel *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo
{
	if (NSOKButton == returnCode)
	{
		[archive_name setString: [savePanel filename]];
		[self validateArchiveName: [[compression_type selectedItem] title]];
		[self archiveFiles];     
	}
}

// =========================================================================
// (void) archiveFiles
// -------------------------------------------------------------------------
// Example in creating dmg: 
//		hdiutil create -srcfolder /TestBackup /Backups/Saturday/testbackup.dmg
// -------------------------------------------------------------------------
// Created: 2004
// Version: 23 February 2009 20:00
// =========================================================================
- (void) archiveFiles
{
    NSMutableArray *args = [[NSMutableArray alloc] init];
    int i = 0;
    int args_length = 0; [args count];
    BOOL run_task = YES;
	NSString *compress_path = nil;
	
	for (int i = 0; i < [records count]; i++)
	{
		[args addObject: [[records objectAtIndex: i] valueForKey: @"FileName"]];
	}
	
	args_length = [args count];
	
	if ( [[[compression_type selectedItem] title] isEqual: @"tar"] || 
		 [[[compression_type selectedItem] title] isEqual: @"tbz"] ||
		 [[[compression_type selectedItem] title] isEqual: @"tgz"] )
	{
		for (i = 0; i < args_length; i++)
		{
			[args insertObject: @"-C" atIndex: i];
			[args insertObject: [[args objectAtIndex:i+1] stringByDeletingLastPathComponent] atIndex: i+1];
			[args replaceObjectAtIndex: i+2 withObject: [ [args objectAtIndex:i+2] lastPathComponent] ];
			
			i += 2;
			args_length += 2;
		}
	}
   
	is_archive = YES;
	
	compress_task = [[NSTask alloc] init];
	
	if ( [ [[compression_type selectedItem] title] isEqual: @"7z"] )
	{
		if (os_version >= 1030)
		{
			// 7za a directory.7z directory
			// ./7za a ~/myarchive.7z ~/temp/macutils
			// ./7za a -t7z archive.7z -r file1 file2 ...
			compress_path  = [ [NSBundle mainBundle] pathForResource:@"7za" ofType:@""];
			
			[compress_task setLaunchPath: compress_path];
			
			[args insertObject: @"a" atIndex: 0];			// Add command
			[args insertObject: @"-t7z" atIndex: 1];		// compression type
			[args insertObject: archive_name atIndex: 2];	// archive name
			[args insertObject: @"-r" atIndex: 3];			// recurse subdirectories
			
			[compress_task setArguments: args];
		}
		else
		{
			run_task = NO;
			NSBeep();
			NSRunAlertPanel(@"Cannot compress", @"Mac OS 10.3 or later is required to compress and archive files using the 7z format.", @"OK", nil, nil);
		}
	}
	else if ( [ [[compression_type selectedItem] title] isEqual: @"tgz"] )
	{
		[compress_task setLaunchPath:@"/usr/bin/tar"];
		
		[args insertObject: @"-cpvzf" atIndex: 0];
		[args insertObject: archive_name atIndex: 1];

		[compress_task setArguments: args];
	}
	else if ( [ [[compression_type selectedItem] title] isEqual: @"tbz"])
	{
		// Mac OS 10.1 cannot archive files as tbz in one step since bzip2 isn't on the system by default
		if (os_version > 1010)
		{
			if (os_version >= 1030)
			{
				compress_path = @"/usr/bin/gnutar";
			}
			
			if ([[NSFileManager defaultManager] isExecutableFileAtPath: compress_path] == YES)
			{				
				[compress_task setLaunchPath: compress_path];
				
				[args insertObject: @"-cpvjf" atIndex: 0];
				[args insertObject: archive_name atIndex: 1];

				[compress_task setArguments: args];
			}
			else
			{
				run_task = NO;
				NSBeep();
				NSRunAlertPanel(@"Cannot compress", @"The tar utility was not found on your system.", @"OK", nil, nil);
			}
		}
		else
		{
			run_task = NO;
			NSBeep();
			NSRunAlertPanel(@"Cannot compress", @"Mac OS 10.1 does not natively support the tbz format.  As an alternative, archive your files as a tar file and then compress it using bz2.", @"OK", nil, nil);
		}
	}
	else if ( [ [[compression_type selectedItem] title] isEqual: @"tar"])
	{
		if ([[NSFileManager defaultManager] isExecutableFileAtPath: @"/usr/bin/tar"] == YES)
		{				
			[compress_task setLaunchPath: @"/usr/bin/tar"];
			
			[args insertObject: @"-cpvf" atIndex: 0];
			[args insertObject: archive_name atIndex: 1];

			[compress_task setArguments: args];
		}
		else
		{
			run_task = NO;
			NSBeep();
			NSRunAlertPanel(@"Cannot compress", @"The tar utility was not found on your system.", @"OK", nil, nil);
		}
		
	}
	else if ( [ [[compression_type selectedItem] title] isEqual: @"zip"])
	{
		// zip   [-aABcdDeEfFghjklLmoqrRSTuvVwXyz!@$]   [-b path]    [-n suffixes]
		// [-t mmddyyyy] [-tt mmddyyyy] [ zipfile [ file1 file2 ...]] [-xi list]
		
		if ([[NSFileManager defaultManager] isExecutableFileAtPath: @"/usr/bin/zip"] == YES)
		{
			compress_path = @"/usr/bin/zip";
		}	
		
		if ([[NSFileManager defaultManager] isExecutableFileAtPath: compress_path] == YES)
		{
			[tempPath setString: @"/tmp/GUITar"];
			BOOL isDir;
			
			[compress_task setLaunchPath: compress_path];
			
			// Reference: http://svn.opengroupware.org/OpenGroupware.org/releases/1.0alpha11-ultra/XmlRpcAPI/NGUnixTool.m
			// Also check pages 212 - 214 in Adv. Mac OS X Programming by Dalrymple + Hillegass
			
			// TODO: Check to see if there is enough HD space to copy the files to a temp directory
			
			// If temp path already exists, erase it, first to remove any old contents
			if ([fm fileExistsAtPath: tempPath isDirectory: &isDir] && isDir)
			{
				[fm removeFileAtPath: tempPath handler: nil];
			}
			
			NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSDate date],NSFileModificationDate,
								 @"owner",@"NSFileOwnerAccountName",
								 @"group",@"NSFileGroupOwnerAccountName",
								 [NSNumber numberWithInt: 0777],@"NSFilePosixPermissions",
								 nil];
			
			// Create temp directory for zip data
			if ([fm createDirectoryAtPath: tempPath attributes: dic] == NO)
			{
				[tempPath release];
				run_task = NO;
				NSBeep();
				NSLog(@"Error creating temp data for zip archive.");
				NSRunAlertPanel(@"Cannot zip", @"There was a problem creating the zip archive.", @"OK", nil, nil);
			}
			else
			{
				// Copy files into a temp directory
				NSEnumerator *enumer= [args objectEnumerator];
				id sourcePath = nil;
				
				while (sourcePath = [enumer nextObject])
				{
					// Yes, you actually have to specify the name of the new file in the destination, not just the directory
					if ([fm copyPath: sourcePath toPath: [tempPath stringByAppendingPathComponent:[sourcePath lastPathComponent]] handler: nil] == NO)
					{
						NSLog(@"Error copying files to temp directory");
					}
				}
				
				// empty the args array
				[args removeAllObjects];
				
				// set the setCurrentDirectoryPath to the temp directory
				[compress_task setCurrentDirectoryPath: tempPath];
				
				[args insertObject: @"-rv" atIndex: 0];
				[args insertObject: archive_name atIndex: 1];
				[args insertObject: @"." atIndex: 2]; // set last element of args to the temp path directory

				[compress_task setArguments: args];

				// Next up: zip everything that is in that temp directory
				// Remember: erase temp directory after everything has been zipped...
			}
		}
		else
		{
			run_task = NO;
			NSBeep();
			NSRunAlertPanel(@"Cannot zip", @"The zip utility was not found on your system.", @"OK", nil, nil);
		}
	}
	
	if (run_task == YES)
	{
		cPipe = [[NSPipe alloc] init];
		
		[compress_task setStandardOutput: cPipe];
		[compress_task setStandardError: cPipe];
		cHandle = [cPipe fileHandleForReading];
		
		[[NSApp delegate] directLogOutput: @"=== Archiving files ===\n"];
		
		[compress_task launch];
		
		[NSApp beginSheet:compressionSheet modalForWindow:window
			modalDelegate:self didEndSelector:NULL contextInfo:nil];
		[compressionIndicator startAnimation: self]; 
		
		[NSThread detachNewThreadSelector: @selector(outputCompressorData:) toTarget: self withObject: cHandle];
	
		[self deleteAllRecords];
	
		// It currently appears that when this drop down sheet appears after the 
		// other Save Panel sheet, things mess up when it collapses.  An odd area
		// is not redrawn.  The whole GUI Tar window just disappears.  Weird.  This doesn't
		// happen with just the GZ or BZIP2, however.
	}
    
    [args release];
}

#pragma mark -

// =========================================================================
// (void) tableViewSelectionDidChange: (NSNotification *) aNotification
// -------------------------------------------------------------------------
// Make sure that the tableView has a delegate connection to the controller
// http://www.oreillynet.com/cs/user/view/cs_msg/6674
// -------------------------------------------------------------------------
// Version: 13 September 2007 21:10
// =========================================================================
- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
    if ([table numberOfSelectedRows] > 0)
    {
        [removeFileButton setEnabled:YES];
    }
    else
    {       
		[removeFileButton setEnabled:NO];
    }
}

// =========================================================================
// (int) numberOfRowsInTableView : (NSTableView*)table
// =========================================================================
- (int) numberOfRowsInTableView : (NSTableView*)table
{
    // returns the number of records
    return [records count];
}


// =========================================================================
// (id) tableView : (NSTableView*)table ...
// -------------------------------------------------------------------------
// Version: 1 February 2009 2:02
// =========================================================================
- (id)tableView : (NSTableView*)table objectValueForTableColumn: (NSTableColumn*) col row: (int) rowIndex
{
    id result = nil;

    if ([[col identifier] isEqualToString:@"Name"])
    {
        result = [[records objectAtIndex:rowIndex] valueForKey: @"FileName"];
    }
	else
	{
		result = [[records objectAtIndex:rowIndex] valueForKey: @"FileSize"];
	}
    
    return result;
}


// =========================================================================
// (NSDragOperation) tableView: (NSTableView *) tv validateDrop: (id ...)
// -------------------------------------------------------------------------
// This method is used by NSTableView to determine a valid drop target. 
// Based on the mouse position, the table view will suggest a proposed drop location.  
// This method must return a value that indicates which dragging operation
// the data source will perform.  
// The data source may "re-target" a drop if desired by calling 
// setDropRow:dropOperation: and returning something other than 
// NSDragOperationNone.  
// One may choose to re-target for various reasons (eg. for better visual 
// feedback when inserting into a sorted position).
// -------------------------------------------------------------------------
// Version: 22. February 2004 20:20
// Created: 22. February 2004 20:20
// =========================================================================
- (NSDragOperation) tableView: (NSTableView *)tv validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) op
{
    return NSDragOperationCopy;
}

// =========================================================================
// (BOOL) tableView: (NSTableView *) tv acceptDrop: (id ...)
// -------------------------------------------------------------------------
// This method is called when the mouse is released over a table view
// that previously decided to allow a drop via the validateDrop method.
// The data source should incorporate the data from the dragging pasteboard
// at this time.
// Solution to copy pasteboard filenames into an array: 
// http://www.cocoadev.com/index.pl?FakeImageView
// -------------------------------------------------------------------------
// Created: 22. February 2004 20:20
// Version: 3 March 2009 22:22
// =========================================================================
- (BOOL) tableView: (NSTableView *) tv acceptDrop: (id <NSDraggingInfo>)info row:(int) row dropOperation: (NSTableViewDropOperation) op
{
    NSPasteboard *pb = [info draggingPasteboard];
    NSArray *rows = [[pb stringForType: NSFilenamesPboardType] propertyList]; //[NSArray arrayWithObjects: rowsData];
    NSEnumerator *enumerator = [rows objectEnumerator];
    NSSound *hear_that_sound;
    id new_record;
    
    while (new_record = [enumerator nextObject])
    {
		if ([self recordsContainsObject: new_record] == NO)
        {
			[records addObject: [self createRecord: new_record]];
        }
    }
    
    hear_that_sound = [[NSSound alloc] initWithContentsOfFile:@"/System/Library/Sounds/Funk.aiff" byReference:NO];
    if (hear_that_sound)
    {
        [hear_that_sound setDelegate:self];
        [hear_that_sound play];
    }

    [table reloadData];
    [table scrollRowToVisible: [records count]-1];

    return YES;
}

#pragma mark -

// =========================================================================
// (void) startCompressor: (NSNotification *)aNotification
// -------------------------------------------------------------------------
// Copy files into the table that were dropped onto the GUI Tar icon
// -------------------------------------------------------------------------
// Created: 28. January 2004 14:31
// Version: 3 March 2009 22:22
// =========================================================================
- (void) startCompressor: (NSNotification *)aNotification
{
    int 	i 	  = 0;
    NSArray 	*temp_file_list = [[NSArray alloc] initWithArray: [aNotification object]];

	for (i = 0; i < [temp_file_list count]; i++)
	{        
		if ([self recordsContainsObject: [temp_file_list objectAtIndex: i]] == NO)
		{
			[records addObject: [self createRecord: [temp_file_list objectAtIndex: i]]];
			[table reloadData];
			[table scrollRowToVisible: [records count]-1];
		}
	}	
	    
    [[NSNotificationCenter defaultCenter] addObserver: self 
            selector:@selector(doneCompressing:) 
            name:NSTaskDidTerminateNotification 
            object:compress_task];    
    
    quitWhenFinished = YES;
    
    [temp_file_list release];
}

// =========================================================================
// (void) doneCompressing: (NSNotification *)aNotification
// -------------------------------------------------------------------------
// Called after the compress_task is finished running.
// -------------------------------------------------------------------------
// Created: 20. June 2003
// Version: 23 February 2009 20:00
// =========================================================================
- (void)doneCompressing:(NSNotification *)aNotification 
{
	BOOL isDir;
	
    [compress_button setEnabled: YES]; // re-enable the Compress button
    [compress_button setTitle: NSLocalizedString(@"Compress", nil)];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSTaskDidTerminateNotification object: nil];
    [compress_task release];		// free up memeory from the task
	[cPipe release];
    compress_task = nil;
	cPipe = nil;
	
	// If temp path already exists, erase it, first to remove any old contents
	if ([fm fileExistsAtPath: tempPath isDirectory: &isDir] && isDir)
	{
		if ([fm removeFileAtPath: tempPath handler: nil] == NO)
		{
			NSLog(@"Failed to remove path: %@", tempPath);
		}
	}
    
    if (was_canceled == NO)
    {
        [compressionIndicator stopAnimation: self];
        [compressionSheet orderOut:nil];
        [NSApp endSheet: compressionSheet];
        
        NSBeep();
		        
        if (is_archive == YES)
        {
            [[NSWorkspace sharedWorkspace] selectFile: archive_name inFileViewerRootedAtPath: nil];
            is_archive = NO;
        }
    }
    else
    {
        NSBeep();
        if (quitWhenFinished == NO)
        {
            NSRunAlertPanel(@"GUI Tar canceled", @"GUI Tar has been canceled.", @"OK", nil, nil);
        }

   		sleep(1);
        was_canceled = NO;
        is_archive = NO;
    }

    if (quitWhenFinished == YES)
    {
        [NSApp terminate:self];
    }
    
}

#pragma mark -

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

@end
