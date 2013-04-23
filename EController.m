#import "EController.h"

//
//  EController.h
//  GUI Tar Version 1.2.4
//
//  Created by admin on 17 June 2003.
//  Copyright (c) 2003-2011 Edenwaith. All rights reserved.
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

@implementation EController


// =========================================================================
// (id)init
// -------------------------------------------------------------------------
// Allocate memory for program
// -------------------------------------------------------------------------
// Version: 3. November 2003 14:14
// =========================================================================
- (id)init 
{
    if (self = [super init])
    {
        untar			 = nil;
        quitWhenFinished = NO;
        beepWhenFinished = YES;
        tempSuspendQuit  = NO;
        pauseTaskRelease = NO;
        wasCanceled      = NO;
        file_list		 = [[NSMutableArray alloc] initWithCapacity: 10];
		directory		 = [[NSMutableString alloc] init];
		fm				 = [NSFileManager defaultManager];
        
		[self checkOSVersion];
		
        [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(startExtractor:) 
            name:@"notifyExtractor" 
            object:nil];         

    }
    return self;
}

// =========================================================================
// (void) delloc
// -------------------------------------------------------------------------
// Deallocate/free up memory used by Untar
// -------------------------------------------------------------------------
// Version: 11. January 2004
// =========================================================================
- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: @"notifyExtractor" object: nil];
    
	if (untar != nil)
	{
		[untar release];
		untar = nil;
	}
    
    [super dealloc];
}

#pragma mark -

// =========================================================================
// (NSString *) fileNameString
// -------------------------------------------------------------------------
// If a file name is too long (over 167 pixels), the entire string will
// not print properly in the text field in the interface.  This checks
// if the file name exceeds the 167 pixel limit, and if so, then it puts 
// an ellipse (ellipsis) in the middle of the file name to abridge it.
// -------------------------------------------------------------------------
// Version: 9. April 2004 16:48
// Created: 2. April 2004 1:05
// =========================================================================
- (NSString *) fileNameString: (NSString *) filename
{
    NSMutableString *current_file_name = [[NSMutableString alloc] initWithString: [filename lastPathComponent]];
    int cfl_length = [current_file_name length];
    float cfl_len = 0.0;
    float field_width = 167.0;

    dict  = [ [NSMutableDictionary alloc] init];
    [dict setObject:[NSFont fontWithName:@"Lucida Grande" size:13.0] forKey:NSFontAttributeName];
    cfl_len = [current_file_name sizeWithAttributes:dict].width;
    
    if (cfl_len > field_width)
    {
        [current_file_name replaceCharactersInRange: NSMakeRange(cfl_length-10, 3) withString:@"..."];
        
        while (cfl_len > field_width)
        {
            [current_file_name deleteCharactersInRange: NSMakeRange(cfl_length-11, 1)];
            cfl_length = [current_file_name length];
            cfl_len = [current_file_name sizeWithAttributes:dict].width;
        }
        
        [dict release];
        
        return (NSString *)current_file_name;
    }
    else
    {
        return (NSString *)current_file_name;
        
        [dict release];
    }
}

// =========================================================================
// (IBAction) getFile: (id)sender
// -------------------------------------------------------------------------
// Get the name of the file to extract files from
// -------------------------------------------------------------------------
// Version: 9 August 2006 21:41
// =========================================================================
- (IBAction)getFile: (id)sender
{
    NSArray *fileTypes = [NSArray arrayWithObjects:@"tar", @"svgz", @"gz", @"tgz", @"z", @"Z", @"taz", @"tbz", @"tbz2", @"bz", @"bz2", @"zip", @"rar", @"7z", nil];
    NSOpenPanel *open_panel = [NSOpenPanel openPanel];
    int result = 0;
    
    [open_panel setCanChooseDirectories:NO];
    
    // NSHomeDirectory()
    result = [open_panel runModalForDirectory:nil file:nil types:fileTypes];
    
    if (result == NSOKButton) 
    {
        [fileField setStringValue: [open_panel filename]];
    }
    
}

