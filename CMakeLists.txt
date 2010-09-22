cmake_minimum_required(VERSION 2.4)
####################################################################
# Project specific information
#
PROJECT(cmake-fedora)
SET(PRJ_SUMMARY "A set of cmake modules  that provides helper macros and targets for fedora developers")

SET(PRJ_DESCRIPTION
    "cmake-fedora consist a set of cmake modules that provides"
    "helper macros and targets for fedora developers."
    )
SET(AUTHORS "Ding-Yi Chen")
SET(MAINTAINER "Ding-Yi Chen <dchen at redhat.com>")
SET(VENDOR "Red Hat, APAC, Inc.")

####################################################################
# Includes
#
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/src)
MESSAGE("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
INCLUDE(ManageVersion)
LOAD_RELEASE_FILE("${CMAKE_SOURCE_DIR}/RELEASE-NOTES.txt")
INCLUDE(UseUninstall)

####################################################################
# Sub directories
#
ADD_SUBDIRECTORY(test)

####################################################################
# Packing
#

#====================================================================
# Files to be install.
#
SET(MAIN_DOCS AUTHORS README ChangeLog NEWS COPYING USER-GUIDE)

#INSTALL(FILES ${MAIN_DOCS}
#    DESTINATION "${PROJECT_DOC_DIR}")

INSTALL(DIRECTORY icons
    DESTINATION  ${PROJECT_DATA_DIR})

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/data/chewing.xml
    DESTINATION "${DATA_DIR}/ibus/component")


#====================================================================
# Hosting Service
#
INCLUDE(UseHostingService)
USE_HOSTING_SERVICE_READ_SETTING_FILE("MAINTAINER_SETTING_NO_PACK")

#====================================================================
# Pack configuration
#

INCLUDE(PackSource)
INCLUDE(PackRPM)
INCLUDE(UseFedpkg)

SET(MY_IGNORE_FILES_COMMON
    "/doc/"  "\\\\.spec$" "messages.po$" "\\\\.orig$"
)

# GOB_GENERATED source codes are now excluded,
# As Bug 519108 (https://bugzilla.redhat.com/show_bug.cgi?id=519108)
# Is fixed from Fedora 11
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
    USE_MOCK("${RPM_BUILD_SPECS}/ibus-chewing.spec.in")
ENDIF(NOT MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")

USE_FEDPKG("${RPM_BUILD_SRPMS}/${PRJ_SRPM_FILE_NAME}")
USE_BODHI()

ADD_DEPENDENCIES(pack_src pot_file)

####################################################################
# Test Suites.
####################################################################
ENABLE_TESTING()

