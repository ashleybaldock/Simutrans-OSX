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
	setlocale( LC_ALL, "C" );
	return code[0] ? code : NULL;
}

void dr_fatal_notify(char const* const msg)
{
	fputs(msg, stderr);
}

bool dr_download_pakset( const char *, bool )
{
	return false;
}

/*
 * Called to spawn game thread
 */
int sysmain(int const argc, char** const argv)
{	
	return simu_main(argc, argv);
}
