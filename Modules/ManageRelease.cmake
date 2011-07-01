# - Common targets for release chores.
# This module provides common targets for release or post-release chores.
#
#  Defines following targets:
#  + changelog_update: Update changelog by copying ChangeLog to ChangeLog.prev
#    and RPM-ChangeLog to RPM-ChangeLog. This target should be execute before
#     starting a new version.
#  + release: Do the release chores.
#    Reads or define following variables:
#    + RELEASE_TARGETS: Depended targets for release.
#      Note that the sequence of the target does not guarantee the
#      sequence of execution.
#
#  + after_release: Chores after release.
#    This depends on changelog_update, commit_after_release, and
#    push_after_release.
#

IF(NOT DEFINED _MANAGE_RELEASE_CMAKE_)
    SET(_MANAGE_RELEASE_CMAKE_ "DEFINED")
    INCLUDE(ManageMaintainerTargets)
    MACRO(MANAGE_RELEASE)
	IF("${HOSTING_SERVICES}" STREQUAL "")
	    MAINTAINER_SETTING_READ_FILE()
	ENDIF("${HOSTING_SERVICES}" STREQUAL "")
	IF("${HOSTING_SERVICES}" STREQUAL "")
	ENDIF("${HOSTING_SERVICES}" STREQUAL "")


    ENDMACRO(MANAGE_RELEASE)

    ADD_CUSTOM_TARGET(changelog_update
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/ChangeLog ${CMAKE_SOURCE_DIR}/ChangeLog.prev
	COMMAND ${CMAKE_COMMAND} -E copy ${RPM_BUILD_SPECS}/RPM-ChangeLog ${RPM_BUILD_SPECS}/RPM-ChangeLog.prev
	DEPENDS ${CMAKE_SOURCE_DIR}/ChangeLog ${RPM_BUILD_SPECS}/RPM-ChangeLog
	COMMENT "Changelogs are updated for next version."
	)

    ## Target: release

    ADD_CUSTOM_TARGET(release
	COMMENT "Release a new version"
	)

    IF(RELEASE_TARGETS)
	ADD_DEPENDENCIES(release ${RELEASE_TARGETS})
    ENDIF(RELEASE_TARGETS)

    ADD_CUSTOM_TARGET(after_release)
    ADD_DEPENDENCIES(after_release push_after_release)
    ADD_DEPENDENCIES(push_after_release commit_after_release)
    ADD_DEPENDENCIES(commit_after_release changelog_update)


ENDIF(NOT DEFINED _MANAGE_RELEASE_CMAKE_)

