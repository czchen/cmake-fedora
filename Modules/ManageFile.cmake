# - Module for File Handling Function
#
# Includes:
#   ManageMessage
#
# Defines following variables:
#
# Defines following functions:
#   FIND_FILE_ERROR_HANDLING(<VAR>
#     [ERROR_MSG errorMessage]
#     [ERROR_VAR errorVar]
#     [VERBOSE_LEVEL verboseLevel]
#     [FIND_FILE_ARGS ...]
#   )
#     Find a file, with proper error handling.
#     It is essentially a wrapper of FIND_FILE
#     Parameter:
#     + VAR: The variable that stores the path of the found program.
#     + name: The filename of the command.
#     + verboseLevel: See ManageMessage for semantic of each verbose level.
#     + ERROR_MSG errorMessage: Error message to be append.
#     + ERROR_VAR errorVar: Variable to be set as 1 when not found.
#     + FIND_FILE_ARGS: A list of arguments to be passed 
#       to FIND_FILE
#
#   FIND_PROGRAM_ERROR_HANDLING(<VAR>
#     [ERROR_MSG errorMessage]
#     [ERROR_VAR errorVar]
#     [VERBOSE_LEVEL verboseLevel]
#     [FIND_PROGRAM_ARGS ...]
#   )
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
#   MANAGE_DIRECTORY_INSTALL(dirType
#     [DEST_SUBDIR subDir]
#     [dirs | DIRECTORY dirs] [ARGS args]
#   )
#     Manage dir installation.
#     Parameter:
#     + dirType: Type of dirs. Valid values:
#       DATA, PRJ_DATA,
#       SYSCONF, SYSCONF_NO_REPLACE, 
#       LIB, LIBEXEC
#     + DEST_SUBDIR subDir: Subdir of Destination dir
#     + dirs: Files to be installed.
#     + args: Arguments for INSTALL.
#
#   MANAGE_FILE_INSTALL(fileType
#     [DEST_SUBDIR subDir]
#     [files | FILES files] [ARGS args]
#   )
#     Manage file installation.
#     Parameter:
#     + fileType: Type of files. Valid values:
#       BIN, PRJ_DOC, DATA, PRJ_DATA, 
#       SYSCONF, SYSCONF_NO_REPLACE, 
#       LIB, LIBEXEC
#     + DEST_SUBDIR subDir: Subdir of Destination dir
#     + files: Files to be installed.
#     + args: Arguments for INSTALL.


