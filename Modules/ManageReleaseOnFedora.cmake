# - Fedora release tasks related to koji, fedpkg and bodhi
#
# This module provides convenient targets and macroes for scratch build,
# submit, and build on koji, using the GIT infrastructure,
# as well as bodhi update.
# Since this module is mainly for Fedora developers/maintainers,
# This module checks ~/.fedora-upload-ca.cert
#
# Includes:
#   ManageMessage
#   ManageSourceVersionControl
#
#
# Defines following variable:
#   FEDORA_RAWHIDE_TAG: Koji tags for rawhide
#   FEDORA_CURRENT_RELEASE_TAGS: Current tags of fedora releases.
# Defines following macros:
#   RELEASE_ON_FEDORA(srpm [NORAWHIDE] [TAGS [tag1 [tag2 ...]])
#   - This call USE_FEDPKG and USE_BODHI and set the corresponding
#     dependencies. This macro is recommended than calling USE_FEDPKG and
#     USE_BODHI directly.
#     Defines following targets:
#     + release_on_fedora: Make necessary steps for releasing on fedora,
#       such as making source file tarballs, source rpms, build with fedpkg
#       and upload to bodhi.
#
#   USE_FEDPKG(srpm [NORAWHIDE] [NOKOJI_SCRATCH_BUILD] [TAGS [tag1 [tag2 ...]])
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
#     + koji_scratch_build: Sent srpm to Koji for scratch build
#
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
    SET(FEDORA_CURRENT_RELEASE_TAGS f15 f14)
    SET(FEDORA_EPEL_RELEASE_TAGS el6 el5)
    SET(FEDORA_RAWHIDE_TAG f16)
    IF("${FEDPKG_DIR}" STREQUAL "")
	SET(FEDPKG_DIR "FedPkg")
    ENDIF(NOT DEFINED FEDPKG_DIR)

    IF(NOT DEFINED FEDORA_KOJI_TAG_POSTFIX_PREFERRED)
	SET(FEDORA_KOJI_TAG_POSTFIX "")
    ENDIF(NOT DEFINED FEDORA_KOJI_TAG_POSTFIX)

    IF(NOT DEFINED EPEL_KOJI_TAG_POSTFIX)
	SET(EPEL_KOJI_TAG_POSTFIX "-testing-candidate")
    ENDIF(NOT DEFINED EPEL_KOJI_TAG_POSTFIX)

    SET(_bodhi_template_file "bodhi.NO_PACK.template")
    SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES} "/${FEDPKG_DIR}/")

    # Need the definition of source version control first, as we need to check tag file.
    INCLUDE(ManageSourceVersionControl)
    INCLUDE(ManageMessage)

    SET(_FEDORA_DIST_TAGS "")

    MACRO(_manange_release_on_fedora_dist_convert_to_koji_target
	    var dist)
	IF(dist MATCHES "^el")
	    STRING(REGEX REPLACE "el\([0-9]+\)"
		"dist-\\1E-epel${EPEL_KOJI_TAG_POSTFIX}" ${var}  "${dist}")
	ELSE(dist MATCHES "^el")
	    # Fedora dists
	    STRING(REGEX REPLACE "f[c-]\([0-9]+\)" _relver "${dist}")
	    IF(_relver GREATER 15)
		SET(${var} "f${_relver}${FEDORA_KOJI_TAG_POSTFIX}")
	    ELSE(_relver GREATER 15)
		SET(${var} "dist-f${_relver}${FEDORA_KOJI_TAG_POSTFIX}")
	    ENDIF(_relver GREATER 15)

	ENDIF(dist MATCHES "^el")
    ENDMACRO(_manange_release_on_fedora_dist_convert_to_koji_target
	kojiTarget dist)

    MACRO(_manange_release_on_fedora_parse_args)
	SET(_FEDORA_RAWHIDE 1)
	SET(_FEDORA_DIST_TAGS "")
	SET(_stage "")
	FOREACH(_arg ${ARGN})
	    IF ("${_arg}" STREQUAL "NORAWHIDE")
		SET(_FEDORA_RAWHIDE 0)
	    ELSEIF("${_arg}" STREQUAL "NOKOJI_SCRATCH_BUILD")
		SET(_FEDORA_KOJI_SCRATCH 0)
	    ELSEIF("${_arg}" STREQUAL "TAGS")
		# No need to further parsing TAGS, as FEDORA_RELEASE_TAGS
		# override whatever specified after TAGS
		IF(NOT FEDORA_RELEASE_TAGS STREQUAL "")
		    BREAK()
		ENDIF(NOT FEDORA_RELEASE_TAGS STREQUAL "")
		SET(_stage "TAGS")
	    ELSE("${_arg}" STREQUAL "NORAWHIDE")
		IF(_stage STREQUAL "TAGS")
		    LIST(APPEND _FEDORA_DIST_TAGS ${_arg})
		ELSE(_stage STREQUAL "TAGS")
		    SET(_FEDORA_SRPM ${_arg})
		ENDIF(_stage STREQUAL "TAGS")
   	    ENDIF("${_arg}" STREQUAL "NORAWHIDE")
	ENDFOREACH(_arg ${ARGN})
	IF(NOT FEDORA_RELEASE_TAGS STREQUAL "")
	    LIST(APPEND _FEDORA_DIST_TAGS ${FEDORA_RELEASE_TAGS})
	ELSEIF(_FEDORA_DIST_TAGS STREQUAL "")
	    LIST(APPEND _FEDORA_DIST_TAGS ${FEDORA_CURRENT_RELEASE_TAGS})
	ENDIF(NOT FEDORA_RELEASE_TAGS STREQUAL "")

	IF(_FEDORA_RAWHIDE EQUAL 1)
	    LIST(INSERT ${_tags} 0 ${FEDORA_RAWHIDE_TAG})
	ENDIF(_FEDORA_RAWHIDE EQUAL 1)
	LIST(REMOVE_DUPLICATES ${_FEDORA_DIST_TAGS})

	MESSAGE("_FEDORA_RAWHIDE=${_FEDORA_RAWHIDE}")
	MESSAGE("_FEDORA_KOJI_SCRATCH=${_FEDORA_KOJI_SCRATCH}")
	MESSAGE("_FEDORA_DIST_TAGS=${_FEDORA_DIST_TAGS}")
    ENDMACRO(_manange_release_on_fedora_parse_args)

    MACRO(USE_KOJI srpm)
	SET(_dependencies_missing 0)
	FIND_PROGRAM(KOJI koji)
	IF(KOJI STREQUAL "KOJI-NOTFOUND")
	    M_MSG(${M_OFF} "Program koji is not found! Koji support disabled.")
	    SET(_dependencies_missing 1)
	ENDIF(KOJI STREQUAL "KOJI-NOTFOUND")

	IF(_dependencies_missing EQUAL 0)
	    IF(_FEDORA_DIST_TAGS STREQUAL "")
		_manange_release_on_fedora_parse_args(${ARGN})
	    ENDIF(_FEDORA_DIST_TAGS STREQUAL "")

	    IF(_FEDORA_KOJI_SCRATCH EQUAL 1)
		ADD_CUSTOM_TARGET(koji_scratch_build
		    COMMENT "koji scratch builds"
		    )

		# Ensure package build in koji before tag
		ADD_DEPENDENCIES(tag koji_scratch_build)
	    ENDIF(_FEDORA_KOJI_SCRATCH EQUAL 1)

	    FOREACH(_tag ${_FEDORA_DIST_TAGS})
		_manange_release_on_fedora_dist_convert_to_koji_target(_branch ${_tag})
		IF(_FEDORA_KOJI_SCRATCH EQUAL 1)
		    ADD_CUSTOM_TARGET(koji_scratch_build_${_tag}
			COMMAND ${KOJI} build --scratch dist-${_branch} ${srpm}
			COMMENT "koji scratch build on ${_tag} with ${srpm}"
			)
		    ADD_DEPENDENCIES(koji_scratch_build_${_tag} rpmlint)
		    ADD_DEPENDENCIES(koji_scratch_build koji_scratch_build_${_tag})
		ENDIF(_FEDORA_KOJI_SCRATCH EQUAL 1)
	    ENDFOREACH(_tag ${_FEDORA_DIST_TAGS})
	ENDIF(_dependencies_missing EQUAL 0)
    ENDMACRO(USE_KOJI srpm)

    MACRO(_use_fedpkg_make_targets srpm)
	#MESSAGE("_FEDORA_DIST_TAGS=${_FEDORA_DIST_TAGS}")
	#Commit summary
	IF (DEFINED CHANGE_SUMMARY)
	    SET (COMMIT_MSG  "-m \"${CHANGE_SUMMARY}\"")
	ELSE(DEFINED CHANGE_SUMMARY)
	    SET (COMMIT_MSG  "")
	ENDIF(DEFINED CHANGE_SUMMARY)

	ADD_CUSTOM_TARGET(fedpkg_scratch_build
	    COMMENT "fedpkg scratch build"
	    )
	ADD_CUSTOM_TARGET(fedpkg_import
	    COMMENT "fedpkg import"
	    )
	ADD_CUSTOM_TARGET(fedpkg_build
	    COMMENT "fedpkg build"
	    )
	SET_TARGET_PROPERTIES(fedpkg_build
	    PROPERTIES EXISTS "true")
	ADD_CUSTOM_TARGET(fedpkg_update
	    COMMENT "fedpkg update"
	    )

	SET(_fedpkg_tag_path_abs_prefix
	    "${FEDPKG_WORKDIR}/.git/refs/tags")
	FOREACH(_tag ${_FEDORA_DIST_TAGS})
	    IF(_tag STREQUAL "${FEDORA_RAWHIDE_TAG}")
		SET(_branch "master")
	    ELSE(_tag STREQUAL "${FEDORA_RAWHIDE_TAG}")
		SET(_branch "${_tag}")
	    ENDIF(_tag STREQUAL "${FEDORA_RAWHIDE_TAG}")
	    SET(_fedpkg_tag_name_prefix "${PRJ_VER}-${PRJ_RELEASE_NO}.${_tag}")

	    ADD_CUSTOM_TARGET(fedpkg_scratch_build_${_tag}
		COMMAND ${FEDPKG} scratch-build --srpm ${srpm}
		DEPENDS ${srpm}
		WORKING_DIRECTORY ${FEDPKG_WORKDIR}
		COMMENT "fedpkg scratch build on ${_branch} with ${srpm}"
		)
	    ADD_DEPENDENCIES(fedpkg_scratch_build_${_tag} rpmlint)
	    ADD_DEPENDENCIES(fedpkg_scratch_build fedpkg_scratch_build_${_tag})

	    ## fedpkg import
	    SET(_import_opt "")
	    IF(NOT ${_tag} STREQUAL ${FEDORA_RAWHIDE_TAG})
		SET(_import_opt "-b ${_tag}")
	    ENDIF(NOT ${_tag} STREQUAL ${FEDORA_RAWHIDE_TAG})

	    SET(_fedpkg_tag_name_imported
		"${_fedpkg_tag_name_prefix}.imported")
	    ADD_CUSTOM_COMMAND(OUTPUT
		${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_imported}
		COMMAND ${FEDPKG} ${_import_opt} import ${srpm}
		COMMAND ${FEDPKG} switch-branch ${_branch}
		COMMAND git tag -a -m "${PRJ_VER}-${PRJ_RELEASE_NO}.${_tag} imported"
		${_fedpkg_tag_name_imported}
		COMMAND git push --tags
		WORKING_DIRECTORY ${FEDPKG_WORKDIR}
		COMMENT "fedpkg import on ${_branch} with ${srpm}"
		VERBATIM
	    )

	    ADD_CUSTOM_TARGET(fedpkg_import_${_tag}
		DEPENDS ${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_imported}
		)
	    ADD_DEPENDENCIES(fedpkg_import_${_tags} tag)
	    ADD_DEPENDENCIES(fedpkg_import fedpkg_import_${_tags})

	    ## fedpkg build
	    SET(_fedpkg_tag_name_built
		"${_fedpkg_tag_name_prefix}.built")
	    ADD_CUSTOM_COMMAND(OUTPUT
		${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_built}
		COMMAND ${FEDPKG} switch-branch ${_branch}
		COMMAND ${FEDPKG} build
		COMMAND git tag -a -m "${PRJ_VER}-${PRJ_RELEASE_NO}.${_tag} built"
		${_fedpkg_tag_name_built}
		COMMAND git push --tags
		WORKING_DIRECTORY ${FEDPKG_WORKDIR}
		COMMENT "fedpkg build on ${_branch}"
		VERBATIM
		)

	    ADD_CUSTOM_TARGET(fedpkg_build_${_tag}
		DEPENDS ${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_built}
		)

	    ADD_DEPENDENCIES(fedpkg_build_${_tags} fedpkg_import_${_tag})
	    ADD_DEPENDENCIES(fedpkg_build fedpkg_build_${_tags})

	    IF("${_target_exists}" STREQUAL "true")
		# Since tag depends on koji_scratch_build_ ${_tag}
		# fedpkg_commit depends on tag should be sufficient.
		ADD_DEPENDENCIES(fedpkg_commit_${_tag}  koji_scratch_build_${_tag})
	    ELSE("${_target_exists}" STREQUAL "true")
		ADD_DEPENDENCIES(fedpkg_commit_${_tag}  fedpkg_scratch_build_${_tag})
	    ENDIF("${_target_exists}" STREQUAL "true")

	    ADD_CUSTOM_TARGET(fedpkg_build_${_tag}
		COMMAND ${FEDPKG} build
		DEPENDS ${_first_tag_path}
		WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		COMMENT "fedpkg build on ${_branch} with ${srpm}"
		)
	    ADD_DEPENDENCIES(fedpkg_build_${_tag} fedpkg_commit_${_tag})
	    ADD_DEPENDENCIES(fedpkg_build fedpkg_build_${_branch})

	    ADD_CUSTOM_TARGET(fedpkg_update_${_tag}
		COMMAND ${FEDPKG} update
		WORKING_DIRECTORY ${FEDPKG_DIR}/${PROJECT_NAME}
		DEPENDS ${_first_tag_path}
		COMMENT "fedpkg update on ${_branch} with ${srpm}"
		)
	    ADD_DEPENDENCIES(fedpkg_update_${_tag} fedpkg_build_${_tag})
	    ADD_DEPENDENCIES(fedpkg_update fedpkg_update_${_tag})
	ENDFOREACH(_tag ${_FEDORA_DIST_TAGS})
    ENDMACRO(_use_fedpkg_make_targets srpm)

    MACRO(USE_FEDPKG srpm)
	SET(_dependencies_missing 0)

	IF(NOT EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
	    M_MSG(${M_OFF}
		"\$HOME/.fedora-upload-ca.cert not found, fedpkg support disabled")
	    SET(_dependencies_missing 1)
	ENDIF(NOT EXISTS $ENV{HOME}/.fedora-upload-ca.cert)

	FIND_PROGRAM(FEDPKG fedpkg)
	IF(FEDPKG STREQUAL "FEDPKG-NOTFOUND")
	    M_MSG(${M_OFF} "Program fedpkg is not found! fedpkg support disabled.")
	    SET(_dependencies_missing 1)
	ENDIF(FEDPKG STREQUAL "FEDPKG-NOTFOUND")

	IF(_dependencies_missing EQUAL 0)
	    IF(_FEDORA_DIST_TAGS STREQUAL "")
		_manange_release_on_fedora_parse_args(${ARGN})
	    ENDIF(_FEDORA_DIST_TAGS STREQUAL "")

	    SET(FEDPKG_DIR_ABS ${CMAKE_BINARY_DIR}/${FEDPKG_DIR})
	    SET(FEDPKG_WORKDIR ${FEDPKG_DIR_ABS}/${PROJECT_NAME})
	    ADD_CUSTOM_COMMAND(OUTPUT ${FEDPKG_DIR_ABS}
		COMMAND mkdir -p ${FEDPKG_DIR_ABS}
		)

	    ADD_CUSTOM_TARGET(fedpkg_clone
		DEPENDS ${FEDPKG_WORKDIR}
		)

	    ADD_CUSTOM_COMMAND(OUTPUT $${FEDPKG_WORKDIR}
		COMMAND ${FEDPKG} clone ${PROJECT_NAME}
		DEPENDS ${FEDPKG_DIR_ABS}
		WORKING_DIRECTORY ${FEDPKG_DIR_ABS}
		)

	    ## Make target commands for the released dist
	    _use_fedpkg_make_targets("${srpm}")
	ENDIF(_dependencies_missing EQUAL 0)
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
	SET(_disabled 0)
	IF(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
	    FIND_PROGRAM(BODHI bodhi)
	    IF(BODHI STREQUAL "BODHI-NOTFOUND")
		M_MSG(${M_OFF} "Program bodhi is not found! bodhi support disabled.")
		SET(_disabled 1)
	    ENDIF(BODHI STREQUAL "BODHI-NOTFOUND")
	ELSE(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
	    M_MSG(${M_OFF}
		"\$HOME/.fedora-upload-ca.cert not found, bodhi support disabled")
	    SET(_disabled 1)
	ENDIF(EXISTS $ENV{HOME}/.fedora-upload-ca.cert)

	IF(_disabled EQUAL 0)
	    SET(_autokarma "True")
	    SET(_stable_karma 3)
	    SET(_unstable_karma -3)
	    SET(_tags "")
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

	    GET_TARGET_PROPERTY(_target_exists fedpkg_build EXISTS)
	    IF("${_target_exists}" STREQUAL "true")
		# Has target: fedpkg_build
		ADD_DEPENDENCIES(bodhi_new fedpkg_build)
	    ENDIF("${_target_exists}" STREQUAL "true")
	ENDIF(_disabled EQUAL 0)
    ENDMACRO(USE_BODHI)

    MACRO(RELEASE_ON_FEDORA srpm)
	GET_TARGET_PROPERTY(_target_exists release EXISTS)
	IF(NOT _target_exists EQUAL 1)
	    M_MSG(${M_OFF} "ManageReleaseOnFedora: maintainer file is invalid, disable release targets" )
	ELSE(NOT _target_exists EQUAL 1)
	    USE_FEDPKG(${srpm} ${ARGN})
	    USE_BODHI(${ARGN})
	    ADD_CUSTOM_TARGET(release_on_fedora)
	    ADD_DEPENDENCIES(release release_on_fedora)
	    ADD_DEPENDENCIES(release_on_fedora bodhi_new)
	ENDIF(NOT _target_exists EQUAL 1)

    ENDMACRO(RELEASE_ON_FEDORA srpm)

ENDIF(NOT DEFINED _MANAGE_RELEASE_ON_FEDORA_)

