# - Get or set variables from various sources.
# Defines the following macros:
#   COMMAND_OUTPUT_TO_VARIABLE(var cmd)
#     - Store command output to a variable, without new line characters (\n and \r).
#       This macro is suitable for command that output one line result.
#       Note that the var will be set to ${var_name}-NOVALUE if cmd does not have
#       any output.
#       * Parameters:
#         var: A variable that stores the result.
#         cmd: A command.
#
#   SETTING_FILE_GET_VARIABLE(var attr_name setting_file [NOUNQUOTED]
#     [NOESCAPE_SEMICOLON] [setting_sign])
#     - Get an attribute value from a setting file.
#       * Parameters:
#         var: Variable to store the attribute value.
#         attr_name: Name of the attribute.
#         setting_file: Setting filename.
#         NOUNQUOTED: (Optional) do not remove the double quote mark around the string.
#         NOESCAPE_SEMICOLON: Escape semicolons.
#         setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
#   SETTING_FILE_GET_ALL_VARIABLES(setting_file [NOUNQUOTED] [NOREPLACE]
#     [NOESCAPE_SEMICOLON] [setting_sign])
#     - Get all attribute values from a setting file.
#       '#' is used to comment out setting.
#       * Parameters:
#         setting_file: Setting filename.
#         NOUNQUOTED: (Optional) do not remove the double quote mark around the string.
#         NOREPLACE (Optional) Without this parameter, this macro replaces
#           previous defined variables, use NOREPLACE to prevent this.
#         NOESCAPE_SEMICOLON: Escape semicolons.
#         setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
#   GET_ENV(var default_value [env])
#     - Get the value of a environment variable, or use default
#       if the environment variable does not exist or is empty.
#       * Parameters:
#         var: Variable to be set
#         default_value: Default value of the var
#         env: (Optional) The name of environment variable. Only need if different from var.
#
#   SET_VAR(var untrimmed_value)
#     - Trim an set the value to a variable.
#       * Parameters:
#         var: Variable to be set
#         untrimmed_value: Untrimmed values that may have space, \t, \n, \r in the front or back of the string.
#

