# - Manage Zanata translation service support
# 
# Zanata is a web-based translation services, this module creates required targets. 
# for common Zanata operation, like put-project, put-version, 
#  push source and/or translation, pull translation and/or sources.
# 
#
# Included Modules:
#   - ManageFile
#   - ManageMessage
#   - ManageString
#
# Define following functions:
#   MANAGE_ZANATA([<serverUrl>] [YES] [ERRORS] [DEBUG]
#       [CHUNK_SIZE <sizeInByte>]
#       [CLEAN_ZANATA_XML]
#       [CLIENT_COMMAND <command> ... ]
#       [COPY_TRANS <bool>]
#       [CREATE_SKELETONS]
#       [DISABLE_SSL_CERT]
#       [ENCODE_TABS <bool>]
#       [EXCLUDES <filePatternList>]
#       [GENERATE_ZANATA_XML]
#       [INCLUDES <filePatternList>]
#       [LOCALES <locale1,locale2...> ]
#       [PROJECT <projectId>]
#       [PROJECT_CONFIG <zanata.xml>]
#       [PROJECT_DESC "<Description>"]
#       [PROJECT_NAME "<project name>"]
#       [PROJECT_TYPE <projectType>]
#       [SRC_DIR <srcDir>]
#       [TRANS_DIR <transDir>]
#       [TRANS_DIR_PULL <transDir>]
#       [USER_CONFIG <zanata.ini>]
#       [USERNAME <username>]
#       [VERSION <ver>]
#     )
#     - Use Zanata as translation service.
#         Zanata is a web-based translation manage system.
#         It uses ${PROJECT_NAME} as project Id (slug);
#         ${PRJ_NAME} as project name;
#         ${PRJ_SUMMARY} as project description 
#         (truncate to 80 characters);
#         and ${PRJ_VER} as version, unless VERSION option is defined.
#
#         In order to use Zanata with command line, you will need either
#         Zanata client:
#         * mvn: Maven build system.
#         * zanata: Zanata python command line client.
#         * zanata-cli: Zanata java command line client.
#
#         In addition, ~/.config/zanata.ini is also required as it contains API key.
#         API key should not be put in source tree, otherwise it might be
#         misused.
#
#         Feature disabled warning (M_OFF) will be shown if Zanata client
#         or zanata.ini is missing.
#       * Parameters:
#         + serverUrl: (Optional) The URL of Zanata server
#           Default: https://translate.zanata.org/zanata/
#         + YES: (Optional) Assume yes for all questions.
#         + ERROR: (Optional) Show errors. As "-e" in maven.
#         + DEBUG: (Optional) Show debug message. As "-X" in maven.
#         + CLEAN_ZANATA_XML: (Optional) zanata.xml will be removed with 
#             "make clean"
#         + CLIENT_COMMAND command ... : (Optional) command path to Zanata client.
#           Default: "mvn"
#         + COPY_TRANS bool: (Optional) Copy translation from existing versions.
#           Default: "true"
#         + CREATE_SKELETONS: (Optional) Create .po file even if there is no translation
#         + DISABLE_SSL_CERT: (Optional) Disable SSL Cert check.
#         + ENCODE_TABS bool: (Optional) Encode tab as "\t"/
#         + EXCLUDES: (Optional) The file pattern that should not be pushed as source.
#           e.g. **/debug*.properties
#         + GENERATE_ZANATA_XML: (Optional) Automatic generate a zanata.xml
#         + INCLUDES: (Optional) The file pattern that should be pushed as source.
#           e.g. **/debug*.properties
#         + LOCALES locales: Locales to sync with Zanata.
#             Specify the locales to sync with this Zanata server.
#             If not specified, it uses client side system locales.
#         + PROJECT projectId: (Optional) This project ID in Zanata.
#           (Space not allowed)
#           Default: CMake Variable PROJECT_NAME
#         + PROJECT_CONFIG zanata.xml: (Optoional) Path to zanata.xml
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/zanata.xml
#         + PROJECT_DESC "Project description": (Optoional) Project description in Zanata.
#           Default: ${PRJ_DESCRIPTION}
#         + PROJECT_NAME "project name": (Optional) Project display name in Zanata.
#           (Space allowed)
#           Default: CMake Variable PROJECT_NAME
#         + PROJECT_TYPE projectType::(Optional) Zanata project type 
#             for this version.
#	      Normally version inherit the project-type from project,
#             if this is not the case, use this parameter to specify
#             the project type.
#           Valid values: file, gettext, podir, properties,
#             utf8properties, xliff
#         + SRC_DIR dir: (Optional) Directory to put source documents like .pot
#             This value will be put in zanata.xml, so it should be relative.
#           Default: "."
#         + TRANS_DIR dir: (Optional) Relative directory to push the translated
#             translated documents like .po
#             This value will be put in zanata.xml, so it should be relative.
#           Default: "."
#         + TRANS_DIR_PULL dir: (Optional) Directory to pull translated documents.
#           Default: CMAKE_CURRENT_BINARY_DIR
#         + USER_CONFIG zanata.ini: (Optoional) Path to zanata.ini
#             Feature disabled warning (M_OFF) will be shown if 
#             if zanata.ini is missing.
#           Default: $HOME/.config/zanata.ini
#         + USERNAME username: (Optional) Zanata username
#         + VERSION version: (Optional) The version to push
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
INCLUDE(ManageZanataDefinition)
INCLUDE(ManageZanataSuggest)

