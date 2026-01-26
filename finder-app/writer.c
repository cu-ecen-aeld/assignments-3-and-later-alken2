/*
Writer C program for writing text to a file
Author: Kenneth Alcineus
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syslog.h>
#include <syslog.h>
#include <unistd.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
    openlog(NULL, 0, LOG_USER);

    if (argc < 3)
    {
        syslog(LOG_ERR, "Two arguments must be specified");
        closelog();
        return 1;
    }

    //owner rw, user r, group r
    int writefile = open(argv[1], O_TRUNC | O_WRONLY | O_CREAT, 0644);
    if (writefile < 0)
    {
        syslog(LOG_ERR, "Could not open file");
        closelog();
        return 1;
    }

    size_t writelen = (size_t)strlen(argv[2]);
    int writesize = (int)write(writefile, argv[2], writelen);
    if (writesize < 0)
    {
        syslog(LOG_ERR, "Could not write to file");
        closelog();
        return 1;
    }

    syslog(LOG_INFO, "File written successfully");
    closelog();
    return 0;
}