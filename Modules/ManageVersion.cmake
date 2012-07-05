# - Targets and macros that related to versioning.
#
# Includes:
#   ManageVariable
#   DateTimeFormat
#
# Included by:
#   PackSource
#
# Defines following macros:
#   LOAD_RELEASE_FILE(releaseFile)
#   - Load release file information.
#     Arguments:
#     + releaseFile: release file to be read.
#       This file should contain following definition:
#       + PRJ_VER: Release version.
#       + SUMMARY: Summary of the release. Will be output as CHANGE_SUMMARY.
#          and a [Changes] section tag, below which listed the change in the
#          release.
#     This macro reads or define following variables:
#     + RELEASE_TARGETS: Sequence of release targets.
#     This macro outputs following files:
#     + ChangeLog: Log of changes.
#       Depends on ChangeLog.prev and releaseFile.
#     This macro defines following targets:
#     + version_check: Check whether the current PRJ_VER value match
#       the PRJ_VER declared in releaseFile.
#     This macro sets following variables:
#     + PRJ_VER: Release version.
#     + CHANGE_SUMMARY: Summary of changes.
#     + CHANGELOG_ITEMS: Lines below the [Changes] tag.
#     + RELEASE_FILE: The loaded release file.
#     + PRJ_DOC_DIR: Documentation for the project.
#       Default: ${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}
#

IF(NOT DEFINED _MANAGE_VERSION_CMAKE_)
    SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageVariable)

    FUNCTION(LOAD_RELEASE_FILE releaseFile)
	COMMAND_OUTPUT_TO_VARIABLE(_grep_line grep -F "[Changes]" -n -m 1 ${releaseFile})

	SET(RELEASE_FILE ${releaseFile} CACHE FILEPATH "Release File")
	FILE(STRINGS ${RELEASE_FILE} _release_lines)

	SET(_changeItemSection 0)
	SET(_changeItems "")
	## Parse release file
	FOREACH(_line ${_release_lines})
	    IF(_changeItemSection)
		### Append lines in change section
		SET(_changeItems  "${_changeItems}\n${_line}")
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

	IF(_changeSection EQUAL 0)
	    MESSAGE(FATAL_ERROR "${RELEASE_FILE} does not have a [Changes] tag!")
	ELSEIF("${_changeItems}" STREQUAL "")
	    MESSAGE(FATAL_ERROR "${RELEASE_FILE} does not have ChangeLog items!")
	ENDIF(_changeSection EQUAL 0)

	SET(CHANGELOG_ITEMS "${_changeItems}")

	SET_COMPILE_ENV(PRJ_DOC_DIR "${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}"
	    CACHE PATH "Project docdir prefix" FORCE)

	INCLUDE(DateTimeFormat)

	SET(CMAKE_CACHE_TXT "CMakeCache.txt")
	# PRJ_VER won't be updated until the removal of CMAKE_CACHE_TXT
	# and execution of cmake .
	SET(_version_check_cmd grep -e 'PRJ_VER=' ${RELEASE_FILE} |  tr -d '\\r\\n' | sed -e s/PRJ_VER=//)
	ADD_CUSTOM_TARGET(version_check
	    COMMAND ${CMAKE_COMMAND} -E echo "PRJ_VER=${PRJ_VER}"
	    COMMAND ${CMAKE_COMMAND} -E echo "Release file="`eval \"${_version_check_cmd}\"`
	    COMMAND test \"`${_version_check_cmd}`\" = \"\" -o \"`${_version_check_cmd}`\" = "${PRJ_VER}"
	   || echo Inconsistent version detected. Fixing..
	   && ${CMAKE_COMMAND} -E remove -f ${CMAKE_CACHE_TXT}
	   && ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	   )

        FILE(WRITE "${CMAKE_BINARY_DIR}/ChangeLog" "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}")
        FILE(APPEND "${CMAKE_BINARY_DIR}/ChangeLog" "${CHANGELOG_ITEMS}\n\n")
	FILE(READ "ChangeLog.prev" CHANGELOG_PREV)
	FILE(APPEND "${CMAKE_BINARY_DIR}/ChangeLog" "${CHANGELOG_PREV}")

	ADD_CUSTOM_COMMAND(OUTPUT ChangeLog  ${CMAKE_CACHE_TXT}
	    COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_CACHE_TXT}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${releaseFile} ChangeLog.prev
	    COMMENT "ChangeLog or ${CMAKE_CACHE_TXT} is older than ${releaseFile}. Rebuilding"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(changelog ALL
	    DEPENDS ChangeLog ${CMAKE_CACHE_TXT}
	    )

	#ADD_CUSTOM_COMMAND(OUTPUT ChangeLog
	#    COMMAND ${CMAKE_COMMAND} -E echo "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}" > ChangeLog
	#    COMMAND cat ${releaseFile}_NO_PACK_CHANGELOG_ITEM  >> ChangeLog
	#    COMMAND echo -e "\\n" >> ChangeLog
	#    COMMAND cat ChangeLog.prev >> ChangeLog
	#    DEPENDS ${CMAKE_SOURCE_DIR}/${releaseFile} ${CMAKE_SOURCE_DIR}/ChangeLog.prev
	#    COMMENT "Building ChangeLog"
	#    VERBATIM
	#    )

	# By this time,
    ENDFUNCTION(LOAD_RELEASE_FILE releaseFile)

ENDIF(NOT DEFINED _MANAGE_VERSION_CMAKE_)

