# - Target for release chores

IF(NOT DEFINED _MANAGE_RELEASE_)
    SET(_MANAGE_RELEASE_ "DEFINED")
    INCLUDE(ManageMaintainerTargets)

    ## Target: release

    ADD_CUSTOM_TARGET(release
	COMMENT "Release a new version"
	)

    IF(RELEASE_TARGETS)
	ADD_DEPENDENCIES(release ${RELEASE_TARGETS})
    ENDIF(RELEASE_TARGETS)

    ADD_CUSTOM_TARGET(post_release)


    ADD_DEPENDENCIES(post_release push_post_release)
    ADD_DEPENDENCIES(push_post_release commit_after_release)
    ADD_DEPENDENCIES(commit_after_release changelog_update)

ENDIF(NOT DEFINED _MANAGE_RELEASE_)

