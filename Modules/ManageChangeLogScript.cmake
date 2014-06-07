# - Script for manipulate ChangeLog
#
# Note that ChangeLog will be updated only when
# 1. "make changelog" is run, or
# 2. Before source archive being built.
#
MACRO(MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE)
    MESSAGE(
	"Manage ChangeLog script: This script is not recommend for end users
  cmake -Dcmd=update 
      -Dchangelog=<path/ChangeLog> 
      -Drelease=<path/RELEASE-NOTES.txt>
      -Dprj_info=<path/prj_info.cmake>
      [\"-D<var>=<value>\"]
      -P <CmakeModulePath>/ManageChangeLogScript.cmake
    Update the ChangeLog.

  cmake -Dcmd=extract_current
      -Drelease=<path/RELEASE-NOTES.txt>
      [\"-D<var>=<value>\"]
      -P <CmakeModulePath>/ManageChangeLogScript.cmake
    Extract current Changelog items from RELEASE-NOTES.txt

  cmake -Dcmd=extract_prev
      -Dver=<ver>
      -Dchangelog=<path/ChangeLog> 
      [\"-D<var>=<value>\"]
      -P <CmakeModulePath>/ManageChangeLogScript.cmake
    Extract prev Changelog items from ChangeLog.

	"
	)
ENDMACRO()

MACRO(EXTRACT_CURRENT_FROM_RELEASE strVar release)
    FILE(STRINGS "${release}" _releaseLines)

    SET(_changeItemSection 0)
    SET(_changeLogThis "")
    ## Parse release file
    FOREACH(_line ${_releaseLines})
	IF(_changeItemSection)
	    ### Append lines in change section
	    STRING_APPEND(_changeLogThis "${_line}" "\n")
	ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
	    ### Start the change section
	    SET(_changeItemSection 1)
	ENDIF()
    ENDFOREACH(_line ${_releaseLines})
    SET(${strVar} "${_changeLogThis}")
ENDMACRO()

MACRO(EXTRACT_CURRENT_FROM_RELEASE strVar release)
    IF("${release}" STREQUAL "")
	MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Drelease=RELEASE-NOTES.txt\"")
    ENDIF()
    IF(NOT EXISTS "${release}")
	M_MSG(${M_FATAL} "File not found:${release}")
    ENDIF()
    FILE(STRINGS "${release}" _releaseLines)

    SET(_changeItemSection 0)
    SET(_changeLogThis "")
    ## Parse release file
    FOREACH(_line ${_releaseLines})
	IF(_changeItemSection)
	    ### Append lines in change section
	    STRING_APPEND(_changeLogThis "${_line}" "\n")
	ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
	    ### Start the change section
	    SET(_changeItemSection 1)
	ENDIF()
    ENDFOREACH(_line ${_releaseLines})
    SET(${strVar} "${_changeLogThis}")
ENDMACRO()

MACRO(EXTRACT_PREV_FROM_CHANGELOG strVar ver changeLogFile)
    IF("${ver}" STREQUAL "")
	MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "EXTRACT_PREV_FROM_CHANGELOG: Requires \"ver\"")
    ENDIF()
    IF("${changeLogFile}" STREQUAL "")
	MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Dchangelog=ChangeLog\"")
    ENDIF()
    IF(NOT EXISTS "${changeLogFile}")
	M_MSG(${M_FATAL} "File not found:${changeLogFile}")
    ENDIF()

    SET(_this "")
    SET(_prev "")
    SET(_isThis 0)
    SET(_isPrev 0)
    EXECUTE_PROCESS(COMMAND cat "${changeLogFile}"
	OUTPUT_VARIABLE _changeLogFileBuf
	OUTPUT_STRIP_TRAILING_WHITESPACE)

    STRING_SPLIT(_lines "\n" "${_changeLogFileBuf}" ALLOW_EMPTY)

    ## List should not ingore empty elements 
    CMAKE_POLICY(SET CMP0007 NEW)
    LIST(LENGTH _lines _lineCount)
    MATH(EXPR _lineCount ${_lineCount}-1)
    FOREACH(_i RANGE ${_lineCount})
	LIST(GET _lines ${_i} _line)
	STRING(REGEX MATCH "^\\* [A-Za-z]+ [A-Za-z]+ [0-9]+ [0-9]+ .*<.+> - (.*)$" _match  "${_line}")
	IF("${_match}" STREQUAL "")
	    # Not a version line
	    IF(_isThis)
		STRING_APPEND(_this "${_line}" "\n")
	    ELSEIF(_isPrev)
		STRING_APPEND(_prev "${_line}" "\n")
	    ELSE(_isThis)
		M_MSG(${M_ERROR} "ChangeLog: Cannot distinguish version for line :${_line}")
	    ENDIF(_isThis)
	ELSE("${_match}" STREQUAL "")
	    # Is a version line
	    SET(_cV "${CMAKE_MATCH_1}")
	    IF("${_cV}" STREQUAL "${ver}")
		SET(_isThis 1)
		SET(_isPrev 0)
	    ELSE("${_cV}" STREQUAL "${ver}")
		SET(_isThis 0)
		SET(_isPrev 1)
		STRING_APPEND(_prev "${_line}" "\n")
	    ENDIF("${_cV}" STREQUAL "${ver}")
	ENDIF("${_match}" STREQUAL "")
    ENDFOREACH(_i RANGE _lineCount)
    SET(${strVar} "${_prev}")
