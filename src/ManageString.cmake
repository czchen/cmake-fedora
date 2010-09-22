# - Collection of String utility macros.
# Defines the following macros:
#   STRING_TRIM(var str [UNQUOTED])
#     - Trim a string by removing the leading and trailing spaces,
#       just like STRING(STRIP ...) in CMake 2.6 and later.
#       This macro is needed as CMake 2.4 does not support STRING(STRIP ..)
#       * Parameters:
#          var: A variable that stores the result.
#          str: A string.
#          UNQUOTED: (Optional) remove the double quote mark around the string.
#
IF(NOT DEFINED _MANAGE_STRING_CMAKE_)
    SET(_MANAGE_STRING_CMAKE_ "DEFINED")

    MACRO(STRING_TRIM var str)
	SET(${var} "")
	IF ("${ARGN}" STREQUAL "UNQUOTED")
	    # Need not trim a quoted string.
	    STRING_UNQUOTED(_var str)
	    IF(NOT _var STREQUAL "")
		# String is quoted
		SET(${var} "${_var}")
	    ENDIF(NOT _var STREQUAL "")
	ENDIF("${ARGN}" STREQUAL "UNQUOTED")

	IF(${var} STREQUAL "")
	    SET(_var_1 "+${str}+")
	    STRING(REGEX REPLACE  "^[+][ \t\r\n]*" "" _var_2 "${_var_1}" )
	    STRING(REGEX REPLACE  "[ \t\r\n]*[+]$" "" ${var} "${_var_2}" )
	ENDIF(${var} STREQUAL "")
    ENDMACRO(STRING_TRIM var str)

    MACRO(STRING_UNQUOTED var str)
	IF ("${ARGN}" STREQUAL "")
	    SET(_quoteChars "\"" "'")
	ELSE ("${ARGN}" STREQUAL "")
	    SET(_quoteChars ${ARGN})
	ENDIF ("${ARGN}" STREQUAL "")

	SET(_var "")
	FOREACH(_qch ${_quoteChars})
	    MESSAGE("_var=${_var} _qch=${_qch}")
	    IF(_var STREQUAL "")
		STRING(REGEX REPLACE "^[ \t\r\n]*${_qch}\(.*\)${_qch}[ \t\r\n]*$" "\\1" _var ${str})
	    ENDIF(_var STREQUAL "")
	ENDFOREACH(_qch ${_quoteChars})
	SET(${var} "${_var}")
    ENDMACRO(STRING_UNQUOTED var str)

ENDIF(NOT DEFINED _MANAGE_STRING_CMAKE_)

