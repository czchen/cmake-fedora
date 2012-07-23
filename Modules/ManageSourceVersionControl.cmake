# - Module for manipulate source version control systems.
# This module provides an universal interface for supported
# source version control systems, namely:
# Git, Mercurial and SVN.
#
# Following targets are defined for each source version control (in Git terminology):
#   - tag: Tag the working tree with PRJ_VER and CHANGE_SUMMARY.
#     This target also does:
#     1. Ensure there is nothing uncommitted.
#     2. Push the commits and tags to server
#   - tag_pre: Targets that 'tag' depends on.
#     So you can push some check before the tag.
#   - after_release_commit:
#     This target does some post release chores, such as
#     updating ChangeLog.prev and RPM-ChangeLog.prev, then push them to server.
#
# Following variables are defined for each source version control:
#   - MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE:
#     The file that would be touched after target tag is completed.
#
#

IF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
    SET(_MANAGE_SOURCE_VERSION_CONTROL_CMAKE_ "DEFINED")
    SET(_after_release_message "After released ${PRJ_VER}")
    INCLUDE(ManageTarget)
    INCLUDE(ManageString)
    STRING_ESCAPE_SEMICOLON(_change_summary_escaped "${CHANGE_SUMMARY}")

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)
	ADD_CUSTOM_TARGET(tag_pre
	    COMMENT "Pre-tagging check"
	    )

	ADD_CUSTOM_COMMAND(TARGET after_release_commit PRE_LINK
	    COMMAND make changelog_prev_update
	    )

	IF(TARGET rpm_changelog_prev_update)
	    ADD_CUSTOM_COMMAND(TARGET after_release_commit PRE_LINK
		COMMAND make rpm_changelog_prev_update
		)
	ENDIF(TARGET rpm_changelog_prev_update)
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_SOURCE_DIR}/.git/refs/tags/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File")

	ADD_CUSTOM_TARGET(after_release_commit
	    COMMAND git commit -a -m "${_after_release_message}"
	    COMMAND git push
	    COMMENT "After released ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET_COMMAND(tag OUTPUT ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    ${_makeTargets}
	    COMMAND make tag_pre
	    COMMAND git commit --short -uno > "${CMAKE_FEDORA_TMP_DIR}/git-status" || echo "Is source committed?"
	    COMMAND test ! -s "${CMAKE_FEDORA_TMP_DIR}/git-status"
	    COMMAND git tag -a -m "${_change_summary_escaped}" "${PRJ_VER}" HEAD
	    ${_depends}
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_HG)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_FEDORA_TEMP_DIR}/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File")

	ADD_CUSTOM_TARGET(after_release_commit
	    COMMAND hg commit -m "${_after_release_message}"
	    COMMAND hg push
	    COMMENT "After released ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND make tag_pre
	    COMMAND hg tag -m "${_change_summary_escaped}" "${PRJ_VER}"
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_HG)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_SVN)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_FEDORA_TEMP_DIR}/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File")

	ADD_CUSTOM_TARGET(after_release_commit
	    COMMAND svn commit -m "${_after_release_message}"
	    COMMENT "After released ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND make tag_pre
	    COMMAND svn copy "${SOURCE_BASE_URL}/trunk" "${SOURCE_BASE_URL}/tags/${PRJ_VER}" -m "${_change_summary_escaped}"
	    COMMAND cmake -E touch ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_SVN)

ENDIF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)