// =========================================================================
// (IBAction) getDir: (id)sender
// -------------------------------------------------------------------------
// Use the NSOpenPanel to retrieve the name of the directory to download
// the extracted files to.  If no directory is specified, the directory
// in which the compressed file is in, is where the files will be saved
// about 'filename': http://developer.apple.com/techpubs/macosx/Cocoa/Reference/ApplicationKit/ObjC_classic/Classes/NSSavePanel.html
// -------------------------------------------------------------------------
// Version: 17 April 2005 19:00
// =========================================================================
- (IBAction)getDir: (id)sender 
{
    NSOpenPanel *dir_panel = [NSOpenPanel openPanel];
    int result = 0;
    
    // choose only directories, not files
    [dir_panel setCanChooseDirectories:YES];
    [dir_panel setCanChooseFiles:NO];

    // NSHomeDirectory()
    result = [dir_panel runModalForDirectory:nil file:nil types:nil];

    if (result == NSOKButton) 
    {
        [dirField setStringValue: [dir_panel filename]];
    }

}

// =========================================================================
// (IBAction) extract : (id)sender
// -------------------------------------------------------------------------
// Check to see if the user has selected an appropriate file to uncompress,
// and if so, then call the unTarIt method to uncompress the file and
// extract the files
// -------------------------------------------------------------------------
// Version: 1 October 2003
// =========================================================================
- (IBAction) extract: (id)sender 
{
    if ( [[UTButton title] isEqual: @"Extract"] )
    {    
        if ([[fileField stringValue] isEqual: @""] == YES) // no file was selected
        {
            NSBeep();
            NSRunAlertPanel(@"Select file", @"You need to select a file to uncompress first.", @"OK", nil, nil);
        }
   
        else
        {           
            [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(doneTarring:) 
                name:NSTaskDidTerminateNotification 
                object:untar];

            [self unTarIt];            
        }
    }
    else if ( [[UTButton title] isEqual: @"Cancel"] )
    {
        [untar terminate];
        
        wasCanceled = YES;
    }
}


// =========================================================================
// (IBAction) cancelExtraction : (id)sender
// -------------------------------------------------------------------------
// Version: 14. January 2004
// Created: 14. January 2004
// =========================================================================
- (IBAction) cancelExtraction: (id)sender
{
    [untar terminate];
    wasCanceled = YES;
}


