cmake_minimum_required(VERSION 2.4)
####################################################################
# Project specific information
#
PROJECT(cmake-fedora)
SET(PRJ_SUMMARY "cmake helper modules for fedora developers")

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
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/src)
MESSAGE("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")

IF(CMAKE_VERSION)
    CMAKE_POLICY(SET CMP0005 OLD)
ENDIF(CMAKE_VERSION)

INCLUDE(ManageVersion)
LOAD_RELEASE_FILE("${CMAKE_SOURCE_DIR}/RELEASE-NOTES.txt")
INCLUDE(UseUninstall)

INCLUDE(CompileEnv)
SET_USUAL_COMPILE_ENVS()


####################################################################
# Packing
#

#====================================================================
# Files to be install.
#
SET(INSTALL_DOCS ${RELEASE_FILE} AUTHORS README ChangeLog COPYING TODO)
STRING_JOIN(PRJ_DOC_LIST " " ${INSTALL_DOCS})

INSTALL(FILES ${INSTALL_DOCS}
    DESTINATION "${PRJ_DOC_DIR}")

#====================================================================
# Hosting Service
#
INCLUDE(UseHostingService)
SET(MAINTAINER_SETTING "MAINTAINER_SETTING_NO_PACK")
USE_HOSTING_SERVICE_READ_SETTING_FILE("${MAINTAINER_SETTING}")

#====================================================================
# Pack configuration
#

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
    USE_FEDPKG("${RPM_BUILD_SRPMS}/${PRJ_SRPM_FILE_NAME}")
    USE_BODHI()
ENDIF(EXISTS ${MAINTAINER_SETTING})

####################################################################
# Test Suites.
#
ENABLE_TESTING()
ADD_TEST("ManageString" ctest -S test/testManageString.cmake)
ADD_TEST("ManageVariable" ctest -S test/testManageVariable.cmake)

