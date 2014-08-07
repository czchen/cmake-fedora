# - Manage Zanata translation service support
# 
# Zanata is a web-based translation services, this module creates the required target 
#
# By calling MANAGE_GETTEXT(), following variables are available in cache:
#   - MANAGE_TRANSLATION_LOCALES: Locales that would be processed.
#
# Included Modules:
#   - ManageFile
#   - ManageMessage
#   - ManageString
#
#   MANAGE_ZANATA([<serverUrl>] [YES]
#       [PROJECT_TYPE <projectType>]
#       [VERSION <ver>]
#       [USERNAME <username>]
#       [CLIENT_COMMAND <command> ... ]
#       [SRC_DIR <srcDir>]
#       [TRANS_DIR <transDir>]
#       [PUSH_OPTIONS <option> ... ]
#       [PULL_OPTIONS <option> ... ]
#       [DISABLE_SSL_CERT]
#       [PROJECT_CONFIG <zanata.xml>]
#       [USER_CONFIG <zanata.ini>]
#     )
#     - Use Zanata as translation service.
#         Zanata is a web-based translation manage system.
#         It uses ${PROJECT_NAME} as project Id (slug);
#         ${PRJ_SUMMARY} as project name;
#         ${PRJ_DESCRIPTION} as project description 
#         (truncate to 80 characters);
#         and ${PRJ_VER} as version, unless VERSION option is defined.
#
#         In order to use Zanata with command line, you will need either
#         Zanata client:
#         * zanata-cli: Zanata java command line client.
#         * mvn: Maven build system.
#
#         In addition, zanata.ini is also required as it contains API key.
#         API key should not be put in source tree, otherwise it might be
#         misused.
#
#         Feature disabled warning (M_OFF) will be shown if Zanata client
#         or zanata.ini is missing.
#       * Parameters:
#         + serverUrl: (Optional) The URL of Zanata server
#           Default: https://translate.zanata.org/zanata/
#         + YES: (Optional) Assume yes for all questions.
#         + PROJECT_TYPE projectType::(Optional) Zanata project type.
#           Valid values: file, gettext, podir, properties,
#             utf8properties, xliff
#           Default values: gettext
#         + VERSION version: (Optional) The version to push
#         + USERNAME username: (Optional) Zanata username
#         + CLIENT_COMMAND command ... : (Optional) Zanata client.
#             Specify zanata client.
#           Default: mvn -e
#         + SRC_DIR dir: Directory to put source documents 
#             (e.g. .pot).
#         + TRANS-DIR dir: Directory to put translated documents 
#         + PUSH_OPTIONS opt ... : (Optional) Zanata push options.
#             Options should be specified like "includes=**/*.properties"
#             No need to put option "push-type=both", or options
#             shown in this cmake-fedora function. (e.g. SRC_DIR,
#             TRANS_DIR, YES)
#         + PULL_OPTIONS opt ... : (Optional) Zanata pull options.
#             Options should be specified like "encode-tabs=true"
#             No need to put options shown in this cmake-fedora function.
#             (e.g. SRC_DIR, TRANS_DIR, YES)
#         + DISABLE_SSL_CERT: (Optional) Disable SSL check
#         + PROJECT_CONFIG zanata.xml: (Optoional) Path to zanata.xml
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/zanata.xml
#         + USER_CONFIG zanata.ini: (Optoional) Path to zanata.ini
#             Feature disabled warning (M_OFF) will be shown if 
#             if zanata.ini is missing.
#           Default: $HOME/.config/zanata.ini
#       * Targets:
#         + zanata_put_projet: Put project in zanata server.
#         + zanata_put_version: Put version in zanata server.
#         + zanata_push: Push source messages to zanata server.
#         + zanata_push_trans: Push translations to  zanata server.
#         + zanata_push_both: Push source messages and translations to
#             zanata server.
#         + zanata_pull: Pull translations from zanata server.
#

IF(DEFINED _MANAGE_ZANATA_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_ZANATA_CMAKE_)
SET(_MANAGE_ZANATA_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageFile)
INCLUDE(ManageString)
INCLUDE(ManageVariable)

SET(ZANATA_MAVEN_SUBCOMMAND_PREFIX "org.zanata:zanata-maven-plugin:")