SET(ZANATA_URL "https://translate.zanata.org/zanata/" CACHE STRING "Zanata Server URL")
SET(ZANATA_PROJECT_TYPE "gettext" CACHE STRING "Project Type of this project")
SET(ZANATA_DESCRIPTION_SIZE 80 CACHE STRING "Zanata description size")

#######################################
## Option Conversion Function

## ZANATA_STRING_DASH_TO_CAMEL_CASE(var opt)
FUNCTION(ZANATA_STRING_DASH_TO_CAMEL_CASE var opt)
    STRING_SPLIT(_strList "-" "${opt}")
    SET(_first 1)
    SET(_retStr "")
    FOREACH(_s ${_strList})
	IF("${_retStr}" STREQUAL "")
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
ENDFUNCTION(ZANATA_STRING_DASH_TO_CAMEL_CASE)

FUNCTION(ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH var optName)
    STRING(REPLACE "_" "-" result "${optName}")
    STRING(TOLOWER "${result}" result)
    SET(${var} "${result}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH)

FUNCTION(ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE var optName)
    STRING(REPLACE "-" "_" result "${optName}")
    STRING(TOUPPER "${result}" result)
    SET(${var} "${result}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE)

FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_MVN listVar subCommandName optName)
    IF("${optName}" STREQUAL "BATCH")
	LIST(APPEND ${listVar} "-B")
    ELSEIF("${optName}" STREQUAL "ERRORS")
	LIST(APPEND ${listVar} "-e")
    ELSEIF("${optName}" STREQUAL "DEBUG")
	LIST(APPEND ${listVar} "-X")
    ELSEIF("${optName}" STREQUAL "DISABLE_SSL_CERT")
	LIST(APPEND ${listVar} "-Dzanata.disableSSLCert")
    ELSEIF(DEFINED ZANATA_MVN_${subCommandName}_OPTION_NAME_${optName})
	## Option name that changed in subCommandName
	ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH(optNameReal
	    "${ZANATA_MVN_${subCommandName}_OPTION_NAME_${optName}}")
	ZANATA_STRING_DASH_TO_CAMEL_CASE(optNameReal "${optNameReal}")
	IF(NOT "${ARGN}" STREQUAL "")
	    LIST(APPEND ${listVar} "-Dzanata.${optNameReal}=${ARGN}")
	ELSE()
	    LIST(APPEND ${listVar} "-Dzanata.${optNameReal}")
	ENDIF()
    ELSE()
	ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH(optNameReal "${optName}")
	ZANATA_STRING_DASH_TO_CAMEL_CASE(optNameReal "${optNameReal}")
	IF(NOT "${ARGN}" STREQUAL "")
	    LIST(APPEND ${listVar} "-Dzanata.${optNameReal}=${ARGN}")
	ELSE()
	    LIST(APPEND ${listVar} "-Dzanata.${optNameReal}")
	ENDIF()
    ENDIF()
    SET(${listVar} "${${listVar}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_MVN)

FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_ZANATA_CLI listVar subCommandName optName)
    IF("${optName}" STREQUAL "BATCH")
	LIST(APPEND ${listVar} "-B")
    ELSEIF("${optName}" STREQUAL "ERRORS")
	LIST(APPEND ${listVar} "-e")
    ELSEIF("${optName}" STREQUAL "DEBUG")
	LIST(APPEND ${listVar} "-X")
    ELSEIF(DEFINED ZANATA_MVN_${subCommandName}_OPTION_NAME_${optName})
	## Option name that changed in subCommand
	## Option name in mvn and zanata-cli is similar, 
	## thus use ZANATA_MVN_<subCommandName>...
	ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH(optNameReal
	    "${ZANATA_MVN_${subCommandName}_OPTION_NAME_${optName}}")
	IF(NOT "${ARGN}" STREQUAL "")
	    LIST(APPEND ${listVar} "--${optNameReal}" "${ARGN}")
	ELSE()
	    LIST(APPEND ${listVar} "--${optNameReal}")
	ENDIF()
    ELSE()
	ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH(optNameReal "${optName}")
	IF(NOT "${ARGN}" STREQUAL "")
	    LIST(APPEND ${listVar} "--${optNameReal}" "${ARGN}")
	ELSE()
	    LIST(APPEND ${listVar} "--${optNameReal}")
	ENDIF()
    ENDIF()
    SET(${listVar} "${${listVar}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_ZANATA_CLI)

FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_PYTHON listVar subCommandName optName)
    IF("${optName}" STREQUAL "BATCH")
	## Python client don't have BATCH
    ELSEIF("${optName}" STREQUAL "ERRORS")
	## Python client don't have ERRORS
    ELSEIF("${optName}" STREQUAL "DEBUG")
	## Python client don't have DEBUG
    ELSE()
	ZANATA_STRING_UPPERCASE_UNDERSCORE_TO_LOWERCASE_DASH(optNameReal "${optName}")
	IF(NOT "${ARGN}" STREQUAL "")
	    LIST(APPEND ${listVar} "--${optNameReal}" "${ARGN}")
	ELSE()
	    LIST(APPEND ${listVar} "--${optNameReal}")
	ENDIF()
    ENDIF()
    SET(${listVar} "${${listVar}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_PYTHON)

FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND listVar backend subCommand optName)
    ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE(subCommandName "${subCommand}")
    IF("${backend}" STREQUAL "mvn")
	ZANATA_CLIENT_OPTNAME_LIST_APPEND_MVN(${listVar} ${subCommandName} ${optName} ${ARGN})
    ELSEIF("${backend}" STREQUAL "zanata-cli")
	ZANATA_CLIENT_OPTNAME_LIST_APPEND_ZANATA_CLI(${listVar} ${subCommandName} ${optName} ${ARGN})
    ELSEIF("${backend}" STREQUAL "zanata")
	ZANATA_CLIENT_OPTNAME_LIST_APPEND_PYTHON(${listVar} ${subCommandName} ${optName} ${ARGN})
    ELSE()
	M_MSG(${M_ERROR} "ManageZanata: Unrecognized zanata backend ${backend}")
    ENDIF()
    SET(${listVar} "${${listVar}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND)

## ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND(var backend subCommand opt)
## e.g ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND(srcDir zanata-cli push "srcDir=.")
FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND var backend subCommand opt)
    STRING_SPLIT(_list "=" "${opt}")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(${var} ${backend} ${subCommand} ${_list})
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_SUB_COMMAND var backend subCommand)
    IF("${backend}" STREQUAL "mvn")
	SET(${var} "${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:${subCommand}" PARENT_SCOPE)
    ELSEIF("${backend}" STREQUAL "zanata")
	## Python client
	IF("${subCommand}" STREQUAL "put-project")
	    SET(${var} "project" "create" PARENT_SCOPE)
	ELSEIF("${subCommand}" STREQUAL "put-version")
	    SET(${var} "version" "create" PARENT_SCOPE)
	ELSE()
	    SET(${var} "${subCommand}" PARENT_SCOPE)
	ENDIF()
    ELSE()
	## zanata-cli
	SET(${var} "${subCommand}" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION(ZANATA_CLIENT_SUB_COMMAND)

FUNCTION(ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP varPrefix)
    ## isValue=2 Must be an option value
    ## isValue=1 Maybe either
    ## isValue=0 Must be an option name
    SET(result "")
    SET(isValue 0)
    SET(optName "")

    FOREACH(opt ${ARGN})
	IF(${isValue} EQUAL 1)
	    ## Can be either, determine what it is
	    IF(DEFINED ZANATA_OPTION_NAME_${opt})
		## This is a new option name
		SET(isValue 0)
	    ELSEIF(NOT "${optName}" STREQUAL "")
		## This should be an option value
		SET(isValue 2)
	    ELSE()
		## Don't know
		M_MSG(${M_ERROR} "ManageZanata: String '${opt}' is neigher a option name, nor a value")
	    ENDIF()
	ENDIF()

	IF (${isValue} EQUAL 0)
	    ## Must be option name
	    IF(NOT DEFINED ZANATA_OPTION_NAME_${opt})
		M_MSG(${M_ERROR} "ManageZanata: Unrecognized option name ${opt}")
	    ENDIF()

	    IF(DEFINED ZANATA_OPTION_NAME_ALIAS_${opt})
		SET(optName "${ZANATA_OPTION_NAME_ALIAS_${opt}}")
	    ELSE()
		SET(optName "${opt}")
	    ENDIF()
	    LIST(APPEND ${varPrefix} "${optName}")
	    LIST(GET ZANATA_OPTION_NAME_${optName} 0 isValue)
	ELSEIF (${isValue} EQUAL 2)
	    ## Must be option value
	    IF("${optName}" STREQUAL "")
		M_MSG(${M_ERROR} "ManageZanata: Value without associated option ${opt}")
	    ENDIF()
	    SET(${varPrefix}_${optName} "${opt}")
	    SET(${varPrefix}_${optName} "${opt}" PARENT_SCOPE)
	    SET(optName "")
	    SET(isValue 0)
	ELSE()
	    ## Don't know
	    M_MSG(${M_ERROR} "ManageZanata: Error: isValue should not be ${isValue} with string '${opt}' ")
	ENDIF()
    ENDFOREACH()

    ## Default Options
    IF("${${varPrefix}_ZANATA_EXECUTABLE}" STREQUAL "")
	FIND_PROGRAM_ERROR_HANDLING(${varPrefix}_ZANATA_EXECUTABLE
	    ERROR_MSG " Zanata support is disabled."
	    ERROR_VAR _zanata_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    FIND_ARGS NAMES zanata-cli mvn zanata
	    )

	SET(${varPrefix}_ZANATA_EXECUTABLE "${${varPrefix}_ZANATA_EXECUTABLE}" PARENT_SCOPE)
    ENDIF()
    GET_FILENAME_COMPONENT(${varPrefix}_ZANATA_BACKEND "${zanataExecutable}" NAME)
    SET(${varPrefix}_ZANATA_BACKEND "${${varPrefix}_ZANATA_BACKEND}" PARENT_SCOPE)

    IF("${${varPrefix}_URL}" STREQUAL "")
	SET(${varPrefix}_URL "https://translate.zanata.org/zanata/" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_USER_CONFIG}" STREQUAL "")
	SET(${varPrefix}_USER_CONFIG "$ENV{HOME}/.config/zanata.ini" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_PROJECT_CONFIG}" STREQUAL "")
	SET(${varPrefix}_PROJECT_CONFIG "${CMAKE_CURRENT_BINARY_DIR}/zanata.xml" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_PROJECT}" STREQUAL "")
	SET(${varPrefix}_PROJECT "${PROJECT_NAME}" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_PROJECT_NAME}" STREQUAL "")
	SET(${varPrefix}_PROJECT_NAME "${${varPrefix}_PROJECT}" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_PROJECT_DESC}" STREQUAL "")
	STRING(LENGTH "${PRJ_SUMMARY}" _prjSummaryLen)
	IF(NOT _prjSummaryLen GREATER ${ZANATA_DESCRIPTION_SIZE})
	    SET(${varPrefix}_PROJECT_DESC "${PRJ_SUMMARY}")
	ELSE()
	    STRING(SUBSTRING "${PRJ_SUMMARY}" 0
		${ZANATA_DESCRIPTION_SIZE} ${varPrefix}_PROJECT_DESC
		)
	ENDIF()
	SET(${varPrefix}_PROJECT_DESC "${${varPrefix}_PROJECT_DESC}" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_PROJECT_TYPE}" STREQUAL "")
	SET(${varPrefix}_PROJECT_TYPE "gettext" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_VERSION}" STREQUAL "")
	SET(${varPrefix}_VERSION "master" PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_SRC_DIR}" STREQUAL "")
	SET(${varPrefix}_SRC_DIR "." PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_TRANS_DIR}" STREQUAL "")
	SET(${varPrefix}_TRANS_DIR "." PARENT_SCOPE)
    ENDIF()

    IF("${${varPrefix}_TRANS_DIR_PULL}" STREQUAL "")
	SET(${varPrefix}_TRANS_DIR_PULL "${${varPrefix}_TRANS_DIR}" PARENT_SCOPE)
    ENDIF()

    SET(${varPrefix} "${${varPrefix}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP)

#   MANAGE_ZANATA_OBTAIN_REAL_COMMAND(<cmdListVar> <zanataExecutable>
#       <subCommand> <optionValidList>
#       [YES] [BATCH] [ERRORS] [DEBUG]
#       [DISABLE_SSL_CERT]
#       [URL <url>]
#       [USERNAME <username>]
#       [KEY <key>]
#       [USER_CONFIG <zanata.ini>]
#       ...
#     )

FUNCTION(MANAGE_ZANATA_OBTAIN_REAL_COMMAND cmdListVar zanataExecutable 
	subCommand optionValidListVar)
    ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP(_o ${ARGN} ZANATA_EXECUTABLE ${zanataExecutable})

    LIST(FIND _o "BATCH" index)
    IF(NOT ${index} LESS 0)
	## BATCH is specified
	IF("${_o_ZANATA_BACKEND}" STREQUAL "zanata")
	    SET(result "yes" "|" "${zanataExecutable}")
	ELSE()
	    SET(result "${zanataExecutable}" "-B")
	ENDIF()
    ELSE()
	SET(result "${zanataExecutable}")
    ENDIF()

    ## Other global options
    FOREACH(optName "DEBUG" "ERRORS")
	LIST(FIND _o "${optName}" index)
	IF(NOT ${index} LESS 0)
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${_o_ZANATA_BACKEND}" "${subCommand}" "${optName}" )
	ENDIF()
    ENDFOREACH(optName)

    ## Sub-command
    ZANATA_CLIENT_SUB_COMMAND(subCommandReal "${_o_ZANATA_BACKEND}" "${subCommand}")
    LIST(APPEND result "${subCommandReal}")

    ## Explicit Options
    FOREACH(optName ${_o})
	LIST(FIND ${optionValidListVar} "${optName}" index)
	IF(NOT ${index} LESS 0)
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${_o_ZANATA_BACKEND}" "${subCommand}" "${optName}" "${_o_${optName}}")
	ENDIF()
    ENDFOREACH(optName)

    ## Implied options: Mandatory options but not specified.
    ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE(subCommandName "${subCommand}")
    ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE(backendName "${_o_ZANATA_BACKEND}")
    
    IF(DEFINED ZANATA_${_o_ZANATA_BACKEND}_${subCommandName}_MANDATORY_OPTIONS)
	FOREACH(optName ${ZANATA_${_o_ZANATA_BACKEND}_${subCommandName}_MANDATORY_OPTIONS})
	    IF(NOT DEFINED _o_${optName})
		ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${_o_ZANATA_BACKEND}" "${subCommand}" "${optName}" )
	    ENDIF()
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${_o_ZANATA_BACKEND}" "${subCommand}" "${optName}" )
	ENDFOREACH(optName)
    ENDIF()

    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_REAL_COMMAND)

#######################################
# ZANATA Put_Version
#

# MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND(<cmdListVar> <zanataExecutable> [SRC_DIR <srcDir> ] ...)
FUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND cmdListVar zanataExecutable)
    ### zanata_put-version
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(result "${zanataExecutable}" put-version
	ZANATA_SUBCOMMAND_PUT_VERSION_VALID_OPTIONS ${ARGN})
    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND)

