# - Collection of String utility macros.
# Defines the following macros:
#   STRING_TRIM(var str [NOUNQUOTE])
#   - Trim a string by removing the leading and trailing spaces,
#     just like STRING(STRIP ...) in CMake 2.6 and later.
#     This macro is needed as CMake 2.4 does not support STRING(STRIP ..)
#     This macro also remove quote and double quote marks around the string,
#     unless NOUNQUOTE is defined.
#     * Parameters:
#       + var: A variable that stores the result.
#       + str: A string.
#       + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#
#   STRING_UNQUOTE(var str)
#   - Remove double quote marks and quote marks around a string.
#     * Parameters:
#       + var: A variable that stores the result.
#       + str: A string.
#
#   STRING_SPLIT(var delimiter str [NOESCAPE_SEMICOLON])
#   - Split a string into a list using a delimiter, which can be in 1 or more
#     characters long.
#     * Parameters:
#       + var: A variable that stores the result.
#       + delimiter: To separate a string.
#       + str: A string.
#       + NOESCAPE_SEMICOLON: (Optional) Do not escape semicolons.
#

IF(NOT DEFINED _MANAGE_STRING_CMAKE_)
    SET(_MANAGE_STRING_CMAKE_ "DEFINED")

    MACRO(STRING_TRIM var str)
	SET(${var} "")
	IF (NOT "${ARGN}" STREQUAL "NOUNQUOTE")
	    # Need not trim a quoted string.
	    STRING_UNQUOTE(_var "${str}")
	    IF(NOT _var STREQUAL "")
		# String is quoted
		SET(${var} "${_var}")
	    ENDIF(NOT _var STREQUAL "")
	ENDIF(NOT "${ARGN}" STREQUAL "NOUNQUOTE")

	IF(${var} STREQUAL "")
	    SET(_var_1 "${str}")
	    STRING(REGEX REPLACE  "^[ \t\r\n]+" "" _var_2 "${_var_1}" )
	    STRING(REGEX REPLACE  "[ \t\r\n]+$" "" _var_3 "${_var_2}" )
	    SET(${var} "${_var_3}")
	ENDIF(${var} STREQUAL "")
    ENDMACRO(STRING_TRIM var str)

    MACRO(STRING_UNQUOTE var str)

	# ';' and '\' are tricky, need to be encoded.
	# '\' => '#B'
	# '#' => '#H'
	# ';' => '#S'
	STRING(REGEX REPLACE "#" "#H" _ret "${str}")
	STRING(REGEX REPLACE "\\\\" "#B" _ret "${_ret}")
	STRING(REGEX REPLACE ";" "#S" _ret "${_ret}")

	IF(_ret MATCHES "^[ \t\r\n]+")
	    STRING(REGEX REPLACE "^[ \t\r\n]+" "" _ret "${_ret}")
	ENDIF(_ret MATCHES "^[ \t\r\n]+")
	IF(_ret MATCHES "^\"")
	    # Double quote
	    STRING(REGEX REPLACE "\"\(.*\)\"[ \t\r\n]*$" "\\1" _ret "${_ret}")
	ELSEIF(_ret MATCHES "^'")
	    # Single quote
	    STRING(REGEX REPLACE "'\(.*\)'[ \t\r\n]*$" "\\1" _ret "${_ret}")
	ELSE(_ret MATCHES "^\"")
	    SET(_ret "")
	ENDIF(_ret MATCHES "^\"")

	# Unencoding
	STRING(REGEX REPLACE "#B" "\\\\" _ret "${_ret}")
	STRING(REGEX REPLACE "#H" "#" _ret "${_ret}")
	STRING(REGEX REPLACE "#S" "\\\\;" ${var} "${_ret}")
    ENDMACRO(STRING_UNQUOTE var str)

    #    MACRO(STRING_ESCAPE_SEMICOLON var str)
    #	STRING(REGEX REPLACE ";" "\\\\;" ${var} "${str}")
    #ENDMACRO(STRING_ESCAPE_SEMICOLON var str)

    MACRO(STRING_SPLIT var delimiter str)
	SET(_max_tokens "")
	FOREACH(_arg ${ARGN})
	    IF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_NOESCAPE_SEMICOLON "NOESCAPE_SEMICOLON")
	    ELSE(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_max_tokens ${_arg})
	    ENDIF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
	ENDFOREACH(_arg)

	IF(NOT _max_tokens)
	    SET(_max_tokens -1)
	ENDIF(NOT _max_tokens)

	# ';' and '\' are tricky, need to be encoded.
	# '\' => '#B'
	# '#' => '#H'
	STRING(REGEX REPLACE "#" "#H" _str "${str}")
	STRING(REGEX REPLACE "#" "#H" _delimiter "${delimiter}")

	STRING(REGEX REPLACE "\\\\" "#B" _str "${_str}")

	IF(NOT _NOESCAPE_SEMICOLON STREQUAL "")
	    # ';' => '#S'
	    STRING(REGEX REPLACE ";" "#S" _str "${_str}")
	    STRING(REGEX REPLACE ";" "#S" _delimiter "${_delimiter}")
	ENDIF(NOT _NOESCAPE_SEMICOLON STREQUAL "")

	SET(_str_list "")
	SET(_token_count 0)
	STRING(LENGTH "${_delimiter}" _de_len)

	WHILE(NOT _token_count EQUAL _max_tokens)
	    #MESSAGE("_token_count=${_token_count} _max_tokens=${_max_tokens} _str=${_str}")
	    MATH(EXPR _token_count ${_token_count}+1)
	    IF(_token_count EQUAL _max_tokens)
		# Last token, no need splitting
		SET(_str_list ${_str_list} "${_str}")
	    ELSE(_token_count EQUAL _max_tokens)
		# in case encoded characters are delimiters
		STRING(LENGTH "${_str}" _str_len)
		SET(_index 0)
		#MESSAGE("_str_len=${_str_len}")
		SET(_token "")
		SET(_str_remain "")
		MATH(EXPR _str_end ${_str_len}-${_de_len}+1)
		SET(_bound "k")
		WHILE(_index LESS _str_end)
		    STRING(SUBSTRING "${_str}" ${_index} ${_de_len} _str_cursor)
		    #MESSAGE("_index=${_index} _str_cursor=${_str_cursor} _de_len=${_de_len} _delimiter=|${_delimiter}|")
		    IF(_str_cursor STREQUAL _delimiter)
			# Get the token
			STRING(SUBSTRING "${_str}" 0 ${_index} _token)
			# Get the rest
			MATH(EXPR _rest_index ${_index}+${_de_len})
			MATH(EXPR _rest_len ${_str_len}-${_index}-${_de_len})
			STRING(SUBSTRING "${_str}" ${_rest_index} ${_rest_len} _str_remain)
			SET(_index ${_str_end})
		    ELSE(_str_cursor STREQUAL _delimiter)
			MATH(EXPR _index ${_index}+1)
		    ENDIF(_str_cursor STREQUAL _delimiter)
		ENDWHILE(_index LESS _str_end)

		#MESSAGE("_token=${_token} _str_remain=${_str_remain}")

		IF(_str_remain STREQUAL "")
		    # Meaning: end of string
		    SET(_str_list ${_str_list} "${_str}")
		    SET(_max_tokens ${_token_count})
		ELSE(_str_remain STREQUAL "")
		    SET(_str_list ${_str_list} "${_token}")
		    SET(_str "${_str_remain}")
		ENDIF(_str_remain STREQUAL "")
	    ENDIF(_token_count EQUAL _max_tokens)
	    #MESSAGE("_token_count=${_token_count} _max_tokens=${_max_tokens} _str=${_str}")
	ENDWHILE(NOT _token_count EQUAL _max_tokens)


	# Unencoding
	STRING(REGEX REPLACE "#B" "\\\\" _str_list "${_str_list}")
	STRING(REGEX REPLACE "#H" "#" _str_list "${_str_list}")

	IF(NOT _NOESCAPE_SEMICOLON STREQUAL "")
	    # ';' => '#S'
	    STRING(REGEX REPLACE "#S" "\\\\;" ${var} "${_str_list}")
	ELSE(NOT _NOESCAPE_SEMICOLON STREQUAL "")
	    SET(${var} ${_str_list})
	ENDIF(NOT _NOESCAPE_SEMICOLON STREQUAL "")

    ENDMACRO(STRING_SPLIT var delimiter str)

ENDIF(NOT DEFINED _MANAGE_STRING_CMAKE_)

