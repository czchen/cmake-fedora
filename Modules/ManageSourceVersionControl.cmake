# - Add source version control targets.
# This module has macros for Git, Mercurial and SVN.
#
# Define following macros:
#   MANAGE_SOURCE_VERSION_CONTROL_GIT()
#   - Use Git as source version control.
#     Reads following variables:
#     + PRJ_VER: Project version.

IF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
    SET(_MANAGE_SOURCE_VERSION_CONTROL_CMAKE_ "DEFINED")
    SET(_after_release_message "After version ${PRJ_VER}")
    MACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)
	ADD_CUSTOM_TARGET(commit_after_release
	    COMMAND git commit -a -m "${_after_release_message"
	    COMMENT "Afer release ${PRJ_VER}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(push_svc_tags
	    COMMAND git push
	    COMMAND git push --tags
	    COMMENT "Git push tags"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    COMMAND git tag -a -m "${CHANGE_SUMMARY}" "${PRJ_VER}" HEAD
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )
	ADD_DEPENDENCIES(tag version_check)

	ADD_CUSTOM_TARGET(release_with_svc)

    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)


ENDIF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)

