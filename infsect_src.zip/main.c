/*
	INFSECT - the INF manipulation tool
	Released to the public domain
	
	The latest version can be found at
	http://razorback95.com/resources/programs/infsect.php
*/

#define COMPILED	__TIMESTAMP__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "infsect.h"

void version() {
	printf("INFSECT version %s %s (%s)\n"
	"Released to the public domain\n\n"
	
	"The latest version can be found at razorback95.com\n", VERSION, COMPILED, TARGET_OS);
}

void help() {
	printf("INFSECT Usage:\n"
	" infsect [file] -s [section] [-g | -d] [field | field=value] [-a | -r]\n"
	" infsect [file] -s [section] -i [field | field=value] [-j limit] [-a | -r]\n"
	" infsect [file] -l	|	infsect [file] -k [section]\n\n"
	
	"General switches:\n"
	" -s		Section name (use without any other args to print)\n"
	" -g		Read or write field value (trail with =value to write)\n"
	" -d		Delete a field\n"
	" -i		Interactive prompt to input value\n"
	" -j		Character limit for interactive input (default %d)\n"
	" -4, -5		Force REGEDIT version 4/5 header (used with REG files)\n"
	" -a		Append subvalue (used with -g)\n"
	" -r		Remove subvalue (used with -g)\n\n"
	
	
	"Alternate switches:\n"
	" -l		List all sections\n"
	" -k		Delete a section\n\n"
	
	"Program information:\n"
	" -h		Display this usage reference\n"
	" -v		Display program version\n", INTERACTIVE_MAX);
}

int abnormalExit(int error, char *name) {
	fprintf(stderr, "ERROR: ");
	switch(error) {
		case FILE_ERROR:
			fprintf(stderr, "cannot open file %s", name);
			break;
		case SECTION_ERROR:
			fprintf(stderr, "section %s not found", name);
			break;
		case FIELD_ERROR:
			fprintf(stderr, "field %s not found", name);
			break;
		case WRITE_ERROR:
			fprintf(stderr, "cannot write to %s", name);
			break;

		case MALFORMED_ERROR:
			fprintf(stderr, "malformed argument");
			break;
		case TOOFEW_ERROR:
			fprintf(stderr, "too few arguments");
			break;
		case REDUND_ERROR:
			fprintf(stderr, "redundant arguments");
			break;
		case BADLIMIT_ERROR:
			fprintf(stderr, "invalid character limit specified");
			break;
		case BADARG_ERROR:
			fprintf(stderr, "invalid argument(s) specified");
			break;
		case BADLIMITDEF_ERROR:
			fprintf(stderr, "default value longer than interactive limit");
			break;

		case NOSECT_ERROR:
			fprintf(stderr, "section not specified");
			break;
		case NOFIELD_ERROR:
			fprintf(stderr, "field/value not specified");
			break;
	}
	fprintf(stderr, "\n");
	return error;
}

void eolSeek(FILE *inf) {
	while (!feof(inf) && fgetc(inf) != '\n');
}

int lineCount(FILE *inf) {
	/*	Return line count in file. This is needed to
		allocate enough space in memory for line breaks
		when this program is run in DOS or Windows. */
	int lines = 0;
	
	fseek(inf, 0, SEEK_SET);
	while (!feof(inf)) if (fgetc(inf) == '\n') ++lines;
	fseek(inf, 0, SEEK_SET);
	return lines;
}

int quoteCheck(char c, int bits) {
	/*	Quote mark handling.
		Some INFs will have MANY quote marks in succession,
		all put together because a double quote ("") is
		used to represent a literal quote mark for writing
		to an INI file from there.
				
		If a non-repeated quote mark is found, toggle
		both bits.
		
		bit 1 = in quote
		bit 2 = still dealing with quote marks in succession
	*/
	if (c == '\"' && !(bits & 2)) {
		bits ^= 3;
	} else if (c != '\"' && bits & 2) {
		/*	After getting out of the repeated quote marks,
			clear the second bit. */
		bits &= 1;
	} else if (c == '\n') {
		/* Clear quote status on new line, it'll probably help */
		bits = 0;
	}
	return bits;
}

