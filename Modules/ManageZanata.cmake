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
# Read following variables:
#   - MANAGE_TRANSLATION_LOCALES: Locales that would be processed.
#
# Define following functions:
#   MANAGE_ZANATA([<serverUrl>] [YES]
#       [DEFAULT_PROJECT_TYPE <projectType>]
#       [PROJECT_TYPE <projectType>]
#       [PROJECT_SLUG <projectId>]
#       [VERSION <ver>]
#       [USERNAME <username>]
#       [CLIENT_COMMAND <command> ... ]
#       [LOCALES <locale1,locale2...> ]
#       [SRC_DIR <srcDir>]
#       [TRANS_DIR <transDir>]
#       [PUSH_OPTIONS <option> ... ]
#       [PULL_OPTIONS <option> ... ]
#       [DISABLE_SSL_CERT]
#       [GENERATE_ZANATA_XML]
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
#         + DEFAULT_PROJECT_TYPE projectType::(Optional) Zanata project-type 
#             on creating project.
#           Valid values: file, gettext, podir, properties,
#             utf8properties, xliff
#           Default: gettext
#         + PROJECT_TYPE projectType::(Optional) Zanata project type 
#             for this version.
#	      Normally version inherit the project-type from project,
#             if this is not the case, use this parameter to specify
#             the project type.
#           Valid values: file, gettext, podir, properties,
#             utf8properties, xliff
#         + PROJECT_SLUG projectId: (Optional) This project ID in Zanata
#           It is required if it is different from PROJECT_NAME
#           Default: PROJECT_NAME
#         + VERSION version: (Optional) The version to push
#         + USERNAME username: (Optional) Zanata username
#         + CLIENT_COMMAND command ... : (Optional) Zanata client.
#             Specify zanata client.
#           Default: mvn -e
#         + LOCALES locales: Locales to sync with Zanata.
#             Specify the locales to sync with this Zanata server.
#             If not specified, it uses MANAGE_TRANSLATION_LOCALES,
#             which is produced by MANAGE_POT_FILE.
#         + SRC_DIR dir: (Optional) Directory to put source documents 
#             (e.g. .pot).
#           Default: CMAKE_CURRENT_SOURCE_DIR
#         + TRANS-DIR dir: (Optional) Directory to put translated documents.
#           Default: CMAKE_CURRENT_BINARY_DIR
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
#         + GENERATE_ZANATA_XML: (Optional) Automatic generate a Zanata.xml
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
FUNCTION(ZANATA_CLIENT_OPT_LIST_APPEND var backend opt)
    STRING(REPLACE "_" "-" opt "${opt}")
    STRING(TOLOWER "${opt}" opt)
    IF(NOT "${ARGN}" STREQUAL "")
	SET(value "${ARGN}")
    ENDIF()
    IF("${backend}" STREQUAL "mvn")
	ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE(opt "${opt}")
	IF(NOT "${value}" STREQUAL "")
	    LIST(APPEND ${var} "-Dzanata.${opt}=${value}")
	ELSE()
	    LIST(APPEND ${var} "-Dzanata.${opt}")
	ENDIF()
    ELSE()
	## zanata-cli
	LIST(APPEND ${var} "--${opt}")
	IF(NOT "${value}" STREQUAL "")
	    LIST(APPEND ${var} "${value}")
	ENDIF()
    ENDIF()
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPT_LIST_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_OPT_LIST_PARSE_APPEND var backend opt)
    STRING_SPLIT(_list "=" "${opt}")
    ZANATA_CLIENT_OPT_LIST_APPEND(${var} ${backend} ${_list})
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPT_LIST_PARSE_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_SUB_COMMAND var backend subCommand)
    IF("${backend}" STREQUAL "mvn")
	SET(${var} "${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:${subCommand}" PARENT_SCOPE)
    ELSE()
	## zanata-cli
	SET(${var} "${subCommand}" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION(ZANATA_CLIENT_SUB_COMMAND)

SET(MANAGE_ZANATA_COMMON_VALID_OPTIONS "YES" "USERNAME" "DISABLE_SSL_CERT" "USER_CONFIG")
SET(MANAGE_ZANATA_PROJECT_VALID_OPTIONS "DEFAULT_PROJECT_TYPE")
SET(MANAGE_ZANATA_VERSION_VALID_OPTIONS "PROJECT_TYPE" "VERSION" )
SET(MANAGE_ZANATA_PROJECT_VERSION_VALID_OPTIONS "PROJECT_CONFIG" "SRC_DIR" "TRANS_DIR")
SET(MANAGE_ZANATA_PUSH_VALID_OPTIONS "")
SET(MANAGE_ZANATA_PULL_VALID_OPTIONS "")
SET(MANAGE_ZANATA_VALID_OPTIONS "GENERATE_ZANATA_XML"
    "PUSH_OPTIONS" "PULL_OPTIONS"
    "CLIENT_COMMAND"
    ${MANAGE_ZANATA_COMMON_VALID_OPTIONS}
    ${MANAGE_ZANATA_PROJECT_VALID_OPTIONS}
    ${MANAGE_ZANATA_VERSION_VALID_OPTIONS}
    ${MANAGE_ZANATA_PUSH_VALID_OPTIONS}
    ${MANAGE_ZANATA_PULL_VALID_OPTIONS}
    )
    
FUNCTION(MANAGE_ZANATA)
    VARIABLE_PARSE_ARGN(_o MANAGE_ZANATA_VALID_OPTIONS ${ARGN})

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
	GET_FILENAME_COMPONENT(ZANATA_BACKEND "${ZANATA_EXECUTABLE}" NAME)
	IF(ZANATA_BACKEND STREQUAL "mvn")
	ELSEIF(ZANATA_BACKEND STREQUAL "zanata-cli")
	ELSE()
	    M_MSG(${M_OFF} "${ZANATA_BACKEND} is ${_o_CLIENT_CMD} not a supported Zanata client")
	    RETURN()
	ENDIF()
    ENDIF()

    ## Manage zanata.xml
    IF("${_o}" STREQUAL "")
	SET(_o_URL "https://translate.zanata.org/zanata/")
    ELSE()
	SET(_o_URL "${_o}")
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
    IF(NOT _o_LOCALES)
	SET(_o_LOCALES "${MANAGE_TRANSLATION_LOCALES}")
    ENDIF()
    IF(DEFINED _o_GENERATE_ZANATA_XML)
	ADD_CUSTOM_TARGET_COMMAND(zanata_xml
	    OUTPUT "${zanataXml}"
	    COMMAND ${CMAKE_COMMAND} 
	    -D cmd=zanata_xml_make
	    -D "url=${_o_URL}"
	    -D "project=${_o_PROJECT_SLUG}"
	    -D "version=${_o_VERSION}"
	    -D "locales=${_o_LOCALES}"
	    -D "zanataXml=${zanataXml}"
	    -P ${CMAKE_FEDORA_MODULE_DIR}/ManageZanataScript.cmake
	    COMMENT "zanata_xml: ${zanataXml}"
	    VERBATIM
	    )
    ENDIF()

    ## Convert to client options
    IF(DEFINED _o_YES)
	LIST(APPEND _o_CLIENT_COMMAND "-B")
    ENDIF()


    ### Common options
    SET(zanataCommonOptions "")
    FOREACH(optCName "URL" ${MANAGE_ZANATA_COMMON_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPT_LIST_APPEND(zanataCommonOptions "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)

    IF("${_o_DEFAULT_PROJECT_TYPE}" STREQUAL "")
	SET(_o_DEFAULT_PROJECT_TYPE "gettext")
    ENDIF()


    ### zanata_put_project
    SET(ZANATA_DESCRIPTION_SIZE 80 CACHE STRING "Zanata description size")
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "put-project")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-slug" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-name" "${PROJECT_NAME}")
    STRING(LENGTH "${PRJ_SUMMARY}" _prjSummaryLen)
    IF(NOT _prjSummaryLen GREATER ${ZANATA_DESCRIPTION_SIZE})
	SET(_description "${PRJ_SUMMARY}")
    ELSE()
	STRING(SUBSTRING "${PRJ_SUMMARY}" 0
	    ${ZANATA_DESCRIPTION_SIZE} _description
	    )
    ENDIF()
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-desc" "${_description}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "default-project-type" "${_o_DEFAULT_PROJECT_TYPE}")
    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_put_project
	COMMAND ${exec}
	COMMENT "zanata_put_project: with ${exec}"
	)

    ### zanata_put_version options
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "put-version")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "version-project" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "version-slug" "${_o_VERSION}")
    IF(_o_PROJECT_TYPE)
	ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-type" "${_o_PROJECT_TYPE}")
    ENDIF()
    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_put_version
	COMMAND ${exec}
	COMMENT "zanata_put_version: with ${exec}"
	)

    ### zanata_push
    IF("${_o_SRC_DIR}" STREQUAL "")
	SET(_o_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF()
    IF("${_o_TRANS_DIR}" STREQUAL "")
	SET(_o_TRANS_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF()

    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "push")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-version" "${_o_VERSION}")
    IF(_o_PROJECT_TYPE)
	ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-type" "${_o_PROJECT_TYPE}")
    ENDIF()
    FOREACH(optCName ${MANAGE_ZANATA_PROJECT_VERSION_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)
    IF(_o_PUSH_OPTIONS)
	FOREACH(optStr ${o_PUSH_OPTIONS})
	    M_MSG(${M_INFO2} "ManageZanata: PUSH_OPTION ${optStr}")
	    ZANATA_CLIENT_OPT_LIST_PARSE_APPEND(options "${ZANATA_BACKEND}" "${optStr}")
	ENDFOREACH(optStr)
    ENDIF()

    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_push
	COMMAND ${exec}
	COMMENT "zanata_push: with ${exec}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_both
    SET(extraOptions "")
    ZANATA_CLIENT_OPT_LIST_APPEND(extraOptions "${ZANATA_BACKEND}" "push-type" "both")
    ADD_CUSTOM_TARGET(zanata_push_both 
	COMMAND ${exec} ${extraOptions}
	COMMENT "zanata_push: with ${exec} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_trans
    SET(extraOptions "")
    ZANATA_CLIENT_OPT_LIST_APPEND(extraOptions "${ZANATA_BACKEND}" "push-type" "trans")
    ADD_CUSTOM_TARGET(zanata_push_trans 
	COMMAND ${exec} ${extraOptions}
	COMMENT "zanata_push: with ${exec} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

    ## zanata_pull
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "pull")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-version" "${_o_VERSION}")
    IF(_o_PROJECT_TYPE)
	ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-type" "${_o_PROJECT_TYPE}")
    ENDIF()
    FOREACH(optCName ${MANAGE_ZANATA_PROJECT_VERSION_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)
    IF(_o_PULL_OPTIONS)
	FOREACH(optStr ${o_PULL_OPTIONS})
	    M_MSG(${M_INFO2} "ManageZanata: PULL_OPTION ${optStr}")
	    ZANATA_CLIENT_OPT_LIST_PARSE_APPEND(options "${ZANATA_BACKEND}" "${optStr}")
	ENDFOREACH(optStr)
    ENDIF()

    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_pull
	COMMAND ${exec}
	COMMENT "zanata_pull: with ${exec}"
	DEPENDS ${zanataXml}
	)

ENDFUNCTION(MANAGE_ZANATA)

#######################################
# MANAGE_ZANATA_XML_MAKE
#

FUNCTION(ZANATA_PARSE_LOCALE language script country modifier suggestCountry suggestModifier str)
    SET(s "")
    SET(c "")
    SET(m "")
    SET(sC "")
    SET(sM "")
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
    STRING(LENGTH "${l}" langLen)

    ## Known cases
    IF(l STREQUAL "zh")
	IF(s STREQUAL "Hans")
	    SET(sC "CN")
	ELSEIF(s STREQUAL "Hant")
	    SET(sC "TW")
	ENDIF()
    ELSEIF(l STREQUAL "sr")
	IF(NOT c)
	    SET(sC "RS")
	ENDIF()
	IF(s STREQUAL "Latn")
	    SET(sM "latin")
	ENDIF()
    ELSEIF(l STREQUAL "aa")
	IF(NOT c)
	    SET(sC "ET")
	ENDIF()
    ELSEIF(l STREQUAL "ar")
	IF(NOT c)
	    SET(sC "SA")
	ENDIF()
    ELSEIF(l STREQUAL "ar")
	IF(NOT c)
	    SET(sC "SA")
	ENDIF()
    ELSEIF(l STREQUAL "ca")
	IF(NOT c)
	    SET(sC "AD")
	ENDIF()
    ELSEIF(l STREQUAL "el")
	IF(NOT c)
	    SET(sC "GR")
	ENDIF()
    ELSEIF(l STREQUAL "en")
	IF(NOT c)
	    SET(sC "US")
	ENDIF()
    ELSEIF(l STREQUAL "en")
	IF(NOT c)
	    SET(sC "US")
	ENDIF()
    ELSEIF(l STREQUAL "li")
	IF(NOT c)
	    SET(sC "NL")
	ENDIF()
    ELSEIF(l STREQUAL "om")
	IF(NOT c)
	    SET(sC "ET")
	ENDIF()
    ELSEIF(l STREQUAL "pa")
	IF(NOT c)
	    SET(sC "IN")
	ENDIF()
    ELSEIF(l STREQUAL "pa")
	IF(NOT c)
	    SET(sC "IN")
	ENDIF()
    ELSEIF(l STREQUAL "ti")
	IF(NOT c)
	    SET(sC "ET")
	ENDIF()
    ELSEIF(langLen EQUAL 2)
	## Use uppercase language as country
	IF(NOT c)
	    STRING(TOUPPER "${l}" sC)
	ENDIF()
    ENDIF()

    SET(${language} "${l}" PARENT_SCOPE)
    SET(${script} "${s}" PARENT_SCOPE)
    SET(${country} "${c}" PARENT_SCOPE)
    SET(${modifier} "${m}" PARENT_SCOPE)
    SET(${suggestCountry} "${sC}" PARENT_SCOPE)
    SET(${suggestModifier} "${sM}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_PARSE_LOCALE)


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

FUNCTION(ZANATA_ZANATA_XML_MAP_BETTER_MATCH var currentBestMatch serverLocale clientLocale)
    IF(currentBestMatch STREQUAL serverLocale)
	## Already found best match, no need to look further
	SET(${var} "${currentBestMatch}" PARENT_SCOPE)
	RETURN()
    ENDIF()

    IF(clientLocale STREQUAL serverLocale)
	## Already found best match, no need to look further
	SET(${var} "${clientLocale}" PARENT_SCOPE)
	RETURN()
    ENDIF()

    ZANATA_PARSE_LOCALE(sLang sScript sCountry sModifier sSCountry sSModifier "${serverLocale}")
    ZANATA_PARSE_LOCALE(cLang cScript cCountry cModifier cSCountry cSModifier "${clientLocale}") 
    M_MSG(${M_INFO3} "ZANATA_ZANATA_XML_MAP_BETTER_MATCH( ${currentBestMatch} ${serverLocale} ${clientLocale})")
    IF("${sLang}" STREQUAL "${cLang}")
	IF(currentBestMatch)
	    ZANATA_PARSE_LOCALE(bLang bScript bCountry bModifier bSCountry bSModifier "${currentBestMatch}") 
	    IF("${sCountry}" STREQUAL "${cCountry}")
		IF("${sModifier}" STREQUAL "${cModifier}")
		    SET(nowBest "${clientLocale}")
		ELSEIF("${sSModifier}" STREQUAL "${cModifier}")
		    SET(nowBest "${clientLocale}")
		ELSE()
		    SET(nowBest "${currentBestMatch}")
		ENDIF()
	    ELSEIF("${sSCountry}" STREQUAL "${cCountry}")
		IF("${sModifier}" STREQUAL "${cModifier}")
		    SET(nowBest "${clientLocale}")
		ELSEIF("${sSModifier}" STREQUAL "${cModifier}")
		    SET(nowBest "${clientLocale}")
		ELSE()
		    SET(nowBest "${currentBestMatch}")
		ENDIF()
	    ELSE()
		SET(nowBest "${currentBestMatch}")
	    ENDIF()
	ELSE()
	    ## Nothing better yet
	    SET(nowBest "${clientLocale}")
	ENDIF()
    ELSE()
	SET(nowBest "${currentBestMatch}")
    ENDIF()
    SET(${var} "${nowBest}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_ZANATA_XML_MAP_BETTER_MATCH)

FUNCTION(ZANATA_ZANATA_XML_MAP zanataXml zanataXmlIn clientLocales)
    INCLUDE(ManageTranslation)
    SET(localeListVar "${ARGN}")
    FILE(STRINGS "${zanataXmlIn}" zanataXmlLines)
    FILE(REMOVE ${zanataXml})

    IF("${clientLocales}" STREQUAL "")
	## Use client-side system locales.
	MANAGE_GETTEXT_LOCALES(clientLocales "" SYSTEM_LOCALES)
    ENDIF()
    M_MSG(${M_INFO3} "clientLocales=${clientLocales}")

    ## Start parsing zanataXmlIn
    FOREACH(line ${zanataXmlLines})
	IF("${line}" MATCHES "<locale>(.*)</locale>")
	    ## Is a locale string
	    SET(sL "${CMAKE_MATCH_1}")

	    ## Find the best match
	    SET(bestMatch "")
	    FOREACH(cL ${clientLocales})
		ZANATA_ZANATA_XML_MAP_BETTER_MATCH(bestMatch "${bestMatch}" "${sL}" "${cL}")
		M_MSG(${M_INFO3} "bestMatch=${bestMatch} sL=${sL} cL=${cL}")
		IF(bestMatch STREQUAL sL)
		    BREAK()
		ENDIF()
	    ENDFOREACH()

	    IF(bestMatch)
		M_MSG(${M_INFO2} "Matched client locale for ${sL} is ${bestMatch}")
	    ELSE()
		STRING(REPLACE "-" "_" sLCorrected "${sL}")
		SET(bestMatch "${sLCorrected}")
		M_MSG(${M_OFF} "Matched client locale for ${sL} is not found, use ${sLCorrected} instead.")
	    ENDIF()
	    IF("${sL}" STREQUAL "${bestMatch}")
		SET(outLine "${line}")
	    ELSE()
		STRING(REPLACE "<locale" "<locale map-from=\"${bestMatch}\"" outLine "${line}")
	    ENDIF()
	    FILE(APPEND "${zanataXml}" "${outLine}\n")
	ELSE()
	    ## Not a locale string, write as-is
	    FILE(APPEND "${zanataXml}" "${line}\n")
	ENDIF()
    ENDFOREACH()
ENDFUNCTION(ZANATA_ZANATA_XML_MAP)


