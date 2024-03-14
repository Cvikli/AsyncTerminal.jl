#include <pty.h>

int openpty(int *amaster, int *aslave, char *name,
                const struct termios *termp,
                const struct winsize *winp);
pid_t forkpty(int *amaster, char *name,
                const struct termios *termp,
                const struct winsize *winp);

#include <utmp.h>

int login_tty(int fd);

fd_master = open("/dev/ptmx", O_RDWR); https://docstore.mik.ua/manuals/hp-ux/en/B2355-60130/ptsname.3C.html