void printSect(FILE *inf) {
	char c;
	int quote = 0;
	
	while (!feof(inf)) {
		c = fgetc(inf);
		quote = quoteCheck(c, quote);
		
		if ((c == '[' && !(quote & 1)) || feof(inf)) {
			break;
		} else {
			putc(c, stdout);
		}
	}
}

int spaceCheck(char *s) {
	/*	Check if the string contains spaces.
		Return values:
		0 = no
		1 = yes
	*/
	char *cut = strchr(s, ' ');
	if (cut) return 0;
	else return 1;
}

char* chop(char *s, char c) {
	/* String name, character to terminate at */
	char *cut = strchr(s, c);
	if (cut) {
		*cut = '\0';
		return cut;
	}
	return NULL;
}

int cutWs(char *s) {
	/* Cut off surrounding whitespace from a string */
	unsigned int i, j = 0, quote = 0;
	
	/* Start with trailing whitespace */
	if (strlen(s) > 1) for (i = strlen(s)-1; i > 0; --i) {
		if ((s[i] == ' ' || s[i] == '\t') && !(quote & 1)) {
			s[i] = '\0';
		} else break;
		quote = quoteCheck(s[i], quote);
	}
	
	/* Now cut off leading whitespace */
	quote = 0;
	for (i = 0; i < strlen(s); ++i) {
		quote = quoteCheck(s[i], quote);
		if ((s[i] == ' ' || s[i] == '\t') && !(quote & 1)) ++j;
		else break;
	}
	
	return j;
}

void wipeComment(char *s) {
	unsigned int i, quote = 0;
	
	/* Find the semicolon, then stop */
	for (i = 0; i < strlen(s); ++i) {
		/* Check to make sure the semicolon is not in a quote */
		quote = quoteCheck(s[i], quote);
		if (s[i] == ';' && !(quote & 1)) {
			s[i] = '\0';
			break;
		}
	}
}

long findSect(FILE *inf, char *section, int opt) {
	int i = 0, j = 0;
	char c, d = '\n';
	char *s;
	/* quoteCheck not needed for finding sections */
	
	while (!feof(inf)) {
		c = fgetc(inf);
		
		/* Skip comments */
		if (c == ';') eolSeek(inf);
		else if (c == '[') {
			/* The preceding character MUST be a newline!!! */
			if (d == '\n') {
				while (!feof(inf)) {
					c = fgetc(inf);
					if (c == '\r' || c == '\n' || c == ']') break;
					else ++i;
				}
				fseek(inf, (i * -1)-1, SEEK_CUR);

				s = malloc(i+1);
				for (j = 0; j < i; ++j) s[j] = fgetc(inf);
				s[j] = '\0';

				/* If NULL set by -l, just output section names */
				if (!section) puts(s);
				else if (strcasecmp(s, section) == 0) {
					/* Section found */
					if (opt & PRINTSECT) {
						eolSeek(inf);
						printSect(inf);
					}
					free(s);
					return ftell(inf);
				}
				
				/* Not a match, try again */
				free(s);
				i = 0;
				j = 0;
			}
		}
		/* Copy character to secondary buffer */
		d = c;
	}
	
	/* Section not found */
	return -1;
}

long getVal(FILE *inf, char *field, int opt) {
	int i = 0, j = 0;
	char c;
	char *s, *sc;	/* s = full line to grab */
	char *value = NULL;
	int quote = 0;
	
	/* Retrieve full line and put in buffer */
	while (!feof(inf)) {
		c = fgetc(inf);
		quote = quoteCheck(c, quote);
		
		/* Field not found */
		if (c == '[' && !(quote & 1)) return -1;
		/* Skip comments */
		else if (c == ';' && !(quote & 1) && i == 0) eolSeek(inf);
		
		/* Determine length of line */
		else if (c == '\r' || c == '\n')  {
			fseek(inf, (i * -1)-1, SEEK_CUR);
			

			/* Create a new buffer and store the line in there */
			s = malloc(i+1);
			for (j = 0; j < i; ++j) s[j] = fgetc(inf);
			s[j] = '\0';

			/* managed later not important just yet */
			value = chop(s, '=');
			
			sc = s;
			sc += cutWs(sc);
			
			if (strcasecmp(sc, field) == 0) {
				/* Print the value to stdout if no new value specified elsewhere */
				if (!(opt & PUTVAL)) {
					if (value) {
						++value;
						value += cutWs(value);
						wipeComment(value);
						puts(value);
					}
					else fprintf(stderr, "%s does not have a value\n", field);
				}
				free(s);
				fseek(inf, (j * -1)+1, SEEK_CUR);
				return ftell(inf);
			} else {
				free(s);
				eolSeek(inf);
				i = 0;
				j = 0;
				quote = 0;
			}
		}
		else ++i;
	}
	
	/* Field not found */
	return -1;
}