// =========================================================================
// (void) unTarIt
// -------------------------------------------------------------------------
// Set up the proper arguments to be made when uncompressing the file
//
// tar can also uncompress via 'compress' with a -Z option
//
// tar -xvzf name_of_file will uncompress both .tar.Z and
// .taz files.
//
// This command will uncompress a .tar.bz2 or .tbz file in one line
// bunzip2 -c *bz2 | tar -xvf -
// Note: May want to add a -f force option for gunzip and bunzip2 to force
// decompression.  Perhaps only as an option.  Fortunately, both Untar and
// GUI Tar work fine without it at this point and just ignore copying over
// any other files.
// -------------------------------------------------------------------------
// Version: 13 February 2009 20:50
// =========================================================================
- (void) unTarIt
{
    int status = 0;
    NSString *util_path = nil;
	BOOL run_task = YES;
    
    [progress_msg setStringValue: [self fileNameString: [[fileField stringValue] lastPathComponent]]];
    [self setWorkingDirectory: [self isArchive: [fileField stringValue]]];
	
	// 7Z -----------------------------------------------------------
	if ([[[fileField stringValue] pathExtension] isEqual: @"7z"])
	{
		util_path  = [ [NSBundle mainBundle] pathForResource:@"7za" ofType:@""];
		
		if ([fm isExecutableFileAtPath: util_path] == YES)
		{
			untar = [[NSTask alloc] init];
			[untar setLaunchPath: util_path ];
		
			// ./7za e -o{/Users/admin/temp} -y ~/temp/Archive\ copy.7z
			[untar setArguments:[NSArray arrayWithObjects: @"x", [@"-o" stringByAppendingString: directory], @"-y",  [fileField stringValue], nil]];	
		}
		else
		{   
			run_task = NO;
			NSBeep();
			NSRunAlertPanel(@"Cannot decompress", @"The 7za utility cannot be found.", @"OK", nil, nil);
		
			// Might need to reinitialize some variables here...
			[fileField setStringValue: @""];
			[dirField setStringValue: @""];
		}	
	}
    // TAR ----------------------------------------------------------
    else if ([ [[fileField stringValue] pathExtension] isEqual: @"tar"])
    {
        untar = [[NSTask alloc] init];
        [untar setLaunchPath:@"/usr/bin/tar"];
        
        // You DON'T need spaces after the -C or -xvf.  This is implied.  If spaces
        // are added, then this won't work, perhaps because it is looking for a file
        // named a space (' '), which doesn't make much sense.
            
        // if no directory was specified, then uncompress the files into the same directory
        // as the file
		
		[untar setArguments:[NSArray arrayWithObjects:@"-C", directory, @"-xvf", [fileField stringValue], nil]];
       
    }
    // TGZ, GZ, Z ----------------------------------------------------
    else if ([ [[fileField stringValue] pathExtension] isEqual: @"gz"] || 
             [ [[fileField stringValue] pathExtension] isEqual: @"svgz"] ||
             [ [[fileField stringValue] pathExtension] isEqual: @"z"] || 
             [ [[fileField stringValue] pathExtension] isEqual: @"tgz"]) // check for .gz, tar.z, tar.gz, or .tgz files
    { 
        if([ [[fileField stringValue] pathExtension] isEqual: @"tgz"] || [ [[[fileField stringValue] stringByDeletingPathExtension] pathExtension] isEqual: @"tar"]) // file is tar.gz, tar.z, or .tgz
        {
            untar = [[NSTask alloc] init];
            [untar setLaunchPath:@"/usr/bin/tar"];
            
			[untar setArguments:[NSArray arrayWithObjects:@"-C", directory, @"-xvzf", [fileField stringValue], nil]];            
        }
        // SVGZ ------------------------------------------------------
        else if ( [[[fileField stringValue] pathExtension] isEqual: @"svgz"] )
        {
            NSString *renamedFile = [[[fileField stringValue]stringByDeletingPathExtension] stringByAppendingString: @".svg.gz"];

            // rename .svgz to .svg.gz
            [fm movePath: [fileField stringValue] toPath: renamedFile handler: nil];

			// If the gunzipped already exists, then do not perform gunzip
            if ([fm fileExistsAtPath: [renamedFile stringByDeletingPathExtension]] == YES)
            {
				run_task = NO;
                NSBeep();
                NSRunAlertPanel(@"Cannot decompress", @"The file %@ already exists.", @"OK", nil, nil, [renamedFile stringByDeletingPathExtension]);
            }
            else
            {
				untar = [[NSTask alloc] init];
				[untar setLaunchPath:@"/usr/bin/gunzip"];
				
				[untar setArguments:[NSArray arrayWithObjects: @"-v", renamedFile, nil]];
			}
        }
        // GZ, DMG.GZ, Z ---------------------------------------------------
        else // otherwise, the file is something like dmg.gz or .gz, so just use gunzip
        {          
            // gunzip does not seem to have a feature to move an uncompressed
            // file into a specified directory.
          
            NSString *currentDMGFile = [[fileField stringValue] stringByDeletingPathExtension];
            
            // If the gunzipped already exists, then do not perform gunzip
            if ([fm fileExistsAtPath: currentDMGFile] == YES)
            {
				run_task = NO;
                NSBeep();
                NSRunAlertPanel(@"Cannot decompress", @"The file %@ already exists.", @"OK", nil, nil, currentDMGFile);
            }
            // uncompress and open dmg.gz files
            else if ( [[currentDMGFile pathExtension] isEqual: @"dmg"] )
            {
                if (tempSuspendQuit == YES)
                {
                    quitWhenFinished = NO;
                }
				
				run_task = NO;
                pauseTaskRelease = YES;
                beepWhenFinished = NO;
                [eCancelButton setEnabled: NO];
            
				untar = [[NSTask alloc] init];
				[untar setLaunchPath:@"/usr/bin/gunzip"];
				
				[untar setArguments:[NSArray arrayWithObjects: @"-v", [fileField stringValue], nil]];
				
				[[NSApp delegate] directLogOutput: @"=== Extracting "];
				[[NSApp delegate] directLogOutput: [[fileField stringValue] lastPathComponent]];
				[[NSApp delegate] directLogOutput: @" ===\n"];
				
				ePipe = [[NSPipe alloc] init];
				
				[untar setStandardOutput: ePipe];
				[untar setStandardError: ePipe];
				eHandle = [ePipe fileHandleForReading];
				
				[untar launch];
				
				[NSApp beginSheet:extractionSheet modalForWindow:e_window
				modalDelegate:self didEndSelector:NULL contextInfo:nil];
				[extractionIndicator startAnimation: self];
				
				[NSThread detachNewThreadSelector: @selector(outputExtractorData:) toTarget: self withObject: eHandle];				

				if ( [[currentDMGFile pathExtension] isEqual: @"dmg"] )
				{
					[untar waitUntilExit];
				
					status = [untar terminationStatus];
					
					[untar release];		// free up memeory from the task
					untar = nil;                         
				
					if ( 0 == status )
					{
						[[NSWorkspace sharedWorkspace] openFile: currentDMGFile];
					}
				}
				
				// reinitialize variables
				beepWhenFinished = YES;
				pauseTaskRelease = NO;
				wasCanceled      = NO;        
				
				if (tempSuspendQuit == YES)
				{
					[NSApp terminate: self];
				}
            
            } // end of DMG section
            else // otherwise, just .gz, or .z
            {
                untar = [[NSTask alloc] init];
                [untar setLaunchPath:@"/usr/bin/gunzip"];
            
                [untar setArguments:[NSArray arrayWithObjects: @"-v", [fileField stringValue], nil]];           
            }   
        }
    }
    // .taz code added 22. August 2003
    // Z, TAZ, TAR.Z ------------------------------------------------
    else if ([ [[fileField stringValue] pathExtension] isEqual: @"Z"] || [[[fileField stringValue] pathExtension] isEqual: @"taz"])
    { 
        if ([ [[[fileField stringValue] stringByDeletingPathExtension] pathExtension] isEqual: @"tar"] || [[[fileField stringValue] pathExtension] isEqual: @"taz"]) // tar.Z or .taz
        {
            // This code can be simplified by this type of command:
            // tar -xvZf my_file.tar.Z (or my_file.taz)
            // Tar can also incorporate the compress utility in itself.
            untar = [[NSTask alloc] init];
            [untar setLaunchPath:@"/usr/bin/tar"];
            
			[untar setArguments:[NSArray arrayWithObjects:@"-C", directory, @"-xvZf", [fileField stringValue], nil]];            
        }
        // Test to see if somefile exists in the same directory as somefile.Z
        else // this is for just a .Z file, not a .tar.Z or .taz or whatever...
        {
            // If the bunzipped file already exists, then do not perform bunzip (bzip2 -d)
            if ([fm fileExistsAtPath: [[fileField stringValue] stringByDeletingPathExtension]] == YES)
            {
				run_task = NO;
                NSBeep();
                NSRunAlertPanel(@"Cannot uncompress", @"The file %@ already exists.", @"OK", nil, nil, [[fileField stringValue] stringByDeletingPathExtension]);
            }
            else
            {
                untar = [[NSTask alloc] init];
                [untar setLaunchPath:@"/usr/bin/uncompress"];                
                [untar setArguments:[NSArray arrayWithObjects: @"-fv", [fileField stringValue], nil]];
            }
        }
    }
    // BZ, BZ2 -----------------------------------------------------
    else if ([ [[fileField stringValue] pathExtension] isEqual: @"bz2"] || 
             [ [[fileField stringValue] pathExtension] isEqual: @"bz"]  ||
             [ [[fileField stringValue] pathExtension] isEqual: @"tbz"] ||
             [ [[fileField stringValue] pathExtension] isEqual: @"tbz2"])
    {
		// Since pre-Jaguar (10.2) systems don't come with bzip2 included, this gnutar attempt at
		// uncompressing a tbz archive cannot be completed in one step.  Instead, just uncompress
		// a tbz file using bzip on Mac OS 10.1 systems.  Otherwise, go ahead as planned.
		if ( os_version >= 1020 &&
			( [ [[fileField stringValue] pathExtension] isEqual: @"tbz"] || 
              [ [[fileField stringValue] pathExtension] isEqual: @"tbz2"] ||
              [ [[[fileField stringValue] stringByDeletingPathExtension] pathExtension] isEqual: @"tar"] ))
        {
			// gnutar in Mac OS 10.3 and later can properly uncompress tbz archives
			// The gnutar man page in 10.2 SAYS it has the option to uncompress tbz files, but it can't
			if ([fm isExecutableFileAtPath: @"/usr/bin/gnutar"] == YES && os_version >= 1030)
			{
				util_path = @"/usr/bin/gnutar";
			}
			
            if ([fm isExecutableFileAtPath: util_path] == YES)
            {
                untar = [[NSTask alloc] init];
                [untar setLaunchPath: util_path];
            				
				[untar setArguments:[NSArray arrayWithObjects:@"-C", directory, @"-xjvf", [fileField stringValue], nil]];
            }
            else
            {   
				run_task = NO;
                NSBeep();
                NSRunAlertPanel(@"Cannot decompress", @"The gnutar utility cannot be found.", @"OK", nil, nil);
            
                // Might need to reinitialize some variables here...
                [fileField setStringValue: @""];
                [dirField setStringValue: @""];
                [progress_msg setStringValue: @""];
            }
        }
		else  // otherwise, just a bz or bz2 compressed file
		{
			if ([fm isExecutableFileAtPath: @"/usr/bin/bzip2"] == YES)
			{
				util_path = @"/usr/bin/bzip2";
			}

			if ([fm isExecutableFileAtPath: util_path] == YES)
			{
				// If the bunzipped file already exists, then do not perform bunzip (bzip2 -d)
				if ([fm fileExistsAtPath: [[fileField stringValue] stringByDeletingPathExtension]] == YES)
				{
					run_task = NO;
					NSBeep();
					NSRunAlertPanel(@"Cannot decompress", @"The file %@ already exists.", @"OK", nil, nil, [[fileField stringValue] stringByDeletingPathExtension]);
				}
				else
				{
					untar = [[NSTask alloc] init];
					[untar setLaunchPath: util_path];
					
					[untar setArguments:[NSArray arrayWithObjects: @"-dv", [fileField stringValue], nil]];
				}
			}
			else
			{   
				run_task = NO;
				NSBeep();
				NSRunAlertPanel(@"Cannot decompress", @"The bzip2 utility was not found on your system.", @"OK", nil, nil);
				
				[fileField setStringValue: @""];
				[dirField setStringValue: @""];
				[progress_msg setStringValue: @""];
			}
		}
    }
    // RAR ---------------------------------------------------------
    else if ([ [[fileField stringValue] pathExtension] isEqual: @"rar"])
    {
        util_path  = [ [NSBundle mainBundle] pathForResource:@"unrar" ofType:@""];
        
        if ([fm isExecutableFileAtPath: util_path] == YES)
        {
            untar = [[NSTask alloc] init];
            [untar setLaunchPath:util_path];
            
            // The directory at the end of the array is where the rar files are extracted.		
			[untar setArguments:[NSArray arrayWithObjects: @"e", [fileField stringValue], directory, nil]];
        }
        else
        {
			run_task = NO;
            NSBeep();
            NSRunAlertPanel(@"Cannot Unrar", @"The unrar utility was not found.", @"OK", nil, nil);
            
            [fileField setStringValue: @""];
            [dirField setStringValue: @""];
            [progress_msg setStringValue: @""];
        }
    }	
    // ZIP ---------------------------------------------------------
    // uncompress a zip file (should be compatible with pkzip)
    // Note: there might be a problem with zip not being on everyone's system.
    // Zip might have been only included on those systems with the Dev Tools
    // installed, which might explain why there is no man page for zip.
	// This is no longer a problem as of Mac OS 10.3 and later
    else if ([ [[fileField stringValue] pathExtension] isEqual: @"zip"])
    {	
		if ([fm isExecutableFileAtPath: @"/usr/bin/unzip"] == YES)
		{
			util_path = @"/usr/bin/unzip";
		}
    
        if ([fm isExecutableFileAtPath: util_path] == YES)
        {
            untar = [[NSTask alloc] init];
            [untar setLaunchPath: util_path];
            
			[untar setArguments:[NSArray arrayWithObjects: @"-d", directory, [fileField stringValue], @"-x", @"__MACOSX*", nil]];        
        }
        else
        {
			run_task = NO;
            NSBeep();
            NSRunAlertPanel(@"Cannot Unzip", @"The unzip utility was not found on your system.", @"OK", nil, nil);
            
            [fileField setStringValue: @""];
            [dirField setStringValue: @""];
            [progress_msg setStringValue: @""];
        }
    }
    else
    {
        [extractionIndicator stopAnimation:self];
        
		run_task = NO;
        NSBeep();
        NSRunAlertPanel(@"Cannot uncompress", @"The file %@ cannot be uncompressed by GUI Tar", @"OK", nil, nil, [fileField stringValue]);
        
        [UTButton setTitle: @"Extract"];
        [UTButton setEnabled: YES];
        [fileField setStringValue: @""];
        [dirField setStringValue: @""];
    }
	
	if (run_task == YES)
	{
		ePipe = [[NSPipe alloc] init];
		
		[untar setStandardOutput: ePipe];
		[untar setStandardError: ePipe];
		eHandle = [ePipe fileHandleForReading];
		
		[[NSApp delegate] directLogOutput: @"=== Extracting "];
		[[NSApp delegate] directLogOutput: [[fileField stringValue] lastPathComponent]];
		[[NSApp delegate] directLogOutput: @" ===\n"];
		
		[untar launch];
		
		[NSApp beginSheet:extractionSheet modalForWindow:e_window
			modalDelegate:self didEndSelector:NULL contextInfo:nil];
		[extractionIndicator startAnimation: self];
		
		[NSThread detachNewThreadSelector: @selector(outputExtractorData:) toTarget: self withObject: eHandle];
	}

}


