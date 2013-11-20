cmake_minimum_required(VERSION 2.6.2)

# CMP0011 should be set here, otherwise policy set in module won't affect
# here.
CMAKE_POLICY(SET CMP0011 OLD)

# Default CMAKE_INSTALL_PREFIX should be set before PROJECT()
SET(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install dir prefix")

# Whether to build on fedora
SET(CMAKE_FEDORA_ENABLE_FEDORA_BUILD "1" CACHE STRING "Enable fedora build")

# Message level INFO1 (5)
SET(MANAGE_MESSAGE_LEVEL 5 CACHE STRING "Message (Verbose) Level")

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
CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/cmake-fedora.conf.in
    "${CMAKE_BINARY_DIR}/cmake-fedora.conf" @ONLY)

####################################################################
# Installing
#
SET(INSTALL_DOCS ${RELEASE_NOTES_FILE} AUTHORS README ChangeLog COPYING TODO)
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

SET(EXECUTABLES scripts/cmake-fedora-newprj scripts/koji-build-scratch)
#STRING_JOIN(PRJ_EXECUTABLES " " ${EXECUTABLES})

INSTALL(PROGRAMS ${EXECUTABLES}
    DESTINATION ${BIN_DIR})

####################################################################
# Source Version Control
#
INCLUDE(ManageSourceVersionControl)
MANAGE_SOURCE_VERSION_CONTROL_GIT()

####################################################################
# Packing
#
INCLUDE(ManageArchive)

IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    INCLUDE(ManageRPM)
    INCLUDE(ManageReleaseFedora)
ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
INCLUDE(ManageRelease)

SET(PRJ_IGNORE_FILES_COMMON
    "/doc/"  "\\\\.spec$" "messages.po$" "\\\\.orig$"
)
LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES ${PRJ_IGNORE_FILES_COMMON} "/bin/" "${KOJI_BUILD_SCRATCH}$")

IF(RPM_BUILD_SOURCES)
    SET(SOURCE_ARCHIVE_DIR ${RPM_BUILD_SOURCES})
ELSE(RPM_BUILD_SOURCES)
    SET(SOURCE_ARCHIVE_DIR ${CMAKE_BINARY_DIR}/SOURCES)
ENDIF(RPM_BUILD_SOURCES)

PACK_SOURCE_ARCHIVE("${SOURCE_ARCHIVE_DIR}")
IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    PACK_RPM()
    RELEASE_FEDORA(fedora epel)
    # "Off" Warning is displayed if mock is not installed.
    RPM_MOCK_BUILD()
    MANAGE_RELEASE(release_fedora)
ELSE(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    MANAGE_RELEASE()
ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)

####################################################################
# Hosting and Release
#
INCLUDE(ManageUpload)
ADD_CUSTOM_TARGET(upload
    COMMENT "Uploading all files"
    )

MANAGE_UPLOAD_FEDORAHOSTED(src USER dchen UPLOAD_FILES ${SOURCE_ARCHIVE_FILE})
ADD_DEPENDENCIES(upload upload_fedorahosted_src)

####################################################################
# Custom
#

# Module-only tarballs
INCLUDE(ManageTarget)
SET(MODULE_ONLY_ARCHIVE ${PROJECT_NAME}-${PRJ_VER}-modules-only.tar.gz)
SET(MODULE_ONLY_LATEST_ARCHIVE ${PROJECT_NAME}-modules-only-latest.tar.gz)
ADD_CUSTOM_TARGET_COMMAND(module-only
    OUTPUT ${MODULE_ONLY_ARCHIVE} ${MODULE_ONLY_LATEST_ARCHIVE}
    COMMAND tar --exclude=.* -czvf  ${MODULE_ONLY_ARCHIVE} Modules/*.cmake Modules/*.cmake.in
    COMMAND ln -sf ${MODULE_ONLY_ARCHIVE} ${MODULE_ONLY_LATEST_ARCHIVE}
    )

MANAGE_UPLOAD_FEDORAHOSTED(modules USER dchen UPLOAD_FILES ${MODULE_ONLY_ARCHIVE} ${MODULE_ONLY_LATEST_ARCHIVE})
ADD_DEPENDENCIES(upload upload_fedorahosted_modules)

####################################################################
# Test Suites.
#
ENABLE_TESTING()
ADD_TEST("ManageString" ctest -S test/testManageString.cmake)
ADD_TEST("ManageVariable" ctest -S test/testManageVariable.cmake)

