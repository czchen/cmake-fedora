cmake_minimum_required(VERSION 2.6.2)

# Included scripts do automatic cmake_policy PUSH and POP.
# OLD: CMake policy in included script will affect the invoker.
# CMAKE_POLICY(SET CMP0011 OLD)

LIST(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_SOURCE_DIR}/Modules)
INCLUDE(ManageEnvironmentCommon RESULT_VARIABLE MANAGE_ENVIRONMENT_PATH)
GET_FILENAME_COMPONENT(CMAKE_FEDORA_MODULE_DIR 
    "${MANAGE_ENVIRONMENT_PATH}" PATH CACHE
    )

# Whether to build on fedora
SET(CMAKE_FEDORA_ENABLE_FEDORA_BUILD "1" CACHE STRING "Enable fedora build")

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
SET(PRJ_GROUP "System Environment/Libraries")
SET(BUILD_ARCH "noarch")
SET(RPM_SPEC_URL "https://fedorahosted.org/%{name}/")
SET(RPM_SPEC_SOURCES "https://fedorahosted.org/releases/c/m/%{name}/%{name}-%{version}-Source.tar.gz")

####################################################################
# Includes
#
INCLUDE(ManageEnvironment)
INCLUDE(ManageArchive)
INCLUDE(ManageVersion)
RELEASE_NOTES_READ_FILE()
INCLUDE(ManageDependency)
INCLUDE(ManageFile)
INCLUDE(ManageSourceVersionControl)
INCLUDE(ManageTarget)
INCLUDE(ManageUninstall)
ENABLE_TESTING()

####################################################################
# Dependencies
#

## Requires
MANAGE_DEPENDENCY(REQUIRES CMAKE VER "2.6.2" REQUIRED)
MANAGE_DEPENDENCY(REQUIRES GIT REQUIRED)

## Workaround for Bug 1115136 otherwise el7 won't work
MANAGE_DEPENDENCY(REQUIRES BODHI-CLIENT REQUIRED
    PROGRAM_NAMES bodhi client.py PROGRAM_SEARCH_PATHS /usr/bin/bodhi)
MANAGE_DEPENDENCY(REQUIRES KOJI  REQUIRED)
MANAGE_DEPENDENCY(REQUIRES RPM-BUILD  REQUIRED)
MANAGE_DEPENDENCY(REQUIRES FEDPKG REQUIRED)

## Build requires
MANAGE_DEPENDENCY(BUILD_REQUIRES CMAKE VER "2.6.2" REQUIRED)

####################################################################
# Building
#


####################################################################
# Installing
#

INSTALL(FILES AUTHORS README ChangeLog COPYING 
    DESTINATION ${PRJ_DOC_DIR}
    )
INSTALL(FILES cmake-fedora.conf
    DESTINATION ${SYSCONF_DIR}
    )

ADD_SUBDIRECTORY(Modules)
ADD_SUBDIRECTORY(scripts)
ADD_SUBDIRECTORY(Templates)

MANAGE_SOURCE_VERSION_CONTROL_GIT()

####################################################################
# Packing
#

ADD_CUSTOM_TARGET(ctest
    COMMAND ctest
    COMMENT "ctest: Run tests"
    )
ADD_DEPENDENCIES(pack_src_pre ctest)

## Pack Source 
SET(SOURCE_ARCHIVE_DIR ${CMAKE_BINARY_DIR}/SOURCES CACHE PATH "Source Archive Dir")
PACK_SOURCE_ARCHIVE("${SOURCE_ARCHIVE_DIR}"
    GITIGNORE ${CMAKE_SOURCE_DIR}/.gitignore
    )

IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    SET(RPM_BUILD_SOURCES ${SOURCE_ARCHIVE_DIR})
    INCLUDE(ManageRPM)
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT check "" "make test")
    PACK_RPM(SPEC_IN "Templates/fedora/project.spec.in")
    RPM_MOCK_BUILD()
ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)

####################################################################
# Hosting 
#
INCLUDE(ManageUpload)
ADD_CUSTOM_TARGET(upload
    COMMENT "Uploading all files"
    )

MANAGE_UPLOAD_FEDORAHOSTED(upload_fedorahosted_src)
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

MANAGE_UPLOAD_FEDORAHOSTED(upload_fedorahosted_modules 
    UPLOAD_FILES ${MODULE_ONLY_ARCHIVE} ${MODULE_ONLY_LATEST_ARCHIVE}
    )
ADD_DEPENDENCIES(upload upload_fedorahosted_modules)

####################################################################
# Release
#

ADD_DEPENDENCIES(upload tag_push)
INCLUDE(ManageRelease)
IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    INCLUDE(ManageReleaseFedora)
    RELEASE_FEDORA(fedora epel)
    # "Off" Warning is displayed if mock is not installed.
    MANAGE_RELEASE(upload tag_push release_fedora)
ELSE(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    MANAGE_RELEASE(upload tag_push)
ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)

####################################################################
# Test Suites.
#
ADD_TEST("ManageString" ctest -S test/testManageString.cmake)
ADD_TEST("ManageVariable" ctest -S test/testManageVariable.cmake)
ADD_TEST("ManageFile" ctest -S test/testManageFile.cmake)
ADD_TEST("ManageTranslation" ctest -S test/testManageTranslation.cmake)
ADD_TEST("ManageZanata" ctest -S test/testManageZanata.cmake)
ADD_TEST("CmakeFedoraScript" ctest -S test/testCmakeFedoraScript.cmake)
ADD_TEST("CmakeFedoraKoji" ctest -S test/testCmakeFedoraKoji.cmake)
ADD_TEST("CmakeFedoraFedpkg" ctest -S test/testCmakeFedoraFedpkg.cmake)
ADD_TEST(NAME "cmake-fedora-newprj"
    CONFIGURATIONS "debug"
    COMMAND ctest -S test/testCmakeFedoraNewprj.cmake
    )
    
