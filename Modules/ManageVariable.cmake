# - Get or set variables from various sources.
#
# Includes:
#   ManageString
#
# Included by:
#   ManageVersion
#   PackRPM
#
# Defines following functions:
#   SETTING_STRING_GET_VARIABLE(var value str 
#     [NOUNQUOTE] [NOREPLACE] [setting_sign]
#     )
#     - Get a variable and a value from a setting in string format.
#       i.e.  VAR=Value
#       pattern. '#' is used for comment.
#       * Parameters:
#         + var: Variable name extracted from str.
#         + value: Value extracted from str
#         + str: String to be extracted variable and value from.
#         + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#         + NOREPLACE (Optional) Without this parameter, this macro replaces
#           previous defined variables, use NOREPLACE to prevent this.
#         + NOESCAPE_SEMICOLON: (Optional) do not escape semicolons.
#         + setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
# Defines following macros:
#   COMMAND_OUTPUT_TO_VARIABLE(var cmd)
#     - Store command output to a variable, without new line characters (\n and \r).
#       This macro is suitable for command that output one line result.
#       Note that the var will be set to ${var_name}-NOVALUE if cmd does not have
#       any output.
#       * Parameters:
#         var: A variable that stores the result.
#         cmd: A command.
#
#   SETTING_FILE_GET_VARIABLES_PATTERN(var attr_pattern setting_file 
#     [NOUNQUOTE] [NOREPLACE]
#     [NOESCAPE_SEMICOLON] [setting_sign]
#     )
#     - Get variable values from a setting file if their names matches given
#       pattern. '#' is used for comment.
#       * Parameters:
#         + var: Variable to store the attribute value.
#           Set to "" to set attribute under matched variable name.
#         + attr_pattern: Regex pattern of variable name.
#         + setting_file: Setting filename.
#         + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#         + NOREPLACE (Optional) Without this parameter, this macro replaces
#           previous defined variables, use NOREPLACE to prevent this.
#         + NOESCAPE_SEMICOLON: (Optional) do not escape semicolons.
#         + setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
#   SETTING_FILE_GET_ALL_VARIABLES(setting_file [NOUNQUOTE] [NOREPLACE]
#     [NOESCAPE_SEMICOLON] [setting_sign]
#     )
#     - Get all variable values from a setting file.
#       It is equivalent to:
#       SETTING_FILE_GET_VARIABLES_PATTERN("" "[A-Za-z_][A-Za-z0-9_]*"
#        "${setting_file}" ${ARGN})
#      '#' is used to comment out setting.
#       * Parameters:
#         + setting_file: Setting filename.
#         + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#         + NOREPLACE (Optional) Without this parameter, this macro replaces
#           previous defined variables, use NOREPLACE to prevent this.
#         + NOESCAPE_SEMICOLON: (Optional) Do not escape semicolons.
#         + setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
#   SETTING_FILE_GET_VARIABLE(var attr_name setting_file 
#     [NOUNQUOTE] [NOREPLACE]
#     [NOESCAPE_SEMICOLON] [setting_sign]
#     )
#     - Get a variable value from a setting file.
#       It is equivalent to:
#	SETTING_FILE_GET_VARIABLES_PATTERN(${var} "${attr_name}"
#	    "${setting_file}" ${ARGN})
#      '#' is used to comment out setting.
#       * Parameters:
#         + var: Variable to store the attribute value.
#         + attr_name: Name of the variable.
#         + setting_file: Setting filename.
#         + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#         + NOREPLACE (Optional) Without this parameter, this macro replaces
#           previous defined variables, use NOREPLACE to prevent this.
#         + NOESCAPE_SEMICOLON: (Optional) do not escape semicolons.
#         + setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
#   SETTING_FILE_GET_ALL_VARIABLES(setting_file [NOUNQUOTE] [NOREPLACE]
#     [NOESCAPE_SEMICOLON] [setting_sign]
#     )
#     - Get all attribute values from a setting file.
#       '#' is used to comment out setting.
#       * Parameters:
#         + setting_file: Setting filename.
#         + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#         + NOREPLACE (Optional) Without this parameter, this macro replaces
#           previous defined variables, use NOREPLACE to prevent this.
#         + NOESCAPE_SEMICOLON: (Optional) Do not escape semicolons.
#         + setting_sign: (Optional) The symbol that separate attribute name and its value.
#           Default value: "="
#
#   GET_ENV(var default_value [env] 
#      [[CACHE type docstring [FORCE]] | PARENT_SCOPE]
#     )
#     - Get the value of a environment variable, or use default
#       if the environment variable does not exist or is empty.
#       * Parameters:
#         var: Variable to be set
#         default_value: Default value of the var
#         env: (Optional) The name of environment variable. Only need if different from var.
#         CACHE ... : Arguments for SET
#         PARENT_SCOPE: Arguments for SET
#
#   SET_VAR(var untrimmed_value)
#     - Trim an set the value to a variable.
#       * Parameters:
#         var: Variable to be set
#         untrimmed_value: Untrimmed values that may have space, \t, \n, \r in the front or back of the string.
#
#   VARIABLE_PARSE_ARGN(var validOptions [arguments ])
#     - Parse the arguments and put the result in var and var_<optName>
#       * Parameters:
#         var: Main variable name.
#         validOptions: List name of valid options.
#         arguments: (Optional) variable to be parsed.
#
#   VARIABLE_TO_ARGN(var prefix validOptions)
#     - Merge the variable and options to the form of ARGN.
#       Like the reverse of VARIABLE_PARSE_ARGN
#       * Parameters:
#         var: Variable that holds result.
#         prefix: Main variable name that to be processed.
#         validOptions: List name of valid options.
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

    # This macro is meant to be internal.
    MACRO(_MANAGE_VARIABLE_SET var value)
	SET(${var} "${value}")
    ENDMACRO(_MANAGE_VARIABLE_SET var value)

    # it deals the "encoded" line.
    FUNCTION(SETTING_STRING_GET_VARIABLE var value str )
	SET(setting_sign "=")
	SET(_NOUNQUOTE "")
	SET(_NOREPLACE "")
	FOREACH(_arg ${ARGN})
	    IF (${_arg} STREQUAL "NOUNQUOTE")
		SET(_NOUNQUOTE "NOUNQUOTE")
	    ELSEIF (${_arg} STREQUAL "NOREPLACE")
		SET(_NOREPLACE "NOREPLACE")
	    ELSE(${_arg} STREQUAL "NOUNQUOTE")
		SET(setting_sign ${_arg})
	    ENDIF(${_arg} STREQUAL "NOUNQUOTE")
	ENDFOREACH(_arg ${ARGN})

	STRING_SPLIT(_tokens "${setting_sign}" "${str}" 2)
	#MESSAGE("_tokens=${_tokens}")
	SET(_varName "")
	SET(_val "")
	FOREACH(_token ${_tokens})
	    #MESSAGE("_varName=${_varName} _token=${_token}")
	    IF(_varName STREQUAL "")
		SET(_varName "${_token}")
	    ELSE(_varName STREQUAL "")
		SET(_val "${_token}")
	    ENDIF(_varName STREQUAL "")
	ENDFOREACH(_token ${_tokens})
	#MESSAGE("_varName=${_varName} _val=${_val}")

	SET(${var} "${_varName}" PARENT_SCOPE)
	# Set var when
	# 1. NOREPLACE is not set, or
	# 2. var has value already.
	SET(_setVar 0)
	IF(_NOREPLACE STREQUAL "")
	    STRING_TRIM(_value "${_val}" ${_NOUNQUOTE})
	ELSEIF(${var} STREQUAL "")
	    STRING_TRIM(_value "${_val}" ${_NOUNQUOTE})
	ELSE(_NOREPLACE STREQUAL "")
	    SET(_value "${${var}}")
	ENDIF(_NOREPLACE STREQUAL "")
	SET(${value} "${_value}" PARENT_SCOPE)
	#MESSAGE("_varName=${_varName} _value=${_value}")

    ENDFUNCTION(SETTING_STRING_GET_VARIABLE var str)

    # Internal macro
    # Similar to STRING_ESCAPE, but read directly from file,
    # This avoid the variable substitution
    # Variable escape is enforced.
    MACRO(FILE_READ_ESCAPE var filename)
	# '$' is very tricky.
	# '$' => '#D'
	GET_FILENAME_COMPONENT(_filename_abs "${filename}" ABSOLUTE)
	EXECUTE_PROCESS(COMMAND cat ${filename}
	    COMMAND sed -e "s/#/#H/g"
	    COMMAND sed -e "s/[$]/#D/g"
	    COMMAND sed -e "s/;/#S/g"
	    COMMAND sed -e "s/[\\]/#B/g"
	    OUTPUT_VARIABLE _ret
	    OUTPUT_STRIP_TRAILING_WHITESPACE)

	STRING(REGEX REPLACE "\n" ";" _ret "${_ret}")
	#MESSAGE("_ret=|${_ret}|")
	SET(${var} "${_ret}")
    ENDMACRO(FILE_READ_ESCAPE var filename)

    MACRO(SETTING_FILE_GET_VARIABLES_PATTERN var attr_pattern setting_file)
	IF("${setting_file}" STREQUAL "")
	    M_MSG(${M_FATAL} "SETTING_FILE_GET_VARIABLES_PATTERN: setting_file ${setting_file} is empty")
	ENDIF("${setting_file}" STREQUAL "")
	SET(setting_sign "=")
	SET(_noUnQuoted "")
	SET(_noEscapeSemicolon "")
	SET(_noReplace "")
	SET(_escapeVariable "")
	FOREACH(_arg ${ARGN})
	    IF (${_arg} STREQUAL "NOUNQUOTE")
		SET(_noUnQuoted "NOUNQUOTE")
	    ELSEIF (${_arg} STREQUAL "NOREPLACE")
		SET(_noReplace "NOREPLACE")
	    ELSEIF (${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_noEscapeSemicolon "NOESCAPE_SEMICOLON")
	    ELSEIF (${_arg} STREQUAL "ESCAPE_VARIABLE")
		SET(_escapeVariable "ESCAPE_VARIABLE")
	    ELSE(${_arg} STREQUAL "NOUNQUOTE")
		SET(setting_sign ${_arg})
	    ENDIF(${_arg} STREQUAL "NOUNQUOTE")
	ENDFOREACH(_arg)

	# Escape everything to be safe.
	FILE_READ_ESCAPE(_lines "${setting_file}")

	#STRING_SPLIT(_lines "\n" "${_txt_content}")
	#MESSAGE("_lines=|${_lines}|")
	SET(_actual_line "")
	SET(_join_next 0)
	FOREACH(_line ${_lines})
	    #MESSAGE("_line=|${_line}|")
	    IF(NOT _line MATCHES "^[ \\t]*#H")
		# Not a comment line.
		IF(_join_next EQUAL 1)
		    SET(_actual_line "${_actual_line}${_line}" )
		ELSE(_join_next EQUAL 1)
		    SET(_actual_line "${_line}")
		ENDIF(_join_next EQUAL 1)
		#MESSAGE("_actual_line=|${_actual_line}|")

		IF(_actual_line MATCHES "#B$")
		    #Join the lines that end with \\
		    SET(_join_next 1)
		    STRING(REGEX REPLACE "#B$" "" _actual_line "${_actual_line}")
		ELSE(_actual_line MATCHES "#B$")
		    SET(_join_next 0)
		    IF(_actual_line MATCHES "[ \\t]*${attr_pattern}[ \\t]*${setting_sign}")
			#MESSAGE("*** matched_line=|${_actual_line}|")
			SETTING_STRING_GET_VARIABLE(_attr _value
			    "${_actual_line}" ${setting_sign} ${_noUnQuoted} )
			#MESSAGE("*** _attr=${_attr} _value=${_value}")
			IF(_noReplace STREQUAL "" OR NOT DEFINED ${_attr})
			    # Unencoding
			    _STRING_UNESCAPE(_value "${_value}" ${_noEscapeSemicolon} ESCAPE_VARIABLE)
			    IF(_escapeVariable STREQUAL "")
				# Variable should not be escaped
				# i.e. need substitution
				_MANAGE_VARIABLE_SET(_value "${_value}")
			    ENDIF(_escapeVariable STREQUAL "")
			    IF("${var}" STREQUAL "")
				SET(${_attr} "${_value}")
			    ELSE("${var}" STREQUAL "")
				SET(${var} "${_value}")
			    ENDIF("${var}" STREQUAL "")
			ENDIF(_noReplace STREQUAL "" OR NOT DEFINED ${_attr})
		    ENDIF(_actual_line MATCHES "[ \\t]*${attr_pattern}[ \\t]*${setting_sign}")

		ENDIF(_actual_line MATCHES "#B$")

	    ENDIF(NOT _line MATCHES "^[ \\t]*#H")
	ENDFOREACH(_line ${_lines})
	#SET(${var} "${_value}")

    ENDMACRO(SETTING_FILE_GET_VARIABLES_PATTERN var attr_pattern setting_file)

    MACRO(SETTING_FILE_GET_VARIABLE var attr_name setting_file)
	SETTING_FILE_GET_VARIABLES_PATTERN(${var} "${attr_name}"
	    "${setting_file}" ${ARGN})
    ENDMACRO(SETTING_FILE_GET_VARIABLE var attr_name setting_file)

    MACRO(SETTING_FILE_GET_ALL_VARIABLES setting_file)
	SETTING_FILE_GET_VARIABLES_PATTERN("" "[A-Za-z_][A-Za-z0-9_.]*"
	    "${setting_file}" ${ARGN})
    ENDMACRO(SETTING_FILE_GET_ALL_VARIABLES setting_file)

    MACRO(GET_ENV var default_value)
	SET(_env "${var}")
	SET(_state "")
	SET(_setArgList "")
	FOREACH(_arg ${ARGN})
	    IF(_state STREQUAL "set_args")
		LIST(APPEND _setArgList "${_arg}")
	    ELSE(_state STREQUAL "set_args")
		IF (_arg STREQUAL "CACHE")
		    SET(_state "set_args")
		    LIST(APPEND _setArgList "${_arg}")
		ELSEIF (_arg STREQUAL "PARENT_SCOPE")
		    SET(_state "set_args")
		    LIST(APPEND _setArgList "${_arg}")
		ELSE(_arg STREQUAL "CACHE")
		    SET(_env "${_arg}")
		ENDIF(_arg STREQUAL "CACHE")
	    ENDIF(_state STREQUAL "set_args")
	ENDFOREACH(_arg ${ARGN})

	IF ("$ENV{${_env}}" STREQUAL "")
	    SET(${var} "${default_value}" ${_setArgList})
	ELSE("$ENV{${_env}}" STREQUAL "")
	    SET(${var} "$ENV{${_env}}" ${_setArgList})
	ENDIF("$ENV{${_env}}" STREQUAL "")
	# MESSAGE("Variable ${var}=${${var}}")
    ENDMACRO(GET_ENV var default_value)

    MACRO(SET_VAR var untrimmedValue)
	SET(_noUnQuoted "")
	FOREACH(_arg ${ARGN})
	    IF (${_arg} STREQUAL "NOUNQUOTE")
		SET(_noUnQuoted "NOUNQUOTE")
	    ENDIF(${_arg} STREQUAL "NOUNQUOTE")
	ENDFOREACH(_arg ${ARGN})
	#MESSAGE("untrimmedValue=${untrimmedValue}")
	IF ("${untrimmedValue}" STREQUAL "")
	    SET(${var} "")
	ELSE("${untrimmedValue}" STREQUAL "")
	    STRING_TRIM(trimmedValue "${untrimmedValue}" ${_noUnQuoted})
	    #MESSAGE("***SET_VAR: trimmedValue=${trimmedValue}")
	    SET(${var} "${trimmedValue}")
	ENDIF("${untrimmedValue}" STREQUAL "")
	#SET(value "${${var}}")
	#MESSAGE("***SET_VAR: ${var}=|${value}|")
    ENDMACRO(SET_VAR var untrimmedValue)

    MACRO(VARIABLE_PARSE_ARGN var validOptions)
	SET(_optName "")	## Last _optName
	SET(_listName ${var})

	## Unset all, otherwise ghost from previous running exists.
	UNSET(${var})
	FOREACH(_o ${validOptions})
	    UNSET(${var}_${_o})
	ENDFOREACH(_o ${validOptions})

	FOREACH(_arg ${ARGN})
	    LIST(FIND ${validOptions} "${_arg}" _optIndex)
	    IF(_optIndex EQUAL -1)
		## Not an option name. Append to existing options
		LIST(APPEND ${_listName} "${_arg}")
	    ELSE(_optIndex EQUAL -1)
		## Is an option name.
		## Obtain option name
		LIST(GET ${validOptions} ${_optIndex} _optName)
		# Init the option name, so it can be find by IF(DEFINED ...)
		SET(${var}_${_optName} "")
		SET(_listName "${var}_${_optName}")
	    ENDIF(_optIndex EQUAL -1)
	ENDFOREACH(_arg ${ARGN})
    ENDMACRO(VARIABLE_PARSE_ARGN var validOptions)

    MACRO(VARIABLE_TO_ARGN var prefix validOptions)
	SET(${var} ${prefix})
	FOREACH(_o ${validOptions})
	    IF(DEFINED ${prefix}_${_o})
		LIST(APPEND ${var} ${_o} ${${prefix}_${_o}})
	    ENDIF(DEFINED ${prefix}_${_o})
	ENDFOREACH(_o ${validOptions})
    ENDMACRO(VARIABLE_TO_ARGN var prefix validOptions)

ENDIF(NOT DEFINED _MANAGE_VARIABLE_CMAKE_)

