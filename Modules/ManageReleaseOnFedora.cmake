# - Module for working with Fedora and EPEL releases.
#
# This module provides convenient targets and macros for Fedora and EPEL
# releases by using fedpkg, koji, and bodhi
# Since this module is mainly for Fedora developers/maintainers,
# This module checks ~/.fedora-upload-ca.cert
#
# This module read the supported release information from cmake-fedora.conf
# It finds cmake-fedora.conf in following order:
# 1. Current directory
# 2. Path as defined CMAKE_SOURCE_DIR
# 3. /etc/cmake-fedora.conf
#
# Includes:
#   ManageMessage
#   ManageSourceVersionControl
#
# Reads following variables:
#   FEDORA_CANDIDATE_PREFERRED:
#     Set to "0" to build against original repo (without update).
#   EPEL_CANDIDATE_PREFERRED:
#     Set to "0" to build against original repo (without update).
# Defines following variable:
#   FEDORA_RAWHIDE_TAG: Koji tag for rawhide.
#   FEDORA_SUPPORTED_RELEASE_TAGS: Releases that are currently supported.
#   FEDORA_CURRENT_RELEASE_TAGS: Releases that are recommend to build against.
#     It is essentially FEDORA_RAWHIDE_TAG + FEDORA_SUPPORTED_RELEASE_TAGS.
# Defines following macros:
#   RELEASE_ON_FEDORA(srpm [TAGS [tag1 [tag2 ...]])
#   - This call USE_FEDPKG and USE_BODHI and set the corresponding
#     dependencies. This macro is recommended than calling USE_FEDPKG and
#     USE_BODHI directly.
#     Arguments:
#     + srpm: srpm file with path.
#     + NOKOJI_SCRATCH_BUILD: Don't use koji_scratch_build before commit with
#       fedpkg.
#     + tag1, tag2...: Dist tags such as "f17", "f16", "el5", or
#       "fedora" for fedora current release defined in cmake-fedora.conf, or
#       "epel" for fedora current release defined in cmake-fedora.conf, or
#       if no tags are defined, then "fedora" is assumed.
#
#     Reads following variables:
#     + FEDORA_RELEASE_TAGS: (optional) Release to be built.
#       Note this override the setting from [tag1 [tag2 ...].
#       Thus, this variable can be defined in RELEASE.txt to specify the
#       dist tags to be built.
#     + FEDPKG_DIR: Directory for fedpkg checkout.
#       Default: FedPkg.
#
#     Defines following targets:
#     + release_on_fedora: Make necessary steps for releasing on fedora,
#       such as making source file tarballs, source rpms, build with fedpkg
#       and upload to bodhi.
#
#   USE_FEDPKG(srpm [NOKOJI_SCRATCH_BUILD] [TAGS [tag1 [tag2 ...]])
#   - Use fedpkg targets if ~/.fedora-upload-ca.cert exists.
#     If ~/.fedora-upload-ca.cert does not exists, this marcos run as an empty
#     macro.
#     Arguments:
#     + srpm: srpm file with path.
#     + NOKOJI_SCRATCH_BUILD: Don't use koji_scratch_build before commit with
#       fedpkg.
#     + tag1, tag2...: Dist tags such as "f17", "f16", "el5", or
#       "fedora" for fedora current release defined in cmake-fedora.conf, or
#       "epel" for fedora current release defined in cmake-fedora.conf, or
#       if no tags are defined, then "fedora" is assumed.
#
#     Defines following targets:
#     + fedpkg_scratch_build: Perform scratch build with fedpkg.
#     + fedpkg_submit: Submit build with fedpkg.
#     + fedpkg_build: Perform build with fedpkg.
#     + fedpkg_update: Update with fedpkg.
#     + koji_scratch_build: Sent srpm to Koji for scratch build
#
#   USE_BODHI([KARMA karmaValue] [TAGS [tag1 [tag2 ...]]  )
#   - Use bodhi targets with bodhi command line client.
#     Argument:
#     + KARMA karmaValue: Set the karma threshold. Default is 3.
#     + TAGS tag1, ....: Dist Tags for submission. Accepts formats like f14,
#        fc14, el6.
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
    INCLUDE(ManageMessage)
    INCLUDE(ManageTarget)
    SET(_manage_release_on_fedora_dependencies_missing 0)

    FIND_FILE(CMAKE_FEDORA_CONF cmake-fedora.conf "." "${CMAKE_SOURCE_DIR}" "${SYSCONF_DIR}")
    M_MSG(${M_INFO1} "CMAKE_FEDORA_CONF=${CMAKE_FEDORA_CONF}")
    IF("${CMAKE_FEDORA_CONF}" STREQUAL "CMAKE_FEDORA_CONF-NOTFOUND")
	M_MSG(${M_OFF} "cmake-fedora.conf cannot be found! Fedora release support disabled.")
	SET(_manage_release_on_fedora_dependencies_missing 1)
    ENDIF("${CMAKE_FEDORA_CONF}" STREQUAL "CMAKE_FEDORA_CONF-NOTFOUND")

    FIND_PROGRAM(FEDPKG_CMD fedpkg)
    IF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program fedpkg is not found! Fedora support disabled.")
	SET(_manage_release_on_fedora_dependencies_missing 1)
    ENDIF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")

    FIND_PROGRAM(GIT_CMD git)
    IF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program git is not found! Fedora support disabled.")
	SET(_manage_release_on_fedora_dependencies_missing 1)
    ENDIF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")

    ## Set variables
    IF(_manage_release_on_fedora_dependencies_missing  EQUAL 0)
	SET(KOJI_BUILD_SCRATCH koji-build-scratch)
	CONFIGURE_FILE(scripts/${KOJI_BUILD_SCRATCH}.in
	    scripts/${KOJI_BUILD_SCRATCH} @ONLY)

	# Set release tags according to CMAKE_FEDORA_CONF
	SETTING_FILE_GET_ALL_VARIABLES(${CMAKE_FEDORA_CONF})

	SET(FEDORA_RAWHIDE_VER "${FEDORA_RAWHIDE_VERSION}"
	    CACHE STRING "Fedora Rawhide ver")
	STRING_SPLIT(_FEDORA_SUPPORTED_VERS " " ${FEDORA_SUPPORTED_VERSIONS})
	SET(FEDORA_SUPPORTED_VERS ${_FEDORA_SUPPORTED_VERS}
	    CACHE STRING "Fedora supported vers" FORCE)

	STRING_SPLIT(_EPEL_SUPPORTED_VERS " " ${EPEL_SUPPORTED_VERSIONS})
	SET(EPEL_SUPPORTED_VERS ${_EPEL_SUPPORTED_VERS}
	    CACHE STRING "EPEL supported vers" FORCE)

	SET(FEDORA_KOJI_TAG_POSTFIX "" CACHE STRING "Koji Fedora tag prefix")
	SET(EPEL_KOJI_TAG_POSTFIX "-testing-candidate"
	    CACHE STRING "Koji EPEL tag prefix")

	SET(BODHI_TEMPLATE_FILE "${CMAKE_FEDORA_TMP_DIR}/bodhi.template"
	    CACHE FILEPATH "Bodhi template file"
	    )
	LIST(APPEND PACK_SOURCE_IGNORE_FILES "/${FEDPKG_DIR}/")

	SET(FEDPKG_DIR "${CMAKE_BINARY_DIR}/FedPkg" CACHE PATH "FedPkg dir")
	FILE(MAKE_DIRECTORY ${FEDPKG_DIR})

	## Fedora package variables
	SET(FEDORA_KARMA "3" CACHE STRING "Fedora Karma")
	SET(FEDORA_UNSTABLE_KARMA "3" CACHE STRING "Fedora unstable Karma")
	SET(FEDORA_AUTO_KARMA "True" CACHE STRING "Fedora auto Karma")
    ENDIF(_manage_release_on_fedora_dependencies_missing  EQUAL 0)

    FUNCTION(MANAGE_RELEASE_ADD_KOJI_TARGETS prefix ver)
	IF(_manage_release_on_fedora_dependencies_missing 0)
	    FIND_PROGRAM(KOJI_CMD koji)
	    IF(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")
		M_MSG(${M_OFF} "Program koji is not found! Koji support disabled.")
	    ELSE(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")

		IF("${prefix}" STREQUAL "f")
		    SET(_koji_target "f${ver}${FEDORA_KOJI_TAG_POSTFIX}")
		ELSE("${prefix}" STREQUAL "f")
		    SET(_koji_target "el${ver}${EPEL_KOJI_TAG_POSTFIX}")
		ENDIF("${prefix}" STREQUAL "f")

		SET(_koji_tag_path_abs_prefix
		    "${CMAKE_FEDORA_TMP_DIR}")

		SET(_koji_tag_name_prefix "${PRJ_VER}-${PRJ_RELEASE_NO}.${_koji_target}")

		SET(_koji_tag_build_scratch_file
		    "${_koji_tag_path_abs_prefix}/${_koji_tag_name_prefix}.build_scratch")

		ADD_CUSTOM_TARGET_COMMAND(koji_${_branch}_build_scratch
		    OUTPUT "${_koji_tag_build_scratch_file}"
		    COMMAND ${KOJI_CMD} build "--scratch" "${_koji_target}" "${PRJ_SRPM}"
		    DEPENDS "${PRJ_SRPM}"
		    COMMENT "koji scratch build on ${_koji_target}"
		    VERBATIM
		    )
	    ENDIF(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")
	ENDIF(_manage_release_on_fedora_dependencies_missing 0)
    ENDFUNCTION(MANAGE_RELEASE_ADD_KOJI_TARGETS prefix ver)

    FUNCTION(MANAGE_RELEASE_ADD_FEDPKG_TARGETS prefix ver)
	IF(_manage_release_on_fedora_dependencies_missing 0)
	    SET(_tag "${prefix}${ver}")
	    SET(_branch ${_tag})
	    IF("${ver}" STREQUAL "${FEDORA_RAWHIDE_VER}")
		SET(_branch "master")
	    ENDIF("${ver}" STREQUAL "${FEDORA_RAWHIDE_VER}")

	    IF("${prefix}" STREQUAL "f")
		SET(_bodhi_tag "fc${ver}")
	    ELSE("${prefix}" STREQUAL "f")
		SET(_bodhi_tag "el${ver}")
	    ENDIF("${prefix}" STREQUAL "f")

	    SET(_fedpkg_tag_path_abs_prefix
		"${FEDPKG_DIR}/.git/refs/tags")

	    SET(_fedpkg_tag_name_prefix "${PRJ_VER}-${PRJ_RELEASE_NO}.${_bodhi_tag}")

	    ## Fedpkg import and commit
	    SET(_import_opt "")
	    IF(NOT ver EQUAL FEDORA_RAWHIDE_VER)
		SET(_import_opt "-b ${_tag}")
	    ENDIF(NOT ver EQUAL FEDORA_RAWHIDE_VER)

	    #Commit summary
	    IF (DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m" "\"${CHANGE_SUMMARY}\"")
	    ELSE(DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m"  "\"On releasing ${PRJ_VER}-${PRJ_RELEASE_NO}\"")
	    ENDIF(DEFINED CHANGE_SUMMARY)
	    # Depends on tag file instead of target "tag"
	    # To avoid excessive scratch build and rpmlint
	    SET(_commit_opt --push --tag "${COMMIT_MSG}")

	    SET(_fedpkg_tag_commit_file
		"${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_prefix}.commit")

	    ADD_CUSTOM_TARGET_COMMAND(fedpkg_${_branch}_commit
		OUTPUT "${_fedpkg_tag_commit_file}"
		COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		COMMAND ${GIT_CMD} pull --tag
		COMMAND ${FEDPKG_CMD} import "${PRJ_SRPM}"
		COMMAND ${FEDPKG_CMD} commit ${_commit_opt}
		COMMAND ${GIT_CMD} push --tags
		DEPENDS ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE} "${PRJ_SRPM}"
		WORKING_DIRECTORY ${FEDPKG_DIR}
		COMMENT "fedpkg commit on ${_branch} with ${PRJ_SRPM}"
		VERBATIM
		)

	    ## Fedpkg build
	    SET(_fedpkg_tag_build_file
		"${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_prefix}.build")

	    ADD_CUSTOM_TARGET_COMMAND(fedpkg_${_branch}_build
		OUTPUT "${_fedpkg_tag_build_file}"
		COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		COMMAND ${FEDPKG_CMD} build
		COMMAND ${GIT_CMD} tag -a -m "${_fedpkg_tag_name_prefix} built"
		COMMAND ${GIT_CMD} push --tags
		DEPENDS ${_fedpkg_tag_commit_file}
		WORKING_DIRECTORY ${FEDPKG_DIR}
		COMMENT "fedpkg build on ${_branch}"
		VERBATIM
		)

	    ## Fedpkg build
	    SET(_fedpkg_tag_update_file
		"${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_prefix}.update")

	    ADD_CUSTOM_TARGET_COMMAND(fedpkg_${_branch}_update
		OUTPUT "${_fedpkg_tag_update_file}"
		COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		COMMAND ${FEDPKG_CMD} build
		COMMAND ${GIT_CMD} tag -a -m "${_fedpkg_tag_name_prefix} updated"
		COMMAND ${GIT_CMD} push --tags
		DEPENDS ${_fedpkg_tag_build_file}
		WORKING_DIRECTORY ${FEDPKG_DIR}
		COMMENT "fedpkg build on ${_branch}"
		VERBATIM
		)

	ENDIF(_manage_release_on_fedora_dependencies_missing 0)
    ENDFUNCTION(MANAGE_RELEASE_ADD_TARGETS tag)

    FUNCTION(MANAGE_RELEASE_ON_FEDORA)
	IF(_manage_release_on_fedora_dependencies_missing 0)
	    ## Parse tags
	    SET(_build_list ${FEDORA_RAWHIDE_VER})
	    FOREACH(_rel ${ARGN})
		IF(_rel STREQUAL "fedora")
		    LIST(APPEND _build_list ${FEDORA_SUPPORTED_RELEASE_TAGS})
		ELSE(_rel STREQUAL "fedora")
		    LIST(APPEND _build_list ${_rel}
		ENDIF(_rel STREQUAL "fedora")
	    ENDFOREACH(_rel ${ARGN})

	    ## Create targets
	    FOREACH(_ver ${_build_list})
		MANAGE_RELEASE_ADD_FEDPKG_TARGETS("f${_ver}")
		MANAGE_RELEASE_ADD_KOJI_TARGETS("f${_ver}")
	    ENDFOREACH(_ver ${_build_list})
	ENDIF(_manage_release_on_fedora_dependencies_missing 0)
    ENDFUNCTION(MANAGE_RELEASE_ON_FEDORA)

	SET(_FEDORA_BUILD_TAGS "")

	MACRO(_manange_release_on_fedora_parse_args)
	    SET(_FEDORA_KARMA "3")
	    SET(_FEDORA_AUTO_KARMA "True")
	    SET(_FEDORA_KOJI_SCRATCH 1)
	    SET(_FEDORA_BUILD_LIST "")
	    SET(_FEDORA_BUILD_TAGS "")

	    SET(_stage "")
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "NOKOJI_SCRATCH_BUILD")
		    SET(_FEDORA_KOJI_SCRATCH 0)
		ELSEIF(_arg STREQUAL "KARMA")
		    SET(_stage "KARMA")
		ELSEIF(_arg STREQUAL "TAGS")
		    IF(NOT "${FEDORA_RELEASE_TAGS}" STREQUAL "")
			# No need to further parsing TAGS, as FEDORA_RELEASE_TAGS
			# override whatever specified after TAGS
			BREAK()
		    ENDIF(NOT "${FEDORA_RELEASE_TAGS}" STREQUAL "")
		    SET(_stage "TAGS")
		ELSE(_arg STREQUAL "NOKOJI_SCRATCH_BUILD")
		    IF(_stage STREQUAL "KARMA")
			IF(_arg STREQUAL "0")
			    SET(_FEDORA_AUTO_KARMA "False")
			ENDIF(_arg STREQUAL "0")
			SET(_FEDORA_KARMA ${_arg})
		    ELSEIF(_stage STREQUAL "TAGS")
			LIST(APPEND _FEDORA_BUILD_LIST "${_arg}")
		    ELSE(_stage STREQUAL "TAGS")
			SET(_FEDORA_SRPM ${_arg})
		    ENDIF(_stage STREQUAL "KARMA")
		ENDIF(_arg STREQUAL "NOKOJI_SCRATCH_BUILD")
	    ENDFOREACH(_arg ${ARGN})

	    # Expend tags to build
	    IF(NOT "${FEDORA_RELEASE_TAGS}" STREQUAL "")
		SET(_FEDORA_BUILD_LIST ${FEDORA_RELEASE_TAGS})
	    ELSEIF(_FEDORA_BUILD_LIST STREQUAL "")
		LIST(APPEND _FEDORA_BUILD_LIST )
	    ENDIF(NOT "${FEDORA_RELEASE_TAGS}" STREQUAL "")

	    FOREACH(_tag ${_FEDORA_BUILD_LIST})
		IF("${_tag}" STREQUAL "fedora")
		    LIST(APPEND _FEDORA_BUILD_TAGS ${FEDORA_CURRENT_RELEASE_TAGS})
		ELSEIF("${_tag}" STREQUAL "epel")
		    LIST(APPEND _FEDORA_BUILD_TAGS ${EPEL_SUPPORTED_RELEASE_TAGS})
		ELSE("${_tag}" STREQUAL "fedora")
		    LIST(APPEND _FEDORA_BUILD_TAGS "${_tag}")
		ENDIF("${_tag}" STREQUAL "fedora")
	    ENDFOREACH(_tag ${_FEDORA_BUILD_LIST})

	    SET(_FEDORA_STABLE_KARMA "${_FEDORA_KARMA}")
	    SET(_FEDORA_UNSTABLE_KARMA "-${_FEDORA_KARMA}")
	ENDMACRO(_manange_release_on_fedora_parse_args)

	MACRO(USE_KOJI srpm)
	    SET(_dependencies_missing 0)
	    FIND_PROGRAM(KOJI_CMD koji)
	    IF(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")
		M_MSG(${M_OFF} "Program koji is not found! Koji support disabled.")
		SET(_dependencies_missing 1)
	    ENDIF(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")
	    FIND_PROGRAM(KOJI_BUILD_SCRATCH_CMD ${KOJI_BUILD_SCRATCH}
		"${CMAKE_BINARY_DIR}/scripts" "${CMAKE_SOURCE_DIR}/scripts")
	    IF(KOJI_BUILD_SCRATCH_CMD STREQUAL "KOJI_BUILD_SCRATCH_CMD-NOTFOUND")
		M_MSG(${M_OFF} "Program ${KOJI_BUILD_SCRATCH} is not found! Koji support disabled.")
		SET(_dependencies_missing 1)
	    ENDIF(KOJI_BUILD_SCRATCH_CMD STREQUAL "KOJI_BUILD_SCRATCH_CMD-NOTFOUND")


	    IF(_dependencies_missing EQUAL 0)
		IF(_FEDORA_BUILD_TAGS STREQUAL "")
		    _manange_release_on_fedora_parse_args(${ARGN})
		ENDIF(_FEDORA_BUILD_TAGS STREQUAL "")


		IF(_FEDORA_KOJI_SCRATCH EQUAL 1)
		    ADD_CUSTOM_TARGET(koji_scratch_build
			COMMAND ${KOJI_BUILD_SCRATCH_CMD} ${srpm} ${_FEDORA_BUILD_TAGS}
			COMMENT "koji scratch builds"
			)

		    ADD_DEPENDENCIES(koji_scratch_build rpmlint)
		    # Ensure package build in koji before tag
		    ADD_DEPENDENCIES(tag koji_scratch_build)

		    FOREACH(_tag ${_FEDORA_BUILD_TAGS})
			ADD_CUSTOM_TARGET(koji_scratch_build_${_tag}
			    COMMAND ${KOJI_BUILD_SCRATCH_CMD} ${srpm} ${_tag}
			    COMMENT "koji scratch builds on ${_tag}"
			    )
		    ENDFOREACH(_tag ${_FEDORA_BUILD_TAGS})
		ENDIF(_FEDORA_KOJI_SCRATCH EQUAL 1)
	    ENDIF(_dependencies_missing EQUAL 0)
	ENDMACRO(USE_KOJI srpm)

	MACRO(_use_fedpkg_make_targets srpm)
	    #Commit summary
	    IF (DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m \"${CHANGE_SUMMARY}\"")
	    ELSE(DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m \"On releasing ${PRJ_VER}-${PRJ_RELEASE_NO}\"")
	    ENDIF(DEFINED CHANGE_SUMMARY)

	    SET(_fedpkg_tag_path_abs_prefix
		"${FEDPKG_WORKDIR}/.git/refs/tags")
	    FOREACH(_tag ${_FEDORA_BUILD_TAGS})
		IF(_tag STREQUAL FEDORA_RAWHIDE_TAG)
		    SET(_branch "master")
		ELSE(_tag STREQUAL FEDORA_RAWHIDE_TAG)
		    SET(_branch "${_tag}")
		ENDIF(_tag STREQUAL FEDORA_RAWHIDE_TAG)

		_use_bodhi_convert_tag(_bodhi_tag "${_tag}")

		SET(_fedpkg_tag_name_prefix "${PRJ_VER}-${PRJ_RELEASE_NO}.${_bodhi_tag}")
		#MESSAGE("_fedpkg_tag_name_prefix=${_fedpkg_tag_name_prefix}")
		SET(_scratch_build_stamp
		    "${CMAKE_FEDORA_TMP_DIR}/${PRJ_VER}_scratch_build_${_tag}")


		ADD_CUSTOM_TARGET(fedpkg_scratch_build_${_tag}
		    DEPENDS ${_scratch_build_stamp}
		    )

		ADD_CUSTOM_COMMAND(OUTPUT ${_scratch_build_stamp}
		    COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		    COMMAND ${FEDPKG_CMD} scratch-build --srpm ${srpm}
		    COMMAND ${CMAKE_COMMAND} -E touch ${_scratch_build_stamp}
		    DEPENDS ${CMAKE_FEDORA_TMP_DIR} ${srpm}
		    WORKING_DIRECTORY ${FEDPKG_WORKDIR}
		    COMMENT "fedpkg scratch build on ${_branch} with ${srpm}"
		    )
		ADD_DEPENDENCIES(fedpkg_scratch_build_${_tag} rpmlint)
		ADD_DEPENDENCIES(fedpkg_scratch_build fedpkg_scratch_build_${_tag})

		# koji_scratch_build is preferred before tag,
		# otherwise, use fedpkg_scratch_build instead
		IF(NOT TARGET koji_scratch_build)
		    ADD_DEPENDENCIES(tag fedpkg_scratch_build)
		ENDIF(NOT TARGET koji_scratch_build)

		## fedpkg import
		SET(_import_opt "")
		IF(NOT _tag STREQUAL FEDORA_RAWHIDE_TAG)
		    SET(_import_opt "-b ${_tag}")
		ENDIF(NOT _tag STREQUAL FEDORA_RAWHIDE_TAG)


		## fedpkg commit and push
		# Depends on tag file instead of target "tag"
		# To avoid excessive scratch build and rpmlint
		SET(_commit_opt --push --tag "${COMMIT_MSG}")
		SET(_fedpkg_tag_name_committed
		    "${_fedpkg_tag_name_prefix}.committed")
		ADD_CUSTOM_COMMAND(OUTPUT
		    ${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_committed}
		    COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		    COMMAND ${FEDPKG_CMD} pull
		    COMMAND ${FEDPKG_CMD} import ${_import_opt} ${srpm}
		    COMMAND ${FEDPKG_CMD} commit ${_commit_opt}
		    COMMAND ${GIT_CMD} push --tags
		    DEPENDS ${FEDPKG_WORKDIR} ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE} ${srpm}
		    WORKING_DIRECTORY ${FEDPKG_WORKDIR}
		    COMMENT "fedpkg commit on ${_branch} with ${srpm}"
		    VERBATIM
		    )

		ADD_CUSTOM_TARGET(fedpkg_commit_${_tag}
		    DEPENDS ${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_committed}
		    )
		ADD_DEPENDENCIES(fedpkg_commit fedpkg_commit_${_tag})

		## fedpkg build
		SET(_fedpkg_tag_name_built
		    "${_fedpkg_tag_name_prefix}.built")
		ADD_CUSTOM_COMMAND(OUTPUT
		    ${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_built}
		    COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		    COMMAND ${FEDPKG_CMD} build
		    COMMAND ${GIT_CMD} tag -a -m "${_fedpkg_tag_name_prefix} built"
		    ${_fedpkg_tag_name_built}
		    COMMAND ${GIT_CMD} push --tags
		    WORKING_DIRECTORY ${FEDPKG_WORKDIR}
		    COMMENT "fedpkg build on ${_branch}"
		    VERBATIM
		    )

		ADD_CUSTOM_TARGET(fedpkg_build_${_tag}
		    DEPENDS ${_fedpkg_tag_path_abs_prefix}/${_fedpkg_tag_name_built}
		    )

		ADD_DEPENDENCIES(fedpkg_build_${_tag} fedpkg_commit_${_tag})
		ADD_DEPENDENCIES(fedpkg_build fedpkg_build_${_tag})

		ADD_CUSTOM_TARGET(fedpkg_update_${_tag}
		    COMMAND ${FEDPKG_CMD} update
		    WORKING_DIRECTORY ${FEDPKG_WORKDIR}/${PROJECT_NAME}
		    DEPENDS ${_first_tag_path}
		    COMMENT "fedpkg update on ${_branch} with ${srpm}"
		    )
		ADD_DEPENDENCIES(fedpkg_update_${_tag} fedpkg_build_${_tag})
		ADD_DEPENDENCIES(fedpkg_update fedpkg_update_${_tag})
	    ENDFOREACH(_tag ${_FEDORA_BUILD_TAGS})
	ENDMACRO(_use_fedpkg_make_targets srpm)

	MACRO(USE_FEDPKG srpm)
	    SET(_dependencies_missing 0)

	    IF(NOT EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
		M_MSG(${M_OFF}
		    "\$HOME/.fedora-upload-ca.cert not found, fedpkg support disabled")
		SET(_dependencies_missing 1)
	    ENDIF(NOT EXISTS $ENV{HOME}/.fedora-upload-ca.cert)

	    FIND_PROGRAM(FEDPKG_CMD fedpkg)
	    IF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")
		M_MSG(${M_OFF} "Program fedpkg is not found! fedpkg support disabled.")
		SET(_dependencies_missing 1)
	    ENDIF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")

	    IF(_dependencies_missing EQUAL 0)
		IF(_FEDORA_BUILD_TAGS STREQUAL "")
		    _manange_release_on_fedora_parse_args(${ARGN})
		ENDIF(_FEDORA_BUILD_TAGS STREQUAL "")

		SET(FEDPKG_DIR_ABS ${CMAKE_BINARY_DIR}/${FEDPKG_DIR})
		SET(FEDPKG_WORKDIR ${FEDPKG_DIR_ABS}/${PROJECT_NAME})
		ADD_CUSTOM_COMMAND(OUTPUT ${FEDPKG_DIR_ABS}
		    COMMAND mkdir -p ${FEDPKG_DIR_ABS}
		    )

		ADD_CUSTOM_COMMAND(OUTPUT ${FEDPKG_WORKDIR}
		    COMMAND ${FEDPKG_CMD} clone ${PROJECT_NAME}
		    DEPENDS ${FEDPKG_DIR_ABS}
		    WORKING_DIRECTORY ${FEDPKG_DIR_ABS}
		    )

		ADD_CUSTOM_TARGET(fedpkg_clone
		    DEPENDS ${FEDPKG_WORKDIR}
		    )

		ADD_CUSTOM_TARGET(fedpkg_scratch_build
		    COMMENT "fedpkg scratch build"
		    )
		ADD_CUSTOM_TARGET(fedpkg_import
		    COMMENT "fedpkg import"
		    )
		ADD_CUSTOM_TARGET(fedpkg_commit
		    COMMENT "fedpkg commit and push"
		    )
		ADD_CUSTOM_TARGET(fedpkg_build
		    COMMENT "fedpkg build"
		    )

		ADD_CUSTOM_TARGET(fedpkg_update
		    COMMENT "fedpkg update"
		    )
		## Make target commands for the released dist
		_use_fedpkg_make_targets("${srpm}")
	    ENDIF(_dependencies_missing EQUAL 0)
	ENDMACRO(USE_FEDPKG srpm)

	# Convert fedora koji tag to bodhi tag
	MACRO(_use_bodhi_convert_tag tag_out tag_in)
	    STRING(REGEX REPLACE "f([0-9]+)" "fc\\1" _tag_replace "${tag_in}")
	    IF(_tag_replace STREQUAL "")
		IF("${tag_in}" STREQUAL "${FEDORA_RAWHIDE_TAG}")
		    SET(${tag_out} "fc${FEDORA_RAWHIDE_VERSION}")
		ELSE("${tag_in}" STREQUAL "${FEDORA_RAWHIDE_TAG}")
		    SET(${tag_out} ${tag_in})
		ENDIF("${tag_in}" STREQUAL "${FEDORA_RAWHIDE_TAG}")
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
	    SET(_dependencies_missing 0)
	    IF(NOT EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
		M_MSG(${M_OFF}
		    "\$HOME/.fedora-upload-ca.cert not found, bodhi support disabled")
		SET(_dependencies_missing 1)
	    ENDIF(NOT EXISTS $ENV{HOME}/.fedora-upload-ca.cert)
	    FIND_PROGRAM(BODHI_CMD bodhi)
	    IF(BODHI_CMD STREQUAL "BODHI_CMD-NOTFOUND")
		M_MSG(${M_OFF} "Program bodhi is not found! bodhi support disabled.")
		SET(_dependencies_missing 1)
	    ENDIF(BODHI_CMD STREQUAL "BODHI_CMD-NOTFOUND")

	    IF(_dependencies_missing EQUAL 0)
		IF(_FEDORA_STABLE_KARMA STREQUAL "")
		    _manange_release_on_fedora_parse_args(${ARGN})
		ENDIF(_FEDORA_STABLE_KARMA STREQUAL "")

		FILE(REMOVE ${BODHI_TEMPLATE_FILE})
		FOREACH(_tag ${_FEDORA_BUILD_TAGS})
		    IF(NOT _tag STREQUAL ${FEDORA_RAWHIDE_TAG})
			_use_bodhi_convert_tag(_bodhi_tag ${_tag})

			FILE(APPEND ${BODHI_TEMPLATE_FILE} "[${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE_NO}.${_bodhi_tag}]\n\n")

			IF(BODHI_UPDATE_TYPE)
			    FILE(APPEND ${BODHI_TEMPLATE_FILE} "type=${BODHI_UPDATE_TYPE}\n\n")
			ELSE(BODHI_UPDATE_TYPE)
			    FILE(APPEND ${BODHI_TEMPLATE_FILE} "type=bugfix\n\n")
			ENDIF(BODHI_UPDATE_TYPE)

			FILE(APPEND ${BODHI_TEMPLATE_FILE} "request=testing\n")
			FILE(APPEND ${BODHI_TEMPLATE_FILE} "bugs=${REDHAT_BUGZILLA}\n")

			_append_notes(${BODHI_TEMPLATE_FILE})

			FILE(APPEND ${BODHI_TEMPLATE_FILE} "autokarma=${_FEDORA_AUTO_KARMA}\n")
			FILE(APPEND ${BODHI_TEMPLATE_FILE} "stable_karma=${_FEDORA_STABLE_KARMA}\n")
			FILE(APPEND ${BODHI_TEMPLATE_FILE} "unstable_karma=${_FEDORA_UNSTABLE_KARMA}\n")
			FILE(APPEND ${BODHI_TEMPLATE_FILE} "close_bugs=True\n")

			IF(SUGGEST_REBOOT)
			    FILE(APPEND ${BODHI_TEMPLATE_FILE} "suggest_reboot=True\n")
			ELSE(SUGGEST_REBOOT)
			    FILE(APPEND ${BODHI_TEMPLATE_FILE} "suggest_reboot=False\n\n")
			ENDIF(SUGGEST_REBOOT)
		    ENDIF(NOT _tag STREQUAL ${FEDORA_RAWHIDE_TAG})
		ENDFOREACH(_tag ${_FEDORA_BUILD_TAGS})

		IF(BODHI_USER)
		    SET(_bodhi_login "-u ${BODHI_USER}")
		ENDIF(BODHI_USER)

		ADD_CUSTOM_TARGET(bodhi_new
		    COMMAND ${BODHI_CMD} --new ${_bodhi_login} --file ${BODHI_TEMPLATE_FILE}
		    COMMENT "Send new package to bodhi"
		    VERBATIM
		    )

		IF(TARGET fedpkg_build)
		    ADD_DEPENDENCIES(bodhi_new fedpkg_build)
		ENDIF(TARGET fedpkg_build)
	    ENDIF(_dependencies_missing EQUAL 0)
	ENDMACRO(USE_BODHI)

	MACRO(RELEASE_ON_FEDORA srpm)
	    IF(TARGET release)
		USE_KOJI(${srpm} ${ARGN})
		USE_FEDPKG(${srpm} ${ARGN})
		USE_BODHI(${ARGN})
		ADD_CUSTOM_TARGET(release_on_fedora)
		ADD_DEPENDENCIES(release release_on_fedora)
		# Release should release in rawhide, which is not included in bodhi_new
		ADD_DEPENDENCIES(release_on_fedora bodhi_new fedpkg_build_${FEDORA_RAWHIDE_TAG})
	    ELSE(TARGET release)
		M_MSG(${M_OFF} "ManageReleaseOnFedora: maintainer file is invalid, disable release targets" )
	    ENDIF(TARGET release)
	ENDMACRO(RELEASE_ON_FEDORA srpm)



ENDIF(NOT DEFINED _MANAGE_RELEASE_ON_FEDORA_)

