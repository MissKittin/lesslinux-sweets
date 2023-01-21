/* Program information */
#define	VERSION		"0.7"
/* COMPILED should be in an actual C file */

/* Default maximum length permitted in interactive input */
#define	INTERACTIVE_MAX	128

#if		(defined _DOS && !(defined __GNUC__))	|| defined	WINDOWS	|| defined	WIN32
#define	strcasecmp		stricmp
#endif

#if		defined	_DOS
#define	TARGET_OS		"DOS"
#elif	defined	WINDOWS || defined	WIN32
#define	TARGET_OS		"Win32"
#else
#define	TARGET_OS		"Unix/Linux/Other"
#endif

/* Options (individual bits) */
#define	PUTVAL			1
#define	INTERACTIVE		2
#define	DELETE			4
#define	DELSECT			8
#define LISTSECT		16
#define	PRINTSECT		32
#define VALID			64

#define	REGFILE			128
#define	REGFILE4		256
#define	REGFILE5		512

#define	APPEND			1024
#define	REMOVE			2048

/* Program errors */
#define	FILE_ERROR		1
#define	SECTION_ERROR	2
#define	FIELD_ERROR		3
#define	WRITE_ERROR		5

/* Argument errors */
#define	MALFORMED_ERROR		4
#define	TOOFEW_ERROR		6
#define	REDUND_ERROR		7
#define	BADLIMIT_ERROR		8
#define	BADARG_ERROR		9
#define	BADLIMITDEF_ERROR	10

#define	NOSECT_ERROR	100
#define	NOFIELD_ERROR	101
#define	NOVAL_ERROR		102

/* Function errors */
#define	PUTVAL_NOVAL	200

/* .REG file headers */
#if defined _DOS || defined WINDOWS || defined WIN32
	#define	REGHEAD			"REGEDIT4\r\n"
	#define	REGHEAD5		"Windows Registry Editor Version 5.00\r\n"
#else
	#define	REGHEAD			"REGEDIT4\n"
	#define	REGHEAD5		"Windows Registry Editor Version 5.00\n"
#endif
#define	REGHEAD_MAX		38
