# - Module for working with Fedora and EPEL releases.
#
# This module provides convenient targets and macros for Fedora and EPEL
# releases by using fedpkg, koji, and bodhi
#
# This module check following files for dependencies:
#  1. ~/.fedora-upload-ca.cert : Ensure it has certificate file to submit to Fedora.
#  2. fedpkg : Required to submit to fedora.
#  3. koji : Required to submit to fedora.
#  4. bodhi : Required to submit to fedora.
#
#  If on of above file is missing, this module will be skipped.
#
# This module read the supported release information from cmake-fedora.conf
# It finds cmake-fedora.conf in following order:
# 1. Current directory
# 2. Path as defined CMAKE_SOURCE_DIR
# 3. /etc/cmake-fedora.conf
#
# Includes:
#   ManageFile
#   ManageMessage
#   ManageTarget
#
# Defines following variables:
#    CMAKE_FEDORA_CONF: Path to cmake_fedora.conf
#    FEDPKG_CMD: Path to fedpkg
#    KOJI_CMD: Path to koji
#    GIT_CMD: Path to git
#    BODHI_CMD: Path to bodhi
#    KOJI_BUILD_SCRATCH_CMD: Path to koji-build-scratch
#    FEDPKG_DIR: Dir for FedPkg. It will use environment variable
#                FEDPKG_DIR, then use $CMAKE_BINARY_DIR/FedPkg.
#    FEDORA_KAMA: Fedora Karma. Default:3
#    FEDORA_UNSTABLE_KARMA: Fedora unstable Karma. Default:3
#    FEDORA_AUTO_KARMA: Whether to use fedora Karma system. Default:"True"
#
# Defines following functions:
#   RELEASE_FEDORA([scopeList])
#   - Release this project to specified Fedora and EPEL releases.
#     Arguments:
#     + scopeList: List of Fedora and EPEL release to be build.
        If not specif
#       E.g. "f18", "f17", "el7"
#       You can also specify "fedora" for fedora active nt releases,
#       and/or "epel" for EPEL current releases.
#
#     Reads following variables:
#     + PRJ_SRPM_FILE: Project SRPM
#     + FEDPKG_DIR: Directory for fedpkg checkout.
#       Default: FedPkg.
#     Reads and define following variables:
#     + FEDORA_RAWHIDE_VER: Numeric version of rawhide, such as 18
#     + FEDORA_SUPPORTED_VERS: Numeric versions of currently supported Fedora,
#       such as 17;16
#     + EPEL_SUPPORTED_VERS: Numeric versions of currently supported EPEL
#       since version 5. Such as 6;5
#     + FEDORA_KARMA: Karma for auto pushing.
#       Default: 3
#     + FEDORA_UNSTABLE_KARMA: Karma for auto unpushing.
#       Default: 3
#     + FEDORA_AUTO_KARMA: Whether to enable auto pushing/unpushing
#       Default: True
#     Defines following targets:
#     + release_fedora: Make necessary steps for releasing on fedora,
#       such as making source file tarballs, source rpms, build with fedpkg
#       and upload to bodhi.
#     + bodhi_new: Submit the package to bodhi
#     + fedpkg_<tag>_build: Build for tag
#     + fedpkg_<tag>_commit: Import, commit and push
#     + koji_build_scratch: Scratch build using koji
#
#

