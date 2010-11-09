cmake_minimum_required(VERSION 2.4)
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
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/Modules)
MESSAGE("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")

IF(CMAKE_VERSION)
    CMAKE_POLICY(SET CMP0005 OLD)
ENDIF(CMAKE_VERSION)

INCLUDE(ManageVersion)
LOAD_RELEASE_FILE("RELEASE-NOTES.txt")
INCLUDE(UseUninstall)

INCLUDE(CompileEnv)
SET_USUAL_COMPILE_ENVS()

INCLUDE(CMakeVersion)

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

INSTALL(FILES CMakeLists.txt ${RELEASE_FILE} SPECS/project.spec.in
    DESTINATION "${PRJ_DOC_DIR}/examples")

INSTALL(DIRECTORY Modules/
    DESTINATION ${DATA_DIR}/cmake/Modules
    REGEX "\\.cmake(\\.in)?$")

INSTALL(DIRECTORY Templates/
    DESTINATION ${DATA_DIR}/cmake/Templates)

INSTALL(PROGRAMS scripts/cmake-fedora-newprj.sh
    DESTINATION ${BIN_DIR})
####################################################################
# Packing
#
SET(MAINTAINER_SETTING "MAINTAINER_SETTING_NO_PACK")
INCLUDE(PackSource)
INCLUDE(PackRPM)
INCLUDE(UseFedpkg)

SET(PRJ_IGNORE_FILES_COMMON
    "/doc/"  "\\\\.spec$" "messages.po$" "\\\\.orig$"
)

SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES}
    ${PRJ_IGNORE_FILES_COMMON} "/bin/")

PACK_SOURCE(PACK_SOURCE_FILE_NAME "${RPM_BUILD_SOURCES}")
PACK_RPM(PRJ_SRPM_FILE_NAME "${RPM_BUILD_SPECS}/project.spec.in" "${PACK_SOURCE_FILE_NAME}")

# If mock exists, then add mock related targets.
FIND_PROGRAM(MOCK_CMD mock)
IF(NOT MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
    USE_MOCK("${RPM_BUILD_SPECS}/project.spec.in")
ENDIF(NOT MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")

IF(EXISTS ${MAINTAINER_SETTING})
    USE_FEDPKG("${RPM_BUILD_SRPMS}/${PRJ_SRPM_FILE_NAME}" TAGS
	${FEDORA_RAWHIDE_TAG} ${FEDORA_CURRENT_RELEASE_TAGS} el6 el5)
    USE_BODHI(TAGS ${FEDORA_CURRENT_RELEASE_TAGS} el6 el5)
ENDIF(EXISTS ${MAINTAINER_SETTING})

####################################################################
# Hosting
#
INCLUDE(UseHostingService)
USE_HOSTING_SERVICE_READ_SETTING_FILE("${MAINTAINER_SETTING}"
    "${RPM_BUILD_SOURCES}/${PACK_SOURCE_FILE_NAME}")


####################################################################
# Test Suites.
#
ENABLE_TESTING()
ADD_TEST("ManageString" ctest -S test/testManageString.cmake)
ADD_TEST("ManageVariable" ctest -S test/testManageVariable.cmake)

