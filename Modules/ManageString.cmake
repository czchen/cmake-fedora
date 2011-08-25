# - Collection of String utility macros.
#
# Included by:
#   ManageVarible
#
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
#     If the string is not quoted, then it returns an empty string.
#     * Parameters:
#       + var: A variable that stores the result.
#       + str: A string.
#
#   STRING_JOIN(var delimiter str_list [str...])
#   - Concatenate strings, with delimiter inserted between strings.
#     * Parameters:
#       + var: A variable that stores the result.
#       + str_list: A list of string.
#       + str: (Optional) more string to be join.
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

    MACRO(STRING_TRIM_LEFT_INDEX var str regex)
	STRING(LENGTH "${str}" _strLen)
	SET(_index 0)
	SET(_ret ${_strLen})
	WHILE(_index LESS _strLen)
	    STRING(SUBSTRING "${str}" ${_index} 1 _strCursor)
	    #MESSAGE("***STRING_UNQUOTE: _i=${_index} _strCursor=${_strCursor}")
	    IF(NOT "${_strCursor}" MATCHES "${regex}")
		SET(_ret ${_index})
		SET(_index ${_strLen})
	    ENDIF(NOT "${_strCursor}" MATCHES "${regex}")

	    MATH(EXPR _index ${_index}+1)
	ENDWHILE(_index LESS _strLen)
	SET(${var} ${_ret})
    ENDMACRO(STRING_TRIM_LEFT_INDEX var str)

    MACRO(STRING_TRIM_RIGHT_INDEX var str regex)
	STRING(LENGTH "${str}" _strLen)
	MATH(EXPR _index ${_strLen})
	SET(_ret -1)
	WHILE(_index GREATER 0)
	    MATH(EXPR _index_1 ${_index}-1)
	    STRING(SUBSTRING "${str}" ${_index_1} 1 _strCursor)
	    #MESSAGE("***STRING_UNQUOTE: _i=${_index} _strCursor=${_strCursor}")

	    IF(NOT "${_strCursor}" MATCHES "${regex}")
		SET(_ret ${_index_1})
		SET(_index 0)
	    ENDIF(NOT "${_strCursor}" MATCHES "${regex}")
	    MATH(EXPR _index ${_index}-1)
	ENDWHILE(_index GREATER 0)
	SET(${var} ${_ret})
    ENDMACRO(STRING_TRIM_RIGHT_INDEX var str)

    MACRO(STRING_TRIM var str)
	STRING_ESCAPE(_ret "${str}" ${ARGN})
	STRING_TRIM_LEFT_INDEX(_leftIndex "${str}" "[ \t\n\r]")
	STRING_TRIM_RIGHT_INDEX(_rightIndex "${str}" "[ \t\n\r]")
	MATH(EXPR _subLen ${_rightIndex}-${_leftIndex}+1)

	IF(_subLen GREATER 0)
	    STRING(SUBSTRING "${str}" ${_leftIndex} ${_subLen} _ret)
	    IF(NOT "${ARGN}" STREQUAL "NOUNQUOTE" AND _subLen GREATER 1)
		STRING(SUBSTRING "${_ret}" 0 1 _lCh)
		MATH(EXPR _subLen_1 ${_subLen}-1)
		STRING(SUBSTRING "${_ret}" _subLen_1 1 _rCh)
		MESSAGE("_lCh=${_lCh} _rCh=${_rCh} _ret=${_ret}")
		IF("${_lCh}" STREQUAL "\"" AND "${_rCh}" STREQUAL "\"")
		    MATH(EXPR _subLen_2 ${_subLen_1}-1)
		    STRING(SUBSTRING "${_ret}" 1 ${_subLen_2} _ret)
		ELSEIF("${_lCh}" STREQUAL "'" AND "${_rCh}" STREQUAL "'")
		    MATH(EXPR _subLen_2 ${_subLen_1}-1)
		    STRING(SUBSTRING "${_ret}" 1 ${_subLen_2} _ret)
		ENDIF("${_lCh}" STREQUAL "\"" AND "${_rCh}" STREQUAL "\"")
	    ENDIF(NOT "${ARGN}" STREQUAL "NOUNQUOTE" AND _subLen GREATER 1)
	ELSE(_subLen GREATER 0)
	    SET(_ret "")
	ENDIF(_subLen GREATER 0)


	# Unencoding
	STRING_UNESCAPE(${var} "${_ret}" ${ARGN})

    ENDMACRO(STRING_TRIM var str)

    # Internal macro
    # Nested Variable cannot be escaped here, as variable is already substituted
    # at the time it passes to this macro.
    MACRO(STRING_ESCAPE var str)
	# ';' and '\' are tricky, need to be encoded.
	# '#' => '#H'
	# '\' => '#B'
	# ';' => '#S'
	SET(_NOESCAPE_SEMICOLON "")
	SET(_NOESCAPE_HASH "")

	FOREACH(_arg ${ARGN})
	    IF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_NOESCAPE_SEMICOLON "NOESCAPE_SEMICOLON")
	    ELSEIF(${_arg} STREQUAL "NOESCAPE_HASH")
		SET(_NOESCAPE_HASH "NOESCAPE_HASH")
	    ENDIF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
	ENDFOREACH(_arg)

	IF(_NOESCAPE_HASH STREQUAL "")
	    STRING(REGEX REPLACE "#" "#H" _ret "${str}")
	ELSE(_NOESCAPE_HASH STREQUAL "")
	    SET(_ret "${str}")
	ENDIF(_NOESCAPE_HASH STREQUAL "")

	STRING(REGEX REPLACE "\\\\" "#B" _ret "${_ret}")
	IF(_NOESCAPE_SEMICOLON STREQUAL "")
	    STRING(REGEX REPLACE ";" "#S" _ret "${_ret}")
	ENDIF(_NOESCAPE_SEMICOLON STREQUAL "")
	#MESSAGE("STRING_ESCAPE:_ret=${_ret}")
	SET(${var} "${_ret}")
    ENDMACRO(STRING_ESCAPE var str)

    MACRO(STRING_UNESCAPE var str)
	# '#B' => '\'
	# '#H' => '#'
	# '#D' => '$'
	# '#S' => ';'
	SET(_ESCAPE_VARIABLE "")
	SET(_NOESCAPE_SEMICOLON "")
	SET(_ret "${str}")
	FOREACH(_arg ${ARGN})
	    IF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_NOESCAPE_SEMICOLON "NOESCAPE_SEMICOLON")
	    ELSEIF(${_arg} STREQUAL "ESCAPE_VARIABLE")
		SET(_ESCAPE_VARIABLE "ESCAPE_VARIABLE")
		STRING(REGEX REPLACE "#D" "$" _ret "${_ret}")
	    ENDIF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
	ENDFOREACH(_arg)
	#MESSAGE("var=${var} _ret=${_ret} _NOESCAPE_SEMICOLON=${_NOESCAPE_SEMICOLON}	ESCAPE_VARIABLE=${_ESCAPE_VARIABLE}")

	STRING(REGEX REPLACE "#B" "\\\\" _ret "${_ret}")
	IF(_NOESCAPE_SEMICOLON STREQUAL "")
	    # ';' => '#S'
	    STRING(REGEX REPLACE "#S" "\\\\;" _ret "${_ret}")
	ELSE(_NOESCAPE_SEMICOLON STREQUAL "")
	    STRING(REGEX REPLACE "#S" ";" _ret "${_ret}")
	ENDIF(_NOESCAPE_SEMICOLON STREQUAL "")
	#MESSAGE("***STRING_UNESCAPE:var=${var} _ret=${_ret}")

	IF(NOT _ESCAPE_VARIABLE STREQUAL "")
	    # '#D' => '$'
	    STRING(REGEX REPLACE "#D" "$" _ret "${_ret}")
	ENDIF(NOT _ESCAPE_VARIABLE STREQUAL "")
	STRING(REGEX REPLACE "#H" "#" _ret "${_ret}")
	#MESSAGE("***STRING_UNESCAPE 2:_ret=${_ret}")
	SET(${var} "${_ret}")
    ENDMACRO(STRING_UNESCAPE var str)


    MACRO(STRING_UNQUOTE var str)
	STRING_ESCAPE(_ret "${str}" ${ARGN})

	STRING(LENGTH "${_ret}" _strLen)
	SET(_index 0)
	SET(_startIndex 0)
	SET(_endIndex 0)
	SET(_quotCh "")
	WHILE(_index LESS _strLen)
	    STRING(SUBSTRING "${_ret}" ${_index} 1 _strCursor)
	    #MESSAGE("***STRING_UNQUOTE: _i=${_index} _strCursor=${_strCursor}")
	    IF("${_quotCh}" STREQUAL "\"")
		IF("${_strCursor}" STREQUAL "${_quotCh}")
		    MATH(EXPR _endIndex ${_index})
		ENDIF("${_strCursor}" STREQUAL "${_quotCh}")
	    ELSEIF("${_quotCh}" STREQUAL "'")
		IF("${_strCursor}" STREQUAL "${_quotCh}")
		    MATH(EXPR _endIndex ${_index})
		ENDIF("${_strCursor}" STREQUAL "${_quotCh}")
	    ELSE("${_quotCh}" STREQUAL "\"")
		IF("${_strCursor}" STREQUAL "\"")
		    # Double quote
		    SET(_quotCh "\"")
		    MATH(EXPR _startIndex ${_index}+1)
		ELSEIF("${_strCursor}" STREQUAL "'")
		    # Single quote
		    SET(_quotCh "'")
		    MATH(EXPR _startIndex ${_index}+1)
		ENDIF("${_strCursor}" STREQUAL "\"")
	    ENDIF("${_quotCh}" STREQUAL "\"")
	    MATH(EXPR _index ${_index}+1)
	ENDWHILE(_index LESS _strLen)

	MATH(EXPR _subLen ${_endIndex}-${_startIndex})
	#MESSAGE("***STRING_UNQUOTE: _start=${_startIndex} _end=${_endIndex} _subLen=${_subLen} q=${_quotCh}")
	IF(_subLen GREATER 0)
	    STRING(SUBSTRING "${_ret}" ${_startIndex} ${_subLen} _ret1)
	ELSE(_subLen GREATER 0)
	    SET(_ret1 "")
	ENDIF(_subLen GREATER 0)

	# Unencoding
	STRING_UNESCAPE(${var} "${_ret1}" ${ARGN})
    ENDMACRO(STRING_UNQUOTE var str)

    #    MACRO(STRING_ESCAPE_SEMICOLON var str)
    #	STRING(REGEX REPLACE ";" "\\\\;" ${var} "${str}")
    #ENDMACRO(STRING_ESCAPE_SEMICOLON var str)

    MACRO(STRING_JOIN var delimiter str_list)
	SET(_ret "")
	FOREACH(_str ${str_list})
	    IF(_ret STREQUAL "")
		SET(_ret "${_str}")
	    ELSE(_ret STREQUAL "")
		SET(_ret "${_ret}${delimiter}${_str}")
	    ENDIF(_ret STREQUAL "")
	ENDFOREACH(_str ${str_list})

	FOREACH(_str ${ARGN})
	    IF(_ret STREQUAL "")
		SET(_ret "${_str}")
	    ELSE(_ret STREQUAL "")
		SET(_ret "${_ret}${delimiter}${_str}")
	    ENDIF(_ret STREQUAL "")
	ENDFOREACH(_str ${str_list})
	SET(${var} "${_ret}")
    ENDMACRO(STRING_JOIN var delimiter str_list)

    MACRO(STRING_SPLIT var delimiter str)
	#MESSAGE("***STRING_SPLIT: var=${var} str=${str}")
	SET(_max_tokens "")
	SET(_NOESCAPE_SEMICOLON "")
	SET(_ESCAPE_VARIABLE "")
	FOREACH(_arg ${ARGN})
	    IF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_NOESCAPE_SEMICOLON "NOESCAPE_SEMICOLON")
	    ELSEIF(${_arg} STREQUAL "ESCAPE_VARIABLE")
		SET(_ESCAPE_VARIABLE "ESCAPE_VARIABLE")
	    ELSE(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_max_tokens ${_arg})
	    ENDIF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
	ENDFOREACH(_arg)

	IF(NOT _max_tokens)
	    SET(_max_tokens -1)
	ENDIF(NOT _max_tokens)

	STRING_ESCAPE(_str "${str}" ${_NOESCAPE_SEMICOLON} ${_ESCAPE_VARIABLE})
	#MESSAGE("_str (escaped)=${_str}")
	STRING_ESCAPE(_delimiter "${delimiter}" ${_NOESCAPE_SEMICOLON} ${_ESCAPE_VARIABLE})

	SET(_str_list "")
	SET(_token_count 0)
	STRING(LENGTH "${_delimiter}" _de_len)

	WHILE(NOT _token_count EQUAL _max_tokens)
	    #MESSAGE("_token_count=${_token_count} _max_tokens=${_max_tokens} _str=${_str}")
	    MATH(EXPR _token_count ${_token_count}+1)
	    IF(_token_count EQUAL _max_tokens)
		# Last token, no need splitting
		LIST(APPEND _str_list "${_str}")
	    ELSE(_token_count EQUAL _max_tokens)
		# in case encoded characters are delimiters
		STRING(LENGTH "${_str}" _str_len)
		SET(_index 0)
		#MESSAGE("_str_len=${_str_len}")
		SET(_token "")
		SET(_str_remain "")
		MATH(EXPR _str_end ${_str_len}-${_de_len}+1)
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

		IF("${_str_remain}" STREQUAL "")
		    # Meaning: end of string
		    LIST(APPEND _str_list "${_str}")
		    SET(_max_tokens ${_token_count})
		ELSE("${_str_remain}" STREQUAL "")
		    LIST(APPEND _str_list "${_token}")
		    SET(_str "${_str_remain}")
		ENDIF("${_str_remain}" STREQUAL "")
	    ENDIF(_token_count EQUAL _max_tokens)
	    #MESSAGE("***STRING_SPLIT:  _token_count=${_token_count}/_max_tokens=${_max_tokens}  _str_list=${_str_list}")
	ENDWHILE(NOT _token_count EQUAL _max_tokens)

	# Unencoding
	STRING_UNESCAPE(${var} "${_str_list}" ${_NOESCAPE_SEMICOLON} ${_ESCAPE_VARIABLE})
    ENDMACRO(STRING_SPLIT var delimiter str)

ENDIF(NOT DEFINED _MANAGE_STRING_CMAKE_)