void modVal(char *value, char *subval, int opt) {
	/* Modify a field's value with a subvalue when using -a or -r */
	int i = 0;
	char *s;
	
	/* Need a carbon copy to work with here */
	char *newBuf = malloc(strlen(value) + strlen(subval) + 1);
	strcpy(newBuf, value);
	
	/* Parse subvalues */
	s = strtok(newBuf, ",");
	do {
		if (s) {
			s += cutWs(s);
			
			/*	Compare active subvalue with one submitted
			as the new value is being appended */
			if (strcasecmp(s, subval) != 0) {
				if (i == 0) strcpy(value, s);
				else sprintf(value + strlen(value), ",%s", s);
				++i;
			} else if ((opt & REMOVE) && i == 0) value[0] = '\0'; /* empty value if last subvalue */
			
		/* Advance to next subvalue */
		s = strtok(NULL, ",");
		}
	} while (s);
	
	if ((opt & APPEND)) {
		if (i == 0 || value[0] == '\0') strcpy(value, subval);
		else sprintf(value + strlen(value), ",%s", subval);
	}
	
	free(newBuf);
}

int regHeader(FILE *inf, char *outb, int opt) {
	int i, iPos = 0, bPos = 0;
	char c;
	char *header = malloc(REGHEAD_MAX+1);

	/* Apply a registry version override if requested */
	if (opt & REGFILE4) {
		eolSeek(inf);
		strcpy(header, REGHEAD);
	}else if (opt & REGFILE5) {
		eolSeek(inf);
		strcpy(header, REGHEAD5);
	} else {
		/* Read the header if it exists, it should be preserved */
		for (i = 0; i < REGHEAD_MAX; ++i) {
			c = fgetc(inf);
			if (c == '\r' || c == '\n' || feof(inf)) {
				#if defined _DOS || defined WINDOWS || defined WIN32
					header[i++] = '\r';
				#endif
				header[i++] = '\n';
				break;
			}
			else header[i] = c;
		}
		header[i] = '\0';
	}
	
	while (header[iPos] != '\0') {
		outb[bPos] = header[iPos++];
		++bPos;
	}
	
	free(header);
	return bPos;
}

