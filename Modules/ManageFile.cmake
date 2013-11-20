# - Module for File Handling Function
#
# Includes:
#   ManageMessage
#
# Defines following variables:
#
# Defines following functions:
#   FIND_PROGRAM_ERROR_HANDLING(<VAR> name verboseLevel 
#     [ERROR_MSG errorMessage]
#     [ERROR_VAR errorVar]
#     [FIND_PROGRAM_ARGS ...]
#   )
#
#     Find an executable program, with proper error handling.
#     It is essentially a wrapper of FIND_PROGRAM
#     Parameter:
#     + VAR: The variable that stores the path of the found program.
#     + name: The filename of the command.
#     + verboseLevel: See ManageMessage for semantic of each verbose level.
#     + ERROR_MSG errorMessage: Error message to be append.
#     + ERROR_VAR errorVar: Variable to be set as 1 when not found.
#     + FIND_PROGRAM_ARGS: A list of arguments to be passed 
#       to FIND_PROGRAM
#

IF(NOT DEFINED _MANAGE_FILE_CMAKE_)
    SET(_MANAGE_FILE_CMAKE_ "DEFINED")

    FUNCTION(FIND_PROGRAM_ERROR_HANDLING VAR name verboseLevel)
	SET(_errorMsg "")
	SET(_errorVar "")
	SET(_findProgramArgList "")
	SET(_state "")
	FOREACH(_arg ${ARGN})
	    IF(_state STREQUAL "ERROR_MSG")
		SET(_errorMsg "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "ERROR_VAR")
		SET(_errorVar "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "FIND_PROGRAM_ARGS")
		LIST(APPEND _findProgramArgList "${_arg}")
	    ELSE(_state STREQUAL "ERROR_MSG")
		IF(_arg STREQUAL "ERROR_MSG")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "ERROR_VAR")
		    SET(_state "${_arg}")
		ELSE(_arg STREQUAL "ERROR_MSG")
		    SET(_state "FIND_PROGRAM_ARGS")
		    LIST(APPEND _findProgramArgList "${_arg}")
		ENDIF(_arg STREQUAL "ERROR_MSG")
	    ENDIF(_state STREQUAL "ERROR_MSG")
	ENDFOREACH(_arg ${ARGN})

	FIND_PROGRAM(${VAR} ${name} ${_findProgramArgList})
	IF(${VAR} STREQUAL "${VAR}-NOTFOUND")
	    M_MSG(${verboseLevel} "Program ${name} is not found!${_errorMsg}")

	    IF (NOT _errorVar STREQUAL "")
		SET(${_errorVar} 1)
	    ENDIF(NOT _errorVar STREQUAL "")
	ENDIF(${VAR} STREQUAL "${VAR}-NOTFOUND")
    ENDFUNCTION(FIND_PROGRAM_ERROR_HANDLING VAR name verboseLevel)
    
ENDIF(NOT DEFINED _MANAGE_FILE_CMAKE_)

