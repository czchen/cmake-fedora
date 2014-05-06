# - Cmake Fedora Script
# Scripts to be invoked in command line
#

MACRO(CMAKE_FEDORA_SCRIPT_PRINT_USAGE)
    MESSAGE(
"   cmake -Dcmd=find_file|find_program -Dnames=\"<name1;name2>\"
           [-Dpaths=\"path1;path2\"]
           [-Derror_msg=msg]
           [-Dverbose_level=verboseLevel]
	   [-Dno_default_path=1]
	   -P <CmakeModulePath>/CmakeFedoraScript.cmake
     Find a file or program with name1 or name2, 
     with proper error handling.
     Options:
       -Dpaths: Pathes that files might be located.
       -Derror_msg: Error message to be shown if not-found.
       -Dverbose_level: Verbose level for not-found message.
          1: Critical (The 'not found' message is shown as critical)
	  2: Error (The 'not found' message is shown as error)
	  3: Warning (The 'not found' message is shown as error)
	  4: Off (The 'not found' message is shown as off, 
	     that is, turn off certain functionality).
	  5: Info1
	  6: Info2
	  7: Info3
	  Default: Error
       -Dno_default_path: CMake default paths will not be search.
          Useful if you only want to search the file list in -Dpaths.
	   
   cmake -Dcmd=manage_file_cache -Drun=\"<command arg1 ...>\"
         -Dcache_file=<cacheFileWithoutDirectory>
         [-Dexpiry_seconds=seconds]
	 [-Dcache_dir=dir]
	 -P <CmakeModulePath>/CmakeFedoraScript.cmake
     Output from either cache file or run command.
     Command is run when 1) cache expired or 2) no cache.
     Cache will be update after run command.

   cmake -Dcmd=get_variable -Dvar=\"<varName>\"
         -P <CmakeModulePath>/CmakeFedoraScript.cmake
     Get variable value from cmake-fedora.conf.

")
ENDMACRO(CMAKE_FEDORA_SCRIPT_PRINT_USAGE)

MACRO(FIND_FILE_OR_PROGRAM)
    SET(_args "")
    IF(error_msg)
	LIST(APPEND _args "ERROR_MSG" "${error_msg}")
    ENDIF(error_msg)

    SET(_verboseLevel "${M_ERROR}")
    IF(DEFINED verbose_level)
	SET(_verboseLevel "${verbose_level}")
    ELSE(DEFINED verbose_level)
	SET(_verboseLevel "${M_ERROR}")
    ENDIF(DEFINED verbose_level)
    LIST(APPEND _args "VERBOSE_LEVEL" "${_verboseLevel}")

    IF(DEFINED no_default_path)
	LIST(APPEND _args "NO_DEFAULT_PATH")
    ENDIF(DEFINED no_default_path)

    LIST(APPEND _args "FIND_ARGS" "NAMES" "${names}")

    IF(paths)
	LIST(APPEND _args "PATHS" "${paths}")
    ENDIF(paths)

    IF(cmd STREQUAL "find_file")
	FIND_FILE_ERROR_HANDLING(_var ${_args})
    ELSEIF(cmd STREQUAL "find_program")
	FIND_PROGRAM_ERROR_HANDLING(_var ${_args})
    ENDIF(cmd STREQUAL "find_file")
    IF(_var STREQUAL "_var-NOTFOUND")
	M_MSG(${_verboseLevel} "${cmd}: '${names}' not found!")
    ELSE(_var STREQUAL "_var-NOTFOUND")
	M_OUT("${_var}")
    ENDIF(_var STREQUAL "_var-NOTFOUND")
    UNSET(_verboseLevel CACHE)
ENDMACRO(FIND_FILE_OR_PROGRAM)

FUNCTION(MANAGE_FILE_CACHE_SCRIPT)
    IF(NOT run)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Drun=<executable>")
    ENDIF(NOT run)
    IF(NOT cache_file)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dcache_file=<filenameWithoutDir>")
    ENDIF(NOT cache_file)

    SET(_opts "")
    IF(expiry_seconds)
	LIST(APPEND _opts EXPIRY_SECONDS "${expiry_seconds}")
    ENDIF(expiry_seconds)

    IF(cache_dir) 
	LIST(APPEND _opts CACHE_DIR "${cache_dir}")
    ENDIF(cache_dir) 

    MANAGE_FILE_CACHE(v ${cache_file} ${_opts} COMMAND sh -c "${run}")
    M_OUT("${v}")
ENDFUNCTION(MANAGE_FILE_CACHE_SCRIPT)

FUNCTION(CMAKE_FEDORA_GET_VARIABLE_SCRIPT)
    IF(NOT var)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dvar=<variable>")
    ENDIF(NOT var)
    CMAKE_FEDORA_CONF_GET_ALL_VARIABLES()
    M_OUT("${${var}}")
ENDFUNCTION(CMAKE_FEDORA_GET_VARIABLE_SCRIPT)

LIST(APPEND CMAKE_MODULE_PATH 
    ${CMAKE_CURRENT_SOURCE_DIR}/Modules ${CMAKE_SOURCE_DIR}/Modules
    ${CMAKE_SOURCE_DIR}/cmake-fedora/Modules 
    ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR} )

INCLUDE(ManageFile RESULT_VARIABLE MANAGE_MODULE_PATH)
IF(NOT MANAGE_MODULE_PATH)
    M_MSG(${M_FATAL} "ManageFile.cmake fedora cannot be found in ${CMAKE_MODULE_PATH}")
ENDIF(NOT MANAGE_MODULE_PATH)
INCLUDE(ManageMessage)

IF(cmd STREQUAL "find_file" OR cmd STREQUAL "find_program")
    IF(NOT names)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dnames=\"<name1;name2>\"")
    ENDIF(NOT names)
    FIND_FILE_OR_PROGRAM()
ELSEIF(cmd STREQUAL "manage_file_cache")
    MANAGE_FILE_CACHE_SCRIPT()
ELSEIF(cmd STREQUAL "get_variable")
    CMAKE_FEDORA_GET_VARIABLE_SCRIPT()
ELSE(cmd STREQUAL "find_file" OR cmd STREQUAL "find_program")
    CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
    M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
ENDIF(cmd STREQUAL "find_file" OR cmd STREQUAL "find_program")


