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
#   MANAGE_ZANATA([[URL] <serverUrl>] [YES] [ERRORS] [DEBUG]
#       [CHUNK_SIZE <sizeInByte>]
#       [CLEAN_ZANATA_XML]
#       [CLIENT_COMMAND <command> ]
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
#       [ZANATA_EXECUTABLE <command> ]
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
#         * zanata-cli: Zanata java command line client.
#         * mvn: Maven build system.
#         * zanata: Zanata python command line client.
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
#         + CLIENT_COMMAND command: (Optional)(Depreciated) command path to Zanata client.
#           Use ZANATA_EXECUTABLE instead.
#           Default: "zanata-cli"
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
#         + ZANATA_EXECUTABLE command : (Optional) command path to Zanata client.
#           Default: "zanata-cli"
#       * Targets:
#         + zanata_put_projet: Put project in zanata server.
#         + zanata_put_version: Put version in zanata server.
#         + zanata_push: Push source messages to zanata server.
#         + zanata_push_trans: Push translations to  zanata server.
#         + zanata_push_both: Push source messages and translations to
#             zanata server.
#         + zanata_pull: Pull translations from zanata server.
#       * Variable Cached:
#         + ZANATA_CLIENT_EXECUTABLE: Full path of the client program.
#         + ZANATA_CLIENT_TYPE: The type of Zanata client, either
#             java: Java client
#             python: Python client
#             mvn: zanata-maven-plugin
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

## Variable ZANATA_* are compulsory  
SET(ZANATA_DESCRIPTION_SIZE 80 CACHE STRING "Zanata description size")

#######################################
# ZANATA "Object"
#
MACRO(MANAGE_ZANATA_XML_OBJECT_NEW var url )
    SET(${var} "url")
    SET(${var}_url "${url}")
    FOREACH(arg ${ARGN})
	IF("${${var}_project}" STREQUAL "")
	    MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY(${var} "project" "${arg}")
	ELSEIF("${${var}_version}" STREQUAL "")
	    MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY(${var} "version" "${arg}")
	ELSEIF("${${var}_type}" STREQUAL "")
	    MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY(${var} "type" "${arg}")
	ENDIF()
    ENDFOREACH(arg)
ENDMACRO(MANAGE_ZANATA_XML_OBJECT_NEW)

MACRO(MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY var key value )
    LIST(APPEND ${var} "${key}")
    SET(${var}_${key} "${value}")
ENDMACRO(MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY)

FUNCTION(MANAGE_ZANATA_XML_OBJECT_TO_STRING outputVar var)
    SET(buf "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
    STRING_APPEND(buf "<config xmlns=\"http://zanata.org/namespace/config/\">" "\n")
    STRING_APPEND(buf "  <url>${${var}_url}</url>" "\n")
    STRING_APPEND(buf "  <project>${${var}_project}</project>" "\n")
    STRING_APPEND(buf "  <project-version>${${var}_version}</project-version>" "\n")
    STRING(TOLOWER "${${var}_type}" projectType)
    STRING_APPEND(buf "  <project-type>${projectType}</project-type>" "\n")
    IF(NOT "${${var}_srcdir}" STREQUAL "")
	STRING_APPEND(buf "  <src-dir>${${var}_srcdir}</src-dyr>" "\n")
    ENDIF()
    IF(NOT "${${var}_transdir}" STREQUAL "")
	STRING_APPEND(buf "  <trans-dir>${${var}_transdir}</trans-dir>" "\n")
    ENDIF()
    IF(NOT "${${var}_locales}" STREQUAL "")
	STRING_APPEND(buf "  <locales>" "\n")
	FOREACH(l ${${${var}_locales})
	    IF(NOT "${${var}_locales_${l}}" STREQUAL "")
		STRING_APPEND(buf "    <locale map-from=\"${${var}_locales_${l}}\">${l}</locale>" "\n")
	    ELSE()
		STRING_APPEND(buf "    <locale>${l}</locale>" "\n")
	    ENDIF()
	ENDFOREACH(l)
	STRING_APPEND(buf "  </locales>" "\n")
    ENDIF()
    STRING_APPEND(buf "</config>" "\n")
    SET(${outputVar} "${buf}" PARENT_SCOPE)
ENDFUNCTION(MANAGE_ZANATA_XML_OBJECT_TO_STRING)

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

FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_JAVA listVar subCommandName optName)
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
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND_JAVA)

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

FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND listVar subCommand optName)
    ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE(subCommandName "${subCommand}")
    ## Skip Options that should not in the final command
    IF(optName STREQUAL "ZANATA_EXECUTABLE")
	RETURN()
    ENDIF()

    ## Invoke corresponding command
    IF(ZANATA_CLIENT_TYPE STREQUAL "mvn")
	ZANATA_CLIENT_OPTNAME_LIST_APPEND_MVN(${listVar} ${subCommandName} ${optName} ${ARGN})
    ELSEIF(ZANATA_CLIENT_TYPE STREQUAL "java")
	ZANATA_CLIENT_OPTNAME_LIST_APPEND_JAVA(${listVar} ${subCommandName} ${optName} ${ARGN})
    ELSEIF(ZANATA_CLIENT_TYPE STREQUAL "python")
	ZANATA_CLIENT_OPTNAME_LIST_APPEND_PYTHON(${listVar} ${subCommandName} ${optName} ${ARGN})
    ELSE()
	M_MSG(${M_ERROR} "ManageZanata: Unrecognized zanata client type ${ZANATA_CLIENT_TYPE}")
    ENDIF()
    SET(${listVar} "${${listVar}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_APPEND)

## ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND(var subCommand opt)
## e.g ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND(srcDir push "srcDir=.")
FUNCTION(ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND var subCommand opt)
    STRING_SPLIT(_list "=" "${opt}")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(${var} ${subCommand} ${_list})
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPTNAME_LIST_PARSE_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_SUB_COMMAND var subCommand)
    IF(ZANATA_CLIENT_TYPE STREQUAL "mvn")
	SET(${var} "${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:${subCommand}" PARENT_SCOPE)
    ELSEIF(ZANATA_CLIENT_TYPE STREQUAL "python")
	## Python client
	IF("${subCommand}" STREQUAL "put-project")
	    SET(${var} "project" "create" PARENT_SCOPE)
	ELSEIF("${subCommand}" STREQUAL "put-version")
	    SET(${var} "version" "create" PARENT_SCOPE)
	ELSE()
	    SET(${var} "${subCommand}" PARENT_SCOPE)
	ENDIF()
    ELSE()
	## java
	SET(${var} "${subCommand}" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION(ZANATA_CLIENT_SUB_COMMAND)

## Set variable for ZANATA
FUNCTION(ZANATA_SET_CACHE_VAR mapVar key)
    IF(NOT DEFINED ZANATA_OPTION_NAME_${key}_VAR_TYPE)
	M_MSG(${M_ERROR} "[ManageZanata] key ${key} is invalid")
	RETURN()
    ENDIF()

    IF("${${mapVar}_${key}}" STREQUAL "")
	IF(key STREQUAL "PROJECT")
	    SET(v "${PROJECT_NAME}")
	ELSEIF(key STREQUAL "PROJECT_CONFIG")
	    SET(v "${CMAKE_CURRENT_DIR_DIR}/zanata.xml")
	ELSEIF(key STREQUAL "USER_CONFIG")
	    SET(v "$ENV{HOME}/.config/zanata.ini")
	ELSE()
	    SET(v "${ZANATA_OPTION_NAME_${key}_DEFAULT}")
	ENDIF()
	SET(force "")
    ELSE()
	SET(v "${${mapVar}_${key}}")
	SET(force "FORCE")
    ENDIF()
    SET(ZANATA_${key} "${v}" CACHE "${ZANATA_OPTION_NAME_VAR_TYPE}" "ZANATA_${key}" ${force})
ENDFUNCTION(ZANATA_SET_CACHE_VAR)

## ZANATA_CMAKE_OPTIONS_PARSE_OPTIONSMAP <varPrefix> [ARGN]
##   Parse the arguments from MANAGE_ZANATA.
## Returns: <varPrefix> contains the specified arguments
## Defines: <varPrefix>_<ARGUMENT> with value 
FUNCTION(ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP varPrefix)
    ## isValue=2 Must be an option value
    ## isValue=1 Maybe either
    ## isValue=0 Must be an option name
    SET(result "")
    SET(isValue 1)
    SET(isOptName 1)
    SET(optName "")
    SET(dependencyMissing 0)

    FOREACH(opt ${ARGN})
	IF(isValue EQUAL 1)
	    ## Can be either, determine what it is
	    IF(DEFINED ZANATA_OPTION_NAME_${opt})
		## This is a new option name
		SET(isValue 0)
	    ELSEIF(NOT "${optName}" STREQUAL "")
		## This should be an option value
		SET(isValue 2)
	    ELSEIF(opt MATCHES "^http")
		## Zanata server url
		SET(optName "URL")
		SET(isValue 2)
	        LIST(APPEND ${varPrefix} "${optName}")
	    ELSE()
		## Cannot decided
		M_MSG(${M_ERROR} "ManageZanata: String '${opt}' is neither a option name, nor a value")
	    ENDIF()
	ENDIF()

	IF (isValue EQUAL 0)
	    ## Must be option name
	    IF(NOT DEFINED ZANATA_OPTION_NAME_${opt})
		M_MSG(${M_ERROR} "ManageZanata: Unrecognized option name ${opt}")
	    ENDIF()

	    IF(DEFINED ZANATA_OPTION_ALIAS_${opt})
		SET(optName "${ZANATA_OPTION_ALIAS_${opt}}")
	    ELSE()
		SET(optName "${opt}")
	    ENDIF()
	    LIST(APPEND ${varPrefix} "${optName}")

	    ## Find on next opt is value or option name
	    LIST(GET ZANATA_OPTION_NAME_${optName} 0 isValue)

	    ## Set value as 1 for no or optional value, as DEFINED is not reliable for sibling functions
	    IF(isValue LESS 2)
	        SET(${varPrefix}_${optName} "1")
	        SET(${varPrefix}_${optName} "1" PARENT_SCOPE)
	    ENDIF()
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
	    ## Invalid Argument
	    M_MSG(${M_ERROR} "ManageZanata: Error: isValue should not be ${isValue} with string '${opt}' ")
	ENDIF()
    ENDFOREACH()

    ##== Set cache variable
    FOREACH(optName ${ZANATA_OPTION_INIT_LIST})
	ZANATA_SET_CACHE_VAR(${varPrefix} "${optName}")
    ENDFOREACH()

    ##== Variable that need to check
    ## USER_CONFIG
    IF(NOT EXISTS "${ZANATA_USER_CONFIG}")
	SET(dependencyMissing 1)
	M_MSG(${M_OFF} "MANAGE_ZANATA: Failed to find zanata.ini at ${ZANATA_USER_CONFIG}")
    ENDIF()

    ## ZANATA_CLIENT_EXECUTABLE
    IF("${_o_ZANATA_EXECUTABLE}" STREQUAL "")
	IF("${ZANATA_CLIENT_EXECUTABLE}" STREQUAL "")
	    SET(zanataClientMissing 0)
	    FIND_PROGRAM_ERROR_HANDLING(ZANATA_CLIENT_EXECUTABLE
		ERROR_MSG " Zanata support is disabled."
		ERROR_VAR zanataClientMissing
		VERBOSE_LEVEL ${M_OFF}
		FIND_ARGS NAMES zanata-cli mvn zanata
		)
	    IF(zanataClientMissing EQUAL 1)
		SET(dependencyMissing 1)
		M_MSG(${M_OFF} "MANAGE_ZANATA: Failed to find zanata client, Zanata support disabled")
	    ELSE()
		SET(ZANATA_CLIENT_EXECUTABLE "${ZANATA_CLIENT_EXECUTABLE}"
		    CACHE FILEPATH "Zanata client excutable"
		    )
	    ENDIF()
	ENDIF()
    ELSE()
	LIST(GET ${varPrefix}_ZANATA_EXECUTABLE 0 ZANATA_CLIENT_EXECUTABLE)
	SET(ZANATA_CLIENT_EXECUTABLE "${${varPrefix}_ZANATA_EXECUTABLE}"
	    CACHE FILEPATH "Zanata client excutable" FORCE
	    )
    ENDIF()
    GET_FILENAME_COMPONENT(zanataClientFilename "${ZANATA_CLIENT_EXECUTABLE}" NAME)
    IF(zanataClientFilename STREQUAL "zanata")
	SET(ZANATA_CLIENT_TYPE "python" CACHE INTERNAL "Zanata Client Type")
    ELSEIF(zanataClientFilename STREQUAL "zanata-cli")
	SET(ZANATA_CLIENT_TYPE "java" CACHE INTERNAL "Zanata Client Type")
    ELSEIF(zanataClientFilename STREQUAL "mvn")
	SET(ZANATA_CLIENT_TYPE "mvn" CACHE INTERNAL "Zanata Client Type")
    ELSE()
	M_MSG(${M_OFF} "${ZANATA_CLIENT_EXECUTABLE} is not a supported Zanata client")
	SET(dependencyMissing 1)
    ENDIF()

    IF(dependencyMissing EQUAL 1)
	SET(${varPrefix}_DEPENDENCY_MISSING 1 PARENT_SCOPE)
	RETURN()
    ENDIF()

    ##== Other Variables
    IF("${${varPrefix}_PROJECT_DESC}" STREQUAL "")
	SET(${varPrefix}_PROJECT_DESC "${PRJ_SUMMARY}")
    ENDIF()
    STRING(LENGTH "${${varPrefix}_PROJECT_DESC}" _prjSummaryLen)
    IF(_prjSummaryLen GREATER ${ZANATA_DESCRIPTION_SIZE})
	STRING(SUBSTRING "${${varPrefix}_PROJECT_DESC}" 0 ${ZANATA_DESCRIPTION_SIZE} 
	    ${varPrefix}_PROJECT_DESC
	    )
    ENDIF()
    SET(${varPrefix}_PROJECT_DESC "${${varPrefix}_PROJECT_DESC}" PARENT_SCOPE)

    SET(${varPrefix} "${${varPrefix}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP)

#   MANAGE_ZANATA_OBTAIN_REAL_COMMAND(<cmdListVar>
#       <subCommand> <optionMapVar>
#       [YES] [BATCH] [ERRORS] [DEBUG]
#       [DISABLE_SSL_CERT]
#       [URL <url>]
#       [USERNAME <username>]
#       [KEY <key>]
#       [USER_CONFIG <zanata.ini>]
#       ...
#     )

FUNCTION(MANAGE_ZANATA_OBTAIN_REAL_COMMAND cmdListVar subCommand optionMapVar)
    IF(${optionMapVar}_BATCH)
	IF(${optionMapVar}_BACKEND STREQUAL "python")
	    SET(result "yes" "|" "${ZANATA_CLIENT_EXECUTABLE}")
	ELSE()
	    SET(result "${ZANATA_CLIENT_EXECUTABLE}")
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${subCommand}" "BATCH" )
	ENDIF()
    ELSE()
	SET(result "${ZANATA_CLIENT_EXECUTABLE}")
    ENDIF()

    FOREACH(optName "DEBUG" "ERRORS")
	IF(${optionMapVar}_${optName})
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${subCommand}" "${optName}" )
	ENDIF()
    ENDFOREACH(optName)

    ## Sub-command
    ZANATA_CLIENT_SUB_COMMAND(subCommandReal "${subCommand}")
    LIST(APPEND result "${subCommandReal}")

    ## Explicit Options
    FOREACH(optName ${${optionMapVar}})
	IF(optName STREQUAL "BATCH")
	ELSEIF(optName STREQUAL "DEBUG")
	ELSEIF(optName STREQUAL "ERRORS")
	ELSE()
	    IF(${optionMapVar}_${optName})
		IF(ZANATA_OPTION_NAME_${optName} EQUAL 1 AND "${${optionMapVar}_${optName}}" STREQUAL "1")
		    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${subCommand}" "${optName}")
		ELSE()
		    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${subCommand}" "${optName}"  "${${optionMapVar}_${optName}}")
		ENDIF()
	    ENDIF()
	ENDIF()
    ENDFOREACH(optName)

    ## Implied options: Mandatory options but not specified.
    ZANATA_STRING_LOWERCASE_DASH_TO_UPPERCASE_UNDERSCORE(subCommandName "${subCommand}")
    STRING(TOUPPER "${ZANATA_CLIENT_TYPE}" zanataClientTypeUpper)
    
    IF(DEFINED ZANATA_${zanataClientTypeUpper}_${subCommandName}_MANDATORY_OPTIONS)
	FOREACH(optName ${ZANATA_${zanataClientTypeUpper}_${subCommandName}_MANDATORY_OPTIONS})
	    IF(DEFINED ZANATA_${optName})
		## Implied options
		IF("${${optionMapVar}_${optName}}" STREQUAL "")
		    ## Not yet append as exlicit options
		    ZANATA_CLIENT_OPTNAME_LIST_APPEND(result "${subCommand}" "${optName}" "${ZANATA_${optName}}")
		ENDIF()
	    ENDIF()
	ENDFOREACH(optName)
    ENDIF()

    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_REAL_COMMAND)

#######################################
# ZANATA Put_Version
#

# MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND(<cmdListVar> <optionMapVar>)
FUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND cmdListVar optionMapVar) 
    ### zanata_put-version
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(result put-version ${optionMapVar})
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

# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(<cmdListVar> <optionMapVar>)
FUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND cmdListVar optionMapVar)
    ### zanata_push
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(result push ${optionMapVar})
    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND)

FUNCTION(MANAGE_ZANATA_PUSH_TARGETS cmdList)
    ADD_CUSTOM_TARGET(zanata_push
	COMMAND ${cmdList}
	COMMENT "zanata_push: with ${cmdList}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_both
    SET(extraOptions "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(extraOptions "PUSH_TYPE" "both")
    ADD_CUSTOM_TARGET(zanata_push_both 
	COMMAND ${cmdList} ${extraOptions}
	COMMENT "zanata_push: with ${cmdList} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_trans
    SET(extraOptions "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(extraOptions "PUSH_TYPE" "trans")
    ADD_CUSTOM_TARGET(zanata_push_trans 
	COMMAND ${cmdList} ${extraOptions}
	COMMENT "zanata_push: with ${cmdList} ${extraOptions}"
	DEPENDS ${zanataXml}
	)
ENDFUNCTION(MANAGE_ZANATA_PUSH_TARGETS)

#######################################
# ZANATA Pull
#

# MANAGE_ZANATA_OBTAIN_PULL_COMMAND(<cmdListVar> <optionMapVar>)
FUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND cmdListVar optionMapVar)
    ### zanata_pull
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(result pull ${optionMapVar})
    SET(${cmdListVar} "${result}" PARENT_SCOPE) 
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND)

FUNCTION(MANAGE_ZANATA_PULL_TARGETS cmdList)
    ADD_CUSTOM_TARGET(zanata_pull
	COMMAND ${cmdList}
	COMMENT "zanata_pull: with ${cmdList}"
	DEPENDS ${zanataXml}
	)

    ### zanata_pull_both
    SET(extraOptions "")
    ZANATA_CLIENT_OPTNAME_LIST_APPEND(extraOptions "PULL_TYPE" "both")
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
    ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP(_o ${ARGN})

    IF(_o_DEPENDENCIES_MISSING EQUAL 1)
	RETURN()
    ENDIF()

    ### Common options
    SET(zanataCommonOptions "")
    FOREACH(optCName "URL" ${ZANATA_CLIENT_COMMON_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPTNAME_LIST_APPEND(zanataCommonOptions "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)

    ### zanata_put_project
    SET(exec "")
    MANAGE_ZANATA_OBTAIN_REAL_COMMAND(exec put-project _o)
    LIST(APPEND exec  ${zanataCommonOptions}) 
    ADD_CUSTOM_TARGET(zanata_put_project
	COMMAND ${exec}
	COMMENT "zanata_put_project: with ${exec}"
	)

    ### zanata_put_version 
    MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND(cmdPushList _o)
    MANAGE_ZANATA_PUT_VERSION_TARGETS("${cmdPushList}")

    ### zanata_push
    MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(cmdPushList _o)
    MANAGE_ZANATA_PUSH_TARGETS("${cmdPushList}")

    ### zanata_pull
    MANAGE_ZANATA_OBTAIN_PULL_COMMAND(cmdPullList _o)
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
    GET_FILENAME_COMPONENT(zanataXmlDir "${zanataXml}" PATH)
    IF(NOT zanataXmlDir)
	SET(zanataXml "./${zanataXml}")
    ENDIF()

    ZANATA_REST_GET_PROJECT_VERSION_TYPE(pType "${url}" "${project}" "${version}")
    MANAGE_ZANATA_XML_OBJECT_NEW(zObj "${url}" "${project}" "${version}" "${pType}")
    MANAGE_ZANATA_XML_OBJECT_TO_STRING(buf zObj)
    FILE(WRITE "${zanataXml}" "${buf}")
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

    ## Start parsing zanataXmlIn and gather serverLocales
    SET(serverLocales "")
    SET(srcDirOrig "")
    SET(transDirOrig "")
    FOREACH(line ${zanataXmlLines})
	IF("${line}" MATCHES "<locale>(.*)</locale>")
	    ## Is a locale string
	    SET(sL "${CMAKE_MATCH_1}")
	    LIST(APPEND serverLocales "${sL}")
	ELSEIF("${line}" MATCHES "<src-dir>(.*)</src-dir>")
	    SET(srcDirOrig "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<trans-dir>(.*)</trans-dir>")
	    SET(transDirOrig "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<url>(.*)</url>")
	    SET(url "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<project>(.*)</project>")
	    SET(project "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<project-version>(.*)</project-version>")
	    SET(version "${CMAKE_MATCH_1}")
	ELSEIF("${line}" MATCHES "<project-type>(.*)</project-type>")
	    SET(projectType "${CMAKE_MATCH_1}")
	ELSE()
	    IF(zanataXmlIsHeader)
		STRING_APPEND(zanataXmlHeader "${line}" "\n")
	    ELSE()
		STRING_APPEND(zanataXmlFooter "${line}" "\n")
	    ENDIF()
	    ## Not a locale string, write as-is
	ENDIF()
    ENDFOREACH()

    MANAGE_ZANATA_XML_OBJECT_NEW(zObj ${url} ${project} ${version} ${projectType})

    ## Build "Client Hash"
    MANAGE_GETTEXT_LOCALES(clientLocales WORKING_DIRECTORY "${workDir}" DETECT_PO_DIR poDir ${ARGN})
    IF(NOT "${srcDirOrig}" STREQUAL "")
	SET(poDir "${srcDirOrig}")
    ELSEIF("${poDir}" STREQUAL "")
	SET(poDir ".")
    ENDIF()

    IF(NOT "${transDirOrig}" STREQUAL "")
	SET(potDir "${transDirOrig}")
    ELSE()
	MANAGE_GETTEXT_DETECT_POT_DIR(potDir WORKING_DIRECTORY "${workDir}")
	IF("${potDir}" STREQUAL "NOTFOUND")
	    M_MSG(${M_ERROR} "ZANATA_ZANATA_XML_MAP: Failed to detect pot dir because .pot files are not found in ${workDir}")
	ELSEIF("${potDir}" STREQUAL "")
	    SET(potDir ".")
	ENDIF()
    ENDIF()
    MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY(zObj "src-dir" "${potDir}")
    MANAGE_ZANATA_XML_OBJECT_ADD_PROPERTY(zObj "trans-dir" "${poDir}")

    
    IF(NOT "${serverLocales}" STREQUAL "")
	## If server locales are available, then start matching the client and server locales

	## clientLocales if not specified
	IF("${clientLocales}" STREQUAL "")
	    MANAGE_GETTEXT_LOCALES(clientLocales SYSTEM_LOCALES)
	ENDIF()
	M_MSG(${M_INFO3} "clientLocales=${clientLocales}")

	LIST(SORT serverLocales)
	ZANATA_BEST_MATCH_LOCALES(bestMatches "${serverLocales}" "${clientLocales}")

	FOREACH(bM ${bestMatches})
	    STRING_SPLIT(lA "," "${bM}")
	    LIST(GET lA 0 sLocale)
	    LIST(GET lA 1 cLocale)
	    LIST(APPEND zObj_locales "${sLocale}")

	    IF(NOT "${sLocale}" STREQUAL "${cLocale}")
		SET(zObj_locales_${sLocale} "${cLocale}")
	    ENDIF()
	ENDFOREACH(bM)
    ENDIF(NOT "${serverLocales}" STREQUAL "")

    MANAGE_ZANATA_XML_OBJECT_TO_STRING(outputBuf zObj)
    FILE(WRITE "${zanataXml}" "${outputBuf}")
ENDFUNCTION(ZANATA_ZANATA_XML_MAP)



