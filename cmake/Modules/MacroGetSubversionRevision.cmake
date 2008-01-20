# - MACRO_GET_SUBVERSION_REVISION(revision)
# Gets the current subversion revision number
#
# Copyright (C) 2006  Andreas Schneider <mail@cynapses.org>
#
#  Redistribution and use is allowed according to the terms of the New
#  BSD license.
#  For details see the accompanying COPYING-CMAKE-SCRIPTS file.

macro (MACRO_GET_SUBVERSION_REVISION revision)

  find_program(SVN_EXECUTEABLE
    NAMES
      svn
    PATHS
      /usr/bin
      /usr/local/bin
  )

  find_file(SVN_DOT_DIR
    NAMES
      entries
    PATHS
      ${CMAKE_SOURCE_DIR}/.svn
  )

  if (SVN_EXECUTEABLE AND SVN_DOT_DIR)
    execute_process(
      COMMAND
        svnversion -n ${CMAKE_SOURCE_DIR}
      RESULT_VARIABLE
        SVN_REVISION_RESULT_VARIABLE
      OUTPUT_VARIABLE
        SVN_REVISION_OUTPUT_VARIABLE
    )

    if (SVN_REVISION_RESULT_VARIABLE EQUAL 0)
      string(REGEX MATCH "^[0-9]+" ${revision} ${SVN_REVISION_OUTPUT_VARIABLE})
    else (SVN_REVISION_RESULT_VARIABLE EQUAL 0)
      set(${revision} 0)
    endif (SVN_REVISION_RESULT_VARIABLE EQUAL 0)
  endif (SVN_EXECUTEABLE AND SVN_DOT_DIR)

endmacro (MACRO_GET_SUBVERSION_REVISION revision)
