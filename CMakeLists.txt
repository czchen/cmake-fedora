cmake_minimum_required(VERSION 2.6.2)

# Included scripts do automatic cmake_policy PUSH and POP.
# OLD: CMake policy in included script will affect the invoker.
# CMAKE_POLICY(SET CMP0011 OLD)

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
SET(PRJ_GROUP "System Environment/Libraries")
SET(BUILD_ARCH "noarch")
SET(RPM_SPEC_URL "https://fedorahosted.org/%{name}/")
SET(RPM_SPEC_SOURCES "https://fedorahosted.org/releases/c/m/%{name}/%{name}-%{version}-Source.tar.gz")

####################################################################
# Includes
#
LIST(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_SOURCE_DIR}/Modules)
INCLUDE(ManageEnvironment RESULT_VARIABLE MANAGE_ENVIRONMENT_PATH)
INCLUDE(ManageVersion)
RELEASE_NOTES_READ_FILE()
INCLUDE(ManageArchive)
INCLUDE(ManageDependency)
INCLUDE(ManageFile)
INCLUDE(ManageSourceVersionControl)
INCLUDE(ManageTarget)
INCLUDE(ManageTranslation)
INCLUDE(ManageUninstall)
ENABLE_TESTING()

####################################################################
# Dependencies
#

# Enable GNOME_SHELL support by set the value to 1
SET_COMPILE_ENV(GNOME_SHELL 1 DISPLAY BOOL "Enable GNOME Shell support")

SET(IBUS_MIN_VER "1.3")
SET(CHEWING_MIN_VER "0.3.3")
## Requires
MANAGE_DEPENDENCY(REQUIRES CMAKE VER "2.6.2" REQUIRED)
MANAGE_DEPENDENCY(REQUIRES KOJI  REQUIRED)
MANAGE_DEPENDENCY(REQUIRES FEDPKG REQUIRED)

## Build requires
MANAGE_DEPENDENCY(BUILD_REQUIRES CMAKE VER "2.6.2" REQUIRED)

####################################################################
# Building
#
CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/cmake-fedora.conf.in
    "${CMAKE_BINARY_DIR}/cmake-fedora.conf" @ONLY)


####################################################################
# Installing
#

MANAGE_SOURCE_VERSION_CONTROL_GIT()

MANAGE_FILE_INSTALL(PRJ_DOC AUTHORS README ChangeLog COPYING TODO)
MANAGE_FILE_INSTALL(SYSCONF cmake-fedora.conf) 

ADD_SUBDIRECTORY(Modules)
ADD_SUBDIRECTORY(scripts)
ADD_SUBDIRECTORY(Templates)

####################################################################
# Packing
#

INCLUDE(ManageRPM)
IF(RPM_BUILD_SOURCES)
    SET(SOURCE_ARCHIVE_DIR ${RPM_BUILD_SOURCES})
ELSE(RPM_BUILD_SOURCES)
    SET(SOURCE_ARCHIVE_DIR ${CMAKE_BINARY_DIR}/SOURCES)
ENDIF(RPM_BUILD_SOURCES)

INCLUDE(ManageRelease)

IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    INCLUDE(ManageRPM)
    INCLUDE(ManageReleaseFedora)
ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)

PACK_SOURCE_ARCHIVE("${SOURCE_ARCHIVE_DIR}"
    GITIGNORE ${CMAKE_SOURCE_DIR}/.gitignore
    )

####################################################################
# Hosting and Release
#
INCLUDE(ManageUpload)
ADD_CUSTOM_TARGET(upload
    COMMENT "Uploading all files"
    )

MANAGE_UPLOAD_FEDORAHOSTED(upload_fedorahosted_src 
    UPLOAD_FILES ${SOURCE_ARCHIVE_FILE})
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
    UPLOAD_FILES ${MODULE_ONLY_ARCHIVE} ${MODULE_ONLY_LATEST_ARCHIVE})
ADD_DEPENDENCIES(upload upload_fedorahosted_modules)

####################################################################
# Release
#
ADD_DEPENDENCIES(upload tag_push)
IF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    PACK_RPM(SPEC_IN "Templates/fedora/project.spec.in")
    RELEASE_FEDORA(fedora epel)
    # "Off" Warning is displayed if mock is not installed.
    RPM_MOCK_BUILD()
    MANAGE_RELEASE(upload release_fedora)
ELSE(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    MANAGE_RELEASE(upload)
ENDIF(CMAKE_FEDORA_ENABLE_FEDORA_BUILD)

####################################################################
# Test Suites.
#
ADD_TEST("ManageFile" ctest -S test/testManageFile.cmake)
ADD_TEST("ManageString" ctest -S test/testManageString.cmake)
ADD_TEST("ManageVariable" ctest -S test/testManageVariable.cmake)

