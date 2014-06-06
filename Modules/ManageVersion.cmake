# - Modules for manipulate versions and prj_info.cmake
#
# Includes:
#   ManageVariable
#   DateTimeFormat
#
# Included by:
#   ManageArchive
#
# Defines following macros:
#   READ_PRJ_INFO_CMAKE(<prjInfoFile>)
#   - Load prj_info.cmake and get the info of projects.
#     This macro is meant to be run by cmake script.
#     Arguments:
#     + prjInfoFile: Location of prj_info.cmake
#
# Defines following functions:
#   RELEASE_NOTES_READ_FILE([releaseFile])
#   - Load release file information.
#     Arguments:
#     + releaseFile: (Optional) release file to be read.
#       This file should contain following definition:
#       - PRJ_VER: Release version.
#       - SUMMARY: Summary of the release. Will be output as CHANGE_SUMMARY.
#       - Section [Changes]:
#         Changes of this release list below the section tag.
#       Default:RELEASE-NOTES.txt
#     This macro writes following files:
#     + PRJ_INFO_CMAKE: ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake
#       Project information files to be included by scripts.
#
#     This macro sets following variables:
#     + PRJ_VER: Release version.
#     + CHANGE_SUMMARY: Summary of changes.
#     + RELEASE_NOTES_FILE: The loaded release file.
#     + PRJ_DOC_DIR: Documentation for the project.
#       Default: ${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}
#

IF(DEFINED _MANAGE_VERSION_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_VERSION_CMAKE_)
SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageVariable)

SET(PRJ_INFO_VARIABLE_LIST 
    PROJECT_NAME PRJ_VER PRJ_SUMMARY SUMMARY_TRANSLATION
    PRJ_DESCRIPTION LICENSE PRJ_GROUP MAINTAINER AUTHORS VENDER
    BUILD_ARCH RPM_SPEC_URL RPM_SPEC_SOURCES BUILD_REQUIRES REQUIRES
    )

MACRO(READ_PRJ_INFO_CMAKE prjInfoFile)
    IF("${prjInfoFile}" STREQUAL "")
	M_MSG(${M_EROR} "Requires prj_info.cmake")
    ENDIF()
    INCLUDE(${prjInfoFile} RESULT_VARIABLE prjInfoPath)
    IF("${prjInfoPath}" STREQUAL "NOTFOUND")
	M_MSG(${M_ERROR} "Failed to read ${prjInfoFile}")
    ENDIF()
ENDMACRO(READ_PRJ_INFO_CMAKE)

MACRO(APPEND_PRJ_INFO_CMAKE prjInfoFile var)
    FILE(APPEND ${prjInfoFile} "SET(${_v} \"${${_v}}\")\n")
ENDMACRO(APPEND_PRJ_INFO_CMAKE)

# Write Project info to prj_info.cmake
# So scripts like ManageChangeLogScript andManageRPMScript 
# can retrieve project information
MACRO(WRITE_PRJ_INFO_CMAKE prjInfoFile)
    FILE(REMOVE ${prjInfoFile})
    FOREACH(_v ${PRJ_INFO_VARIABLE_LIST})
	APPEND_PRJ_INFO_CMAKE("${prjInfoFile}" _v)
    ENDFOREACH(_v)
ENDMACRO(WRITE_PRJ_INFO_CMAKE prjInfoFile)

FUNCTION(RELEASE_NOTES_READ_FILE)
    INCLUDE(ManageString)
    FOREACH(_arg ${ARGN})
	IF(EXISTS ${_arg})
	    SET(RELEASE_NOTES_FILE ${_arg} CACHE FILEPATH "Release File")
	ENDIF(EXISTS ${_arg})
    ENDFOREACH(_arg ${ARGN})

    IF(NOT RELEASE_NOTES_FILE)
	SET(RELEASE_NOTES_FILE "RELEASE-NOTES.txt" CACHE FILEPATH "Release Notes")
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

    SET(PRJ_INFO_CMAKE "${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake"
	CACHE FILEPATH "prj_info.cmake")

    WRITE_PRJ_INFO_CMAKE(${PRJ_INFO_CMAKE})
ENDFUNCTION(RELEASE_NOTES_READ_FILE)