// =========================================================================
// (void) outputExtractorData: (NSFileHandle *) handle
// -------------------------------------------------------------------------
// Direct the output data sent from the task to the console log
// -------------------------------------------------------------------------
// Created: February 2009
// Version: 10 February 2009 21:16
// =========================================================================
- (void) outputExtractorData: (NSFileHandle *) handle
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *data;
	
    while ([data=[handle availableData] length])
    {		
        NSString *string = [[NSString alloc] initWithData:data encoding: NSASCIIStringEncoding];

		// Send text over to the WinController
		[[NSApp delegate] directLogOutput: string];
        
        [string release];
    }
	
	[[NSApp delegate] directLogOutput: @"\n"];
	
	// Save log data to file
	[[NSApp delegate] saveLogFile];
	
    [pool release];
	
	[NSThread exit]; // exit the thread, of course
}


// =========================================================================
// (NSString *) fileNameWithoutExtension: (NSString *) filename
// -------------------------------------------------------------------------
// Return the name of the file without the file extension
// Archive.tar.gz would return "Archive"
// -------------------------------------------------------------------------
// Created: 6 February 2007 20:38
// Version: 6 February 2007 20:38
// =========================================================================
- (NSString *) fileNameWithoutExtension: (NSString *) filename
{
	NSArray *fileTypes = [NSArray arrayWithObjects:@"tar", @"svgz", @"gz", @"tgz", @"z", @"Z", @"taz", @"tbz", @"tbz2", @"bz", @"bz2", @"zip", @"rar", @"7z", nil];

	if ([fileTypes containsObject: [filename pathExtension]] == NO)
	{
		return (filename);
	}
	else
	{
		return ([self fileNameWithoutExtension: [filename stringByDeletingPathExtension]]);
	}
}


