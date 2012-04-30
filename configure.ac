#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])
AC_INIT([unisync-client], 0.1, [github.com/Duncanl/unisync-client])

# Checks for programs.

AC_PROG_EGREP
AC_PROG_MKDIR_P
AC_PROG_SED

AC_PATH_PROG(BASH, bash, no)
if test $BASH = no; then
   AC_MSG_ERROR([Fatal Error: Bash was not found])
   exit
fi

AC_CHECK_PROG(SSH, ssh, yes, no)
if test $SSH = no; then
   AC_MSG_ERROR([Fatal Error: SSH was not found])
   exit
fi

AC_CHECK_PROG(LSYNCD, lsyncd, yes, no)
if test $LSYNCD = no; then
   AC_MSG_ERROR([Fatal Error: lsyncd was not found])
   exit
fi

AC_CHECK_PROG(UNISON, unison, yes, no)
if test $UNISON = no; then
   AC_MSG_ERROR([Fatal Error: unison was not found])
   exit
fi

AC_CHECK_PROG(AUTOSSH, autossh, yes, no)
if test $AUTOSSH = no; then
   AC_MSG_ERROR([Fatal Error: autossh was not found])
   exit
fi

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.


AC_SYS_INTERPRETER

AC_CONFIG_FILES([Makefile
                 bin/Makefile
                 libexec/Makefile
                 etc/Makefile])

AM_INIT_AUTOMAKE
AC_ARG_PROGRAM
AC_OUTPUT
