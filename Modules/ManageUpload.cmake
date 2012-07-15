# - Upload files to hosting services.
# You can either use sftp, scp or supply custom command for upload.
# The custom command should be in following format:
#    cmd [OPTIONS] [url]
#

IF(NOT DEFINED _MANAGE_UPLOAD_CMAKE_)
    SET(_MANAGE_UPLOAD_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)

    # MANAGE_UPLOAD_GET_OPTIONS cmd [USER user] [HOST_URL hostUrl] [HOST_ALIAS hostAlias]
    # [FILE_ALIAS fileAlias] [UPLOAD_FILES files] [REMOTE_DIR remoteDir] [UPLOAD_OPTIONS sftpOptions] [DEPENDS files]

    FUNCTION(_MANAGE_UPLOAD_GET_OPTIONS varList varPrefix)
	SET(_optName "")	## OPTION name
	SET(_opt "")		## Variable that hold option values
	SET(_varList "")
	SET(VALID_OPTIONS "USER" "HOST_URL" "HOST_ALIAS" "FILE_ALIAS" "UPLOAD_FILES" "REMOTE_DIR" "UPLOAD_OPTIONS" "DEPENDS")
	FOREACH(_arg ${ARGN})
	    LIST(FIND VALID_OPTIONS "${_arg}" _optIndex)
	    IF(_optIndex EQUAL -1)
		IF(NOT _optName STREQUAL "")
		    ## Append to existing variable
		    LIST(APPEND _opt "${_arg}")
		ENDIF(NOT _optName STREQUAL "")
	    ELSE(_optIndex EQUAL -1)
		## Obtain option name and variable name
		LIST(GET VALID_OPTIONS  ${_optIndex} _optName)
		SET(_opt "${varPrefix}_${_optName}")

		## If variable is not in varList, then set cache and add it to varList
		LIST(FIND _varList "${_opt}" _varIndex)
		IF(_varIndex EQUAL -1)
		    SET(${_opt} "" CACHE STRING "${_optName}" FORCE)
		    LIST(APPEND _varList "${_opt}")
		ENDIF(_varIndex EQUAL -1)
	    ENDIF(_optIndex EQUAL -1)
	ENDFOREACH(_arg ${ARGN})
	SET(${varList} "${_varList}" PARENT_SCOPE)
    ENDFUNCTION(_MANAGE_UPLOAD_GET_OPTIONS varPrefix varList)

    MACRO(MANAGE_UPLOAD_MAKE_TARGET varPrefix)
	SET(_target "upload")
	IF(NOT ${varPrefix}_HOST_ALIAS STREQUAL "")
	    SET(_target "${_target}_${${varPrefix}_HOST_ALIAS}")
	ENDIF(NOT ${varPrefix}_HOST_ALIAS STREQUAL "")
	IF(NOT ${varPrefix}_FILE_ALIAS STREQUAL "")
	    SET(_target "${_target}_${${varPrefix}_FILE_ALIAS}")
	ENDIF(NOT ${varPrefix}_FILE_ALIAS STREQUAL "")

	IF(${varPrefix}_DEPENDS)
	    SET(_DEPENDS "DEPENDS" ${${varPrefix}_DEPENDS})
	ENDIF(_DEPENDS)

	## Determine url for upload
	IF(${varPrefix}_HOST_URL)
	    IF(${varPrefix}_USER)
		SET(UPLOAD_URL "${${varPrefix}_USER}@${${varPrefix}_HOST_URL}")
	    ELSE(${varPrefix}_USER)
		SET(UPLOAD_URL "${${varPrefix}_HOST_URL}")
	    ENDIF(${varPrefix}_USER)
	ELSE(${varPrefix}_HOST_URL)
	    SET(UPLOAD_URL "")
	ENDIF(${varPrefix}_HOST_URL)

	IF(REMOTE_DIR)
	    SET(UPLOAD_URL "${UPLOAD_URL}:${REMOTE_DIR}")
	ENDIF(REMOTE_DIR)

	ADD_CUSTOM_TARGET(${_target}
	    COMMAND ${${varPrefix}_UPLOAD_CMD} ${${varPrefix}_UPLOAD_OPTIONS} ${ARGN} ${UPLOAD_URL}
	    ${_DEPENDS}
	    COMMENT "${${varPrefix}_HOST_ALIAS} uploading ${${varPrefix}_FILE_ALIAS}."
	    VERBATIM
	    )
    ENDMACRO(MANAGE_UPLOAD_MAKE_TARGET varPrefix)

    FUNCTION(MANAGE_UPLOAD_CMD cmd)
	FIND_PROGRAM(UPLOAD_CMD "${cmd}")
	IF(UPLOAD_CMD STREQUAL "UPLOAD_CMD-NOTFOUND")
	    M_MSG(${M_FATAL} "Program ${cmd} is not found!")
	ELSE(UPLOAD_CMD STREQUAL "UPLOAD_CMD-NOTFOUND")
	    _MANAGE_UPLOAD_GET_OPTIONS(varList "upload" ${ARGN})
	    SET(upload_UPLOAD_CMD ${UPLOAD_CMD})
	    MANAGE_UPLOAD_MAKE_TAGET("upload")
	ENDIF(UPLOAD_CMD STREQUAL "UPLOAD_CMD-NOTFOUND")
    ENDFUNCTION(MANAGE_UPLOAD_CMD cmd)

    FUNCTION(MANAGE_UPLOAD_SFTP)
	MANAGE_UPLOAD_CMD(sftp ${ARGN})
    ENDMACRO(MANAGE_UPLOAD_SFTP)

    MACRO(MANAGE_UPLOAD_SCP)
	MANAGE_UPLOAD_CMD(scp ${ARGN})
    ENDMACRO(MANAGE_UPLOAD_SCP)

    #MACRO(MANAGE_UPLOAD_GOOGLE_UPLOAD)
    #	FIND_PROGRAM(CURL_CMD curl)
    #	IF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    #	    MESSAGE(FATAL_ERROR "Need curl to perform google upload")
    #	ENDIF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    #ENDMACRO(MANAGE_UPLOAD_GOOGLE_UPLOAD)

    MACRO(MANAGE_UPLOAD_SOURCEFORGE_FILE_RELEASE)
	_MANAGE_UPLOAD_GET_OPTIONS(varList "sourceforge" ${ARGN})
	set(source_HOST_URL frs.sourceforge.net)
	IF(sourceforge_USER)
	    SET(sourceforge_REMOTE_DIR "/home/frs/project/${PROJECT_NAME}")
	ENDIF(sourceforge_USER)
	MANAGE_UPLOAD_MAKE_TAGET("sourceforge")
    ENDMACRO(MANAGE_UPLOAD_SOURCEFORGE_FILE_RELEASE)

    MACRO(MANAGE_UPLOAD_FEDORAHOSTED)
	_MANAGE_UPLOAD_GET_OPTIONS(varList "fedorahosted" ${ARGN})
	set(source_HOST_URL "fedorahosted.org")
	SET(fedorahosted_REMOTE_DIR "${PROJECT_NAME}")
	IF(sourceforge_USER)
	ENDIF(sourceforge_USER)
	MANAGE_UPLOAD_MAKE_TAGET("fedorahosted" ${fedorahosted_UPLOAD_FILES})
    ENDMACRO(MANAGE_UPLOAD_FEDORAHOSTED)

ENDIF(NOT DEFINED _MANAGE_UPLOAD_CMAKE_)