// =========================================================================
// - (void) setWorkingDirectory: (BOOL) isArchive
// -------------------------------------------------------------------------
// Set the working directory where files will be extracted to when an
// archive is opened.
// -------------------------------------------------------------------------
// Created: 8 February 2007 22:14
// Version: 10 February 2007 21:28
// =========================================================================
- (void) setWorkingDirectory: (BOOL) isArchive
{
	BOOL isDir = YES;
	
	if (isArchive == YES)
	{
		if ([[dirField stringValue] isEqual: @""] == YES)
		{
			[directory setString: [[ [[fileField stringValue] stringByDeletingLastPathComponent] stringByAppendingString:@"/"] stringByAppendingString:[self fileNameWithoutExtension: [[fileField stringValue] lastPathComponent]]] ];
		}
		else
		{
			[directory setString: [[ [dirField stringValue] stringByAppendingString:@"/"] stringByAppendingString:[self fileNameWithoutExtension: [[fileField stringValue] lastPathComponent]]] ];
		}
		
		// Create the working directory if it does not already exist.
		if ( ![fm fileExistsAtPath: directory isDirectory:&isDir] && isDir )
		{
			[fm createDirectoryAtPath:directory attributes:nil];
		}
	}
	else // just compressed files (i.e. .gz, .svgz, .bz)
	{	// This is an arbitrary value since compressed files normally wouldn't make use of "directory"
		[directory setString: [[fileField stringValue] stringByDeletingLastPathComponent]];
	}
	
}