## Internal
FUNCTION(ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE var opt)
    STRING_SPLIT(_strList "-" "${opt}")
    SET(_first 1)
    SET(_retStr "")
    FOREACH(_s ${_strList})
	IF("${_retStr}" STREQUAL "")
	    STRING(TOLOWER "${_s}" _s)
	    SET(_retStr "${_s}")
	ELSE()
	    STRING(LENGTH "${_s}" _len)
	    MATH(EXPR _tailLen ${_len}-1)
	    STRING(SUBSTRING "${_s}" 0 1 _head)
	    STRING(SUBSTRING "${_s}" 1 ${_tailLen} _tail)
	    STRING(TOUPPER "${_head}" _head)
	    STRING(TOLOWER "${_tail}" _tail)
	    STRING_APPEND(_retStr "${_head}${_tail}")
	ENDIF()
    ENDFOREACH(_s)
    SET(${var} "${_retStr}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE)

## Internal
FUNCTION(ZANATA_CLIENT_OPT_LIST_APPEND var cmd opt)
    IF(${ARGN})
	SET(_value "${ARGN}")
    ENDIF()
    IF("${cmd}" STREQUAL "mvn")
	ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE(opt "${opt}")
	IF(NOT "${_value}" STREQUAL "")
	    LIST(APPEND ${var} "-Dzanata.${opt}=${_value}")
	ELSE()
	    LIST(APPEND ${var} "-Dzanata.${opt}")
	ENDIF()
    ELSE()
	## zanata-cli
	LIST(APPEND ${var} "--${opt}")
	IF(NOT "${_value}" STREQUAL "")
	    LIST(APPEND ${var} "${_value}")
	ENDIF()
    ENDIF()
ENDFUNCTION(ZANATA_CLIENT_OPT_LIST_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_OPT_LIST_PARSE_APPEND var cmd opt)
    STRING_SPLIT(_list "=" "${opt}")
    ZANATA_CLIENT_OPT_LIST_APPEND(${var} ${cmd} ${_list})
ENDFUNCTION(ZANATA_CLIENT_OPT_LIST_PARSE_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_SUB_COMMAND var cmd cmdList subCommand)
    SET(_list ${cmdList})
    IF("${cmd}" STREQUAL "mvn")
	IF("${subCommand}" STREQUAL "put-project")
	    LIST(APPEND _list "ZANATA_MAVEN_SUBCOMMAND_PREFIX:putproject")
	ELSEIF("${subCommand}" STREQUAL "put-version")
	    LIST(APPEND _list "ZANATA_MAVEN_SUBCOMMAND_PREFIX:putversion")
	ELSE()
	    LIST(APPEND _list 
		"ZANATA_MAVEN_SUBCOMMAND_PREFIX:${subCommand}"
		)
	ENDIF()
    ELSE()
	## zanata-cli
	LIST(APPEND _list "${subCommand}")
    ENDIF()
ENDFUNCTION(ZANATA_CLIENT_SUB_COMMAND)

FUNCTION(MANAGE_ZANATA)
    SET(_clientValidCommonOptions
	"USERNAME" "URL" 
	"DISABLE_SSL_CERT"  "USER_CONFIG" 
	)

    SET(_clientValidPutVersionPushPullOptions
	"PROJECT_TYPE"
	)

    SET(_clientValidPushPullOptions
	"SRC_DIR" "TRANS_DIR" "PROJECT_CONFIG"
	)

    SET(_validAllOptions 
	"YES" "CLIENT_COMMAND" "VERSION" "PUSH_OPTIONS" "PULL_OPTIONS"
	${_clientValidCommonOptions} 
	${_clientValidPutVersionPushPullOptions}
	${_clientValidPutVersionOptions} 
	${_clientValidPushPullOptions}
	)
    VARIABLE_PARSE_ARGN(_o _validAllOptions ${ARGN})

    SET(_zanata_dependency_missing 0)
    ## Is zanata.ini exists
    IF("${_o_USER_CONFIG}" STREQUAL "")
	SET(_o_USER_CONFIG "$ENV{HOME}/.config/zanata.ini")
    ENDIF()
    IF(NOT EXISTS ${_o_USER_CONFIG})
	SET(_zanata_dependency_missing 1)
	M_MSG(${M_OFF} "MANAGE_ZANATA: Failed to find zanata.ini at ${_o_USER_CONFIG}"
	    )
    ENDIF(NOT EXISTS ${_o_USER_CONFIG})

    ## Find client command 
    IF("${_o_CLIENT_COMMAND}" STREQUAL "")
	FIND_PROGRAM_ERROR_HANDLING(ZANATA_EXECUTABLE
	    ERROR_MSG " Zanata support is disabled."
	    ERROR_VAR _zanata_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    FIND_ARGS NAMES zanata-cli mvn
	    )

	IF(NOT _zanata_dependency_missing)
	    SET(_o_CLIENT_COMMAND "${ZANATA_EXECUTABLE}" "-e")
	ENDIF()
    ELSE()
	LIST(GET _o_CLIENT_COMMAND 0 ZANATA_EXECUTABLE)
    ENDIF()

    ## Disable unsupported  client.
    IF(_zanata_dependency_missing)
	RETURN()
    ELSE()
	GET_FILENAME_COMPONENT(_cmd "${ZANATA_EXECUTABLE}" NAME)
	IF(_cmd STREQUAL "mvn")
	ELSEIF(_cmd STREQUAL "zanata-cli")
	ELSE()
	    M_MSG(${M_OFF} "${_cmd} is ${_o_CLIENT_CMD} not a supported Zanata client")
	    RETURN()
	ENDIF()
    ENDIF()

    ## Convert to client options
    IF(_o_YES)
	LIST(APPEND _o_CLIENT_COMMAND "-B")
    ENDIF()

    IF("${_o}" STREQUAL "")
	SET(_o_URL "https://translate.zanata.org/zanata/")
    ELSE()
	SET(_o_URL "${_o}")
    ENDIF()

    ### Common options
    FOREACH(_optCName ${_clientValidCommonOptions})
	STRING(REPLACE "_" "-" "${_optCName}" _optName)
	ZANATA_CLIENT_OPT_LIST_APPEND(_o_CLIENT_COMMAND "${_cmd}"
	    "${_optName}" "${_o_${_optName}}"
	    )
    ENDFOREACH(_optCName)

    ### zanata_put_project
    SET(ZANATA_DESCRIPTION_SIZE 80 CACHE STRING "Zanata description size")
    ZANATA_CLIENT_SUB_COMMAND(_zntPutProjectCmdList "${_cmd}"
	"${_o_CLIENT_COMMAND}" "put-project"
	)
    IF("${_o_PROJECT_TYPE}" STREQUAL "")
	SET(_o_PROJECT_TYPE "gettext")
    ENDIF()
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutProjectCmdList "${_cmd}"
	"project-slug" "${PROJECT_NAME}"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutProjectCmdList "${_cmd}"
	"project-name" "${PROJECT_NAME}"
	)
    STRING(LENGTH "${PRJ_SUMMARY}" _prjSummaryLen)
    IF(NOT _prjSummaryLen GREATER ${ZANATA_DESCRIPTION_SIZE})
	SET(_description "${PRJ_SUMMARY}")
    ELSE()
	STRING(SUBSTRING "${PRJ_SUMMARY}" 0
	    ${ZANATA_DESCRIPTION_SIZE} _description
	    )
    ENDIF()
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutProjectCmdList "${_cmd}"
	"project-desc" "${_description}"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutProjectCmdList "${_cmd}"
	"default-project-type" "${_o_PROJECT_TYPE}"
	)
    ADD_CUSTOM_TARGET(zanata_put_project
	COMMAND ${_zntPutProjectCmdList}
	COMMENT "zanata_put_project: with ${_zntPutProjectCmdList}"
	)

    ### zanata_put_version options
    ZANATA_CLIENT_SUB_COMMAND(_zntPutVersionCmdList "${_cmd}"
	"${_o_CLIENT_COMMAND}" "put-version"
	)
    IF("${_o_VERSION}" STREQUAL "")
	SET(_o_VERSION "${PRJ_VER}")
    ENDIF()
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutVersionCmdList "${_cmd}"
	"version-slug" "${_o_VERSION}"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutVersionCmdList "${_cmd}"
	"version-project" "${PROJECT_NAME}"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPutVersionCmdList "${_cmd}"
	"project-type" "${_o_PROJECT_TYPE}"
	)
    ADD_CUSTOM_TARGET(zanata_put_version
	COMMAND ${_zntPutVersionCmdList}
	COMMENT "zanata_put_version: with ${_zntPutVersionCmdList}"
	)

    ### zanata_push
    ZANATA_CLIENT_SUB_COMMAND(_zntPushCmdList "${_cmd}"
	"${_o_CLIENT_COMMAND}" "push"
	)
    IF("${_o_SRC_DIR}" STREQUAL "")
	SET(_o_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF()
    IF("${_o_TRANS_DIR}" STREQUAL "")
	SET(_o_TRANS_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF()
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPushCmdList "${_cmd}"
	"project" "${PROJECT_NAME}"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPushCmdList "${_cmd}"
	"project-version" "${_o_VERSION}"
	)
    FOREACH(_opt ${_clientValidPutVersionPushPullOptions}
	    ${_clientValidPushPullOptions}
	    )
	IF(DEFINED ${_o_${_opt}})
	    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPushCmdList ${_cmd}
		"${_opt}" "${_o_${_opt}}"
		)
	ENDIF()
    ENDFOREACH(_opt)
    IF(NOT "${_o_PUSH_OPTIONS}" STREQUAL "")
	FOREACH(_opt ${_o_PUSH_OPTIONS})
	    M_MSG(${M_INFO2} "ManageZanata: PUSH_OPTION ${_opt}")
	    ZANATA_CLIENT_OPT_LIST_PARSE_APPEND(_zntPushCmdList "${_cmd}" "${_opt}")
	ENDFOREACH(_opt)
    ENDIF()
    ADD_CUSTOM_TARGET(zanata_push
	COMMAND ${_zntPushCmdList}
	COMMENT "zanata_push: with ${_zntPushCmdList}"
	)

    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPushTransOptsList "${_cmd}" "push-type" "trans")
    ADD_CUSTOM_TARGET(zanata_push_trans
	COMMAND ${_zntPushCmdList} ${_zntPushTransOptsList}
	COMMENT "zanata_push_trans: with ${_zntPushCmdList}"
	)

    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPushBothOptsList "${_cmd}" "push-type" "both")
    ADD_CUSTOM_TARGET(zanata_push_both
	COMMAND ${_zntPushCmdList} ${_zntPushBothOptsList}
	COMMENT "zanata_push_both: with ${_zntPushCmdList}"
	)

    ### zanata_pull
    ZANATA_CLIENT_SUB_COMMAND(_zntPullCmdList "${_cmd}"
	"${_o_CLIENT_COMMAND}" "pull"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPullCmdList "${_cmd}"
	"project" "${PROJECT_NAME}"
	)
    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPullCmdList "${_cmd}"
	"project-version" "${_o_VERSION}"
	)
    FOREACH(_opt ${_clientValidPutVersionPushPullOptions}1
	    ${_clientValidPushPullOptions}
	    )
	IF(DEFINED ${_o_${_opt}})
	    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPullCmdList ${_cmd}
		"${_opt}" "${_o_${_opt}}"
		)
	ENDIF()
    ENDFOREACH(_opt)
    IF(NOT "${_o_PUSH_OPTIONS}" STREQUAL "")
	FOREACH(_opt ${_o_PULL_OPTIONS})
	    M_MSG(${M_INFO2} "ManageZanata: PULL_OPTION ${_opt}")
	    ZANATA_CLIENT_OPT_LIST_PARSE_APPEND(_zntPullCmdList "${_cmd}" "${_opt}")
	ENDFOREACH(_opt)
    ENDIF()
    ADD_CUSTOM_TARGET(zanata_pull
	COMMAND ${_zntPullCmdList}
	COMMENT "zanata_pull: with ${_zntPullCmdList}"
	)

    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPullSrcOptsList "${_cmd}" "pull-type" "source")
    ADD_CUSTOM_TARGET(zanata_pull_src
	COMMAND ${_zntPullCmdList} ${_zntPullSrcOptsList}
	COMMENT "zanata_pull_trans: with ${_zntPullCmdList}"
	)

    ZANATA_CLIENT_OPT_LIST_APPEND(_zntPullBothOptsList "${_cmd}" "pull-type" "both")
    ADD_CUSTOM_TARGET(zanata_pull_both
	COMMAND ${_zntPullCmdList} ${_zntPullBothOptsList}
	COMMENT "zanata_pull_both: with ${_zntPullCmdList}"
	)
ENDFUNCTION(MANAGE_ZANATA)

