//
//  NSFileManager+Utils.m
//  GUI Tar
//
//  Created by Chad Armstrong on 12/26/10.
//  Copyright 2010 Edenwaith. All rights reserved.
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

#import "NSFileManager+Utils.h"


@implementation NSFileManager (Utils)

// =========================================================================
// (BOOL) isFileSymbolicLink: (NSString *)path
// -------------------------------------------------------------------------
// Check to see if a file is a symbolic/soft link, so the link
// can be deleted with rm instead of srm, so the original file is not 
// accidentally erased.
// -------------------------------------------------------------------------
// Version: 19. November 2004 21:28
// Created: 19. November 2004 21:28
// =========================================================================
- (BOOL) isFileSymbolicLink: (NSString *) path
{
    NSDictionary *fattrs = [self fileAttributesAtPath: path traverseLink:NO];
	
    if ( [[fattrs objectForKey:NSFileType] isEqual: @"NSFileTypeSymbolicLink"])
    {
        return (YES);
    }
    else
    {
        return (NO);
    }
}

// =========================================================================
// (FSRef) convertStringToFSRef: (NSString *) path
// -------------------------------------------------------------------------
// Convert NSString to FSRef
// -------------------------------------------------------------------------
// Created: 10 December 2009 22:37
// Version: 9 June 2010 21:23
// =========================================================================
- (FSRef) convertStringToFSRef: (NSString *) path
{
	FSRef output;	
	NSURL *fileURL = [NSURL fileURLWithPath: path];
	
    if (!CFURLGetFSRef( (CFURLRef)fileURL, &output )) 
	{
        NSLog( @"Failed to create FSRef." );
    }	
	
	return output;
}

// =========================================================================
// (unsigned long long) fileSize: (NSString *) path
// -------------------------------------------------------------------------
// Created: 10 December 2009 22:45
// Version: 21 May 2010 22:39
// =========================================================================
- (unsigned long long) fileSize: (NSString *) path
{
	unsigned long long pathFileSize = 0;
	
	if ([self isFileSymbolicLink: path] == YES)
	{
		NSDictionary *fattrs = [self fileAttributesAtPath: path traverseLink: NO];
		
		if (fattrs != nil)
		{
			NSNumber *numFileSize;
			
			numFileSize = [fattrs objectForKey: NSFileSize];
			pathFileSize = [numFileSize unsignedLongLongValue];
		}
	}
	else
	{
		FSRef ref = [self convertStringToFSRef: path];
		pathFileSize = [self fastFolderSizeAtFSRef: &ref];
	}
	
	return (pathFileSize);
}


// =========================================================================
// (unsigned long long) fastFolderSizeAtFSRef:(FSRef*)theFileRef
// =========================================================================
- (unsigned long long) fastFolderSizeAtFSRef:(FSRef*)theFileRef
{
	FSIterator	thisDirEnum = NULL;
	unsigned long long totalSize = 0;
	
	// Iterate the directory contents, recursing as necessary
	if (FSOpenIterator(theFileRef, kFSIterateFlat, &thisDirEnum) == noErr)
	{
		const ItemCount kMaxEntriesPerFetch = 256;
		ItemCount actualFetched;
		FSRef	fetchedRefs[kMaxEntriesPerFetch];
		FSCatalogInfo fetchedInfos[kMaxEntriesPerFetch];
		
		OSErr fsErr = FSGetCatalogInfoBulk(thisDirEnum, kMaxEntriesPerFetch, &actualFetched,
										   NULL, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes | kFSCatInfoNodeFlags, fetchedInfos,
										   fetchedRefs, NULL, NULL);
		while ((fsErr == noErr) || (fsErr == errFSNoMoreItems))
		{
			ItemCount thisIndex;
			for (thisIndex = 0; thisIndex < actualFetched; thisIndex++)
			{
				// Recurse if it's a folder
				if (fetchedInfos[thisIndex].nodeFlags & kFSNodeIsDirectoryMask)
				{
					totalSize += [self fastFolderSizeAtFSRef:&fetchedRefs[thisIndex]];
				}
				else
				{
					// add the size for this item
					totalSize += fetchedInfos[thisIndex].dataLogicalSize + fetchedInfos[thisIndex].rsrcLogicalSize;
				}
			}
			
			if (fsErr == errFSNoMoreItems)
			{
				break;
			}
			else
			{
				// get more items
				fsErr = FSGetCatalogInfoBulk(thisDirEnum, kMaxEntriesPerFetch, &actualFetched,
											 NULL, kFSCatInfoDataSizes | kFSCatInfoNodeFlags, fetchedInfos,
											 fetchedRefs, NULL, NULL);
			}
		}
		FSCloseIterator(thisDirEnum);
	}
	else
	{
		FSCatalogInfo		fsInfo;
		
		if (FSGetCatalogInfo(theFileRef, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes, &fsInfo, NULL, NULL, NULL) == noErr)
		{
			if (fsInfo.rsrcLogicalSize > 0)
			{
				totalSize += (fsInfo.dataLogicalSize + fsInfo.rsrcLogicalSize);
			}
			else
			{
				totalSize += (fsInfo.dataLogicalSize);
			}
		}
	}
	
	return totalSize;
}

// =========================================================================
// (NSString *) formatFileSize: (double) file_size
// -------------------------------------------------------------------------
// Created: 8 August 2007 22:09
// Version: 25 May 2010
// =========================================================================
- (NSString *) formatFileSize: (double) file_size
{
	NSString *file_size_label;
	double baseSize = 1024.0;	// For Mac OS 10.6+, set this to 1000.0
	
	SInt32		systemVersion;
	Gestalt(gestaltSystemVersion, (SInt32 *) &systemVersion); 	// What version of OS X are we running?
	
	if (systemVersion >= 0x00001060)
	{
		baseSize = 1000.0;
	}
	
	if ( (file_size / baseSize) < 1.0)
		file_size_label = @" bytes";
	else if ((file_size / pow(baseSize, 2)) < 1.0)
	{
		file_size = file_size / baseSize;
		file_size_label = @" KB";
	}
	else if ((file_size / pow(baseSize, 3)) < 1.0)
	{
		file_size = file_size / pow(baseSize, 2);
		file_size_label = @" MB";
	}
	else
	{
		file_size = file_size / pow(baseSize, 3);
		file_size_label = @" GB";
	}	
	
	return ([NSString stringWithFormat: @"%.1f%@", file_size, file_size_label]);
}

@end