int putVal(FILE *inf, char *outf, char *sect, char *field, char *value, int opt, unsigned int limit) {
	char c, *valBuf = NULL; /* used to store source value to modify */
	long point, bPos = 0;
	char *valPtr = value;
	int i, q = 0, newVal = 0, bufLen = limit, quote = 0;
	/*	newVal:
		0 = overwrite existing field
		1 = create new field
		2 = create new section and field
	*/
	
	if (field && value) bufLen += strlen(field) + strlen(value);
	
	if (opt & DELSECT) point = ftell(inf) - strlen(sect);
	else {
		point = getVal(inf, field, opt);
		
		if (point < 0) {
			/* Don't try to delete a field if it doesn't exist */
			if ((opt & DELETE) || (opt & REMOVE)) return PUTVAL_NOVAL;
			
			/* getVal() found nothing, just put it at the top of the section */
			fseek(inf, 0, SEEK_SET);
			/* Create the section if it does not exist */
			if (findSect(inf, sect, 0) < 0) newVal = 2;
			else {
				eolSeek(inf);
				newVal = 1;
			}
			point = ftell(inf);
		}
	}
	
	/* Restart from beginning of file */
	fseek(inf, 0, SEEK_SET);
	
	/* For .REG files, a header must be applied */
	if ((opt & REGFILE) || (opt & REGFILE5)) bPos += regHeader(inf, outf, opt);
	
	while(!feof(inf)) {
		c = fgetc(inf);
		
		/* Hit the field point? */
		if (ftell(inf) == point) {
			if (opt & DELSECT) {
				/* Delete the section by skipping over it entirely */
				while (!feof(inf)) {
					c = fgetc(inf);
					quote = quoteCheck(c, quote);
					if (c == '[' && !(quote & 1)) {
						outf[bPos++] = '[';
						break;
					}
				}
			} else {
				if (newVal == 0) eolSeek(inf);
				else {
					#if defined _DOS || defined WINDOWS || defined WIN32
						outf[bPos++] = '\r';
					#endif
					outf[bPos++] = '\n';
				}
				
				if (!(opt & DELETE)) {
					if (newVal == 2) bufLen += strlen(sect)+4;
					/* Calculate full size of value and use that to add to malloc() */
					if (((opt & APPEND) || (opt & REMOVE)) && newVal == 0) {
						fseek(inf, point, SEEK_SET);
						while (!feof(inf) && fgetc(inf) != '=');
						
						while (!feof(inf)) {
							c = fgetc(inf);
							if (c == '\r' || c == '\n') break;
							++q;
						}
						fseek(inf, (q * -1)-1, SEEK_CUR);
						bufLen += q;
						
						valBuf = malloc(bufLen+1);
						for (i = 0; i < q; ++i) valBuf[i] = fgetc(inf);
						valBuf[i] = '\0';
						wipeComment(valBuf);
						
						fseek(inf, point, SEEK_SET);
						modVal(valBuf, value, opt);
						valPtr = valBuf;
						eolSeek(inf);
					}
					
					/*	Switched to IA16-GCC for creating the DOS builds, hopefully
						this will be more reliable. This, of course, requires
						checking some compiler definitions to know the right
						line break style to use. */
						
					/* DOS/Windows style */
					#if defined _DOS || defined WINDOWS || defined WIN32
					if (newVal == 2) {
						sprintf(outf+bPos, "\r\n[%s]\r\n", sect);
						bPos += strlen(sect)+6;
						point = 0;
					}
					sprintf(outf+bPos, "%s = %s\r\n", field, valPtr);
					bPos += strlen(field) + strlen(valPtr) + 5;
					
					/* Unix style */
					#else
					if (newVal == 2) {
						sprintf(outf+bPos, "\n[%s]\n", sect);
						bPos += strlen(sect)+4;
						point = 0;
					}
					sprintf(outf+bPos, "%s = %s\n", field, valPtr);
					bPos += strlen(field) + strlen(valPtr) + 4;
					#endif
					
					if (valBuf) free(valBuf);
				}
			}
		/* Else, normal character duplication to memory buffer */
		}
		#if defined _DOS || defined WINDOWS || defined WIN32
		else if (!feof(inf) && c == '\n') {
			/* New lines should be CR LF in DOS or Windows */
			outf[bPos++] = '\r';
			outf[bPos++] = '\n';
		}
		#endif
		else if (!feof(inf) && c != '\r') outf[bPos++] = c;
		
	}
	
	/* Terminate the buffer */
	outf[bPos] = '\0';
	return 0;
}

int promptVal(char *field, char *value, char *valBuf, unsigned int userLen) {
	char *valMod = NULL;
	
	/* Use interactive input if requested */
	
	printf("%s", field);
	if (value) printf(", default %s", value);
	if (userLen != INTERACTIVE_MAX) printf(", limit %d", userLen-2);
	printf(": ");

	fgets(valBuf, userLen, stdin);

	/* Give up if no value is in place */
	if (!valBuf || valBuf[0] == '\n' || valBuf[0] == '\r') {
		/* Use default value if user inputs nothing */
		if (value) strcpy(valBuf, value);
		else {
			fprintf(stderr, "no value specified\n");
			return -1;
		}
	} else {
		/* Cut off that newline! */
		valBuf[strlen(valBuf)-1] = '\0';
	}
	/* Cut off excess newline */
	//if (valBuf[0] != '\n')
	valBuf[strlen(valBuf)] = '\0';

	/* If the user put spaces in the input, surround it with quotes */
	if (spaceCheck(valBuf) == 0) {
		valMod = malloc(strlen(valBuf)+3);
		sprintf(valMod, "\"%s\"", valBuf);
		strcpy(valBuf, valMod);
		free(valMod);
	}
	return 0;
}

