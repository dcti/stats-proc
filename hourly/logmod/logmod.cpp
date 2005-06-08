/*
 * Format log file entries
 *
 * $Id: logmod.cpp,v 1.19 2005/06/08 17:16:59 gregh Exp $
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

enum Project {
    RC564,
    OGR,
    OGRP2,
    RC572
};
bool pproxy;
bool logdb;

void usage()
{
    fprintf(stderr, "Usage: logmod [-rc5 | -ogr | -ogrp2 | -rc572] [-pproxy] [-logdb] \n");
    exit(1);
}

void error(int line, const char *msg, const char *buf)
{
    fprintf(stderr, "BADLOG: line %d: (%s) %s\n", line, msg, buf);
}

inline char *charfwd(char *p, char c)
{
    while (*p != c) {
        if (*p == 0) {
            return NULL;
        }
        p++;
    }
    return p;
}

inline char *charrev(char *p, char c)
{
    while (*p != c) {
        if (*p == 0) {
            return NULL;
        }
        p--;
    }
    return p;
}

void process_line(int project, int line, const char *origbuf)
{
    char buf[256];

    strcpy(buf, origbuf);
    int len = strlen(buf);
    char *p = buf;
    // first field is date/time stamp
    char *date = p;
    int date_year, date_month, date_day;
    if (
            sscanf(date, "%d/%d/%d", &date_month, &date_day, &date_year) != 3
            && sscanf(date, "%d-%d-%d", &date_year, &date_month, &date_day) != 3
        )
    {
        error(line, "invalid date format", origbuf);
        return;
    }
    if (date_year < 0 || date_month < 1 || date_day < 1) {
        error(line, "invalid date (negative numbers not allowed)", origbuf);
        return;
    }
    if (date_year < 97) {
        date_year += 2000;   // two-digit year after y2k
    } else if (date_year < 1900) {
        date_year += 1900;   // two-digit year before y2k
    }
    p = charfwd(p, ',');
    if (p == NULL) {
        error(line, "no comma after date", origbuf);
        return;
    }
    p++;
    // next field is ip address which we don't care about
    p = charfwd(p, ',');
    char *ip = p;
    if (p == NULL) {
        error(line, "no comma after ip", origbuf);
        return;
    }
    *p = 0;
    p++;
    // this is the start of the email address
    char *email = p;

    // 08/23/03 12:35:26,127.0.0.1,moo@web.de,CA:601D239C:00000000,1,27,2,90050484,7,CA:601D239C:039A1A18,1,1

    // count the number of trailing fields
    // if it is sensible, use sane logic otherwise fall back to backscanning
    int trailing = 0;
    for (int i = 0; p[i] != 0; i++) {
        if (p[i] == ',') {
            trailing++;
        }
    }
    bool sane = false;
    switch (project) {
    case RC564:
        sane = (trailing == 5);
        break;
    case RC572:
        sane = (trailing == 6 || trailing == 9);
        break;
    case OGR:
        if (pproxy) {
            sane = (trailing == 5);
        } else {
            sane = (trailing == 6);
        }
        break;
    default:
        error(line, "unexpected project", origbuf);
        abort();
    }

    char *projectid, *real_project_id, *workunit_id, *size, *os, *cpu, *version, *core, *cmc_last, *cmc_ok, *status;
    if (sane) {

        char *fields[10];
        int i = 0;
        for (; *p != 0; p++) {
            if (*p == ',') {
                *p = 0;
                fields[i] = p+1;
                i++;
            }
        }
        assert(i == trailing);
        switch (project) {
        case RC564:
            projectid = "205",
            size      = fields[1];
            os        = fields[2];
            cpu       = fields[3];
            version   = fields[4];
            status    = "0";
            break;
        case RC572:
            projectid = "8";
            workunit_id = fields[0];
            size        = fields[1];
            os          = fields[2];
            cpu         = fields[3];
            version     = fields[4];
            core        = fields[5];
            cmc_last    = fields[6];
            cmc_ok      = fields[7];
            status      = (trailing == 9 ? fields[8] : (char*)"0");
            break;
        case OGR:
            projectid = fields[0];
            projectid[2] = 0;
            if (atoi(projectid) == 26) {
                projectid = "25";
            }
            // TODO strip off leading ruler length
            workunit_id = fields[0];
            size        = fields[1];
            os          = fields[2];
            cpu         = fields[3];
            version     = fields[4];
            status      = (trailing == 6 ? fields[5] : (char*)"-32767");
            break;
        case OGRP2:
            projectid = fields[0];
            projectid[2] = 0;
            if (atoi(projectid) == 26) {
                projectid = "25";
            }
            // Because we log P2 seperately, we want to track it seperately in the database, which means different project_id's
            switch (atoi(projectid)) {
                case 24:
                    real_project_id = "9";
                    break;
                case 25:
                    real_project_id = "10";
                    break;
            }

            // TODO strip off leading ruler length
            workunit_id = fields[0];
            size        = fields[1];
            os          = fields[2];
            cpu         = fields[3];
            version     = fields[4];
            status      = (trailing == 6 ? fields[5] : (char*)"-32767");
            break;
        default:
            error(line, "unexpected project", origbuf);
            abort();
        }

    } else {

        // This logic exists only because old clients could log
        // commas in email addresses. This insane case should
        // no longer need to change.

        // we'll start from the end of the string
        char *q = buf + len;
        if (q[-1] == '\n') {
            q--;
        }
        *q = 0;
        len--;

        // split off fields starting from the end.
        int wantedfields = 0;
        switch (project) {
        case RC564:
          wantedfields = 4;  // size,cpu,os,version
          break;
        case RC572:
          wantedfields = 5;  // size,cpu,os,version,coreid
          break;
        case OGR:
          if (pproxy) {
              wantedfields = 4;  // size,cpu,os,version
          } else {
              wantedfields = 5;  // size,cpu,os,version,status
          }
          break;
        default:
          error(line, "unexpected project", origbuf);
          abort();
        }

        char *endfieldptrs[10]; // room for several numeric fields at the end
        int endfields = 0;
        while (endfields < wantedfields) {
            q--;
            if (!isdigit(*q)) {
                if (*q == ',') {
                    *q = 0;
                    endfieldptrs[endfields++] = q+1;
                } else {
                    break;
                }
            }
        }
        if (endfields != wantedfields) {
            char text[80];
            snprintf(text, sizeof(text), "wrong number of required numeric fields at end (expected %d but found %d)", wantedfields, endfields);
            error(line, text, origbuf);
            return;
        }
        switch (project) {
        case RC564:
            size    = endfieldptrs[3];
            os      = endfieldptrs[2];
            cpu     = endfieldptrs[1];
            version = endfieldptrs[0];
            status  = "0";
            break;
        case RC572:
            size    = endfieldptrs[4];
            os      = endfieldptrs[3];
            cpu     = endfieldptrs[2];
            version = endfieldptrs[1];
            status  = "0";      // coreid is ignored
            break;
        case OGR:
            if (pproxy) {
                size    = endfieldptrs[3];
                os      = endfieldptrs[2];
                cpu     = endfieldptrs[1];
                version = endfieldptrs[0];
                status  = "-32767";
            } else {
                size    = endfieldptrs[4];
                os      = endfieldptrs[3];
                cpu     = endfieldptrs[2];
                version = endfieldptrs[1];
                status  = endfieldptrs[0];
            }
            break;
        default:
            error(line, "unexpected project", origbuf);
            abort();
        }

        q--;
        q = charrev(q, ',');
        if (q == NULL) {
            error(line, "could not back up to workunit id", origbuf);
            return;
        }

        // determine project id
        switch (project) {
        case RC564:
            projectid = "205";
            break;
        case RC572:
            projectid = "8";
            break;
        case OGR:
            projectid = q+1;
            projectid[2] = 0;
            if (atoi(projectid) == 26) {
                projectid = "25";
            }
            break;
        }
        *q = 0;

    }

    // convert version to exclude buildfrac if it had it.
    int iversion = atoi(version);
    if (iversion >= 90010477 && 
        iversion <  99000000) {
        sprintf(version, "%d", iversion / 10000);
    }

    // translate any commas in the email to periods.
    p = email;
    while(1) {
        p = charfwd(p, ',');
        if (p == NULL) {
            break;
        }
        *p = '.';
    }

    if ( logdb ) {
        switch (project) {
            case OGR:
                printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", date, ip, email, projectid, workunit_id, size, os, cpu, version, status);
                break;
            case OGRP2:
                printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", date, ip, email, real_project_id, workunit_id, size, os, cpu, version, status);
                break;
            case RC572:
                printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", date, ip, email, projectid, workunit_id, size, os, cpu, version, core, cmc_last, cmc_ok, status);
                break;
        }
    } else {
        // error checking
        int nstatus = atoi(status);
        switch (project) {
        case OGR:
            if ( !pproxy && !(nstatus >= -5 && nstatus <= 5) ) {
                error(line, "status not between -5 and 5", origbuf);
                return;
            }
            break;
        case RC572:
            if (nstatus != 0 && nstatus != 1) {
                error(line, "cmcstatus not 0 or 1", origbuf);
                return;
            }
            break;
        case RC564:
        default:
            break;
        }

        // write out the final entry.
        printf("%04d%02d%02d,%s,%s,%s,%s,%s,%s\n", date_year, date_month, date_day, email, projectid, size, os, cpu, version);
    }
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        usage();
    }
    Project project;
    if (strcmp(argv[1], "-rc5") == 0 || strcmp(argv[1], "-rc564") == 0) {
        project = RC564;
    } else if (strcmp(argv[1], "-ogr") == 0) {
        project = OGR;
    } else if (strcmp(argv[1], "-ogrp2") == 0) {
        project = OGRP2;
    } else if (strcmp(argv[1], "-rc572") == 0) {
        project = RC572;
    } else {
        usage();
    }

    if (argc > 2) {
        if (strcmp(argv[2], "-pproxy") == 0) {
            pproxy = true;
        } else {
            if (argc = 3 && strcmp(argv[2], "-logdb") == 0) {
                logdb = true;
            } else {
                usage();
            }
        }
    } else {
        pproxy = false;
    }

    if (argc > 3) {
        if (strcmp(argv[2], "-logdb") == 0) {
            logdb = true;
        } else {
            usage();
        }
    } else {
        logdb = false;
    }

    char buf[256];
    int line = 1;
    while (fgets(buf, sizeof(buf), stdin) != NULL) {
        int len = strlen(buf);
        if (buf[len-1] == '\n') {
            buf[len-1] = 0;
            len--;
        }
        process_line(project, line, buf);
        line++;
    }
    return 0;
}

// vi: expandtab sw=4 ts=4