IF(NOT DEFINED _MANAGE_VARIABLE_CMAKE_)
    SET(_MANAGE_VARIABLE_CMAKE_ "DEFINED")
    INCLUDE(ManageString)

    MACRO(COMMAND_OUTPUT_TO_VARIABLE var cmd)
	EXECUTE_PROCESS(
	    COMMAND ${cmd} ${ARGN}
	    OUTPUT_VARIABLE _cmd_output
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	IF(_cmd_output)
	    SET(${var} ${_cmd_output})
	ELSE(_cmd_output)
	    SET(var "${var}-NOVALUE")
	ENDIF(_cmd_output)
	#SET(value ${${var}})
	#MESSAGE("var=${var} _cmd_output=${_cmd_output} value=|${value}|" )
    ENDMACRO(COMMAND_OUTPUT_TO_VARIABLE var cmd)

    # This is internal macro, as it deals the "encoded" line.
    MACRO(SETTING_FILE_LINE_PARSE attr value setting_sign _noUnQuoted str)
	STRING_SPLIT(_tokens "${setting_sign}" "${str}" 2)
	SET(_index 0)
	FOREACH(_token ${_tokens})
	    IF(_index EQUAL 0)
		SET(${attr} "${_token}")
	    ELSE(_index EQUAL 0)
		STRING_TRIM(_value "${_token}" ${_noUnQuoted})
		SET(${value} "${_value}")
	    ENDIF(_index EQUAL 0)
	    MATH(EXPR _index ${_index}+1)
	ENDFOREACH(_token ${_tokens})
    ENDMACRO(SETTING_FILE_LINE_PARSE attr value setting_file)

    MACRO(SETTING_FILE_GET_VARIABLE var attr_name setting_file)
	SET(setting_sign "=")
	SET(_noUnQuoted "")
	SET(_noEscapeSemicolon "")
	FOREACH(_arg ${ARGN})
	    IF (${_arg} STREQUAL "UNQUOTED")
		SET(_noUnQuoted "UNQUOTED")
	    ELSE(${_arg} STREQUAL "UNQUOTED")
		SET(setting_sign ${_arg})
	    ELSEIF (${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_noEscapeSemicolon "NOESCAPE_SEMICOLON")
	    ENDIF(${_arg} STREQUAL "UNQUOTED")
	ENDFOREACH(_arg)

	SET(_find_pattern "\n[ \\t]*(${attr_name}\)[ \\t]*${setting_sign}\([^\n]*\)")

	# ';' is tricky, need to be encoded before loading from file
	# '#' => '#H'
	# ';" => '#S'
	IF(_noEscapeSemicolon STREQUAL "")
	    EXECUTE_PROCESS(COMMAND sed -e "s/#/#H/g" ${setting_file}
		COMMAND sed -e "s/\;/#S/g"
		OUTPUT_VARIABLE _txt_content
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	ELSE(_noEscapeSemicolon STREQUAL "")
	    EXECUTE_PROCESS(COMMAND sed -e "s/#/#H/g" ${setting_file}
		OUTPUT_VARIABLE _txt_content
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	ENDIF(_noEscapeSemicolon STREQUAL "")

	STRING_SPLIT(_lines "\n" "${_txt_content}")
	FOREACH(_line ${_lines})
	    IF(_line MATCHES "[ \\t]${attr_name}[ \\t]*${setting_sign}")
		SETTING_FILE_LINE_PARSE(_attr _value ${setting_sign}
		    ${_noUnQuoted} "${_line}")
		# Unencoding
		STRING(REGEX REPLACE "#S" "\\\\;" ${_value} "${_value}")
		STRING(REGEX REPLACE "#H" "#" ${_value} "${_value}")
	    ENDIF(_line MATCHES "[ \\t]${attr_name}[ \\t]*${setting_sign}")
	ENDFOREACH(_line ${_lines})

    ENDMACRO(SETTING_FILE_GET_VARIABLE var attr_name setting_file)

    MACRO(SETTING_FILE_GET_ALL_VARIABLES setting_file)
	SET(setting_sign "=")
	SET(_noUnQuoted "")
	SET(_NOREPLACE "")
	SET(_noEscapeSemicolon "")
	SET(SED "sed")
	FOREACH(_arg ${ARGN})
	    IF (${_arg} STREQUAL "UNQUOTED")
		SET(_noUnQuoted "UNQUOTED")
	    ELSEIF (${_arg} STREQUAL "NOREPLACE")
		SET(_NOREPLACE "NOREPLACE")
	    ELSEIF (${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_noEscapeSemicolon "NOESCAPE_SEMICOLON")
	    ELSE(${_arg} STREQUAL "UNQUOTED")
		SET(setting_sign ${_arg})
	    ENDIF(${_arg} STREQUAL "UNQUOTED")
	ENDFOREACH(_arg)
	SET(_find_pattern "\n[ \\t]*([A-Za-z0-9_]*\)[ \\t]*${setting_sign}\([^\n]*\)")

	# Use "#" to Escape ';', "#@" for original "#"
	IF(NOT _noEscapeSemicolon STREQUAL "")
	    FILE(READ "${setting_file}" _txt_content)
	ELSE(NOT _noEscapeSemicolon STREQUAL "")
	    EXECUTE_PROCESS(COMMAND sed -e "s/#/#@/g" ${setting_file}
		COMMAND sed -e "s/\;/#/g"
		OUTPUT_VARIABLE _txt_content
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	ENDIF(NOT _noEscapeSemicolon STREQUAL "")

	SET(_txt_content "\n${_txt_content}\n")

	STRING(REGEX MATCHALL "${_find_pattern}" _matched_lines "${_txt_content}")

	#MESSAGE("_matched_lines=|${_matched_lines}|")
	SET(_result_line)
	SET(_var)

	FOREACH(_line ${_matched_lines})
	    #MESSAGE("### _line=|${_line}|")
	    STRING(REGEX REPLACE "${_find_pattern}" "\\1" _var "${_line}")
	    STRING(REGEX REPLACE "${_find_pattern}" "\\2" _result_line "${_line}")

	    # Replace semicolon back.
	    STRING(REGEX REPLACE "#[^@]" "\\\\;" _result_line
		"${_result_line}")
	    STRING(REGEX REPLACE "#@" "#" _result_line
		"${_result_line}")
	    STRING(REGEX REPLACE "\\\\;" ";" _result_line
		"${_result_line}")

	    IF (NOT "${_var}" STREQUAL "")
		IF ("${_NOREPLACE}" STREQUAL "" OR "${${_var}}" STREQUAL "" )
		    #MESSAGE("### _var=${_var} _result_line=|${_result_line}|")
		    SET_VAR(${_var} "${_result_line}")
		ELSE("${_NOREPLACE}" STREQUAL "" OR "${${_var}}" STREQUAL "")
		    SET(val ${${_var}})
		    #MESSAGE("### ${_var} is already defined as ${val}")
		ENDIF("${_NOREPLACE}" STREQUAL "" OR "${${_var}}" STREQUAL "")
	    ENDIF(NOT "${_var}" STREQUAL "")
	ENDFOREACH()
    ENDMACRO(SETTING_FILE_GET_ALL_VARIABLES setting_file)

    MACRO(GET_ENV var default_value)
	IF(${ARGC} GREATER 2)
	    SET(_env "${ARGV2}")
	ELSE(${ARGC} GREATER 2)
	    SET(_env "${var}")
	ENDIF(${ARGC} GREATER 2)
	IF ("$ENV{${_env}}" STREQUAL "")
	    SET(${var} "${default_value}")
	ELSE()
	    SET(${var} "$ENV{${_env}}")
	ENDIF()
	# MESSAGE("Variable ${var}=${${var}}")
    ENDMACRO(GET_ENV var default_value)

    MACRO(SET_VAR var untrimmedValue)
	SET(_noUnQuoted "")
	FOREACH(_arg ${ARGN})
	    IF (${_arg} STREQUAL "UNQUOTED")
		SET(_noUnQuoted "UNQUOTED")
	    ENDIF(${_arg} STREQUAL "UNQUOTED")
	ENDFOREACH(_arg)
	IF ("${untrimmedValue}" STREQUAL "")
	    SET(${var} "")
	ELSE("${untrimmedValue}" STREQUAL "")
	    STRING_TRIM(trimmedValue "${untrimmedValue}" ${_noUnQuoted})
	    SET(${var} "${trimmedValue}")
	ENDIF("${untrimmedValue}" STREQUAL "")
	#SET(value "${${var}}")
	#MESSAGE("### ${var}=|${value}|")
    ENDMACRO(SET_VAR var untrimmedValue)

ENDIF(NOT DEFINED _MANAGE_VARIABLE_CMAKE_)