IF(NOT DEFINED _MANAGE_RELEASE_FEDORA_)
    SET(_MANAGE_RELEASE_FEDORA_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageFile)
    INCLUDE(ManageTarget)
    SET(_manage_release_fedora_dependencies_missing 0)
    SET(KOJI_BUILD_SCRATCH "koji-build-scratch" CACHE INTERNAL "Koji build scratch name")

    FIND_FILE(CMAKE_FEDORA_CONF cmake-fedora.conf "." "${CMAKE_SOURCE_DIR}" "${SYSCONF_DIR}")
    M_MSG(${M_INFO1} "CMAKE_FEDORA_CONF=${CMAKE_FEDORA_CONF}")
    IF("${CMAKE_FEDORA_CONF}" STREQUAL "CMAKE_FEDORA_CONF-NOTFOUND")
	M_MSG(${M_OFF} "cmake-fedora.conf cannot be found! Fedora release support disabled.")
	SET(_manage_release_fedora_dependencies_missing 1)
    ENDIF("${CMAKE_FEDORA_CONF}" STREQUAL "CMAKE_FEDORA_CONF-NOTFOUND")

    FIND_PROGRAM_ERROR_HANDLING(FEDPKG_CMD fedokg ${M_OFF} 
	ERROR_MSG " Fedora support disabled."
	ERROR_VAR _manage_release_fedora_dependencies_missing
    )

    FIND_PROGRAM_ERROR_HANDLING(KOJI_CMD koji ${M_OFF} 
        ERROR_MSG " Fedora support disabled."
        ERROR_VAR _manage_release_fedora_dependencies_missing
    )

    FIND_PROGRAM(GIT_CMD git)
    IF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program git is not found! Fedora support disabled.")
	SET(_manage_release_fedora_dependencies_missing 1)
    ENDIF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")

    FIND_PROGRAM(BODHI_CMD bodhi)
    IF(BODHI_CMD STREQUAL "BODHI_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program bodhi is not found! Bodhi support disabled.")
    ENDIF(BODHI_CMD STREQUAL "BODHI_CMD-NOTFOUND")

    FIND_PROGRAM(KOJI_BUILD_SCRATCH_CMD ${KOJI_BUILD_SCRATCH} PATHS ${CMAKE_BINARY_DIR}/scripts . )
    IF(KOJI_BUILD_SCRATCH_CMD STREQUAL "KOJI_BUILD_SCRATCH_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program koji_build_scratch is not found!")
    ENDIF(KOJI_BUILD_SCRATCH_CMD STREQUAL "KOJI_BUILD_SCRATCH_CMD-NOTFOUND")

    FIND_PROGRAM(CMAKE_FEDORA_KOJI_CMD "cmake-fedora-koji" PATHS ${CMAKE_BINARY_DIR}/scripts . )
    IF(CMAKE_FEDORA_KOJI_CMD STREQUAL "CMAKE_FEDORA_KOJI_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program koji_build_scratch is not found!")
    ENDIF(CMAKE_FEDORA_KOJI_CMD STREQUAL "CMAKE_FEDORA_KOJI_CMD-NOTFOUND")

    FIND_PROGRAM(CMAKE_FEDORA_FEDPKG_CMD "cmake-fedora-fedpkg" PATHS ${CMAKE_BINARY_DIR}/scripts . )
    IF(CMAKE_FEDORA_FEDPKG_CMD STREQUAL "CMAKE_FEDORA_FEDPKG_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program koji_build_scratch is not found!")
    ENDIF(CMAKE_FEDORA_FEDPKG_CMD STREQUAL "CMAKE_FEDORA_FEDPKG_CMD-NOTFOUND")

    ## Set variables
    IF(NOT _manage_release_fedora_dependencies_missing)
	# Set release tags according to CMAKE_FEDORA_CONF
	SETTING_FILE_GET_ALL_VARIABLES(${CMAKE_FEDORA_CONF})


	SET(BODHI_TEMPLATE_FILE "${CMAKE_FEDORA_TMP_DIR}/bodhi.template"
	    CACHE FILEPATH "Bodhi template file"
	)

    GET_ENV(FEDPKG_DIR "${CMAKE_BINARY_DIR}/FedPkg" CACHE PATH "FedPkg dir")

	GET_FILENAME_COMPONENT(_FEDPKG_DIR_NAME ${FEDPKG_DIR} NAME)
	LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES "/${_FEDPKG_DIR_NAME}/")

	## Fedora package variables
	SET(FEDORA_KARMA "3" CACHE STRING "Fedora Karma")
	SET(FEDORA_UNSTABLE_KARMA "-3" CACHE STRING "Fedora unstable Karma")
	SET(FEDORA_AUTO_KARMA "True" CACHE STRING "Fedora auto Karma")

	SET(FEDPKG_PRJ_DIR "${FEDPKG_DIR}/${PROJECT_NAME}")

	## Don't use what is in git, otherwise it will be cleaned
	## By make clean
	SET(FEDPKG_PRJ_DIR_GIT "${FEDPKG_PRJ_DIR}/.git/.cmake-fedora")
    ENDIF(NOT _manage_release_fedora_dependencies_missing)

    FUNCTION(RELEASE_FEDORA_KOJI_BUILD_SCRATCH)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    ADD_CUSTOM_TARGET(koji_build_scratch
		COMMAND ${KOJI_BUILD_SCRATCH_CMD} ${PRJ_SRPM_FILE} ${ARGN}
		DEPENDS "${PRJ_SRPM_FILE}"
		COMMENT "koji scratch build on ${PRJ_SRPM_FILE}"
		VERBATIM
		)
	ENDIF(NOT _manage_release_fedora_dependencies_missing)
	ADD_DEPENDENCIES(koji_build_scratch rpmlint)
	ADD_DEPENDENCIES(tag_pre koji_build_scratch)
    ENDFUNCTION(RELEASE_FEDORA_KOJI_BUILD_SCRATCH)

    FUNCTION(RELEASE_FEDORA_FEDPKG)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    IF(NOT DEFINED MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE)
		M_MSG($M_ERROR "Undefined MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE, please use MANAGE_SOURCE_VERSION_CONTROL_GIT or other source version control")
	    ENDIF(NOT DEFINED MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE)
	    IF (DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m" "${CHANGE_SUMMARY}")
	    ELSE(DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m"  "On releasing ${PRJ_VER}-${PRJ_RELEASE_NO}")
	    ENDIF(DEFINED CHANGE_SUMMARY)
	    ADD_CUSTOM_TARGET(fedpkg_build
		COMMAND $CMAKE_FEDORA_FEDPKG -d $FEDPKG_DIR 
		$COMMIT_MSG $PRJ_SRPM_FILE $ARGN
		DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    )
	ENDIF(NOT _manage_release_fedora_dependencies_missing)
    ENDFUNCTION(RELEASE_FEDORA_FEDPKG)

    FUNCTION(RELEASE_FEDORA)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    ## Parse tags
	    SET(_scope_list ${ARGN})
	    RELEASE_FEDORA_KOJI_BUILD_SCRATCH(${_scope_list})
	    RELEASE_FEDORA_FEDPKG(${_scope_list})
	    ADD_CUSTOM_TARGET(release_fedora
		COMMENT "Release for Fedora")
	    ADD_DEPENDENCIES(release_fedora fedpkg_build)
	    ADD_DEPENDENCIES(release release_fedora)
	ENDIF(NOT _manage_release_fedora_dependencies_missing)
    ENDFUNCTION(RELEASE_FEDORA)
ENDIF(NOT DEFINED _MANAGE_RELEASE_FEDORA_)