// =========================================================================
// - (BOOL) isArchive
// -------------------------------------------------------------------------
// Check if a file is an archive (tar, tar.gz, rar, zip, 7z, tbz, etc.) or
// if it is just a compressed file.
// -------------------------------------------------------------------------
// Created: 10 February 2007 21:29
// Version: 10 February 2007 21:29
// =========================================================================
- (BOOL) isArchive: (NSString *) filename
{
	NSArray *compressedFileExtensions = [NSArray arrayWithObjects: @"svgz", @"gz", @"z", @"Z", @"bz", @"bz2", nil];
	
	if ([compressedFileExtensions containsObject: [filename pathExtension]] &&
		[[[filename stringByDeletingPathExtension] pathExtension] isEqual: @"tar"] == NO)
	{
		return (NO);
	}
	else
	{
		return (YES);
	}
}


// =========================================================================
// (void) startExtractor: (NSNotification *)aNotification
// -------------------------------------------------------------------------
// Version: 24. November 2006 0:19
// Created: 28. January 2004 14:34
// -------------------------------------------------------------------------
// This is called from the WinController after a file is dropped onto the 
// GUI Tar icon.
// =========================================================================
- (void) startExtractor: (NSNotification *)aNotification
{
    NSArray *file_types = [NSArray arrayWithObjects:@"tar", @"svgz", @"gz", @"tgz", @"z", @"Z", @"taz", @"tbz", @"tbz2", @"bz", @"bz2", @"zip", @"rar", @"7z", nil];
    int i = 0;
    
    [file_list setArray: [aNotification object]];
    
    for (i = 0; i < [file_list count]; i++)
    {
        if ([file_types containsObject: [[file_list objectAtIndex: i] pathExtension]] == YES)
        {
            [fileField setStringValue: [file_list objectAtIndex: i]];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(doneTarring:) 
                name:NSTaskDidTerminateNotification 
                object:untar];
                
    quitWhenFinished = YES;
    beepWhenFinished = NO;
    tempSuspendQuit  = YES;
    
    [self unTarIt];
}


// =========================================================================
// (void)doneTarring: (NSNotification *)aNotification
// -------------------------------------------------------------------------
// This file is called once the tar NSTask is complete
// NOTE [9. Nov 2003] : Need to reinitialize variables after a task has been
// completed.  Otherwise, odd messages will appear (such as Untar has been
// canceled), or it won't bing when necessary.
// -------------------------------------------------------------------------
// Version: 15 February 2009 16:00
// =========================================================================
- (void)doneTarring:(NSNotification *)aNotification 
{   
    NSMutableString *open_dir = [[NSMutableString alloc] init];

    if ([[dirField stringValue] isEqualToString: @""])
    {
        [open_dir setString: [[fileField stringValue] stringByDeletingLastPathComponent]];
    }
    else
    {
        [open_dir setString: [dirField stringValue]];
    }
    
    [fileField setStringValue: @""];
    [dirField setStringValue: @""];
    [progress_msg setStringValue: @""];
    
    [UTButton setTitle: @"Extract"];
    [UTButton setEnabled: YES]; 	// re-enable the Untar button

    [extractionIndicator stopAnimation: self];
    [extractionSheet orderOut:nil];
    [NSApp endSheet: extractionSheet];
    [eCancelButton setEnabled: YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSTaskDidTerminateNotification object: nil];

    // The NSTask untar's resources are released here for most cases
    // except when there is more than one process to be run, such as
    // with a dmg.gz file.  Otherwise, Disk Copy will not always run
    // if Untar's resources are released here.    
    if (pauseTaskRelease == NO)
    {
        [untar release];		// free up memeory from the task
        untar = nil; 
		[ePipe release];
		ePipe = nil;
    }
   
    // Need to reinitialize variables after a task has been
    // completed.  Otherwise, odd messages will appear (such as Untar has been
    // canceled), or it won't bing when necessary.
    if (wasCanceled == YES)
    {
        NSBeep();
        NSRunAlertPanel(@"GUI Tar canceled", @"GUI Tar has been canceled.", @"OK", nil, nil);
        
        beepWhenFinished = YES;
        tempSuspendQuit  = NO;
        pauseTaskRelease = NO;
        wasCanceled      = NO;
    }
    else if (beepWhenFinished == YES)
    {
        NSBeep();
        
        beepWhenFinished = YES;
        tempSuspendQuit  = NO;
        pauseTaskRelease = NO;
        wasCanceled      = NO;    
        
        [[NSWorkspace sharedWorkspace] selectFile: nil inFileViewerRootedAtPath: open_dir];
    }

    if (quitWhenFinished == YES)
    {
        NSBeep();
        [[NSWorkspace sharedWorkspace] selectFile: nil inFileViewerRootedAtPath: open_dir];
		sleep(1);
        [NSApp terminate:self];
    }
 
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

@end
