# - Read setting files and provides developer only targets.
# This module has macros that generate variables such as
# upload to a hosting services, which are valid to only the developers.
# This is normally done by checking the existence of a developer
# setting file.
#
# Includes:
#    ManageSourceVersionControl
#
# Included by:
#    ManageReleaseOnFedora
#
# Defines following Macros:
#   MANAGE_MAINTAINER_TARGETS_UPLOAD(hostService fileLocalPath [file2LocalPath ..]
#   [DEST_PATH destPath] [FILE_ALIAS fileAlias])
#   - Upload a file to hosting services
#     Arguments:
#     + hostService: The name of the hosting services.
#       Some properties will get preset if hostSevice is recognized.
#     + fileLocalPath: Local path of the file to be uploaded.
#     + file2LocalPath: (Optional) Local path of 2nd (3rd and so on) file to be uploaded.
#     + DEST_PATH destPath: (Optional) Destination path.
#       Default is "." if DEST_PATH is not used.
#     + FILE_ALIAS fileAlias: (Optional) Alias to be appeared as part of make target.
#       Default: file name is used.
#
#   MAINTAINER_SETTING_READ_FILE(filename packedSourcePath)
#   - Read the maintainer setting file.
#     It checks the existence of setting file.
#     If it does not exist, this macro acts as a no-op;
#     if it exists, then it reads variables defined in the setting file,
#     and set relevant targets.
#     See the "Setting File Format" section for description of file format.
#     Arguments:
#     + filename: Filename of the setting file.
#     + packedSourcePath: Source tarball.
#     Reads following variables:
#     + PRJ_VER: Project version.
#     + CHANGE_SUMMARY: Change summary.
#     Reads or define following variables:
#     + RELEASE_TARGETS: Depended targets for release.
#       Note that the sequence of the target does not guarantee the
#       sequence of execution.
#     Defines following targets:
#     + changelog_update: Update changelog by copying ChangeLog to ChangeLog.prev
#       and RPM-ChangeLog to RPM-ChangeLog. This target should be execute before
#       starting a new version.
#     + tag: tag the latest commit with the ${PRJ_VER} and ${CHANGE_SUMMARY} as comment.
#       Note that this target is actually included through ManageSourceVersionControl.
#     + upload: upload the source packages to hosting services.
#     + release: Do the release chores.
#       The actual depended target to be done for release is defined via RELEASE_TARGETS.
#
# Setting File Format
#
# It is basically the "variable=value" format.
# For variables which accept list, use ';' to separate each element.
# A line start with '#' is deemed as comment.
#
# Recognized Variable:
# Although it does no harm to define other variables in the setting file,
# but this module only recognizes following variables:
#
#   HOSTING_SERVICES
# A list of hosting services that packages are hosted. It allows multiple elements.
#
#   SOURCE_VERSION_CONTROL
# Version control system for the source code. Accepted values: git, hg, svn, cvs.
#
# The services can be defined by following format:
#   <ServiceName>_<PropertyName>=<value>
#
# ServiceName is the name of the hosting service.
# If using a known service name, you may be able to omit some definition such
# like protocol, as they have build in value.
# Do not worry that your hosting service is
# not in the known list, you can still benefit from this module, providing
# your hosting service use supported protocols.
#
# Known service name is: SourceForge, FedoraHosted.
#
#
# PropertyName is a property that is needed to preform the upload.
#    USER: the user name for the hosting service.
#    SITE: the host name of the hosting service.
#    PROTOCOL:  (Optional if service is known) Protocol for upload.
#          Supported: sftp, scp.
#    BATCH: (Optional) File that stores the batch commands.
#    BATCH_TEMPATE: (Optional) File that provides template to for generating
#                   batch commands.
#                   If BATCH is also given: Generated batch file is named
#                   as defined with BATCH;
#                   if BATCH is not given: Generated batch file is named
#                   as ${CMAKE_BINARY_DIR}/BatchUpload-${ServiceName}
#    OPTIONS: (Optional) Other options to be passed.
#
# Example:
#
# For a hosting service "Host1" with git,
# while uploading the source package to "Host2" with sftp.
# The setting file might looks as follows:
#
# SOURCE_VERSION_CONTROL=git
# # No, Host1 is not needed here.
# HOSTING_SERVICES=Host2
#
# Host2_USER=host2account
# Host2_PROTOCOL=sftp
# Host2_SITE=host2hostname
# Host2_BATCH_TEMPLATE=BatchUpload-Host2.in
#

