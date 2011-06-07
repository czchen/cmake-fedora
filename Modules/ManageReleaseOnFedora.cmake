# - Fedora release tasks related to koji, fedpkg and bodhi
#
# This module provides convenient targets and macroes for scratch build,
# submit, and build on koji, using the GIT infrastructure,
# as well as bodhi update.
# Since this module is mainly for Fedora developers/maintainers,
# This module checks ~/.fedora-upload-ca.cert
#
# Defines following variable:
#   FEDORA_RAWHIDE_TAG: Koji tags for rawhide
#   FEDORA_CURRENT_RELEASE_TAGS: Current tags of fedora releases.
# Defines following macros:
#   RELEASE_ON_FEDORA(srpm [NORAWHIDE] [tag1 [tag2 ...])
#   - This call USE_FEDPKG and USE_BODHI and set the corresponding
#     dependencies. This macro is recommended than calling USE_FEDPKG and
#     USE_BODHI directly.
#     Defines following targets:
#     + release_on_fedora: Make necessary steps for releasing on fedora,
#       such as making source file tarballs, source rpms, build with fedpkg
#       and upload to bodhi.
#
#   USE_FEDPKG(srpm [NORAWHIDE] [tag1 [tag2 ...])
#   - Use fedpkg targets if ~/.fedora-upload-ca.cert exists.
#     If ~/.fedora-upload-ca.cert does not exists, this marcos run as an empty
#     macro.
#     Argument:
#     + srpm: srpm file with path.
#     + NORAWHIDE: Don't build on rawhide.
#     + NOKOJI_SCRATCH_BUILD: Don't use koji_scratch_build before commit with
#       fedpkg.
#     + tag1, tag2...: Dist tags such as f14, f13, el5.
#       if no defined, then tags in FEDORA_CURRENT_RELEASE_TAGS are used.
#     Reads following variables:
#     + FEDORA_RELEASE_TAGS: (optional) Release to be built.
#       Note this override the setting from [tag1 [tag2 ...].
#       Thus, this variable can be defined in RELEASE.txt to specify the
#       dist tags to be built.
#     + FEDPKG_DIR: Directory for fedpkg checkout.
#       Default: FedPkg.
#     Defines following targets:
#     + fedpkg_scratch_build: Perform scratch build with fedpkg.
#     + fedpkg_submit: Submit build with fedpkg.
#     + fedpkg_build: Perform build with fedpkg.
#     + fedpkg_update: Update with fedpkg.
#     + koji_scratch_build: Sent srpm for scratch build
#   USE_BODHI([TAGS [tag1 [tag2 ...]] [KARMA karmaValue] )
#   - Use bodhi targets with bodhi command line client.
#     Argument:
#     + TAGS tag1, ....: Dist Tags for submission. Accepts formats like f14,
#        fc14, el6.
#     + KARMA karmaValue: Set the karma threshold. Default is 3.
#     Reads following variables:
#     + BODHI_UPDATE_TYPE: Type of update. Default is "bugfix".
#     + BODHI_USER: Login username for bodhi (for -u).
#     + FEDORA_CURRENT_RELEASE_TAGS: If TAGS is not defined, then it will be
#       use as default tags.
#     + SUGGEST_REBOOT: Whether this update require reboot to take effect.
#       Default is "False".
#     Defines following targets:
#     + bodhi_new: Send a new release to bodhi.
#

