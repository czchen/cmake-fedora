# - Read setting files and provides developer only targets.
# This module has macros that generate variables such as
# upload to a hosting services, which are valid to only the developers.
# This is normally done by checking the existence of a developer
# setting file.
#
# Defines following Macros:
#   MAINTAINER_SETTING_READ_FILE(filename packedSourcePath)
#   - It checks the existence of setting file.
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
#   <ServiceName>_<protocol>_<PropertyName>=<value>
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
# Protocol is the protocol used to upload file.
#  Supported protocol is: SFTP, SCP.
#
# PropertyName is a property that is needed to preform the upload.
# It is usually associate to the Protocol.
#
#  For protocol SFTP:
#    USER: the user name for sftp.
#    SITE: the host name of the sftp site.
#    BATCH: (Optional) File that stores the batch commands.
#    BATCH_TEMPATE: (Optional) File that provides template to for generating
#                   batch commands.
#                   If BATCH is also given: Generated batch file is named
#                   as defined with BATCH;
#                   if BATCH is not given: Generated batch file is named
#                   as ${CMAKE_BINARY_DIR}/BatchUpload-${ServiceName}
#   OPTIONS: (Optional) Other options for sftp.
#
#  For protocol SCP:
#    USER: the user name for sftp.
#    SITE: the host name of the sftp site.
#    DEST_PATH: (Optional) file path of remote.
#    OPTIONS: (Optional) Other options for scp.
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
# Host2_SFTP_USER=host2account
# Host2_SFTP_SITE=host2hostname
# Host2_SFTP_BATCH_TEMPLATE=BatchUpload-Host2.in
#

