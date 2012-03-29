/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 25/03/2012
 */

/*
 * This file provides OSX specific functionality, use instead of simsys.cc
 * Provides support for application sandboxing
 */

#include "macros.h"
#include "simmain.h"
#include "simsys.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>


#include <limits.h>
#include <locale.h>

struct sys_event sys_event;


void dr_mkdir(char const* const path)
{
	mkdir(path, 0777);
}


/*
 * Provides the user's home directory
 * Creates Simutrans-specific sub-directories if they don't already exist
 */
char const* dr_query_homedir()
{
	static char buffer[PATH_MAX];
	
	sprintf(buffer, "%s/Library/Application Support", [NSHomeDirectory() UTF8String]);
	
	NSLog(@"%s", buffer);
	
	// create other subdirectories
	strcat(buffer, "/");
	
	char b2[PATH_MAX];
	sprintf(b2, "%smaps", buffer);
	dr_mkdir(b2);
	sprintf(b2, "%ssave", buffer);
	dr_mkdir(b2);
	sprintf(b2, "%sscreenshot", buffer);
	dr_mkdir(b2);
	
	return buffer;
}

/*
 * Provides the logging location for the application
 */
char const* dr_query_logdir()
{
	static char buffer[PATH_MAX];
	
	sprintf(buffer, "%s/Library/Logs", [NSHomeDirectory() UTF8String]);
	
	return buffer;
}

/*
 * Query for user pakset directory
 * This is a location users can place their own paksets
 * and use the in-game pakset selection dialog to choose one
 */
char const* dr_query_objdir()
{
	static char buffer[PATH_MAX];
	
	// TODO - this should be a user-accesible location (needs sandbox privs to read)
	sprintf(buffer, "%s/Library/Application Support/paksets/", [NSHomeDirectory() UTF8String]);
	
	return buffer;
}


/*
 * Hook to permit use of OS-native file loading window
 * To display in-game load window, return false
 */
bool dr_native_load()
{
	// TODO - call method to display save dialog
	// TODO - implement a special event which will be posted to the game thread
	//        if a file is to be loaded, which triggers the game to actually load it
	//        We will have permission to read the file at that point thanks to Powerbox
	return false;
}

/*
 * Hook to permit use of OS-native file saving window
 * To display in-game load window, return false
 */
bool dr_native_save()
{
	// TODO - call method to display save dialog
	return false;
}


/*
 * This retrieves the 2 byte string for the default language
 */
const char *dr_get_locale_string()
{
	static char code[4];
	char *ptr;
	setlocale( LC_ALL, "" );
	ptr = setlocale( LC_ALL, NULL );
	code[0] = 0;
	for(  unsigned long i = 0;  i < lengthof(code) - 1  &&  isalpha(ptr[i]);  i++  ) {
		code[i] = tolower(ptr[i]);
		code[i+1] = 0;
	}
	setlocale( LC_ALL, "C" );	// or the numberourpur may be broken
	return code[0] ? code : NULL;
}



void dr_fatal_notify(char const* const msg)
{
	// TODO - show message box in app
	fputs(msg, stderr);
}


int sysmain(int const argc, char** const argv)
{
#if defined __GLIBC__
	/* glibc has a non-standard extension */
	char* buffer2 = 0;
#else
	char buffer2[PATH_MAX];
#endif
	char buffer[PATH_MAX];
	ssize_t const length = readlink("/proc/self/exe", buffer, lengthof(buffer) - 1);
	if (length != -1) {
		buffer[length] = '\0'; /* readlink() does not NUL-terminate */
		argv[0] = buffer;
	}
	// no process file system => need to parse argv[0]
	/* should work on most unix or gnu systems */
	argv[0] = realpath(argv[0], buffer2);
	
	return simu_main(argc, argv);
}