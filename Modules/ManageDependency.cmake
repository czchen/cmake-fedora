# - Dependency Management Module
# This module handle dependencies by using pkg-config and/or
# search the executable.
# 
# Included Modules:
#  - ManageFile
#  - ManageVariable
#
# Defines following functions:
#   MANAGE_DEPENDENCY(<listVar> <var> [VER <ver> [EXACT]] [REQUIRED] 
#     [PROGRAM_NAMES <name1> ...] [PKG_CONFIG <pkgConfigName>]
#     [FEDORA_NAME <fedoraPkgName>] [DEVEL]
#     )
#     - Add a new dependency to a list. 
#       The dependency will also be searched.
#       If found, ${var}_FOUND is set as 1.
#       If not found:
#         + If REQUIRED is specified: a M_ERROR message will be printed. #	    + If REQUIRED is not specified: a M_OFF message will be printed.
#       * Parameters:
#         + listVar: List variable store a kind of dependencies.
#           Recognized lists:
#           - BUILD_REQUIRES: Dependencies in build stage
#           - REQUIRES:       Dependencies for runtime
#           - REQUIRES_PRE:   Dependencies before the package install
#           - REQUIRES_PREUN: Dependencies before the package uninstall
#           - REQUIRES_POST:  Dependencies after the package install
#           - REQUIRES_POSTUN:Dependencies after the package uninstall
#         + var: Main variable. Uppercase variable name is recommended,
#           (e.g. GETTEXT)
#         + VER ver [EXACT]: Minimum version.
#           Specify the exact version by providing "EXACT".
#         + REQUIRED: The dependency is required at build time.
#           If specified, this dependency will be searched:
#             - if found, ${var}_FOUND is set as 1.
#	      - if not found, an error message will be printed and
#	        build stop at build stage.
#	    If not specified, this 
#         + PROGRAM_NAMES name1 ...: Executable to be found.
#           name2 and others are aliases to name1.
#           If found, ${var}_EXECUTABLE is defined as the full path 
#           to the executable; if not found; the whole dependency is
#           deemed as not found.
#         + PKG_CONFIG pkgConfigName: Name of the pkg-config file
#           exclude the directory and .pc. e.g. "gtk+-2.0"
#         + FEDORA_NAME fedoraPkgName: Package name in Fedora. 
#           If not specified, use the lower case of ${var}.
#           Note that '-devel' should be omitted here.
#         + DEVEL: devel package is used. It will append '-devel'
#           to fedoraPkgName
#
IF(DEFINED _MANAGE_DEPENDENCY_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_DEPENDENCY_CMAKE_)
SET(_MANAGE_DEPENDENCY_CMAKE_ "DEFINED")
INCLUDE(ManageFile)
INCLUDE(ManageVariable)

## This need to be here, otherwise the variable won't be available
## the 2nd time called.
FIND_PACKAGE(PkgConfig)