ENDMACRO()

MACRO(CHANGELOG_UPDATE prj_info release changelog)
    PRJ_INFO_CMAKE_READ("${prj_info}")

    EXTRACT_CURRENT_FROM_RELEASE(currentStr "${release}")
    EXTRACT_PREV_FROM_CHANGELOG(prevStr "${PRJ_VER}" "${changelog}")
    FILE(WRITE "${changelog}" "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}\n")
    FILE(APPEND "${changelog}" "${currentStr}\n\n")
    FILE(APPEND "${changelog}" "${prevStr}")
ENDMACRO()

SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
SET(CMAKE_FEDORA_ADDITIONAL_SCRIPT_PATH ${CMAKE_SOURCE_DIR}/scripts ${CMAKE_SOURCE_DIR}/cmake-fedora/scripts)

LIST(APPEND CMAKE_MODULE_PATH 
    ${CMAKE_CURRENT_SOURCE_DIR}/Modules ${CMAKE_SOURCE_DIR}/Modules
    ${CMAKE_SOURCE_DIR}/cmake-fedora/Modules 
    ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR} )

INCLUDE(ManageMessage RESULT_VARIABLE MANAGE_MODULE_PATH)
IF(MANAGE_MODULE_PATH STREQUAL "NOTFOUND")
    MESSAGE(FATAL_ERROR "ManageMessage.cmake cannot be found in ${CMAKE_MODULE_PATH}")
ENDIF()
INCLUDE(ManageString)
INCLUDE(ManageVariable)
INCLUDE(DateTimeFormat)
INCLUDE(ManageVersion)
IF(NOT DEFINED cmd)
    MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE()
ELSE()
    IF("${cmd}" STREQUAL "update")
	CHANGELOG_UPDATE(${prj_info} ${release} ${changelog})
    ELSEIF("${cmd}" STREQUAL "extract_current")
	EXTRACT_CURRENT_FROM_RELEASE(outVar ${release})
	M_OUT("${outVar}")
    ELSEIF("${cmd}" STREQUAL "extract_prev")
	IF("${ver}" STREQUAL "")
	    MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE()
	    M_MSG(${M_FATAL} "Requires \"-Dver=ver\"")
	ENDIF()
	EXTRACT_PREV_FROM_CHANGELOG(outVar ${ver} ${changelog})
	M_OUT("${outVar}")
    ELSE()
	MANAGE_CHANGELOG_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
    ENDIF()
ENDIF()