IF(NOT DEFINED _USE_HOSTING_SERVICE_CMAKE_)
    SET(_USE_HOSTING_SERVICE_CMAKE_ "DEFINED")
    MACRO(USE_HOSTING_SERVICE_SFTP alias user site packedSourcePath)
	SET(_developer_upload_cmd "sftp")
	IF(NOT "${${alias}_BATCH_TEMPLATE}" STREQUAL "")
	    IF(NOT "${alias}_BATCH" STREQUAL "")
		SET(${alias}_BATCH
		    ${CMAKE_BINARY_DIR}/BatchUpload-${alias}_NO_PACK)
	    ENDIF(NOT "${alias}_BATCH" STREQUAL "")
	    CONFIGURE_FILE(${alias}_BATCH_TEMPLATE ${alias}_BATCH)
	    SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES} ${alias}_BATCH)
	ENDIF(NOT "${${alias}_BATCH_TEMPLATE}" STREQUAL "")

	IF(NOT "${alias}_BATCH" STREQUAL "")
	    SET(_developer_upload_cmd "${_developer_upload_cmd} -b ${alias}_BATCH" )
	ENDIF(NOT "${alias}_BATCH" STREQUAL "")

	IF(NOT "${alias}_OPTIONS" STREQUAL "")
	    SET(_developer_upload_cmd "${_developer_upload_cmd} -F ${alias}_OPTIONS" )
	ENDIF(NOT "${alias}_OPTIONS" STREQUAL "")

	SET(_developer_upload_cmd "${_developer_upload_cmd} ${user}@${site}")

	ADD_CUSTOM_TARGET(upload_${alias}
	    COMMAND ${_developer_upload_cmd}
	    DEPENDS ${DEVELOPER_DEPENDS}
	    COMMENT "Uploading the package releases to ${alias}..."
	    VERBATIM
	    )
    ENDMACRO(USE_HOSTING_SERVICE_SFTP user site packedSourcePath)

    # MACRO(USE_HOSTING_SERVICE_SCP alias user site packedSourcePath
    #   [DEST_PATH destination]
    #   [OPTIONS options]
    # )
    MACRO(USE_HOSTING_SERVICE_SCP alias user site packedSourcePath)
	FIND_PROGRAM(_developer_upload_cmd scp)
	IF(_developer_upload_cmd STREQUAL "_developer_upload_cmd-NOTFOUND")
	    MESSAGE(FATAL_ERROR "Program scp is not found!")
	ENDIF(_developer_upload_cmd STREQUAL "_developer_upload_cmd-NOTFOUND")

	SET(_stage "NONE")
	SET(_destPath "")
	SET(_options "")
	FOREACH(_arg ${ARGN})
	    IF(_arg STREQUAL "DEST_PATH")
		SET(_stage "DEST_PATH")
	    ELSEIF(_arg STREQUAL "OPTIONS")
		SET(_stage "OPTIONS")
	    ELSE(_arg STREQUAL "DEST_PATH")
		IF(_stage STREQUAL "DEST_PATH")
		    SET(_destPath "${_arg}")
		ELSEIF(_stage STREQUAL "OPTIONS")
		    SET(_options "${_options} ${_arg}")
		ENDIF(_stage STREQUAL "DEST_PATH")
	    ENDIF(_arg STREQUAL "DEST_PATH")
	ENDFOREACH(_arg ${ARGN})
	IF(_destPath)
	    SET(_dest "${user}@${site}:${_destPath}")
	ELSE(_destPath)
	    SET(_dest "${user}@${site}")
	ENDIF(_destPath)

	ADD_CUSTOM_TARGET(upload_${alias}
	    COMMAND ${_developer_upload_cmd} ${_options}  ${packedSourcePath} ${_dest}
	    DEPENDS ${packedSourcePath} ${DEVELOPER_DEPENDS}
	    COMMENT "Uploading the package releases to ${alias}..."
	    VERBATIM
	    )
    ENDMACRO(USE_HOSTING_SERVICE_SCP user site packedSourcePath)

    MACRO(USE_HOSTING_SERVICE_GOOGLE_UPLOAD)
	FIND_PROGRAM(CURL_CMD curl)
	IF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
	    MESSAGE(FATAL_ERROR "Need curl to perform google upload")
	ENDIF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    ENDMACRO(USE_HOSTING_SERVICE_GOOGLE_UPLOAD)

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

	# Setting for each hosting service
	FOREACH(_service ${HOSTING_SERVICES})
	    IF(_service STREQUAL "[Ss][Oo][Uu][Rr][Cc][Ee][Ff][Oo][Rr][Gg][Ee]")
		USE_HOSTING_SERVICE_SFTP("${_service}" ${${_service}_USER}
		    frs.sourceforge.net ${packedSourcePath})
	    ELSEIF(_service MATCHES "[Ff][Ee][Dd][Oo][Rr][Aa][Hh][Oo][Ss][Tt][Ee][Dd]")
		USE_HOSTING_SERVICE_SCP("${_service}" ${${_service}_HOSTED_USER}
		    fedorahosted.org  ${packedSourcePath}
		    DEST_PATH "${PROJECT_NAME}")
	    ELSEIF(_service STREQUAL "GOOGLECODE")
		USE_HOSTING_SERVICE_GOOGLE_UPLOAD()
	    ELSEIF(_service STREQUAL "GITHUB")
	    ELSE(_service STREQUAL "SOURCEFORGE")
		# Generic hosting service
		IF(NOT "${${_service}_SFTP_USER}" STREQUAL "")
		    # SFTP hosting service
		    USE_HOSTING_SERVICE_SFTP("${_service}" ${${_service}_SFTP_USER}
			${${_service}_SFTP_SITE}
			BATCH ${${_service}_SFTP_BATCH}
			BATCH_TEMPLATE ${${_service}_SFTP_BATCH_TEMPLATE}
			OPTIONS ${${_service}_SFTP_OPTIONS})
		ELSEIF(NOT "${${_service}_SCP_USER}" STREQUAL "")
		ENDIF(NOT "${${_service}_SFTP_USER}" STREQUAL "")
	    ENDIF(_service STREQUAL "SOURCEFORGE")
	    ADD_DEPENDENCIES(upload "upload_${_service}")

	ENDFOREACH(_service ${HOSTING_SERVICES})


	## Target: release
	IF(NOT DEFINED RELEASE_TARGETS)
	    SET(RELEASE_TARGETS koji_scratch_build tag upload rpmlint fedpkg_commit
		fedpkg_build bodhi_new changelog_update commit_after_release
		push_svc_tags)
	ENDIF(NOT DEFINED RELEASE_TARGETS)

	ADD_CUSTOM_TARGET(release
	    COMMENT "Sent release"
	    )

	ADD_DEPENDENCIES(release ${RELEASE_TARGETS})

    ENDIF(EXISTS "${filename}")

    ENDMACRO(MAINTAINER_SETTING_READ_FILE filename packedSourcePath)

ENDIF(NOT DEFINED _USE_HOSTING_SERVICE_CMAKE_)