IF(NOT DEFINED _MANAGE_MAINTAINER_TARGETS_CMAKE_)
    SET(_MANAGE_MAINTAINER_TARGETS_CMAKE_ "DEFINED")

    MACRO(MANAGE_MAINTAINER_TARGETS_SFTP
	    hostService remoteBasePath destPath fileAlias fileLocalPath )
	FIND_PROGRAM(_developer_upload_cmd sftp)
	IF(_developer_upload_cmd STREQUAL "_developer_upload_cmd-NOTFOUND")
	    MESSAGE(FATAL_ERROR "Program sftp is not found!")
	ENDIF(_developer_upload_cmd STREQUAL "_developer_upload_cmd-NOTFOUND")

	IF(NOT "${${hostService}_BATCH_TEMPLATE}" STREQUAL "")
	    IF(NOT "${hostService}_BATCH" STREQUAL "")
		SET(${hostService}_BATCH
		    ${CMAKE_BINARY_DIR}/BatchUpload-${hostService}_NO_PACK)
	    ENDIF(NOT "${hostService}_BATCH" STREQUAL "")
	    CONFIGURE_FILE(${hostService}_BATCH_TEMPLATE ${hostService}_BATCH)
	    SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES} ${hostService}_BATCH)
	ENDIF(NOT "${${hostService}_BATCH_TEMPLATE}" STREQUAL "")

	IF(NOT "${hostService}_BATCH" STREQUAL "")
	    SET(_developer_upload_cmd "${_developer_upload_cmd} -b ${hostService}_BATCH" )
	ENDIF(NOT "${hostService}_BATCH" STREQUAL "")

	IF(NOT "${hostService}_OPTIONS" STREQUAL "")
	    SET(_developer_upload_cmd "${_developer_upload_cmd} -F ${hostService}_OPTIONS" )
	ENDIF(NOT "${hostService}_OPTIONS" STREQUAL "")

	SET(_developer_upload_cmd "${_developer_upload_cmd} ${${hostService}_USER}@${${hostService}_SITE}")

	ADD_CUSTOM_TARGET(upload_${hostService}_${fileAlias}
	    COMMAND ${_developer_upload_cmd}
	    DEPENDS ${fileLocalPath} ${DEVELOPER_DEPENDS}
	    COMMENT "Uploading the ${fileLocalPath} to ${hostService}..."
	    VERBATIM
	    )
    ENDMACRO(MANAGE_MAINTAINER_TARGETS_SFTP
        hostService remoteBasePath destPath fileAlias fileLocalPath )

    MACRO(MANAGE_MAINTAINER_TARGETS_SCP
	    hostService remoteBasePath destPath fileAlias fileLocalPath)
	FIND_PROGRAM(_developer_upload_cmd scp)
	IF(_developer_upload_cmd STREQUAL "_developer_upload_cmd-NOTFOUND")
	    MESSAGE(FATAL_ERROR "Program scp is not found!")
	ENDIF(_developer_upload_cmd STREQUAL "_developer_upload_cmd-NOTFOUND")

	IF("${remoteBasePath}" STREQUAL ".")
	    IF("${destPath}" STREQUAL ".")
		SET(_dest "")
	    ELSE("${destPath}" STREQUAL ".")
		SET(_dest ":${destPath}")
	    ENDIF("${destPath}" STREQUAL ".")
	ELSE("${remoteBasePath}" STREQUAL ".")
	    IF("${destPath}" STREQUAL ".")
		SET(_dest ":${remoteBasePath}")
	    ELSE("${destPath}" STREQUAL ".")
		SET(_dest ":${remoteBasePath}/${destPath}")
	    ENDIF("${destPath}" STREQUAL ".")
	ENDIF("${remoteBasePath}" STREQUAL ".")

	ADD_CUSTOM_TARGET(upload_${hostService}_${fileAlias}
	    COMMAND ${_developer_upload_cmd} ${${hostService}_OPTIONS} ${fileLocalPath}
	      ${${hostService}_USER}@${${hostService}_SITE}${_dest}
	    DEPENDS ${fileLocalPath} ${DEVELOPER_DEPENDS}
	    COMMENT "Uploading the ${fileLocalPath} to ${hostService}..."
	    VERBATIM
	    )
    ENDMACRO(MANAGE_MAINTAINER_TARGETS_SCP
	hostService fileLocalPath remoteBasePath destPath fileAlias)

    MACRO(MANAGE_MAINTAINER_TARGETS_GOOGLE_UPLOAD)
	FIND_PROGRAM(CURL_CMD curl)
	IF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
	    MESSAGE(FATAL_ERROR "Need curl to perform google upload")
	ENDIF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    ENDMACRO(MANAGE_MAINTAINER_TARGETS_GOOGLE_UPLOAD)

    MACRO(MANAGE_MAINTAINER_TARGETS_UPLOAD hostService fileLocalPath)
	SET(_destPath ".")
	SET(_remoteBasePath ".")
	GET_FILENAME_COMPONENT(_fileAlias "${fileLocalPath}" NAME)
	SET(_fileLocalPathList ${fileLocalPath})
	SET(_stage "")
	FOREACH(_arg ${ARGN})
	    IF ("${_arg}" STREQUAL "FILE_ALIAS")
		SET(_stage "FILE_ALIAS")
	    ELSEIF("${_arg}" STREQUAL "DEST_PATH")
		SET(_stage "DEST_PATH")
	    ELSE("${_arg}" STREQUAL "FILE_ALIAS")
		IF(_stage STREQUAL "FILE_ALIAS")
		    SET(_fileAlias "${_arg}")
		ELSEIF(_stage STREQUAL "DEST_PATH")
		    SET(_destPath "${_arg}")
		ELSE(_stage STREQUAL "FILE_ALIAS")
		    LIST(APPEND _fileLocalPathList "${_arg}")
		ENDIF(_stage STREQUAL "FILE_ALIAS")
	    ENDIF("${_arg}" STREQUAL "FILE_ALIAS")
	ENDFOREACH(_arg ${ARGN})

	IF("${hostService}" MATCHES "[Ss][Oo][Uu][Rr][Cc][Ee][Ff][Oo][Rr][Gg][Ee]")
	    SET(${hostService}_PROTOCOL sftp)
	    SET(${hostService}_SITE frs.sourceforge.net)
	ELSEIF("${hostService}" MATCHES "[Ff][Ee][Dd][Oo][Rr][Aa][Hh][Oo][Ss][Tt][Ee][Dd]")
	    SET(${hostService}_PROTOCOL scp)
	    SET(${hostService}_SITE fedorahosted.org)
	    SET(_remoteBasePath "${PROJECT_NAME}")
	ELSE("${hostService}" MATCHES "[Ss][Oo][Uu][Rr][Cc][Ee][Ff][Oo][Rr][Gg][Ee]")
	ENDIF("${hostService}" MATCHES "[Ss][Oo][Uu][Rr][Cc][Ee][Ff][Oo][Rr][Gg][Ee]")

	IF(${hostService}_PROTOCOL STREQUAL "sftp")
	    MANAGE_MAINTAINER_TARGETS_SFTP(${hostService} "${_remoteBasePath}"
		"${_destPath}" "${_fileAlias}" "${_fileLocalPathList}")
	ELSEIF(${hostService}_PROTOCOL STREQUAL "scp")
	    MANAGE_MAINTAINER_TARGETS_SCP(${hostService} "${_remoteBasePath}"
		"${_destPath}" "${_fileAlias}" "${_fileLocalPathList}")
	ENDIF(${hostService}_PROTOCOL STREQUAL "sftp")
	ADD_DEPENDENCIES(upload_${hostService} upload_${hostService}_${_fileAlias})
    ENDMACRO(MANAGE_MAINTAINER_TARGETS_UPLOAD hostService fileLocalPath)

    MACRO(MAINTAINER_SETTING_READ_FILE filename packedSourcePath)
	IF(EXISTS "${filename}")
	    INCLUDE(ManageVariable)
	    INCLUDE(ManageVersion)
	    INCLUDE(ManageSourceVersionControl)
	    SETTING_FILE_GET_ALL_VARIABLES("${filename}" UNQUOTED)

	    #===================================================================
	    # Targets:
	    ADD_CUSTOM_TARGET(upload
		COMMENT "Uploading source to hosting services"
		)

	    ADD_CUSTOM_TARGET(changelog_update
		COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/ChangeLog ${CMAKE_SOURCE_DIR}/ChangeLog.prev
		COMMAND ${CMAKE_COMMAND} -E copy ${RPM_BUILD_SPECS}/RPM-ChangeLog ${RPM_BUILD_SPECS}/RPM-ChangeLog.prev
		DEPENDS ${CMAKE_SOURCE_DIR}/ChangeLog ${RPM_BUILD_SPECS}/RPM-ChangeLog
		COMMENT "Changelogs are updated for next version."
		)

	    IF(SOURCE_VERSION_CONTROL STREQUAL "git")
		MANAGE_SOURCE_VERSION_CONTROL_GIT()
	    ELSEIF(SOURCE_VERSION_CONTROL STREQUAL "hg")
		MANAGE_SOURCE_VERSION_CONTROL_HG()
	    ELSEIF(SOURCE_VERSION_CONTROL STREQUAL "svn")
		MANAGE_SOURCE_VERSION_CONTROL_SVN()
	    ELSEIF(SOURCE_VERSION_CONTROL STREQUAL "cvs")
		MANAGE_SOURCE_VERSION_CONTROL_CVS()
	    ENDIF(SOURCE_VERSION_CONTROL STREQUAL "git")

	    #
	    ADD_DEPENDENCIES(upload tag)

	    # Setting for each hosting service
	    FOREACH(_hostService ${HOSTING_SERVICES})
		ADD_CUSTOM_TARGET(upload_${_hostService})
		MANAGE_MAINTAINER_TARGETS_UPLOAD(${_hostService} ${packedSourcePath} FILE_ALIAS "source_tarball")
		ADD_DEPENDENCIES(upload upload_${_hostService})
	    ENDFOREACH(_hostService ${HOSTING_SERVICES})

	    ## Target: release
	    IF(NOT DEFINED RELEASE_TARGETS)
		SET(RELEASE_TARGETS release_on_fedora)
	    ENDIF(NOT DEFINED RELEASE_TARGETS)

	    ADD_CUSTOM_TARGET(release
		COMMENT "Sent release"
		)

	    ADD_DEPENDENCIES(release push_post_release)
	    ADD_DEPENDENCIES(push_post_release ${RELEASE_TARGETS})
	    FOREACH(_release_target ${RELEASE_TARGETS})
		ADD_DEPENDENCIES(${_release_target} upload)
	    ENDFOREACH(_release_target ${RELEASE_TARGETS})

	ENDIF(EXISTS "${filename}")

    ENDMACRO(MAINTAINER_SETTING_READ_FILE filename packedSourcePath)

ENDIF(NOT DEFINED _MANAGE_MAINTAINER_TARGETS_CMAKE_)