## This is declared as function, because 
## macro does not play nice if listVar is required in different
## source dir.
FUNCTION(MANAGE_DEPENDENCY listVar var)
    SET(_validOptions "VER" "EXACT" "REQUIRED" 
	"PROGRAM_NAMES" "PKG_CONFIG" "FEDORA_NAME" "DEVEL")
    VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
    SET(_dirty 0)

    IF(DEFINED _opt_REQUIRED)
	SET(_verbose "${M_ERROR}")
	SET(_required "REQUIRED")
        SET(_progNotFoundMsg 
	    "Program names ${_opt_PROGRAM_NAMES} not found, install ${var}")
    ELSE(DEFINED _opt_REQUIRED)
	SET(_verbose "${M_OFF}")
	SET(_required "")
	SET(_progNotFoundMsg 
	    "Program names ${_opt_PROGRAM_NAMES} not found, ${var} support disabled")
    ENDIF(DEFINED _opt_REQUIRED)
    IF(_opt_VER)
	IF(DEFINED _opt_EXACT)
	    SET(_rel "=")
	    SET(_exact "EXACT")
	ELSE(DEFINED _opt_EXACT)
	    SET(_rel ">=")
	    SET(_exact "")
	ENDIF(DEFINED _opt_EXACT)
    ENDIF(_opt_VER)

    IF(_opt_PROGRAM_NAMES)
	M_MSG(${M_INFO2} "ManageDependency: finding program names ${_opt_PROGRAM_NAMES}")
	FIND_PROGRAM_ERROR_HANDLING(${var}_EXECUTABLE
	    ERROR_VAR _dirty
	    ERROR_MSG "${_progNotFoundMsg}"
	    VERBOSE_LEVEL "${_verbose}"
	    FIND_ARGS NAMES "${_opt_PROGRAM_NAMES}"
	    )
	MARK_AS_ADVANCED(${var}_EXECUTABLE)
    ENDIF(_opt_PROGRAM_NAMES)

    IF(_opt_FEDORA_NAME)
	SET(_name "${_opt_FEDORA_NAME}")
    ELSE(_opt_FEDORA_NAME)
	STRING(TOLOWER "${var}" _name)
    ENDIF(_opt_FEDORA_NAME)

    IF(DEFINED _opt_DEVEL)
	SET(_name "${_name}-devel")
    ENDIF(DEFINED _opt_DEVEL)
    IF("${_opt_VER}" STREQUAL "")
	SET(_newDep  "${_name}")
    ELSE("${_opt_VER}" STREQUAL "")
	SET(_newDep  "${_name} ${_rel} ${_opt_VER}")
    ENDIF("${_opt_VER}" STREQUAL "")
    IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
	SET(_rpm_missing 0)
	FIND_PROGRAM_ERROR_HANDLING(RPM_CMD
	    ERROR_VAR _rpm_missing
	    ERROR_MSG "Program rpm not found, dependency check disabled."
	    VERBOSE_LEVEL ${M_OFF}
	    FIND_ARGS "rpm"
	    )
	IF(NOT _rpm_missing)
	    EXECUTE_PROCESS(COMMAND ${RPM_CMD} -q ${_name}
		RESULT_VARIABLE _rpm_ret
		OUTPUT_QUIET
		ERROR_QUIET
		)
	    IF(_rpm_ret)
		## Dependency not found
		M_MSG(${_verbose} "RPM ${_name} is not installed")
		SET(_dirty 1)
	    ENDIF(_rpm_ret)
	ENDIF(NOT _rpm_missing)
    ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)

    IF(_opt_PKG_CONFIG)
	IF(PKG_CONFIG_EXECUTABLE)
	    LIST(FIND ${listVar} "pkgconfig" _index)
	    IF(_index EQUAL -1)
		LIST(APPEND ${listVar} "pkgconfig")
	    ENDIF(_index EQUAL -1)
	ELSE(PKG_CONFIG_EXECUTABLE)
	    M_MSG(${M_ERROR} "pkgconfig is required with ${var}")
	ENDIF(PKG_CONFIG_EXECUTABLE)
	PKG_CHECK_MODULES(${var} ${_required}
	    "${_opt_PKG_CONFIG}${_rel}${_opt_VER}")
	EXECUTE_PROCESS(COMMAND ${PKG_CONFIG_EXECUTABLE}
	    --print-variables "${_opt_PKG_CONFIG}"
	    OUTPUT_VARIABLE _variables
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    RESULT_VARIABLE _pkgconfig_ret
	    )
	IF(NOT _pkgconfig_ret)
	    STRING_SPLIT(${var}_VARIABLES "\n" "${_variables}")
	    FOREACH(_v ${${var}_VARIABLES})
		STRING(TOUPPER "${_v}" _u)
		EXECUTE_PROCESS(COMMAND ${PKG_CONFIG_EXECUTABLE}
		    --variable "${_v}" "${_opt_PKG_CONFIG}"
		    OUTPUT_VARIABLE ${var}_${_u}
		    OUTPUT_STRIP_TRAILING_WHITESPACE
		    )
		SET(${var}_${_u} "${${var}_${_u}}" 
		    CACHE INTERNAL "pkgconfig ${var}_${u}")
		MARK_AS_ADVANCED(${var}_${_u})
		M_MSG(${M_INFO1} "${var}_${_u}=${${var}_${_u}}")
	    ENDFOREACH(_v)
	ENDIF(NOT _pkgconfig_ret)
    ENDIF(_opt_PKG_CONFIG)

    ## Insert when it's not duplicated
    IF(NOT _dirty)
	SET(${var}_FOUND "1" CACHE INTERNAL "Found ${var}")
    ENDIF(NOT _dirty)
    LIST(FIND ${listVar} "${_newDep}" _index)
    IF(_index EQUAL -1)
	LIST(APPEND ${listVar} "${_newDep}")
	SET(${listVar} "${${listVar}}" PARENT_SCOPE)
    ENDIF(_index EQUAL -1)
ENDFUNCTION(MANAGE_DEPENDENCY)

