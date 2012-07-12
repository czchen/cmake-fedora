# - RPM generation, maintaining (remove old rpm) and verification (rpmlint).
# This module provides macros that provides various rpm building and
# verification targets.
#
# Includes:
#   ManageMessage
#   ManageVariable
#   PackSource
#
# Reads following variables:
#
# Reads and defines following variables if dependencies are satisfied:
#   RPM_SPEC_IN_FILE: spec.in that generate spec
#   RPM_SPEC_FILE: spec file for rpmbuild.
#   RPM_SRPM_FILE: Source RPM of the project
#   RPM_SR
#   RPM_DIST_TAG: (optional) Current distribution tag such as el5, fc10.
#     Default: Distribution tag from rpm --showrc
#
#   RPM_BUILD_TOPDIR: (optional) Directory of  the rpm topdir.
#     Default: ${CMAKE_BINARY_DIR}
#
#   RPM_BUILD_SPECS: (optional) Directory of generated spec files
#     and RPM-ChangeLog.
#     Note this variable is not for locating
#     SPEC template (project.spec.in), RPM-ChangeLog source files.
#     These are located through the path of spec_in.
#     Default: ${RPM_BUILD_TOPDIR}/SPECS
#
#   RPM_BUILD_SOURCES: (optional) Directory of source (tar.gz or zip) files.
#     Default: ${RPM_BUILD_TOPDIR}/SOURCES
#
#   RPM_BUILD_SRPMS: (optional) Directory of source rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/SRPMS
#
#   RPM_BUILD_RPMS: (optional) Directory of generated rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/RPMS
#
#   RPM_BUILD_BUILD: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILD
#
#   RPM_BUILD_BUILDROOT: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILDROOT
#
# Defines following variables:
#   RPM_IGNORE_FILES: A list of exclude file patterns for PackSource.
#     This value is appended to PACK_SOURCE_IGNORE_FILES after including
#     this module.
#
# Defines following Macros:
#   PACK_RPM(var spec_in sourcePackage [fileDependencies] )
#   - Generate spec and pack rpm  according to the spec file.
#     It needs variable from PackSource, so call P before cno need to call it manually,
#     note that environment variables for PackSource should be defined
#     before calling this macro.
#     Arguments:
#     + var: The filename of srpm is outputted to this var.
#            Path is excluded.
#     + spec_in: RPM spec file template.
#     + sourcePackage: Source package/tarball without path.
#       The sourcePackage should be in RPM_BUILD_SOURCES.
#     + fileDependencies: other files that rpm targets depends on.
#     Targets:
#     + srpm: Build srpm (rpmbuild -bs).
#     + rpm: Build rpm and srpm (rpmbuild -bb)
#     + rpmlint: Run rpmlint to generated rpms.
#     + clean_rpm": Clean all rpm and build files.
#     + clean_pkg": Clean all source packages, rpm and build files.
#     + clean_old_rpm: Remove old rpm and build files.
#     + clean_old_pkg: Remove old source packages and rpms.
#     This macro defines following variables:
#     + PRJ_RELEASE: Project release with distribution tags. (e.g. 1.fc13)
#     + PRJ_RELEASE_NO: Project release number, without distribution tags. (e.g. 1)
#     + PRJ_SRPM_PATH: Filename of generated SRPM file, including relative path.
#
#   USE_MOCK(spec_in)
#   - Add mock related targets.
#     Arguments:
#     + spec_in: RPM spec input template.
#     Targets:
#     + rpm_mock_i386: Make i386 rpm
#     + rpm_mock_x86_64: Make x86_64 rpm
#     This macor reads following variables?:
#     + MOCK_RPM_DIST_TAG: Prefix of mock configure file, such as "fedora-11", "fedora-rawhide", "epel-5".
#         Default: Convert from RPM_DIST_TAG
#

