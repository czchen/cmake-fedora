cmake_minimum_required(VERSION 2.6.2)

# CMP0011 should be set here, otherwise policy set in module won't affect
# here.
CMAKE_POLICY(SET CMP0011 OLD)

# Default CMAKE_INSTALL_PREFIX should be set before PROJECT()
SET(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install dir prefix")

####################################################################
# Project specific information
#
PROJECT(cmake-fedora NONE)
SET(PRJ_SUMMARY "CMake helper modules for fedora developers")

SET(PRJ_DESCRIPTION
"cmake-fedora consist a set of cmake modules that provides
helper macros and targets for fedora developers."
    )
SET(AUTHORS "Ding-Yi Chen")
SET(MAINTAINER "Ding-Yi Chen <dchen at redhat.com>")
SET(VENDOR "Red Hat, APAC, Inc.")
SET(LICENSE BSD)

####################################################################
# Includes
#
SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/Modules ${CMAKE_ROOT}/Modules )
INCLUDE(ManageEnvironment RESULT_VARIABLE MANAGE_ENVIRONMENT_PATH)
INCLUDE(ManageVersion)
RELEASE_NOTES_READ_FILE()
INCLUDE(ManageUninstall)

####################################################################
# Building
#

####################################################################
# Installing
#
SET(INSTALL_DOCS ${RELEASE_FILE} AUTHORS README ChangeLog COPYING TODO)
STRING_JOIN(PRJ_DOC_LIST " " ${INSTALL_DOCS})

INSTALL(FILES ${INSTALL_DOCS}
    DESTINATION "${PRJ_DOC_DIR}")

INSTALL(FILES cmake-fedora.conf
    DESTINATION "${SYSCONF_DIR}")

INSTALL(FILES CMakeLists.txt ${RELEASE_FILE} SPECS/project.spec.in
    DESTINATION "${PRJ_DOC_DIR}/examples")

INSTALL(DIRECTORY Modules/
    DESTINATION ${DATA_DIR}/cmake/Modules
    REGEX "\\.cmake(\\.in)?$")

INSTALL(DIRECTORY Templates/
    DESTINATION ${DATA_DIR}/cmake/Templates)

SET(EXECUTABLES scripts/cmake-fedora-newprj.sh scripts/koji-build-scratch.sh)
#STRING_JOIN(PRJ_EXECUTABLES " " ${EXECUTABLES})

INSTALL(PROGRAMS ${EXECUTABLES}
    DESTINATION ${BIN_DIR})
####################################################################
# Packing
#
SET(MAINTAINER_SETTING "${CMAKE_SOURCE_DIR}/MAINTAINER_SETTING_NO_PACK")
INCLUDE(PackSource)
INCLUDE(PackRPM)
INCLUDE(ManageRelease)
INCLUDE(ManageReleaseOnFedora)

SET(PRJ_IGNORE_FILES_COMMON
    "/doc/"  "\\\\.spec$" "messages.po$" "\\\\.orig$"
)

LIST(APPEND PACK_SOURCE_IGNORE_FILES ${PRJ_IGNORE_FILES_COMMON} "/bin/")

PACK_SOURCE(PACK_SOURCE_FILE_NAME "${RPM_BUILD_SOURCES}")
PACK_RPM(PRJ_SRPM_FILE_NAME "${RPM_BUILD_SPECS}/project.spec.in" "${PACK_SOURCE_FILE_NAME}")

CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/scripts/${KOJI_BUILD_SCRATCH}.in
    "${CMAKE_BINARY_DIR}/scripts/${KOJI_BUILD_SCRATCH}" @ONLY)

# "Off" Warning is displayed if mock is not installed.
USE_MOCK("${RPM_BUILD_SPECS}/project.spec.in")

####################################################################
# Hosting and Release
#

# "Off" Warning is displayed if ${MAINTAINER_SETTING} does not exist.
MANAGE_RELEASE(${MAINTAINER_SETTING} UPLOAD src ${RPM_BUILD_SOURCES}/${PACK_SOURCE_FILE_NAME})


RELEASE_ON_FEDORA("${RPM_BUILD_SRPMS}/${PRJ_SRPM_FILE_NAME}"
    TAGS fedora epel)

####################################################################
# Custom
#

# Module-only tarballs
ADD_CUSTOM_COMMAND(OUTPUT ${PROJECT_NAME}-${PRJ_VER}-modules-only.tar.gz
    ${PROJECT_NAME}-modules-only-latest.tar.gz
    COMMAND tar --exclude=.* -czvf  ${PROJECT_NAME}-${PRJ_VER}-modules-only.tar.gz Modules/*.cmake Modules/*.cmake.in
    COMMAND ln -sf ${PROJECT_NAME}-${PRJ_VER}-modules-only.tar.gz ${PROJECT_NAME}-modules-only-latest.tar.gz
    )

ADD_CUSTOM_TARGET(module_only
    DEPENDS ${PROJECT_NAME}-${PRJ_VER}-modules-only.tar.gz ${PROJECT_NAME}-modules-only-latest.tar.gz
    )

IF(EXISTS "${MAINTAINER_SETTING}")
    MANAGE_MAINTAINER_TARGETS_UPLOAD(
	${PROJECT_NAME}-${PRJ_VER}-modules-only.tar.gz
	${PROJECT_NAME}-modules-only-latest.tar.gz
	FILE_ALIAS module_only )
ENDIF(EXISTS "${MAINTAINER_SETTING}")


####################################################################
# Test Suites.
#
ENABLE_TESTING()
ADD_TEST("ManageString" ctest -S test/testManageString.cmake)
ADD_TEST("ManageVariable" ctest -S test/testManageVariable.cmake)