FUNCTION(MANAGE_ZANATA_PUT_VERSION_TARGETS cmdList)
    ADD_CUSTOM_TARGET(zanata_put_version
	COMMAND ${cmdList}
	COMMENT "zanata_put-version: with ${cmdList}"
	DEPENDS ${zanataXml}
	)
ENDFUNCTION(MANAGE_ZANATA_PUT_VERSION_TARGETS)


#######################################
# ZANATA Push
#

# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(<cmdListVar> <zanataExecutable> [SRC_DIR <srcDir> ] ...)
FUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND cmdListVar zanataExecutable)
    ### zanata_push
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(result "${zanataExecutable}" push
	ZANATA_SUBCOMMAND_PUSH_VALID_OPTIONS ${ARGN})
    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND)

FUNCTION(MANAGE_ZANATA_PUSH_TARGETS cmdList)
    ADD_CUSTOM_TARGET(zanata_push
	COMMAND ${cmdList}
	COMMENT "zanata_push: with ${cmdList}"
	DEPENDS ${zanataXml}
	)

    LIST(GET cmdList 0 zanataExecutable)
    GET_FILENAME_COMPONENT(zanataBackend "${zanataExecutable}" NAME)

    ### zanata_push_both
    SET(extraOptions "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(extraOptions "${zanataBackend}" "PUSH_TYPE" "both")
    ADD_CUSTOM_TARGET(zanata_push_both 
	COMMAND ${cmdList} ${extraOptions}
	COMMENT "zanata_push: with ${cmdList} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_trans
    SET(extraOptions "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(extraOptions "${zanataBackend}" "PUSH_TYPE" "trans")
    ADD_CUSTOM_TARGET(zanata_push_trans 
	COMMAND ${cmdList} ${extraOptions}
	COMMENT "zanata_push: with ${cmdList} ${extraOptions}"
	DEPENDS ${zanataXml}
	)
ENDFUNCTION(MANAGE_ZANATA_PUSH_TARGETS)

#######################################
# ZANATA Pull
#

# MANAGE_ZANATA_OBTAIN_PULL_COMMAND(<cmdListVar> <zanataExecutable> [SRC_DIR <srcDir> ] ...)
FUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND cmdListVar zanataExecutable)
    ### zanata_push
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(result "${zanataExecutable}" pull
	ZANATA_SUBCOMMAND_PULL_VALID_OPTIONS ${ARGN})
    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND)

FUNCTION(MANAGE_ZANATA_PULL_TARGETS cmdList)
    ADD_CUSTOM_TARGET(zanata_pull
	COMMAND ${cmdList}
	COMMENT "zanata_pull: with ${cmdList}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_both
    SET(extraOptions "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(extraOptions "${zanataBackend}" "PULL_TYPE" "both")
    ADD_CUSTOM_TARGET(zanata_pull_both 
	COMMAND ${cmdList} ${extraOptions}
	COMMENT "zanata_pull: with ${cmdList} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

ENDFUNCTION(MANAGE_ZANATA_PULL_TARGETS)


#######################################
# ZANATA Main
#

FUNCTION(MANAGE_ZANATA)
    VARIABLE_PARSE_ARGN(_o MANAGE_ZANATA_VALID_OPTIONS ${ARGN})

    SET(_zanata_dependency_missing 0)
    ## Is zanata.ini exists
    IF("${_o_USER_CONFIG}" STREQUAL "")
	SET(_o_USER_CONFIG "$ENV{HOME}/.config/zanata.ini")
    ENDIF()
    IF(NOT DEFINED ${_o_USER_CONFIG})
	SET(_zanata_dependency_missing 1)
	M_MSG(${M_OFF} "MANAGE_ZANATA: Failed to find zanata.ini at ${_o_USER_CONFIG}"
	    )
    ENDIF(NOT DEFINED ${_o_USER_CONFIG})

    ## Find client command 
    IF("${_o_CLIENT_COMMAND}" STREQUAL "")
	FIND_PROGRAM_ERROR_HANDLING(ZANATA_EXECUTABLE
	    ERROR_MSG " Zanata support is disabled."
	    ERROR_VAR _zanata_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    FIND_ARGS NAMES zanata-cli mvn zanata
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
	GET_FILENAME_COMPONENT(ZANATA_BACKEND "${ZANATA_EXECUTABLE}" NAME)
	IF(ZANATA_BACKEND STREQUAL "mvn")
	ELSEIF(ZANATA_BACKEND STREQUAL "zanata-cli")
	ELSE()
	    M_MSG(${M_OFF} "${ZANATA_BACKEND} is ${_o_CLIENT_CMD} not a supported Zanata client")
	    RETURN()
	ENDIF()
    ENDIF()

    ## Manage zanata.xml
    IF(NOT "${_o}" STREQUAL "")
	SET(ZANATA_URL "${_o}" CACHE STRING "Zanata Server URL")
    ENDIF()
    IF("${_o_PROJECT_SLUG}" STREQUAL "")
	SET(_o_PROJECT_SLUG "${PROJECT_NAME}")
    ENDIF()
    IF("${_o_VERSION}" STREQUAL "")
	SET(_o_VERSION "${PRJ_VER}")
    ENDIF()
    IF(_o_PROJECT_CONFIG)
	SET(zanataXml "${_o_PROJECT_CONFIG}")
    ELSE()
	SET(zanataXml "${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml")
    ENDIF()
    IF(DEFINED _o_GENERATE_ZANATA_XML)
	ADD_CUSTOM_TARGET_COMMAND(zanata_xml
	    OUTPUT "${zanataXml}"
	    COMMAND ${CMAKE_COMMAND} 
	    -D cmd=zanata_xml_make
	    -D "url=${ZANATA_URL}"
	    -D "project=${_o_PROJECT_SLUG}"
	    -D "version=${_o_VERSION}"
	    -D "locales=${_o_LOCALES}"
	    -D "zanataXml=${zanataXml}"
	    -P ${CMAKE_FEDORA_MODULE_DIR}/ManageZanataScript.cmake
	    COMMENT "zanata_xml: ${zanataXml}"
	    VERBATIM
	    )
	IF(NOT DEFINED _o_CLEAN_ZANATA_XML)
	    SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")
	ENDIF()
    ENDIF()

    ## Convert to client options
    IF(DEFINED _o_YES)
	LIST(APPEND _o_CLIENT_COMMAND "-B")
    ENDIF()

    ### Common options
    SET(zanataCommonOptions "")
    FOREACH(optCName "URL" ${ZANATA_CLIENT_COMMON_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(zanataCommonOptions "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)

    IF("${_o_DEFAULT_PROJECT_TYPE}" STREQUAL "")
	SET(_o_DEFAULT_PROJECT_TYPE "gettext")
    ENDIF()

    ### zanata_put_project
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "put-project")
    SET(options "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(options "${ZANATA_BACKEND}" "project-slug" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(options "${ZANATA_BACKEND}" "project-name" "${PROJECT_NAME}")
    IF(NOT _prjSummaryLen GREATER ${ZANATA_DESCRIPTION_SIZE})
	SET(_description "${PRJ_SUMMARY}")
    ELSE()
	STRING(SUBSTRING "${PRJ_SUMMARY}" 0
	    ${ZANATA_DESCRIPTION_SIZE} _description
	    )
    ENDIF()
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(options "${ZANATA_BACKEND}" "project-desc" "${_description}")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(options "${ZANATA_BACKEND}" "default-project-type" "${_o_DEFAULT_PROJECT_TYPE}")
    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_put_project
	COMMAND ${exec}
	COMMENT "zanata_put_project: with ${exec}"
	)

    ### zanata_put_version 
    VARIABLE_TO_ARGN(putVersionOptions "_o" MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_VALID_OPTIONS)
    MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND(cmdPutVersionList "${ZANATA_EXECUTABLE}" ${putVersion})
    MANAGE_ZANATA_PUT_VERSION_TARGETS("${cmdPutVersionList}")

    ### zanata_push
    VARIABLE_TO_ARGN(pushOptions "_o" MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_VALID_OPTIONS)
    MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(cmdPushList "${ZANATA_EXECUTABLE}" ${pushOptions})
    MANAGE_ZANATA_PUSH_TARGETS("${cmdPushList}")


    ### zanata_pull
    VARIABLE_TO_ARGN(pullOptions "_o" MANAGE_ZANATA_OBTAIN_PULL_COMMAND_VALID_OPTIONS)
    MANAGE_ZANATA_OBTAIN_PULL_COMMAND(cmdPullList "${ZANATA_EXECUTABLE}" ${pullOptions} )
    MANAGE_ZANATA_PULL_TARGETS("${cmdPullList}")
ENDFUNCTION(MANAGE_ZANATA)

#######################################
# MANAGE_ZANATA_XML_MAKE
#
FUNCTION(ZANATA_LOCALE_COMPLETE var language script country modifier)
    IF("${modifier}" STREQUAL "")
	SET(sModifier "${ZANATA_SUGGEST_MODIFIER_${language}_${script}_}")
	IF(NOT "${sModifier}" STREQUAL "")
	    SET(modifier "${sModifier}")
	ENDIF()
    ENDIF()
    IF("${country}" STREQUAL "")
	SET(sCountry "${ZANATA_SUGGEST_COUNTRY_${language}_${script}_}")
	IF(NOT "${sCountry}" STREQUAL "")
	    SET(country "${sCountry}")
	ENDIF()
    ENDIF()
    IF("${script}" STREQUAL "")
	SET(sScript "${ZANATA_SUGGEST_SCRIPT_${language}_${country}_${modifier}}")
	IF(NOT "${sScript}" STREQUAL "")
	    SET(script "${sScript}")
	ENDIF()
    ENDIF()
    SET(${var} "${language}_${script}_${country}_${modifier}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_LOCALE_COMPLETE var locale)

FUNCTION(LOCALE_PARSE_STRING language script country modifier str)
    INCLUDE(ManageZanataSuggest)
    SET(s "")
    SET(c "")
    SET(m "")
    IF("${str}" MATCHES "(.*)@(.*)")
	SET(m "${CMAKE_MATCH_2}")
	SET(str "${CMAKE_MATCH_1}")
    ENDIF()
    STRING(REPLACE "-" "_" str "${str}")
    STRING_SPLIT(lA "_" "${str}")
    LIST(LENGTH lA lLen)
    LIST(GET lA 0 l)
    IF(lLen GREATER 2)
	LIST(GET lA 2 c)
    ENDIF()
    IF(lLen GREATER 1)
	LIST(GET lA 1 x)
	IF("${x}" MATCHES "[A-Z][a-z][a-z][a-z]")
	    SET(s "${x}")
	ELSE()
	    SET(c "${x}")
	ENDIF()
    ENDIF()

    SET(${language} "${l}" PARENT_SCOPE)
    SET(${script} "${s}" PARENT_SCOPE)
    SET(${country} "${c}" PARENT_SCOPE)
    SET(${modifier} "${m}" PARENT_SCOPE)
ENDFUNCTION(LOCALE_PARSE_STRING)

FUNCTION(ZANATA_JSON_GET_VALUE var key string)
    STRING(REGEX REPLACE ".*[{,]\"${key}\":\"([^\"]*)\".*" "\\1" ret "${string}")
    SET(${var} "${ret}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_JSON_GET_VALUE)

FUNCTION(ZANATA_JSON_TO_ARRAY var string)
    STRING(REGEX REPLACE "[[]\(.*\)[]]" "\\1" ret1 "${string}")
    STRING(REGEX REPLACE "},{" "};{" ret "${ret1}")
    SET(${var} "${ret}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_JSON_TO_ARRAY)

FUNCTION(ZANATA_REST_GET_PROJECT_VERSION_TYPE var url project version)
    SET(restUrl "${url}rest/projects/p/${project}/iterations/i/${version}")
    EXECUTE_PROCESS(COMMAND curl -f -G -s -H  "Content-Type:application/json" 
	-H "Accept:application/json" "${restUrl}"
	RESULT_VARIABLE curlRet
	OUTPUT_VARIABLE curlOut)
    IF(NOT curlRet EQUAL 0)
	M_MSG(${M_OFF} "Failed to get project type from project ${project} to ${version} with ${url}")
	RETURN()
    ENDIF()
    ZANATA_JSON_GET_VALUE(ret "projectType" "${curlOut}")
    SET(${var} "${ret}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_REST_GET_PROJECT_VERSION_TYPE)

FUNCTION(ZANATA_REST_GET_PROJECT_VERSION_LOCALES var url project version)
    SET(restUrl "${url}rest/projects/p/${project}/iterations/i/${version}/locales")
    EXECUTE_PROCESS(COMMAND curl -f -G -s -H  "Content-Type:application/json" 
	-H "Accept:application/json" "${restUrl}"
	RESULT_VARIABLE curlRet
	OUTPUT_VARIABLE curlOut)
    IF(NOT curlRet EQUAL 0)
	M_MSG(${M_OFF} "Failed to get project type from project ${project} to ${version} with ${url}")
	RETURN()
    ENDIF()
    ZANATA_JSON_TO_ARRAY(nodeArray "${curlOut}")
    SET(retArray "")
    FOREACH(node ${nodeArray})
	ZANATA_JSON_GET_VALUE(l "localeId" "${node}")
	LIST(APPEND retArray "${l}")
    ENDFOREACH()
    SET(${var} "${retArray}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_REST_GET_PROJECT_VERSION_LOCALES)

FUNCTION(ZANATA_ZANATA_XML_DOWNLOAD zanataXml url project version)
    SET(zanataXmlUrl 
	"${url}iteration/view/${project}/${version}?actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29"
	)
    GET_FILENAME_COMPONENT(zanataXmlDir "${zanataXml}" PATH)
    IF(NOT zanataXmlDir)
	SET(zanataXml "./${zanataXml}")
    ENDIF()
    FILE(DOWNLOAD "${zanataXmlUrl}" "${zanataXml}" LOG logv)
    M_MSG(${M_INFO1} "LOG=${logv}")
ENDFUNCTION(ZANATA_ZANATA_XML_DOWNLOAD)

FUNCTION(ZANATA_BEST_MATCH_LOCALES var serverLocales clientLocales)
    ## Build "Client Hash"
    SET(result "")
    FOREACH(cL ${clientLocales})
	LOCALE_PARSE_STRING(cLang cScript cCountry cModifier "${cL}")
	SET(_ZANATA_CLIENT_LOCALE_${cLang}_${cScript}_${cCountry}_${cModifier} "${cL}")
	ZANATA_LOCALE_COMPLETE(cCLocale "${cLang}" "${cScript}" "${cCountry}" "${cModifier}")
	SET(compKey "_ZANATA_CLIENT_COMPLETE_LOCALE_${cCLocale}")
	IF("${${compKey}}" STREQUAL "")
	    SET("${compKey}" "${cL}")
	ENDIF()
    ENDFOREACH()

    ## 1st pass: Exact match
    FOREACH(sL ${serverLocales})
	LOCALE_PARSE_STRING(sLang sScript sCountry sModifier "${sL}")
	SET(scKey "_ZANATA_CLIENT_LOCALE_${sLang}_${sScript}_${sCountry}_${sModifier}")
	## Exact match locale
	SET(cLExact "${${scKey}}")
	IF(NOT "${cLExact}" STREQUAL "")
	    SET(_ZANATA_SERVER_LOCALE_${sL} "${cLExact}")
	    SET(_ZANATA_CLIENT_LOCALE_${cLExact}  "${sL}")
	    LIST(APPEND result "${sL},${cLExact}")
	ENDIF()
    ENDFOREACH() 

    ## 2nd pass: Find the next best match
    FOREACH(sL ${serverLocales})
	IF("${_ZANATA_SERVER_LOCALE_${sL}}" STREQUAL "")
	    ## no exact match
	    LOCALE_PARSE_STRING(sLang sScript sCountry sModifier "${sL}")

	    ## Locale completion
	    ZANATA_LOCALE_COMPLETE(sCLocale "${sLang}" "${sScript}" "${sCountry}" "${sModifier}")
	    SET(sCompKey "_ZANATA_CLIENT_COMPLETE_LOCALE_${sCLocale}")
	    SET(bestMatch "")

	    ## Match client locale after Locale completion
	    SET(cLComp "${${sCompKey}}")
	    IF(NOT "${cLComp}" STREQUAL "")
		## And the client locale is not occupied
		IF("${_ZANATA_CLIENT_LOCALE_${cLComp}}" STREQUAL "")
		    SET(_ZANATA_SERVER_LOCALE_${sL} "${cLComp}")
		    SET(_ZANATA_CLIENT_LOCALE_${cLComp}  "${sL}")
		    SET(bestMatch "${cLComp}")
		ENDIF()
	    ENDIF()
	    IF(bestMatch STREQUAL "")
		## No matched, use corrected sL
		STRING(REPLACE "-" "_" bestMatch "${sL}")
		IF("${bestMatch}" STREQUAL "${sL}")
		    M_MSG(${M_OFF} "${sL} does not have matched client locale, use as-is.")
		ELSE()
		    M_MSG(${M_OFF} "${sL} does not have matched client locale, use ${bestMatch}.")
		ENDIF()
	    ENDIF()
	    LIST(APPEND result "${sL},${bestMatch}")
	ENDIF()
    ENDFOREACH() 
    LIST(SORT result)
    SET(${var} "${result}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_BEST_MATCH_LOCALES)

FUNCTION(ZANATA_ZANATA_XML_MAP zanataXml zanataXmlIn workDir)
    INCLUDE(ManageTranslation)
    INCLUDE(ManageZanataSuggest)
    FILE(STRINGS "${zanataXmlIn}" zanataXmlLines)
    FILE(REMOVE ${zanataXml})

    ## Build "Client Hash"
    MANAGE_GETTEXT_LOCALES(clientLocales WORKING_DIRECTORY "${workDir}" DETECT_PO_DIR poDir ${ARGN})
    IF("${poDir}" STREQUAL "")
	SET(poDir ".")
    ENDIF()

    MANAGE_GETTEXT_DETECT_POT_DIR(potDir WORKING_DIRECTORY "${workDir}")
    IF("${potDir}" STREQUAL "NOTFOUND")
	M_MSG(${M_ERROR} "ZANATA_ZANATA_XML_MAP: Failed to detect pot dir because .pot files are not found in ${workDir}")
    ELSEIF("${potDir}" STREQUAL "")
	SET(potDir ".")
    ENDIF()


    ## Last resort
    IF("${clientLocales}" STREQUAL "")
	MANAGE_GETTEXT_LOCALES(clientLocales SYSTEM_LOCALES)
    ENDIF()
    M_MSG(${M_INFO3} "clientLocales=${clientLocales}")
    SET(serverLocales "")
    SET(zanataXmlHeader "")
    SET(zanataXmlFooter "")
    SET(zanataXmlIsHeader 1)
    SET(srcDirOrig "")
    SET(transDirOrig "")

    ## Start parsing zanataXmlIn and gather serverLocales
    FOREACH(line ${zanataXmlLines})
	IF("${line}" MATCHES "<locale>(.*)</locale>")
	    ## Is a locale string
	    SET(sL "${CMAKE_MATCH_1}")
	    LIST(APPEND serverLocales "${sL}")
	ELSEIF("${line}" MATCHES "<src-dir>(.*)</src-dir>")
	    SET(srcDirOrig "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<trans-dir>(.*)</trans-dir>")
	    SET(transDirOrig "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<locales>")
	    SET(transDirOrig "${CMAKE_MATCH_1}")
	    Set(zanataXmlIsHeader 0)
	ELSE()
	    IF(zanataXmlIsHeader)
		STRING_APPEND(zanataXmlHeader "${line}" "\n")
	    ELSE()
		STRING_APPEND(zanataXmlFooter "${line}" "\n")
	    ENDIF()
	    ## Not a locale string, write as-is
	ENDIF()
    ENDFOREACH()
    LIST(SORT serverLocales)
    ZANATA_BEST_MATCH_LOCALES(bestMatches "${serverLocales}" "${clientLocales}")

    FILE(WRITE "${zanataXml}" "${zanataXmlHeader}\n")

    FILE(APPEND "${zanataXml}" "  <src-dir>${potDir}</src-dir>\n")
    FILE(APPEND "${zanataXml}" "  <trans-dir>${poDir}</trans-dir>\n")
    FILE(APPEND "${zanataXml}" "  <locales>\n")

    FOREACH(bM ${bestMatches})
	STRING_SPLIT(lA "," "${bM}")
	LIST(GET lA 0 sLocale)
	LIST(GET lA 1 cLocale)
	IF("${sLocale}" STREQUAL "${cLocale}")
	    FILE(APPEND "${zanataXml}" "    <locale>${sLocale}</locale>\n")
	ELSE()
	    FILE(APPEND "${zanataXml}" "    <locale map-from=\"${cLocale}\">${sLocale}</locale>\n")
	ENDIF()
    ENDFOREACH(bM)
    FILE(APPEND "${zanataXml}" "${zanataXmlFooter}\n")
ENDFUNCTION(ZANATA_ZANATA_XML_MAP)