IF(NOT DEFINED _PACK_RPM_CMAKE_)
    SET (_PACK_RPM_CMAKE_ "DEFINED")

    INCLUDE(ManageMessage)
    INCLUDE(ManageTarget)
    SET(_manage_rpm_dependency_missing 0)

    FIND_PROGRAM(_RPMBUILD_CMD NAMES "rpmbuild-md5")
    IF("${_RPMBUILD_CMD}" STREQUAL "_RPMBUILD_CMD-NOTFOUND")
	M_MSG(${M_OFF} "rpmbuild is not found in PATH, rpm build support is disabled.")
	SET(_manage_rpm_dependency_missing 1)
	SET(RPMBUILD_CMD "" CACHE FILEPATH "rpmbuild")
    ENDIF("${_RPMBUILD_CMD}" STREQUAL "_RPMBUILD_CMD-NOTFOUND")
    SET(RPMBUILD_CMD "${_RPMBUILD_CMD}" CACHE FILEPATH "rpmbuild")

    IF(NOT RPM_SPEC_IN_FILE STREQUAL "")
	IF(NOT EXISTS ${RPM_SPEC_IN_FILE})
	    SET(RPM_SPEC_IN_FILE "" CACHE FILEPATH "spec.in")
	ENDIF(NOT EXISTS ${RPM_SPEC_IN_FILE})
    ENDIF(NOT RPM_SPEC_IN_FILE STREQUAL "")

    IF(RPM_SPEC_IN_FILE STREQUAL "")
	SET(_RPM_SPEC_IN_FILE_SEARCH_NAMES  "${PROJECT}.spec.in" "project.spec.in")
	SET(_RPM_SPEC_IN_FILE_SEARCH_PATH "${CMAKE_SOURCE_DIR}/SPECS" "SPECS" "." "${RPM_BUILD_TOPDIR}/SPECS")
	FIND_FILE(_RPM_SPEC_IN_FILE NAMES ${_RPM_SPEC_IN_FILE_SEARCH_NAMES} PATHS ${_RPM_SPEC_IN_FILE_SEARCH_PATH})
	IF(_RPM_SPEC_IN_FILE STREQUAL "_RPM_SPEC_IN_FILE-NOTFOUND")
	    M_MSG(${M_OFF} "Cannot find ${PROJECT}.spec.in or project .in"
		"${_RPM_SPEC_IN_FILE_SEARCH_PATH}")
	    M_MSG(${M_OFF} "rpm build support is disabled.")
	    SET(_manage_rpm_dependency_missing 1)
	    SET(RPM_SPEC_IN_FILE "" CACHE FILEPATH "spec.in" FORCE)
	    SET(RPMBUILD_CMD "" CACHE FILEPATH "rpmbuild")
	ELSE(_RPM_SPEC_IN_FILE STREQUAL "_RPM_SPEC_IN_FILE-NOTFOUND")
	    SET(RPM_SPEC_IN_FILE ${_RPM_SPEC_IN_FILE} CACHE FILEPATH "spec.in" FORCE)
	ENDIF(_RPM_SPEC_IN_FILE STREQUAL "_RPM_SPEC_IN_FILE-NOTFOUND")
    ENDIF(RPM_SPEC_IN_FILE STREQUAL "")
    SET(RPM_SPEC_IN_FILE "${RPM_SPEC_IN_FILE}" CACHE FILEPATH "spec.in" FORCE)

    IF(_manage_rpm_dependency_missing 0)
	INCLUDE(ManageVariable)
	INCLUDE(PackSource)
	SET (SPEC_FILE_WARNING "This file is generated, please modified the .spec.in file instead!")

	EXECUTE_PROCESS(COMMAND rpm --showrc
	    COMMAND grep -E "dist[[:space:]]*\\."
	    COMMAND sed -e "s/^.*dist\\s*\\.//"
	    COMMAND tr \\n \\t
	    COMMAND sed  -e s/\\t//
	    OUTPUT_VARIABLE _RPM_DIST_TAG)

	SET(RPM_DIST_TAG "${_RPM_DIST_TAG}" CACHE STRING "RPM Dist Tag")
	SET(RPM_BUILD_TOPDIR "${CMAKE_BINARY_DIR}" CACHE PATH "RPM topdir")
	SET(RPM_BUILD_SPECS "${RPM_BUILD_TOPDIR}" CACHE PATH "RPM SPECS dir")
	SET(RPM_BUILD_SOURCES "${RPM_BUILD_TOPDIR}/SOURCES" CACHE PATH "RPM SOURCES dir")
	SET(RPM_BUILD_SRPMS "${RPM_BUILD_TOPDIR}/SRPMS" CACHE PATH "RPM SRPMS dir")
	SET(RPM_BUILD_RPMS "${RPM_BUILD_TOPDIR}/RPMS" CACHE PATH "RPM RPMS dir")
	SET(RPM_BUILD_BUILD "${RPM_BUILD_TOPDIR}/BUILD" CACHE PATH "RPM BUILD dir")
	SET(RPM_BUILD_BUILDROOT "${RPM_BUILD_TOPDIR}/BUILDROOT" CACHE PATH "RPM BUILDROOT dir")

	## RPM spec.in and RPM-ChangeLog.prev
	SET(RPM_SPEC_FILE "${RPM_BUILD_SPECS}/${PROJECT_NAME}.spec" CACHE FILEPATH "spec")
	SET(RPM_SPEC_IN_FILE "${_RPM_SPEC_IN_FILE}" CACHE FILEPATH "spec.in")
	GET_FILENAME_COMPONENT(_RPM_SPEC_IN_DIR "${RPM_SPEC_IN_FILE}" PATH)
	SET(RPM_SPEC_IN_DIR "${_RPM_SPEC_IN_DIR}" CACHE INTERNAL "Dir contains spec.in")
	SET(RPM_CHANGELOG_PREV_FILE "${_RPMS_SPEC_IN_DIR}/RPM-ChangeLog.prev" CACHE INTERNAL "ChangeLog.prev for RPM")
	SET(RPM_CHANGELOG_FILE "${RPM_BUILD_SPECS}/RPM-ChangeLog" CACHE FILEPATH "ChangeLog for RPM")

	# Add RPM build directories in ignore file list.
	GET_FILENAME_COMPONENT(_rpm_build_sources_basename ${RPM_BUILD_SOURCES} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_srpms_basename ${RPM_BUILD_SRPMS} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_rpms_basename ${RPM_BUILD_RPMS} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_build_basename ${RPM_BUILD_BUILD} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_buildroot_basename ${RPM_BUILD_BUILDROOT} NAME)
	SET(RPM_IGNORE_FILES
	    "/${_rpm_build_sources_basename}/" "/${_rpm_build_srpms_basename}/" "/${_rpm_build_rpms_basename}/"
	    "/${_rpm_build_build_basename}/" "/${_rpm_build_buildroot_basename}/" "debug.*s.list")

	SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES}
	    ${RPM_IGNORE_FILES})

	SET(RPM_CHANGELOG_FILE "${CMAKE_BINARY_DIR}/${RPM_BUILD_SPECS}/RPM-ChangeLog" CACHE FILEPATH
	    "RPM-ChangeLog")
	SET(RPM_CHANGELOG_PREV_FILE "${CMAKE_SOURCE_DIR}/${RPM_BUILD_SPECS}/RPM-ChangeLog.prev" FILEPATH
	    "RPM-ChangeLog.prev")
    ENDIF(_manage_rpm_dependency_missing 0)

    FUNCTION(RPM_SPEC_IN_READ_FILE)
	SETTING_FILE_GET_VARIABLE(_releaseStr Release "${RPM_SPEC_IN_FILE}" ":")
	STRING(REPLACE "%{?dist}" ".${RPM_DIST_TAG}" _PRJ_RELEASE ${_releaseStr})
	STRING(REPLACE "%{?dist}" "" _PRJ_RELEASE_NO ${_releaseStr})
	#MESSAGE("_releaseTag=${_releaseTag} _releaseStr=${_releaseStr}")

	SET(PRJ_RELEASE ${_PRJ_RELEASE} CACHE STRING "Release with dist" FORCE)
	SET(PRJ_RELEASE_NO ${_PRJ_RELEASE_NO} CACHE STRING "Release w/o dist" FORCE)
	SET(PRJ_SRPM "${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE}.src.rpm" CACHE STRING "PRJ SRPM" FORCE)
	SET(PRJ_SRPM_FILE "${RPM_BUILD_SRPMS}/${PRJ_SRPM}" CACHE FILEPATH "PRJ SRPM File" FORCE)

	## GET BuildArch
	SETTING_FILE_GET_VARIABLE(_archStr BuildArch "${RPM_SPEC_IN_FILE}" ":")
	IF(NOT _archStr STREQUAL "noarch")
	    SET(_archStr ${CMAKE_HOST_SYSTEM_PROCESSOR})
	ENDIF(NOT _archStr STREQUAL "noarch")
	SET(RPM_BUILD_ARCH "${_archStr}" CACHE STRING "BuildArch")

	## Main rpm
	SET(PRJ_RPM_FILES "${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}/${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE}.${RPM_BUILD_ARCH}.rpm")

	## Obtains sub packages
	## [TODO]
    ENDFUNCTION(RPM_SPEC_IN_READ_FILE)

    MACRO(RPM_CHANGELOG_WRITE_FILE)
	INCLUDE(DateTimeFormat)

	FILE(WRITE ${RPM_CHANGELOG_FILE} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}-${PRJ_RELEASE_NO}")
	FILE(READ "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.this" _changeLog_items)

	FILE(APPEND ${RPM_CHANGELOG_FILE} "_changeLog_items\n\n")

	# Update RPM_ChangeLog
	# Use this instead of FILE(READ is to avoid error when reading '\'
	# character.
	EXECUTE_PROCESS(COMMAND cat "${RPM_CHANGELOG_PREV_FILE}"
	    OUTPUT_VARIABLE RPM_CHANGELOG_PREV
	    OUTPUT_STRIP_TRAILING_WHITESPACE)

	FILE(APPEND ${RPM_CHANGELOG_FILE} "${RPM_CHANGELOG_PREV}")

	ADD_CUSTOM_COMMAND(OUTPUT ${RPM_CHANGELOG_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${CHANGELOG_FILE} ${RPM_CHANGELOG_PREV_FILE}
	    COMMENT "Write ${RPM_CHANGELOG_FILE}"
	    VERBATIM
	    )
    ENDMACRO(RPM_CHANGELOG_WRITE_FILE)

    MACRO(PACK_RPM)
	IF(_manage_rpm_dependency_missing 0)
	    RPM_SPEC_IN_READ_FILE()
	    RPM_CHANGELOG_WRITE_FILE()

	    # Generate spec
	    CONFIGURE_FILE(${RPM_SPEC_IN_FILE} ${RPM_SPEC_FILE})

	    #-------------------------------------------------------------------
	    # RPM build commands and targets

	    ADD_CUSTOM_COMMAND(OUTPUT ${RPM_BUILD_BUILD}
		COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_BUILD}
		)

	    # Don't worry about SRPMS, RPMS and BUILDROOT, it will be created by rpmbuild
	    ADD_CUSTOM_TARGET_COMMAND(srpm
		OUTPUT ${PRJ_SRPM_FILE}
		COMMAND ${RPMBUILD_CMD} -bs ${RPM_SPEC_FILE}
		--define '_sourcedir ${RPM_BUILD_SOURCES}'
		--define '_builddir ${RPM_BUILD_BUILD}'
		--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
		--define '_rpmdir ${RPM_BUILD_RPMS}'
		--define '_specdir ${RPM_BUILD_SPECS}'
		DEPENDS ${RPM_SPEC_FILE}
		${RPM_BUILD_SOURCES}/${sourcePackage} ${fileDependencies}
		COMMENT "Building srpm"
		)

	    # RPMs (except SRPM)

	    ADD_CUSTOM_TARGET_COMMAND(rpm
		OUTPUT ${PRJ_RPM_FILES}
		COMMAND ${RPMBUILD_CMD} -bb  ${RPM_SPEC_FILE}
		--define '_sourcedir ${RPM_BUILD_SOURCES}'
		--define '_builddir ${RPM_BUILD_BUILD}'
		--define '_buildrootdir ${RPM_BUILD_BUILDROOT}'
		--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
		--define '_rpmdir ${RPM_BUILD_RPMS}'
		--define '_specdir ${RPM_BUILD_SPECS}'
		DEPENDS ${RPM_SPEC_FILE} ${RPM_SRPM_FILE}
		COMMENT "Building rpm"
		)


	    ADD_CUSTOM_TARGET(install_rpms
		COMMAND find ${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}
		-name '${PROJECT_NAME}*-${PRJ_VER}-${PRJ_RELEASE_NO}.*.${RPM_BUILD_ARCH}.rpm' !
		-name '${PROJECT_NAME}-debuginfo-${PRJ_RELEASE_NO}.*.${RPM_BUILD_ARCH}.rpm'
		-print -exec sudo rpm --upgrade --hash --verbose '{}' '\\;'
		DEPENDS ${PRJ_RPM_FILES}
		COMMENT "Install all rpms except debuginfo"
		)

	    ADD_CUSTOM_TARGET(rpmlint
		COMMAND find .
		-name '${PROJECT_NAME}*-${PRJ_VER}-${PRJ_RELEASE_NO}.*.rpm'
		-print -exec rpmlint '{}' '\\;'
		DEPENDS ${_prj_srpm_path} ${_prj_rpm_path}
		)

	    ADD_CUSTOM_TARGET(clean_old_rpm
		COMMAND find .
		-name '${PROJECT_NAME}*.rpm' ! -name '${PROJECT_NAME}*-${PRJ_VER}-${PRJ_RELEASE_NO}.*.rpm'
		-print -delete
		COMMAND find ${RPM_BUILD_BUILD}
		-path '${PROJECT_NAME}*' ! -path '${RPM_BUILD_BUILD}/${PROJECT_NAME}-${PRJ_VER}-*'
		-print -delete
		COMMENT "Cleaning old rpms and build."
		)

	    ADD_CUSTOM_TARGET(clean_old_pkg
		)

	    ADD_DEPENDENCIES(clean_old_pkg clean_old_rpm clean_old_pack_src)

	    ADD_CUSTOM_TARGET(clean_rpm
		COMMAND find . -name '${PROJECT_NAME}-*.rpm' -print -delete
		COMMENT "Cleaning rpms.."
		)
	    ADD_CUSTOM_TARGET(clean_pkg
		)

	    ADD_DEPENDENCIES(clean_rpm clean_old_rpm)
	    ADD_DEPENDENCIES(clean_pkg clean_rpm clean_pack_src)
	ENDIF(_manage_rpm_dependency_missing 0)
    ENDMACRO(PACK_RPM)

    MACRO(USE_MOCK)
	FIND_PROGRAM(MOCK_CMD mock)
	IF(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
	    M_MSG(${M_WARN} "mock is not found in PATH, mock support disabled.")
	ELSE(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
	    IF(NOT RPM_BUILD_ARCH STREQUAL "noarch")
		IF(NOT DEFINED MOCK_RPM_DIST_TAG)
		    STRING(REGEX MATCH "^fc([1-9][0-9]*)"  _fedora_mock_dist "${RPM_DIST_TAG}")
		    STRING(REGEX MATCH "^el([1-9][0-9]*)"  _el_mock_dist "${RPM_DIST_TAG}")

		    IF (_fedora_mock_dist)
			STRING(REGEX REPLACE "^fc([1-9][0-9]*)" "fedora-\\1" MOCK_RPM_DIST_TAG "${RPM_DIST_TAG}")
		    ELSEIF (_el_mock_dist)
			STRING(REGEX REPLACE "^el([1-9][0-9]*)" "epel-\\1" MOCK_RPM_DIST_TAG "${RPM_DIST_TAG}")
		    ELSE (_fedora_mock_dist)
			SET(MOCK_RPM_DIST_TAG "fedora-devel")
		    ENDIF(_fedora_mock_dist)
		ENDIF(NOT DEFINED MOCK_RPM_DIST_TAG)

		#MESSAGE ("MOCK_RPM_DIST_TAG=${MOCK_RPM_DIST_TAG}")
		SET(_prj_srpm_path "${RPM_BUILD_SRPMS}/${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE}.src.rpm")
		ADD_CUSTOM_TARGET(rpm_mock_i386
		    COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_RPMS}/i386
		    COMMAND ${MOCK_CMD} -r  "${MOCK_RPM_DIST_TAG}-i386" --resultdir="${RPM_BUILD_RPMS}/i386" ${RPM_SRPM_FILE}
		    DEPENDS ${RPM_SRPM_FILE}
		    )

		ADD_CUSTOM_TARGET(rpm_mock_x86_64
		    COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_RPMS}/x86_64
		    COMMAND ${MOCK_CMD} -r  "${MOCK_RPM_DIST_TAG}-x86_64" --resultdir="${RPM_BUILD_RPMS}/x86_64" ${RPM_SRPM_FILE}
		    DEPENDS ${RPM_SRPM_FILE}
		    )
	    ENDIF(NOT RPM_BUILD_ARCH STREQUAL "noarch")
	ENDIF(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")

    ENDMACRO(USE_MOCK)

ENDIF(NOT DEFINED _PACK_RPM_CMAKE_)

