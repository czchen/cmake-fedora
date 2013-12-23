# - Modules for manipulate version and ChangeLog
#
# Includes:
#   ManageVariable
#   DateTimeFormat
#
# Included by:
#   PackSource
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
#     This macro outputs following files:
#     + ChangeLog: Log of changes.
#       Depends on ChangeLog.prev and releaseFile.
#     This macro sets following variables:
#     + PRJ_VER: Release version.
#     + CHANGE_SUMMARY: Summary of changes.
#     + CHANGELOG_ITEMS: Lines below the [Changes] tag.
#     + RELEASE_NOTES_FILE: The loaded release file.
#     + PRJ_DOC_DIR: Documentation for the project.
#       Default: ${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}
#
#

IF(NOT DEFINED _MANAGE_VERSION_CMAKE_)
    SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageVariable)

    SET(CHANGELOG_FILE "${CMAKE_SOURCE_DIR}/ChangeLog" CACHE FILEPATH
	"ChangeLog")
    SET(CHANGELOG_PREV_FILE "${CMAKE_SOURCE_DIR}/ChangeLog.prev" CACHE FILEPATH
	"ChangeLog.prev")

    ADD_CUSTOM_TARGET(changelog_prev_update
	COMMAND ${CMAKE_COMMAND} -E copy ${CHANGELOG_FILE} ${CHANGELOG_PREV_FILE}
	DEPENDS ${CHANGELOG_FILE}
	COMMENT "${CHANGELOG_FILE} are saving as ${CHANGELOG_PREV_FILE}"
	)

    MACRO(_MANAGE_CHANGELOG_UPDATE_MERGE_LINES ver writeVerContent changeLogFile)
	SET(_cV "")
	FOREACH(_line ${_changeLogFileBuf})
	    STRING(REGEX MATCH "^\\* [A-Za-z]+ [A-Za-z]+ [0-9]+ [0-9]+ .+ <.+> - (.*)$" _match  "${_line}")
	    IF(_match STREQUAL "")
		# Not a version line
		IF(NOT "${_cV}" STREQUAL "${ver}" OR writeVerContent)
		    ## Write to ChangeLog when
		    ### version not the same
		    ### or writeVerContent=1 (Nothing from ReleaseNote)
		    FILE(APPEND "${changeLogFile}" "${_line}\n")
		ENDIF(NOT "${_cV}" STREQUAL "${ver}" OR writeVerContent)
	    ELSE(_match STREQUAL "")
		# Is a version line
		SET(_cV "${CMAKE_MATCH_1}")
		IF(NOT "${_cV}" STREQUAL "${ver}")
		    FILE(APPEND "${changeLogFile}" "${_line}\n")
		ENDIF(NOT "${_cV}" STREQUAL "${ver}")
	    ENDIF(_match STREQUAL "")
	ENDFOREACH(_line ${_changeLogFileBuf})
    ENDMACRO(_MANAGE_CHANGELOG_UPDATE_MERGE_LINES ver writeVerContent changeLogFile)

    FUNCTION(MANAGE_CHANGELOG_UPDATE changeLogFile ver newChangeStr)
	SET(_changeLogFileBuf "")
	IF(EXISTS "${changeLogFile}")
	    FILE(STRINGS "${changeLogFile}" _changeLogFileBuf)
	ENDIF(EXISTS "${changeLogFile}")
	
	INCLUDE(DateTimeFormat)

	FILE(WRITE ${CHANGELOG_FILE} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}\n")
	IF (newChangeStr)
	    FILE(APPEND ${CHANGELOG_FILE} "${newChangeStr}\n\n")
	    _MANAGE_CHANGELOG_UPDATE_MERGE_LINES(${ver} 0 "${CHANGELOG_FILE}")
	ELSE(newChangeStr)
	    _MANAGE_CHANGELOG_UPDATE_MERGE_LINES(${ver} 1 "${CHANGELOG_FILE}")
	ENDIF(newChangeStr)
    ENDFUNCTION(MANAGE_CHANGELOG_UPDATE var changeLogFile ver newChangeStr)

    FUNCTION(RELEASE_NOTES_READ_FILE)
	INCLUDE(ManageString)
	SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")
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
	ENDFOREACH(_line ${_release_line})

	FILE(WRITE "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.this" "${CHANGELOG_ITEMS}")

	SET_COMPILE_ENV(PRJ_DOC_DIR "${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}"
	    CACHE PATH "Project docdir prefix" FORCE
	    )

	MANAGE_CHANGELOG_UPDATE(${CHANGELOG_FILE} ${PRJ_VER} "${CHANGELOG_ITEMS}")

	ADD_CUSTOM_COMMAND(OUTPUT ${CHANGELOG_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${RELEASE_NOTES_FILE}
	    COMMENT "Building ${CHANGELOG_FILE}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(changelog ALL
	    DEPENDS ${CHANGELOG_FILE}
	    VERBATIM
	    )

    ENDFUNCTION(RELEASE_NOTES_READ_FILE)
ENDIF(NOT DEFINED _MANAGE_VERSION_CMAKE_)

