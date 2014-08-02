# - Manage Version and project information (prj_info.cmake)
#
# Included Modules:
#   - DateTimeFormat
#   - ManageString
#   - ManageVariable
#
# Set cache for following variables:
#   - PRJ_INFO_CMAKE_FILE: 
#
# Defines following functions:
#   RELEASE_NOTES_READ_FILE([<release_file>])
#   - Load release file information.
#     * Parameters:
#       + release_file: (Optional) release file to be read.
#         This file should contain following definition:
#         - PRJ_VER: Release version.
#         - SUMMARY: Summary of the release. Will be output as CHANGE_SUMMARY.
#         - Section [Changes]:
#           Changes of this release list below the section tag.
#         Default:${CMAKE_SOURCE_DIR}/RELEASE-NOTES.txt
#     * Values to cached:
#       + PRJ_VER: Version.
#       + CHANGE_SUMMARY: Summary of changes.
#       + RELEASE_NOTES_FILE: The loaded release file.
#     * Compile flags defined:
#       + PRJ_VER: Project version.
#
#   PRJ_INFO_CMAKE_WRITE([<prj_info_file>])
#   - Write the project infomation to prj_info.cmake/
#     * Parameters:
#       + prj_info_file: (Optional) File name to write project information.
#         Default: ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake
#     * Values to cached:
#       + PRJ_INFO_CMAKE: Path to prj_info.cmake
#         Default: ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake
#
#   PRJ_INFO_CMAKE_APPEND(<var> [<prj_info_file>])
#   - Append  var to prj_info.cmake.
#     * Parameters:
#       + var: Variable to be append to prj_info.cmake.
#       + prj_info_file: (Optional) File name to be appended to.
#         Default: ${PRJ_INFO_CMAKE}, otherwise ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake.
#     * Values to cached:
#       + PRJ_INFO_CMAKE: Path to prj_info.cmake
#         Default: ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake
#
# Defines following macros:
#   PRJ_INFO_CMAKE_READ(<prj_info_file>)
#   - Read prj_info.cmake and get the info of projects.
#     This macro is meant to be run by cmake script.
#     Arguments:
#     + prj_info_file: Location of prj_info.cmake
#

IF(DEFINED _MANAGE_VERSION_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_VERSION_CMAKE_)
SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageVariable)

SET(PRJ_INFO_VARIABLE_LIST 
    PROJECT_NAME PRJ_VER PRJ_SUMMARY SUMMARY_TRANSLATIONS
    PRJ_DESCRIPTION DESCRIPTION_TRANSLATIONS 
    LICENSE PRJ_GROUP MAINTAINER AUTHORS VENDER
    BUILD_ARCH RPM_SPEC_URL RPM_SPEC_SOURCES
    )

FUNCTION(PRJ_INFO_CMAKE_WHICH var prj_info_file)
    IF("${prj_info_file}" STREQUAL "")
	IF("${PRJ_INFO_CMAKE}" STREQUAL "")
	    SET(PRJ_INFO_CMAKE "${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake" CACHE INTERNAL "prj_info.cmake")
	ENDIF()
	SET(${var} "${PRJ_INFO_CMAKE}" PARENT_SCOPE)
    ELSE()
	SET(${var} "${prj_info_file}" PARENT_SCOPE)
    ENDIF()
    
ENDFUNCTION(PRJ_INFO_CMAKE_WHICH)

FUNCTION(PRJ_INFO_CMAKE_APPEND var prj_info_file)
    PRJ_INFO_CMAKE_WHICH(outFile ${prj_info_file})
    IF(NOT "${${var}}" STREQUAL "")
	STRING_ESCAPE_BACKSLASH(_str "${${var}}")
	STRING_ESCAPE_DOLLAR(_str "${_str}")
	STRING_ESCAPE_QUOTE(_str "${_str}")
	FILE(APPEND ${outFile} "SET(${var} \"${_str}\")\n")
    ENDIF(NOT "${${var}}" STREQUAL "")
ENDFUNCTION(PRJ_INFO_CMAKE_APPEND)

MACRO(PRJ_INFO_CMAKE_READ prj_info_file)
    IF("${prj_info_file}" STREQUAL "")
	M_MSG(${M_EROR} "Requires prj_info.cmake")
    ENDIF()
    INCLUDE(${prj_info_file} RESULT_VARIABLE prjInfoPath)
    IF("${prjInfoPath}" STREQUAL "NOTFOUND")
	M_MSG(${M_ERROR} "Failed to read ${prj_info_file}")
    ENDIF()
ENDMACRO(PRJ_INFO_CMAKE_READ)

FUNCTION(PRJ_INFO_CMAKE_WRITE prj_info_file)
    PRJ_INFO_CMAKE_WHICH(outFile ${prj_info_file})
    FILE(REMOVE "${outFile}")
    FOREACH(_v ${PRJ_INFO_VARIABLE_LIST})
	PRJ_INFO_CMAKE_APPEND(${_v} "${outFile}")
    ENDFOREACH(_v)
ENDFUNCTION(PRJ_INFO_CMAKE_WRITE prj_info_file)

FUNCTION(RELEASE_NOTES_READ_FILE)
    INCLUDE(ManageString)
    FOREACH(_arg ${ARGN})
	IF(EXISTS ${_arg})
	    SET(RELEASE_NOTES_FILE ${_arg} CACHE FILEPATH "Release File")
	ENDIF(EXISTS ${_arg})
    ENDFOREACH(_arg ${ARGN})

    IF(NOT RELEASE_NOTES_FILE)
	SET(RELEASE_NOTES_FILE "${CMAKE_SOURCE_DIR}/RELEASE-NOTES.txt" CACHE FILEPATH "Release Notes")
    ENDIF(NOT RELEASE_NOTES_FILE)

    FILE(STRINGS "${RELEASE_NOTES_FILE}" _release_lines)

    SET(_changeItemSection 0)
    SET(CHANGELOG_ITEMS "")
    ## Parse release file
    FOREACH(_line ${_release_lines})
	IF(_changeItemSection)
	    ### Append lines in change section
	    STRING_APPEND(CHANGELOG_ITEMS "${_line}" "\n")
	ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
	    ### Start the change section
	    SET(_changeItemSection 1)
	ELSE(_changeItemSection)
	    ### Variable Setting section
	    SETTING_STRING_GET_VARIABLE(var value "${_line}")
	    #MESSAGE("var=${var} value=${value}")
	    IF(NOT var MATCHES "#")
		IF(var STREQUAL "PRJ_VER")
		    SET_COMPILE_ENV(${var} "${value}" CACHE STRING "Project Version" FORCE)
		ELSEIF(var STREQUAL "SUMMARY")
		    SET(CHANGE_SUMMARY "${value}" CACHE STRING "Change Summary" FORCE)
		ELSE(var STREQUAL "PRJ_VER")
		    SET(${var} "${value}" CACHE STRING "${var}" FORCE)
		ENDIF(var STREQUAL "PRJ_VER")
	    ENDIF(NOT var MATCHES "#")
	ENDIF(_changeItemSection)
    ENDFOREACH(_line ${_release_lines})

    SET(PRJ_INFO_CMAKE_FILE "${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake"
	CACHE FILEPATH "prj_info.cmake")

    PRJ_INFO_CMAKE_WRITE(${PRJ_INFO_CMAKE_FILE})
ENDFUNCTION(RELEASE_NOTES_READ_FILE)

