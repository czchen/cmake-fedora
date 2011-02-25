# - Add source version control targets.
# Macros for build Git, Mercurial, SVN and CVS specific targets.
# These macros are called internally.
# However, thes macros provides following targets which may be useful:
#  - tag: Tag the release using the selected source version control.
#
# Define following macros:
#   MANAGE_SOURCE_VERSION_CONTROL_GIT()
#   - Use Git as source version control.
#     Reads following variables:
#     + PRJ_VER: Project version.
#
#   MANAGE_SOURCE_VERSION_CONTROL_HG()
#   - Use Mercurial as source version control.
#     Reads following variables:
#     + PRJ_VER: Project version.
#
#   MANAGE_SOURCE_VERSION_CONTROL_SVN()
#   - Use SVN as source version control.
#     Reads following variables:
#     + PRJ_VER: Project version.
#
#   MANAGE_SOURCE_VERSION_CONTROL_CVS()
#   - Use CVS as source version control.
#     Reads following variables:
#     + PRJ_VER: Project version.
#

IF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
    SET(_MANAGE_SOURCE_VERSION_CONTROL_CMAKE_ "DEFINED")
    SET(_after_release_message "After version ${PRJ_VER}")

    ## Common action
    MACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)
	ADD_DEPENDENCIES(tag version_check)
	ADD_DEPENDENCIES(upload tag)
	ADD_DEPENDENCIES(changelog_update tag)
	ADD_DEPENDENCIES(commit_after_release changelog_update)
	ADD_DEPENDENCIES(push_post_release commit_after_release)
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)
	SET(_MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE ${CMAKE_SOURCE_DIR}/.git/refs/tags/${PRJ_VER})

	ADD_CUSTOM_TARGET(commit_after_release
	    COMMAND git commit -a -m "${_after_release_message}"
	    COMMENT "After release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(push_post_release
	    COMMAND git push
	    COMMAND git push --tags
	    COMMENT "Git push tags"
	    VERBATIM
	    )

	SET(_force_commit_cmd "if git commit -a -m 'On release ${PRJ_VER}'"
	    "then echo 'Commit uncommitted changes.'"
	    "else echo 'Nothing new to commit.'"
	    "fi")

	ADD_CUSTOM_TARGET(force_commit
	    COMMAND eval "${_force_commit_cmd}"
	    COMMENT "Force commit uncommitted changes"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    DEPENDS ${_MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    )

	ADD_DEPENDENCIES(tag force_commit)

	ADD_CUSTOM_COMMAND(OUTPUT ${_MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    COMMAND git tag -a -m "${CHANGE_SUMMARY}" "${PRJ_VER}" HEAD
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )


	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_HG)
	ADD_CUSTOM_TARGET(commit_after_release
	    COMMAND hg commit --m "${_after_release_message}"
	    COMMENT "Afer release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(push_post_release
	    COMMAND hg push
	    COMMENT "Mercurial push tags"
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
	ADD_CUSTOM_TARGET(commit_after_release
	    COMMAND svn commit -m "${_after_release_message}"
	    COMMENT "Afer release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(push_post_release
	    COMMENT "SVN push is done at commit"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND svn copy "${SOURCE_BASE_URL}/trunk" "${SOURCE_BASE_URL}/tags/${PRJ_VER}" -m "${CHANGE_SUMMARY}"
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_SVN)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_CVS)
	ADD_CUSTOM_TARGET(commit_after_release
	    COMMAND svn commit -m "${_after_release_message}"
	    COMMENT "Afer release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(push_post_release
	    COMMENT "SVN push is done at commit"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND cvs tag "${PRJ_VER}"
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_CVS)

ENDIF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)

