# - Module for manipulate source version control systems.
# This module provides an universal interface for supported
# source version control systems, namely:
# Git, Mercurial and SVN.
#
# Following targets are defined (in Git terminology):
#   - tag: Tag the working tree with PRJ_VER and CHANGE_SUMMARY.
#     This target also does:
#     1. Ensure there is nothing uncommitted.
#     2. Push the commits and tags to server
#   - after_release_commit:
#     This target does some post release chores, such as
#     updating ChangeLog.prev and RPM-ChangeLog.prev, then push them to server.
#
# Following variables are defined:
#   - MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE:
#     The file that would be touched after target tag is completed.
#
# Included by:
#    ManageMaintainerTargets
#    ManageReleaseOnFedora
#

IF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
    SET(_MANAGE_SOURCE_VERSION_CONTROL_CMAKE_ "DEFINED")
    SET(_after_release_message "After version ${PRJ_VER}")
    INCLUDE(ManageTarget)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)
	ADD_CUSTOM_COMMAND(TARGET after_release_commit PRELINK
	    COMMAND make changelog_prev_update
	    )
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_SOURCE_DIR}/.git/refs/tags/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File")

	ADD_CUSTOM_TARGET(after_release_commit
	    COMMAND git commit -a -m "${_after_release_message}"
	    COMMAND git push
	    COMMENT "After release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET_COMMAND(tag OUTPUT ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    COMMAND test -z "\$(git commit --short -uno)"
	    COMMAND git tag -a -m "${CHANGE_SUMMARY}" "${PRJ_VER}" HEAD
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
	    COMMAND hg commit -m "${after_release_message}"
	    COMMAND hg push
	    COMMENT "After release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND hg tag -m "${CHANGE_SUMMARY}" "${PRJ_VER}"
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
	    COMMAND svn commit -m "${after_release_message}"
	    COMMENT "After release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND svn copy "${SOURCE_BASE_URL}/trunk" "${SOURCE_BASE_URL}/tags/${PRJ_VER}" -m "${CHANGE_SUMMARY}"
	    COMMAND cmake -E touch ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_SVN)

ENDIF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)