IF(NOT DEFINED _MANAGE_FILE_CMAKE_)
    SET(_MANAGE_FILE_CMAKE_ "DEFINED")
    SET(FILE_INSTALL_BIN_LIST "")
    SET(FILE_INSTALL_PRJ_DOC_LIST "")
    SET(FILE_INSTALL_DATA_LIST "")
    SET(FILE_INSTALL_PRJ_DATA_LIST "")
    SET(FILE_INSTALL_SYSCONF_LIST "")
    SET(FILE_INSTALL_SYSCONF_NO_REPLACE_LIST "")
    SET(FILE_INSTALL_LIB_LIST "")
    SET(FILE_INSTALL_LIBEXEC_LIST "")
    SET(DIRECTORY_INSTALL_DATA_LIST "")
    SET(DIRECTORY_INSTALL_PRJ_DATA_LIST "")
    SET(DIRECTORY_INSTALL_SYSCONF_LIST "")
    SET(DIRECTORY_INSTALL_SYSCONF_NO_REPLACE_LIST "")
    SET(DIRECTORY_INSTALL_LIB_LIST "")
    SET(DIRECTORY_INSTALL_LIBEXEC_LIST "")

    FUNCTION(MANAGE_DIRECTORY_INSTALL dirType)
	SET(_state "")
	SET(_dirList "")
	SET(_argList "")
	SET(_subDir "")
	FOREACH(_arg ${ARGN})
	    IF(_arg STREQUAL "DEST_SUBDIR")
		SET(_state "${_arg}")
	    ELSEIF(_arg STREQUAL "DIRECTORY")
		SET(_state "${_arg}")
	    ELSEIF(_arg STREQUAL "ARGS")
		SET(_state "${_arg}")
	    ELSE(_arg STREQUAL "DEST_SUBDIR")
		IF(_state STREQUAL "")
		    SET(_state "DIRECTORY")
		    LIST(APPEND _dirList "${_arg}")
		ELSEIF(_state STREQUAL "DEST_SUBDIR")
		    SET(_subDir "${_arg}")
		    SET(_state "")
		ELSEIF(_state STREQUAL "DIRECTORY")
		    LIST(APPEND _dirList "${_arg}")
		ELSEIF(_state STREQUAL "ARGS")
		    LIST(APPEND _argList "${_arg}")
		ENDIF(_state STREQUAL "")
	    ENDIF(_arg STREQUAL "DEST_SUBDIR")
	ENDFOREACH(_arg ${ARGN})

	IF(dirType STREQUAL "SYSCONF_NO_REPLACE")
	    SET(_destDir "${SYSCONF_DIR}/${_subDir}")
	    INSTALL(DIRECTORY ${_dirList} DESTINATION "${_destDir}" ${_argList})
	ELSE(dirType STREQUAL "SYSCONF_NO_REPLACE")
	    SET(_destDir "${${dirType}_DIR}/${_subDir}")
	    INSTALL(DIRECTORY ${_dirList} DESTINATION "${_destDir}" ${_argList})

	ENDIF(dirType STREQUAL "SYSCONF_NO_REPLACE")

	IF(_subDir)
	    FOREACH(_d ${_dirList})
		LIST(APPEND DIRECTORY_INSTALL_${dirType}_LIST 
		    "${_subDir}/${_d}")
	    ENDFOREACH(_d ${_dirList})
	ELSE(_subDir)
	    LIST(APPEND DIRECTORY_INSTALL_${dirType}_LIST 
		"${_dirList}")
	ENDIF(_subDir)
    ENDFUNCTION(MANAGE_DIRECTORY_INSTALL dirType)

    FUNCTION(MANAGE_FILE_INSTALL fileType)
	SET(_state "")
	SET(_fileList "")
	SET(_argList "")
	SET(_subDir "")
	FOREACH(_arg ${ARGN})
	    IF(_arg STREQUAL "DEST_SUBDIR")
		SET(_state "${_arg}")
	    ELSEIF(_arg STREQUAL "FILES")
		SET(_state "${_arg}")
	    ELSEIF(_arg STREQUAL "ARGS")
		SET(_state "${_arg}")
	    ELSE(_arg STREQUAL "DEST_SUBDIR")
		IF(_state STREQUAL "")
		    SET(_state "FILES")
		    LIST(APPEND _fileList "${_arg}")
		ELSEIF(_state STREQUAL "DEST_SUBDIR")
		    SET(_subDir "${_arg}")
		    SET(_state "")
		ELSEIF(_state STREQUAL "FILES")
		    LIST(APPEND _fileList "${_arg}")
		ELSEIF(_state STREQUAL "ARGS")
		    LIST(APPEND _argList "${_arg}")
		ENDIF(_state STREQUAL "")
	    ENDIF(_arg STREQUAL "DEST_SUBDIR")
	ENDFOREACH(_arg ${ARGN})

	IF(fileType STREQUAL "SYSCONF_NO_REPLACE")
	    SET(_destDir "${SYSCONF_DIR}/${_subDir}")
	    INSTALL(FILE ${_fileList} DESTINATION "${_destDir}" ${_argList})
	ELSEIF(fileType STREQUAL "BIN")
	    SET(_destDir "${${fileType}_DIR}/${_subDir}")
	    INSTALL(PROGRAM ${_fileList} DESTINATION "${_destDir}" ${_argList})
	ELSE(fileType STREQUAL "SYSCONF_NO_REPLACE")
	    SET(_destDir "${${fileType}_DIR}/${_subDir}")
	    INSTALL(FILE ${_fileList} DESTINATION "${_destDir}" ${_argList})

	ENDIF(fileType STREQUAL "SYSCONF_NO_REPLACE")

	IF(_subDir)
	    FOREACH(_f ${_fileList})
		LIST(APPEND FILE_INSTALL_${fileType}_LIST 
		    "${_subDir}/${_f}")
	    ENDFOREACH(_f ${_fileList})
	ELSE(_subDir)
	    LIST(APPEND FILE_INSTALL_${fileType}_LIST 
		"${_fileList}")
	ENDIF(_subDir)
    ENDFUNCTION(MANAGE_FILE_INSTALL fileType)

    FUNCTION(FIND_FILE_ERROR_HANDLING VAR)
	SET(_verboseLevel ${M_ERROR})
	SET(_errorMsg "")
	SET(_errorVar "")
	SET(_findFileArgList "")
	SET(_state "")
	FOREACH(_arg ${ARGN})
	    IF(_state STREQUAL "ERROR_MSG")
		SET(_errorMsg "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "ERROR_VAR")
		SET(_errorVar "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "VERBOSE_LEVEL")
		SET(_verboseLevel "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "FIND_FILE_ARGS")
		LIST(APPEND _findFileArgList "${_arg}")
	    ELSE(_state STREQUAL "ERROR_MSG")
		IF(_arg STREQUAL "ERROR_MSG")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "ERROR_VAR")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "VERBOSE_LEVEL")
		    SET(_state "${_arg}")
		ELSE(_arg STREQUAL "ERROR_MSG")
		    SET(_state "FIND_FILE_ARGS")
		    LIST(APPEND _findFileArgList "${_arg}")
		ENDIF(_arg STREQUAL "ERROR_MSG")
	    ENDIF(_state STREQUAL "ERROR_MSG")
	ENDFOREACH(_arg ${ARGN})

	FIND_FILE(${VAR} ${_findFileArgList})
	IF(${VAR} STREQUAL "${VAR}-NOTFOUND")
	    M_MSG(${_verboseLevel} "File ${_findFileArgList} is not found!${_errorMsg}")
	    IF (NOT _errorVar STREQUAL "")
		SET(${_errorVar} 1)
	    ENDIF(NOT _errorVar STREQUAL "")
	ENDIF(${VAR} STREQUAL "${VAR}-NOTFOUND")
    ENDFUNCTION(FIND_FILE_ERROR_HANDLING VAR)

    FUNCTION(FIND_PROGRAM_ERROR_HANDLING VAR)
	SET(_verboseLevel ${M_ERROR})
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
	    ELSEIF(_state STREQUAL "VERBOSE_LEVEL")
		SET(_verboseLevel "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "FIND_PROGRAM_ARGS")
		LIST(APPEND _findProgramArgList "${_arg}")
	    ELSE(_state STREQUAL "ERROR_MSG")
		IF(_arg STREQUAL "ERROR_MSG")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "ERROR_VAR")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "VERBOSE_LEVEL")
		    SET(_state "${_arg}")
		ELSE(_arg STREQUAL "ERROR_MSG")
		    SET(_state "FIND_PROGRAM_ARGS")
		    LIST(APPEND _findProgramArgList "${_arg}")
		ENDIF(_arg STREQUAL "ERROR_MSG")
	    ENDIF(_state STREQUAL "ERROR_MSG")
	ENDFOREACH(_arg ${ARGN})

	FIND_PROGRAM(${VAR} ${_findProgramArgList})
	IF(${VAR} STREQUAL "${VAR}-NOTFOUND")
	    M_MSG(${_verboseLevel} "Program ${_findProgramArgList} is not found!${_errorMsg}")
	    IF (NOT _errorVar STREQUAL "")
		SET(${_errorVar} 1)
	    ENDIF(NOT _errorVar STREQUAL "")
	ENDIF(${VAR} STREQUAL "${VAR}-NOTFOUND")
    ENDFUNCTION(FIND_PROGRAM_ERROR_HANDLING VAR)
    
ENDIF(NOT DEFINED _MANAGE_FILE_CMAKE_)