IF(NOT DEFINED _MANAGE_RELEASE_ON_FEDORA_)
    SET(_MANAGE_RELEASE_ON_FEDORA_ "DEFINED")
    SET(FEDORA_CURRENT_RELEASE_TAGS f15 f14 f13)
    SET(FEDORA_RAWHIDE_TAG f16)
    IF(NOT DEFINED FEDPKG_DIR)
	SET(FEDPKG_DIR "FedPkg")
    ELSEIF (FEDPKG_DIR STREQUAL "")
	SET(FEDPKG_DIR "FedPkg")
    ENDIF(NOT DEFINED FEDPKG_DIR)
    SET(_bodhi_template_file "bodhi.NO_PACK.template")
    SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES} "/${FEDPKG_DIR}/")

    MACRO(_use_koji_make_targets srpm)
	SET(_tags ${ARGN})
	#commit
	IF(DEFINED CHANGE_SUMMARY)
	    SET (COMMIT_MSG  "-m \"${CHANGE_SUMMARY}\"")
	ELSE(DEFINED CHANGE_SUMMARY)
	    SET (COMMIT_MSG  "")
	ENDIF(DEFINED CHANGE_SUMMARY)
	SET(_first_branch "")
	FOREACH(_tag ${_tags})
	    SET(_branch ${_tag})
	    IF(_tag MATCHES "^el")
		STRING(REGEX REPLACE "el\([0-9]+\)"
		    "\\1E-epel-testing-candidate"  _branch
		    "${_tag}")
	    ENDIF(_tag MATCHES "^el")

	    ADD_CUSTOM_TARGET(koji_scratch_build_${_tag}
		COMMAND ${KOJI} build --scratch dist-${_branch} ${srpm}
		DEPENDS ${srpm}
		COMMENT "koji scratch build on ${_tag} with ${srpm}"
		)

	    ADD_DEPENDENCIES(koji_scratch_build_${_tag} rpmlint)
	    ADD_DEPENDENCIES(koji_scratch_build koji_scratch_build_${_tag})
	ENDFOREACH(_tag ${_tags})
    ENDMACRO(_use_koji_make_targets srpm)

    MACRO(_use_fedpkg_make_targets srpm)
	SET(_tags ${ARGN})
	#MESSAGE("_tags=${_tags}")
	#commit
	IF (DEFINED CHANGE_SUMMARY)
	    SET (COMMIT_MSG  "-m \"${CHANGE_SUMMARY}\"")
	ELSE(DEFINED CHANGE_SUMMARY)
	    SET (COMMIT_MSG  "")
	ENDIF(DEFINED CHANGE_SUMMARY)
	SET(_first_branch "")
	ADD_CUSTOM_TARGET(fedpkg_scratch_build
	    COMMENT "fedpkg scratch build"
	    )
	ADD_CUSTOM_TARGET(fedpkg_commit
	    COMMENT "fedpkg commit"
	    )
	ADD_CUSTOM_TARGET(fedpkg_build
	    COMMENT "fedpkg build"
	    )
	ADD_CUSTOM_TARGET(fedpkg_update
	    COMMENT "fedpkg update"
	    )

	## Know the tag file path
	LIST(GET _tags 0 _first_tag)
	# bodhi tags is used as tag file name
	_use_bodhi_convert_tag(_first_bodhi_tag ${_first_tag})
	SET(_first_tag_name ${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE_NO}.${_first_bodhi_tag})
	SET(_first_tag_relative_path  .git/refs/tags/${_first_tag_name})
	SET(_first_tag_path  ${FEDPKG_DIR}/${PROJECT_NAME}/${_first_tag_relative_path})
	#MESSAGE("_first_tag_path=${_first_tag_path}")

	FOREACH(_tag ${_tags})
	    IF(_tag STREQUAL "${FEDORA_RAWHIDE_TAG}")
		SET(_branch "master")
	    ELSE(_tag STREQUAL "${FEDORA_RAWHIDE_TAG}")
		SET(_branch "${_tag}")
	    ENDIF(_tag STREQUAL "${FEDORA_RAWHIDE_TAG}")

	    ADD_CUSTOM_TARGET(fedpkg_git_pull_${_tag}
		COMMAND ${FEDPKG} switch-branch ${_branch}
		COMMAND git pull
		DEPENDS ${FEDPKG_DIR}/${PROJECT_NAME}
		WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		COMMENT "fedpkg: switching to ${_branch} and pulling changes"
		)

	    ADD_CUSTOM_TARGET(fedpkg_scratch_build_${_tag}
		COMMAND ${FEDPKG} scratch-build --srpm ${srpm}
		DEPENDS ${srpm}
		WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		COMMENT "fedpkg scratch build on ${_branch} with ${srpm}"
		)
	    ADD_DEPENDENCIES(fedpkg_scratch_build_${_tag} fedpkg_git_pull_${_tag})
	    ADD_DEPENDENCIES(fedpkg_scratch_build fedpkg_scratch_build_${_tag})
	    ADD_DEPENDENCIES(fedpkg_scratch_build_${_tag} rpmlint)

	    ADD_CUSTOM_TARGET(fedpkg_build_${_tag}
		COMMAND ${FEDPKG} build
		DEPENDS ${_first_tag_path}
		WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		COMMENT "fedpkg build on ${_branch} with ${srpm}"
		)
	    ADD_DEPENDENCIES(fedpkg_build_${_tag} fedpkg_git_pull_${_tag})
	    ADD_DEPENDENCIES(fedpkg_build fedpkg_build_${_branch})

	    ADD_CUSTOM_TARGET(fedpkg_update_${_tag}
		COMMAND ${FEDPKG} update
		WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		DEPENDS ${_first_tag_path}
		COMMENT "fedpkg update on ${_branch} with ${srpm}"
		)
	    ADD_DEPENDENCIES(fedpkg_update_${_tag} fedpkg_git_pull_${_tag})
	    ADD_DEPENDENCIES(fedpkg_update fedpkg_update_${_tag})

	    IF(_first_branch STREQUAL "")
		SET(_first_branch ${_branch})

		SET(_fedpkg_import_cmd "${FEDPKG} switch-branch ${_branch}"
		    "git-pull"
		    "if [ ! -e ${_first_tag_relative_path} ]"
		    "then ${FEDPKG} import  ${srpm}"
		    "${FEDPKG} commit -m 'Release version ${PRJ_VER}'"
		    "git tag -a -m 'Release version ${PRJ_VER}' ${_first_tag_name}"
		    "${FEDPKG} push"
		    "fi")

		# import primary branch
		ADD_CUSTOM_COMMAND(OUTPUT ${_first_tag_path}
		    COMMAND eval "${_fedpkg_import_cmd}"
		    WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		    COMMENT "fedpkg import on ${_branch} with ${srpm}"
		    VERBATIM
		    )

		#		ADD_CUSTOM_COMMAND(OUTPUT ${_first_tag_path}
		#    COMMAND ${FEDPKG} import  ${srpm}
		#    COMMAND ${FEDPKG} commit -t -m "Release version ${PRJ_VER}" -p
		#    DEPENDS fedpkg_git_pull_${_tag}
		#    WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		#    COMMENT "fedpkg import on ${_branch} with ${srpm}"
		#    VERBATIM
		#    )

		ADD_CUSTOM_TARGET(fedpkg_commit_${_tag}
		    DEPENDS ${_first_tag_path}
		    COMMENT "fedpkg commit on ${_branch} with ${srpm}"
		    )

	    ELSE(_first_branch STREQUAL "")
		ADD_CUSTOM_TARGET(fedpkg_commit_${_tag}
		    COMMAND git merge ${_first_branch}
		    COMMAND ${FEDPKG} push
		    DEPENDS ${_first_tag_path}
		    WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		    COMMENT "fedpkg commit on ${_branch} with ${srpm}"
		    )
	    ENDIF(_first_branch STREQUAL "")
	    ADD_DEPENDENCIES(fedpkg_commit_${_tag} fedpkg_git_pull_${_tag})

	    IF(_no_koji_scratch_build EQUAL 0)
		ADD_DEPENDENCIES(fedpkg_commit_${_tag} koji_scratch_build_${_tag})
	    ENDIF(_no_koji_scratch_build EQUAL 0)
	    ADD_DEPENDENCIES(fedpkg_commit_${_tag} rpmlint)
	    ADD_DEPENDENCIES(fedpkg_commit fedpkg_commit_${_tag})
	    ADD_DEPENDENCIES(fedpkg_build_${_tag} fedpkg_commit_${_tag})

	ENDFOREACH(_tag ${_tags})
    ENDMACRO(_use_fedpkg_make_targets srpm)

    MACRO(USE_FEDPKG srpm)
	IF(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
	    SET(_rawhide 1)
	    SET(_koji_dist_tags "")
	    SET(_stage "")
	    SET(_no_koji_scratch_build 0)

	    FOREACH(_arg ${ARGN})
		IF ("${_arg}" STREQUAL "NORAWHIDE")
		    SET(_rawhide 0)
		ELSEIF("${_arg}" STREQUAL "NOKOJI_SCRATCH_BUILD")
		    SET(_no_koji_scratch_build 1)
		ELSEIF("${_arg}" STREQUAL "TAGS")
		    SET(_stage "TAGS")
		ELSE("${_arg}" STREQUAL "NORAWHIDE")
		    IF(_stage STREQUAL "TAGS")
			LIST(APPEND _koji_dist_tags ${_arg})
		    ENDIF(_stage STREQUAL "TAGS")
		ENDIF("${_arg}" STREQUAL "NORAWHIDE")
	    ENDFOREACH(_arg)

	    #MESSAGE("_koji_dist_tags=${_koji_dist_tags}")
	    IF("${_koji_dist_tags}" STREQUAL "")
		SET(_koji_dist_tags ${FEDORA_CURRENT_RELEASE_TAGS})
	    ENDIF("${_koji_dist_tags}" STREQUAL "")

	    IF(_rawhide EQUAL 1)
		LIST(INSERT _koji_dist_tags 0 ${FEDORA_RAWHIDE_TAG})
	    ENDIF(_rawhide EQUAL 1)
	    LIST(REMOVE_DUPLICATES _koji_dist_tags)

	    FIND_PROGRAM(FEDPKG fedpkg)
	    IF(FEDPKG STREQUAL "FEDPKG-NOTFOUND")
		MESSAGE("Program fedpkg is not found!")
	    ELSE(FEDPKG STREQUAL "FEDPKG-NOTFOUND")
		ADD_CUSTOM_COMMAND(OUTPUT ${FEDPKG_DIR}
		    COMMAND mkdir -p ${FEDPKG_DIR}
		    )

		ADD_CUSTOM_TARGET(fedpkg_clone
		    DEPENDS ${FEDPKG_DIR}/${PROJECT_NAME}
		    )

		ADD_CUSTOM_COMMAND(OUTPUT ${FEDPKG_DIR}/${PROJECT_NAME}
		    COMMAND ${FEDPKG} clone ${PROJECT_NAME}
		    DEPENDS ${FEDPKG_DIR}
		    WORKING_DIRECTORY ${FEDPKG_DIR}
		    )


		## Make target commands for the released dist
		_use_fedpkg_make_targets("${srpm}" ${_koji_dist_tags})

	    ENDIF(FEDPKG STREQUAL "FEDPKG-NOTFOUND")
	    FIND_PROGRAM(KOJI koji)
	    IF(KOJI STREQUAL "KOJI-NOTFOUND")
		MESSAGE("Program koji is not found!")
	    ELSE(KOJI STREQUAL "KOJI-NOTFOUND")
		## Make target commands for the released dist
		ADD_CUSTOM_TARGET(koji_scratch_build
		    COMMENT "Koji scratch build"
		    )
		_use_koji_make_targets("${srpm}" ${_koji_dist_tags})

	    ENDIF(KOJI STREQUAL "KOJI-NOTFOUND")

	ENDIF(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
    ENDMACRO(USE_FEDPKG srpm)

    MACRO(_use_bodhi_convert_tag tag_out tag_in)
	STRING(REGEX REPLACE "f([0-9]+)" "fc\\1" _tag_replace "${tag_in}")
	IF(_tag_replace STREQUAL "")
	    SET(${tag_out} ${tag_in})
	ELSE(_tag_replace STREQUAL "")
	    SET(${tag_out} ${_tag_replace})
	ENDIF(_tag_replace STREQUAL "")
    ENDMACRO(_use_bodhi_convert_tag tag_out tag_in)

    MACRO(_append_notes _file)
	STRING(REGEX REPLACE "\n" "\n " _notes "${CHANGELOG_ITEMS}")
	FILE(APPEND ${_file} "notes=${_notes}\n\n")
    ENDMACRO(_append_notes _file)

    MACRO(USE_BODHI)
	# Bodhi does not really require .fedora-upload-ca.cert
	# But since this macro is meant for package maintainers,
	# so..
	SET(_autokarma "True")
	SET(_stable_karma 3)
	SET(_unstable_karma -3)
	SET(_tags "")
	IF(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
	    FIND_PROGRAM(BODHI bodhi)
	    IF(BODHI STREQUAL "BODHI-NOTFOUND")
		MESSAGE("Program bodhi is not found!")
	    ELSE(BODHI STREQUAL "BODHI-NOTFOUND")
		SET(_stage "NONE")
		FOREACH(_arg ${ARGN})
		    IF(_arg STREQUAL "TAGS")
			SET(_stage "TAGS")
		    ELSEIF(_arg STREQUAL "KARMA")
			SET(_stage "KARMA")
		    ELSE(_arg STREQUAL "TAGS")
			# option values
			IF(_stage STREQUAL "TAGS")
			    SET(_tags ${_tags} ${_arg})
			ELSEIF(_stage STREQUAL "KARMA")
			    IF(_arg STREQUAL "0")
				SET(_autokarma "False")
			    ELSE(_arg STREQUAL "0")
				SET(_autokarma "True")
			    ENDIF(_arg STREQUAL "0")
			    SET(_stable_karma "${_arg}")
			    SET(_unstable_karma "-${_arg}")
			    SET(_tags ${_arg})
			ENDIF(_stage STREQUAL "TAGS")
		    ENDIF(_arg STREQUAL "TAGS")
		ENDFOREACH(_arg ${ARGN})

		IF(NOT _tags)
		    SET(_tags ${FEDORA_CURRENT_RELEASE_TAGS})
		ENDIF(NOT _tags)

		IF(NOT "${FEDORA_RELEASE_TAGS}" STREQUAL "")
		    SET(_tags ${FEDORA_RELEASE_TAGS})
		ENDIF(NOT "${FEDORA_RELEASE_TAGS}" STREQUAL "")

		FILE(REMOVE ${_bodhi_template_file})
		FOREACH(_tag ${_tags})
		    _use_bodhi_convert_tag(_bodhi_tag ${_tag})

		    FILE(APPEND ${_bodhi_template_file} "[${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE_NO}.${_bodhi_tag}]\n\n")

		    IF(BODHI_UPDATE_TYPE)
			FILE(APPEND ${_bodhi_template_file} "type=${BODHI_UPDATE_TYPE}\n\n")
		    ELSE(BODHI_UPDATE_TYPE)
			FILE(APPEND ${_bodhi_template_file} "type=bugfix\n\n")
		    ENDIF(BODHI_UPDATE_TYPE)

		    FILE(APPEND ${_bodhi_template_file} "request=testing\n")
		    FILE(APPEND ${_bodhi_template_file} "bugs=${REDHAT_BUGZILLA}\n")

		    _append_notes(${_bodhi_template_file})

		    FILE(APPEND ${_bodhi_template_file} "autokarma=${_autokarma}\n")
		    FILE(APPEND ${_bodhi_template_file} "stable_karma=${_stable_karma}\n")
		    FILE(APPEND ${_bodhi_template_file} "unstable_karma=${_unstable_karma}\n")
		    FILE(APPEND ${_bodhi_template_file} "close_bugs=True\n")

		    IF(SUGGEST_REBOOT)
			FILE(APPEND ${_bodhi_template_file} "suggest_reboot=True\n")
		    ELSE(SUGGEST_REBOOT)
			FILE(APPEND ${_bodhi_template_file} "suggest_reboot=False\n\n")
		    ENDIF(SUGGEST_REBOOT)
		ENDFOREACH(_tag ${_tags})

		IF(BODHI_USER)
		    SET(_bodhi_login "-u ${BODHI_USER}")
		ENDIF(BODHI_USER)

		ADD_CUSTOM_TARGET(bodhi_new
		    COMMAND bodhi --new ${_bodhi_login} --file ${_bodhi_template_file}
		    COMMENT "Send new package to bodhi"
		    VERBATIM
		    )

		GET_TARGET_PROPERTY(_target_location fedpkg_build LOCATION)
		IF(NOT "${_target_location}" STREQUAL "NOTFOUND")
		    # Has target: fedpkg_build
		    ADD_DEPENDENCIES(bodhi_new fedpkg_build)
		ENDIF(NOT "${_target_location}" STREQUAL "NOTFOUND")
	    ENDIF(BODHI STREQUAL "BODHI-NOTFOUND")
	ENDIF(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
    ENDMACRO(USE_BODHI)

    MACRO(RELEASE_ON_FEDORA srpm)
	USE_FEDPKG(${srpm} ${ARGN})
	USE_BODHI(${ARGN})
	ADD_CUSTOM_TARGET(release_on_fedora)
	ADD_DEPENDENCIES(release_on_fedora bodhi_new)
    ENDMACRO(RELEASE_ON_FEDORA srpm)

ENDIF(NOT DEFINED _MANAGE_RELEASE_ON_FEDORA_)