int main(int argc, char *argv[]) {
	/* Option variable, pack bits in here */
	int opt = 0;

	/* Working argument */
	int warg = 1;
	/* Length of user input (defaults to failsafe) */
	int argLen = INTERACTIVE_MAX;
	unsigned int userLen = INTERACTIVE_MAX;
	
	/* Line counter */
	int lines;
	
	/* Working files */
	FILE *inf, *outf;
	char *fname = NULL, *fext = NULL;
	/* Various reusable names */
	char *section = NULL;
	/* Also resuable pointers, initialize them to NULL */
	char *field = NULL, *value = NULL, *intVal = NULL;
	
	/*	Need a memory buffer for the output file
		(if you're using DOS, you're gonna have to deal with the
		same old 64KB limit...) */
	char *outb;
	size_t fsize = 0;

	/* no arguments? */
	if (argc < 2) {
		help();
		return 0;
	}
	/* check the first argument */
	else if (argc < 3) {
		if (strcasecmp("-v", argv[1]) == 0)	version();
		
		else help(); /* -h is implied. */
		return 0;
	}

	/* Process command line arguments */
	for (warg = 2; warg < argc; ++warg) {
		/* If DELSECT set, ignore further arguments */
		if (opt & DELSECT) break;
		if (argv[warg][0] == '-') {
			/* Convert character in argument to lowercase if needed */
			if (argv[warg][1] >= 'A' && argv[warg][1] <= 'Z') argv[warg][1] += 32;
			
			switch(argv[warg][1]) {
				case '\0':
					/* Safety measure: break out if argument is of wrong size */
					return abnormalExit(MALFORMED_ERROR, NULL);
				case 'l':
					opt |= LISTSECT;
					break;
				case 'k':
					/* Delete section */
					opt |= DELSECT | PUTVAL;
				case 's':
					/* Safety measure: break out if insufficient arguments specified */
					if (argc < 4) {
						return abnormalExit(NOSECT_ERROR, NULL);
					}
					
					/* Get the section */
					section = argv[++warg];
					break;
				case 'd':
					opt |= DELETE | PUTVAL;
				case 'i':
					/* If DELETE is set, this is ignored later on */
					opt |= INTERACTIVE | PUTVAL;
				case 'g':
					/* Break out if too few arguments */
					if (argc < 6) {
						return abnormalExit(TOOFEW_ERROR, NULL);
					} else if (opt & VALID) {
						return abnormalExit(REDUND_ERROR, NULL);
					}
					++warg;
					opt |= VALID;
					
					/* Is no field/value specified? */
					if (warg > argc) {
						return abnormalExit(NOFIELD_ERROR, NULL);
					}
					
					/* Copy full argument to new buffer */
					field = argv[warg];
					argLen = strlen(field);
					
					/* Split field and value */
					value = chop(field, '=');
					if (value) {
						++value;
						opt = opt | PUTVAL;
					}
					/*	Or else rightmost bit for opt is 0, as was declared.
						Assume that to be the case onward.
					*/
					break;
				case 'a':
					opt |= APPEND;
					break;
				case 'r':
					opt |= REMOVE;
					break;
				case 'j':
					/* Set character limit for interactive input */
					++warg;
					if (warg <= argc) {
						/*	Only do this if the user actually specified a number!
							NOTE: needs three extra bytes here */
						userLen = atoi(argv[warg])+2;
						if (userLen <= 2) {
							return abnormalExit(BADLIMIT_ERROR, NULL);
						}
					}
					break;
				case '4':
					/*	Force Registry Editor version 4 in .REG files
						(Windows 95/98/ME/NT4) */
					opt |= REGFILE4;
					break;
				case '5':
					/*	Force Registry Editor version 5 in .REG files
						(Windows 2000 and onward) */
					opt |= REGFILE5;
					break;
			}
		}
	}
	
	/* first argument has to be a file name... */
	fname = argv[1];
	
	/* Get extension of file; .REG files get special treatment */
	fext = strchr(fname, '.');
	if (fext) {
		++fext;
		if (strcasecmp(fext, "reg") == 0) opt |= REGFILE;
	}
	
	/* Break out if interactive length limit longer than default value */
	if (value && (strlen(value) > userLen-2) && (opt & INTERACTIVE)) {
		return abnormalExit(BADLIMITDEF_ERROR, NULL);
	}
	/* End of argument processing */
	
	/* Break out if invalid arguments passed */
	if (argc > 4 && !(opt & VALID)) {
		return abnormalExit(BADARG_ERROR, NULL);
	} else if (!section && !(opt & LISTSECT)) {
		return abnormalExit(NOSECT_ERROR, NULL);
	}
	
	// Open the file for reading
	inf = fopen(fname, "rb");
	if (!inf) {
		if (opt & PUTVAL) {
			/*	If the file does not exist but a write mode is being used,
				such a file is to be created here. */
			outf = fopen(fname, "wb");
			if (!outf) {
				return abnormalExit(WRITE_ERROR, fname);
			}
			
			/* Allows the registry file to not be empty because dumb */
			if (opt & REGFILE5) fprintf(outf, REGHEAD5);
			else if (opt & REGFILE) fprintf(outf, REGHEAD);
			
			fclose(outf);
			inf = fopen(fname, "rb");
		} else {
			return abnormalExit(FILE_ERROR, fname);
		}
	}
	
	/* Get the file size */
	fseek(inf, 0, SEEK_END);
	fsize = (size_t)ftell(inf) + argLen + userLen + REGHEAD_MAX + 8;
	fseek(inf, 0, SEEK_SET);
	
	/* Get line count to determine the correct buffer size when using CRLF */
	lines = lineCount(inf);
	fsize += lines;
	
	/* TODO: be able to manage sectionless files */
	/* Move file cursor to position */
	if (opt & LISTSECT) {
		/* If -l specified, just list all sections and exit normally */
		findSect(inf, NULL, 0);
		return 0;
	} else if (argc == 4 && !(opt & DELSECT)) {
		/* Print the entire section if no further arguments given. */
		opt |= PRINTSECT;
		findSect(inf, section, opt);
		return 0;
	} else if (findSect(inf, section, 0) < 0 && !(opt & PUTVAL)) {
		return abnormalExit(SECTION_ERROR, section);
	}
	
	if (opt & PUTVAL) {
		if (opt & INTERACTIVE && !(opt & DELETE)) {
			intVal = malloc(userLen+3);
			if (promptVal(field, value, intVal, userLen) == 0) value = intVal;
			else {
				free(intVal);
				return NOVAL_ERROR;
			}
		}
		
		outb = malloc(fsize);
		if (putVal(inf, outb, section, field, value, opt, userLen) != PUTVAL_NOVAL) {
			outf = fopen(fname, "wb");
			if (!outf) {
				free(outb);
				return abnormalExit(WRITE_ERROR, fname);
			}
			/*	Wow, trying to create a special function to write the buffer to a file
				was really dumb... it's fast enough for computers from 1995 and later,
				but it was HORRIBLY slow on an XT. writeFile() is useless,
				fprintf() is much faster.
				
				Of course, now I found out there is also fwrite()... */
			fwrite(outb, strlen(outb), 1, outf);
			free(outb);
		} else {
			return abnormalExit(FIELD_ERROR, field);
		}
	} else {
		if (getVal(inf, field, opt) == -1) {
			return abnormalExit(FIELD_ERROR, field);
		}
	}
	
	/* Let the operating system close all files */
	if (intVal) free(intVal);
	return 0;
}
