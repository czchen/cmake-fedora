# - Manage Translation
# This module supports software translation by:
#   1) Creates gettext related targets.
#   2) Communicate to Zanata servers.
#
# Included Modules:
#   - ManageArchive
#   - ManageDependency
#   - ManageFile
#   - ManageMessage
#
# Defines following targets:
#   + translations: Virtual target that make the translation files.
#     Once MANAGE_GETTEXT is used, this target invokes targets that
#     build translation.
#
# Defines following variables:
#   + XGETTEXT_OPTIONS_C: Default xgettext options for C programs.
# Defines or read from following variables:
#   + MANAGE_TRANSLATION_MSGFMT_OPTIONS: msgfmt options
#     Default: --check --check-compatibility --strict
#   + MANAGE_TRANSLATION_MSGMERGE_OPTIONS: msgmerge options
#     Default: --update --indent --backup=none
#   + MANAGE_TRANSLATION_XGETEXT_OPTIONS: xgettext options
#     Default: ${XGETTEXT_OPTIONS_C}
#
# Defines following functions:
#   ADD_POT_FILE(<potFile> [SRCS <src> ...]
#	[XGETTEXT_OPTIONS <opt> ...]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Add a new pot file and source files that create the pot file.
#        Useful for multiple pot files.
#       * Parameters:
#         + potFile: .pot file with path.
#         + SRCS src ... : Source files for xgettext to work on.
#         + XGETTEXT_OPTIONS opt ... : xgettext options.
#         + COMMAND cmd ... : Non-xgettext command that create pot file.
#         + DEPENDS file ... : Files that pot file depends on.
#             SRCS files are already depended on, so no need to list here.
#       * Variables to cache:
#         + MANAGE_TRANSLATION_GETTEXT_POT_LIST: List of pot file.
#
#   MANAGE_GETTEXT([ALL] 
#       [SRCS <src> ...]
#       [POT_FILE <potFile>]
#	[LOCALES <locale> ... | SYSTEM_LOCALES]
#       [MSGFMT_OPTIONS <msgfmtOpt>]
#       [MSGMERGE_OPTIONS <msgmergeOpt>]
#	[XGETTEXT_OPTIONS <xgettextOpt>]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Provide Gettext support like generation of .pot or .gmo files.
#       It generates .pot file using xgettext; update po files;
#         and generate gmo files.
#       It also add gettext dependency to dependency list.
#       You can specify the locales to be processed by
#         + LOCALE <locale> ... 
#         + SYSTEM_LOCALES: Locales returned by "locale -a", 
#           exclude the encoding.
#         + or nothing to use the existing po files.
#       * Parameters:
#         + ALL: (Optional) make target "all" depends on gettext targets.
#         + SRCS src ... : Source files for xgettext to work on.
#         + POT_FILE potFile: (optional) pot files with path.
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#         + LOCALES locale ... : (optional) Locale list to be generated.
#         + SYSTEM_LOCALES: (optional) System locales from locale -a.
#         + MSGFMT_OPTIONS msgfmtOpt: (optional) msgfmt options.
#           Default: ${MANAGE_TRANSLATION_MSGFMT_OPTIONS}
#         + MSGMERGE_OPTIONS msgmergeOpt: (optional) msgmerge options.
#           Default: ${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}, which is
#         + XGETTEXT_OPTIONS xgettextOpt: (optional) xgettext options.
#           Default: ${XGETTEXT_OPTIONS_C}
#         + COMMAND cmd ... : Non-xgettext command that create pot file.
#         + DEPENDS file ... : Files that pot file depends on.
#             SRCS files are already depended on, so no need to list here.
#       * Targets:
#         + pot_files: Generate pot files.
#         + gmo_files: Converts po files to mo files.
#         + update_po: Update po files according to pot files.
#       * Variables read:
#         + MANAGE_GETTEXT_POT_LIST: 
#            (Optional) List of pot file.
#       * Variables to cache:
#         + MSGMERGE_CMD: the full path to the msgmerge tool.
#         + MSGFMT_CMD: the full path to the msgfmt tool.
#         + XGETTEXT_CMD: the full path to the xgettext.
#         + MANAGE_GETTEXT_LOCALES: Locales to be processed.
#
#   MANAGE_ZANATA(serverUrl [YES])
#   - Use Zanata (was flies) as translation service.
#     Arguments:
#     + serverUrl: The URL of Zanata server
#     + YES: Assume yes for all questions.
#     Reads following variables:
#     + ZANATA_XML_FILE: Path to zanata.xml
#       Default:${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml
#     + ZANATA_INI_FILE: Path to zanata.ini
#       Default:${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml
#     + ZANATA_PUSH_OPTIONS: Options for zanata push
#     + ZANATA_PULL_OPTIONS: Options for zanata pull
#     Targets:
#     + zanata_project_create: Create project with PROJECT_NAME in zanata
#       server.
#     + zanata_version_create: Create version PRJ_VER in zanata server.
#     + zanata_push: Push source messages to zanata server
#     + zanata_push_trans: Push source messages and translations to zanata server.
#     + zanata_pull: Pull translations from zanata server.
#

IF(DEFINED _MANAGE_TRANSLATION_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_TRANSLATION_CMAKE_)
SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
INCLUDE(ManageArchive)
INCLUDE(ManageMessage)
INCLUDE(ManageFile)
INCLUDE(ManageDependency)

SET(XGETTEXT_OPTIONS_C --language=C --keyword=_ --keyword=N_ 
    --keyword=C_:1c,2 --keyword=NC_:1c,2 -s
    )

SET(MANAGE_TRANSLATION_MSGFMT_OPTIONS 
    "--check" CACHE STRING "msgfmt options"
    )
SET(MANAGE_TRANSLATION_MSGMERGE_OPTIONS 
    "--indent" "--update" "--backup=none" CACHE STRING "msgmerge options"
    )
SET(MANAGE_TRANSLATION_XGETTEXT_OPTIONS 
    ${XGETTEXT_OPTIONS_C}
    CACHE STRING "xgettext options"
    )
SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")

IF(NOT TARGET translations)
    ADD_CUSTOM_TARGET(translations
	COMMENT "translations: Making translations"
	)
ENDIF(NOT TARGET translations)
SET(_gettext_dependency_missing 0)

#######################################
# GETTEXT support
#

MACRO(MANAGE_GETTEXT_INIT)
    IF(DEFINED XGETTEXT_CMD)
	RETURN()
    ENDIF(DEFINED XGETTEXT_CMD)
    FOREACH(_name "xgettext" "msgmerge" "msgfmt")
	STRING(TOUPPER "${_name}" _cmd)
	FIND_PROGRAM_ERROR_HANDLING(${_cmd}_CMD
	    ERROR_MSG " gettext support is disabled."
	    ERROR_VAR _gettext_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    "${_name}"
	    )
	M_MSG(${M_INFO1} "${_cmd}_CMD=${${_cmd}_CMD}")
    ENDFOREACH(_name "xgettext" "msgmerge" "msgfmt")
ENDMACRO(MANAGE_GETTEXT_INIT)

FUNCTION(ADD_POT_FILE potFile)
    MANAGE_GETTEXT_INIT()
    IF(_gettext_dependency_missing)
	RETURN()
    ENDIF(_gettext_dependency_missing)
    SET(_validOptions 
	"SRCS" "XGETTEXT_OPTIONS" "COMMAND" "DEPENDS"
	)
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})
    IF("${_o_COMMAND}" STREQUAL "")
	## xgettext mode
	IF(NOT _o_XGETTEXT_OPTIONS)
	    SET(_o_XGETTEXT_OPTIONS 
		"${MANAGE_TRANSLATION_XGETTEXT_OPTIONS}"
		)
	ENDIF()
	IF("${_o_SRCS}" STREQUAL "")
	    M_MSG(${M_WARN} 
		"ADD_POT_FILE: xgettext: No SRCS for ${potFile}"
		)
	    RETURN()
	ENDIF()
	ADD_CUSTOM_COMMAND(OUTPUT ${potFile}
	    COMMAND ${XGETTEXT_CMD} ${_o_XGETTEXT_OPTIONS} 
	    -o ${potFile}
	    --package-name=${PROJECT_NAME} 
	    --package-version=${PRJ_VER} ${_o_SRCS}
	    DEPENDS ${_o_SRCS} ${_o_DEPENDS}
	    COMMENT "${potFile}: xgettext: Extract translatable messages"
	    )
    ELSE()
	ADD_CUSTOM_COMMAND(OUTPUT ${potFile}
	    COMMAND ${_o_COMMAND}
	    DEPENDS ${_o_DEPENDS}
	    COMMENT "${potFile}: Extract translatable messages"
	    )
    ENDIF("${_o_COMMAND}" STREQUAL "")
    LIST(APPEND MANAGE_TRANSLATION_GETTEXT_POT_LIST ${potFile})
    SET(MANAGE_TRANSLATION_GETTEXT_POT_LIST
	"${MANAGE_TRANSLATION_GETTEXT_POT_LIST}"
	CACHE INTERNAL "List of pot files"
	)
ENDFUNCTION(ADD_POT_FILE potFile)


FUNCTION(MANAGE_GETTEXT)
    MANAGE_DEPENDENCY(BUILD_REQUIRES GETTEXT REQUIRED)
    MANAGE_DEPENDENCY(BUILD_REQUIRES FINDUTILS REQUIRED)
    MANAGE_DEPENDENCY(REQUIRES GETTEXT REQUIRED)
    MANAGE_GETTEXT_INIT()
    IF(_gettext_dependency_missing)
	RETURN()
    ENDIF(_gettext_dependency_missing)

    SET(_validOptions 
	"SRCS" "XGETTEXT_OPTIONS" "COMMAND" "DEPENDS"
	"ALL" "LOCALES" "SYSTEM_LOCALES" "POT_FILE"
	"MSGFMT_OPTIONS" "MSGMERGE_OPTIONS"
	)
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})
    IF(DEFINED _o_ALL)
	SET(_all "ALL")
    ENDIF(DEFINED _o_ALL)

    ## Pot files
    IF(_o_POT_FILES)
	SET(_o_POT_FILES 
	    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot"
	    )
    ENDIF(_o_POT_FILES)
    ## In case pot files are not in source control
    SOURCE_ARCHIVE_CONTENTS_ADD(${_o_POT_FILES})

    ## Directory that contains pot
    SET(_potDirList "")
    FOREACH(_pot ${_o_POT_FILES})
	GET_FILENAME_COMPONENT(_potDir ${_pot} PATH)
	LIST(APPEND _potDirList "${_potDir}")
    ENDFOREACH(_pot)

    ## Locales
    IF("${_o_LOCALES}" STREQUAL "")
	IF(DEFINED _o_SYSTEM_LOCALES)
	    EXECUTE_PROCESS(
		COMMAND locale -a | grep -e '^[a-z]*_[A_Z]*$' | xargs | sed -e 's/ /;/g'
		OUTPUT_VARIABLE _o_LOCALES
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	ELSE()
	    ## LOCALES is not specified, detect now
	    FOREACH(_potDir ${_potDirList})
		EXECUTE_PROCESS(
		    COMMAND find ${_potDir} -name "*.po" -printf '%f ' | sed -e 's/.po /;/g'
		    OUTPUT_VARIABLE _locales
		    OUTPUT_STRIP_TRAILING_WHITESPACE
		    )
		LIST(APPEND _o_LOCALES ${_locales})
	    ENDFOREACH(_potDir)
	    LIST(REMOVE_DUPLICATES ${_o_LOCALES})
	ENDIF(DEFINED _o_SYSTEM_LOCALES)
    ENDIF("${_o_LOCALES}" STREQUAL "")

    ## Other options
    FOREACH(_oName "MSGFMT" "MSGMERGE" "XGETTEXT")
	IF(NOT _o_${_oName}_OPTIONS)
	    SET(_o_${_oName}_OPTIONS 
		"${MANAGE_TRANSLATION_${_oName}_OPTIONS}"
		)
	ENDIF(NOT _o_${_oName}_OPTIONS)
    ENDFOREACH(_oName "MSGFMT" "MSGMERGE" "XGETTEXT")
   
    ## Source files
    SET(_srcList "")
    SET(_srcList_abs "")
    FOREACH(_sF ${_o_SRCS})
	FILE(RELATIVE_PATH _relFile 
	    "${CMAKE_CURRENT_BINARY_DIR}" "${_sF}")
	LIST(APPEND _srcList ${_relFile})
	GET_FILENAME_COMPONENT(_absPoFile ${_sF} ABSOLUTE)
	LIST(APPEND _srcList_abs ${_absPoFile})
    ENDFOREACH(_sF ${_o_SRCS})

    ### Generating pot files
    FOREACH(_pot ${_o_POT_FILES})
	ADD_CUSTOM_COMMAND(OUTPUT ${_pot}
	GET_FILENAME_COMPONENT(_potDir ${_pot} PATH)
	LIST(APPEND _potDirList "${_potDir}")
    ENDFOREACH(_pot)
    ADD_CUSTOM_TARGET_COMMAND(pot_file
	NO_FORCE OUTPUT ${_o_POT_FILES} ${_all}
	COMMAND ${XGETTEXT_CMD} ${_o_XGETTEXT_OPTIONS} 
	-o ${_o_POT_FILES}
	--package-name=${PROJECT_NAME} 
	--package-version=${PRJ_VER} ${_srcList}
	DEPENDS ${_srcList_abs}
	COMMENT "Extract translatable messages to ${_potFile}"
	)

    ### Generating gmo files
    SET(_gmoList "")
    SET(_poList "")
    FOREACH(_locale ${_o_LOCALES})
	SET(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_locale}.gmo)
	SET(_poFile ${CMAKE_CURRENT_SOURCE_DIR}/${_locale}.po)
	SOURCE_ARCHIVE_CONTENTS_ADD("${_poFile}")
	ADD_CUSTOM_COMMAND(OUTPUT ${_poFile}
	    COMMAND ${MSGMERGE_CMD} 
	    ${_o_MSGMERGE_OPTIONS} ${_poFile} ${_o_POT_FILES}
	    DEPENDS ${_o_POT_FILES}
	    COMMENT "Running ${MSGMERGE_CMD}"
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${_gmoFile}
	    COMMAND ${MSGFMT_CMD} 
	    ${_o_MSGFMT_OPTIONS} -o ${_gmoFile} ${_poFile}
	    DEPENDS ${_poFile}
	    COMMENT "Running ${MSGFMT_CMD}"
	    )

	LIST(APPEND _gmoList "${_gmoFile}")
	## No need to use MANAGE_FILE_INSTALL
	## As this will handle by rpmbuild
	INSTALL(FILES ${_gmoFile} DESTINATION 
	    ${DATA_DIR}/locale/${_locale}/LC_MESSAGES 
	    RENAME ${_o_POT_FILES_NAME}.mo
	    )
    ENDFOREACH(_locale ${_o_LOCALES})
    SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_potFile}" )

    ADD_CUSTOM_TARGET(gmo_files ${_all}
	DEPENDS ${_gmoList}
	COMMENT "Generate gmo files for translation"
	)

    ADD_DEPENDENCIES(translations gmo_files)
ENDFUNCTION(MANAGE_GETTEXT)


    #========================================
    # ZANATA support
    MACRO(MANAGE_ZANATA serverUrl)
	SET(ZANATA_SERVER "${serverUrl}")
	FIND_PROGRAM(ZANATA_CMD zanata)
	SET(_manage_zanata_dependencies_missing 0)
	IF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata (python client) not found! zanata support disabled.")
	ENDIF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")

	SET(ZANATA_XML_FILE "${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml" CACHE FILEPATH "zanata.xml")
	IF(NOT EXISTS "${ZANATA_XML_FILE}")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata.xml is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS "${ZANATA_XML_FILE}")

	SET(ZANATA_INI_FILE "$ENV{HOME}/.config/zanata.ini" CACHE FILEPATH "zanata.ni")
	IF(NOT EXISTS "${ZANATA_INI_FILE}")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata.ini is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS "${ZANATA_INI_FILE}")

	IF(NOT _manage_zanata_dependencies_missing)
	    SET(_zanata_args --url "${ZANATA_SERVER}"
		--project-config "${ZANATA_XML_FILE}" --user-config "${ZANATA_INI_FILE}")

	    # Parsing arguments
	    SET(_yes "")
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "YES")
		    SET(_yes "yes" "|")
		ENDIF(_arg STREQUAL "YES")
	    ENDFOREACH(_arg ${ARGN})

	    ADD_CUSTOM_TARGET(zanata_project_create
		COMMAND ${ZANATA_CMD} project create ${PROJECT_NAME} ${_zanata_args}
		--project-name "${PROJECT_NAME}" --project-desc "${PRJ_SUMMARY}"
		COMMENT "Creating project ${PROJECT_NAME} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    ADD_CUSTOM_TARGET(zanata_version_create
		COMMAND ${ZANATA_CMD} version create
		${PRJ_VER} ${_zanata_args} --project-id "${PROJECT_NAME}"
		COMMENT "Creating version ${PRJ_VER} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    SET(_po_files_depend "")
	    IF(MANAGE_TRANSLATION_GETTEXT_PO_FILES)
		SET(_po_files_depend "DEPENDS" ${MANAGE_TRANSLATION_GETTEXT_PO_FILES})
	    ENDIF(MANAGE_TRANSLATION_GETTEXT_PO_FILES)
	    # Zanata push
	    ADD_CUSTOM_TARGET(zanata_push
		COMMAND ${_yes}
		${ZANATA_CMD} push ${_zanata_args} ${ZANATA_PUSH_OPTIONS}
		${_po_files_depend}
		COMMENT "Push source messages to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(zanata_push pot_file)

	    # Zanata push with translation
	    ADD_CUSTOM_TARGET(zanata_push_trans
		COMMAND ${_yes}
		${ZANATA_CMD} push ${_zanata_args} --push-type both ${ZANATA_PUSH_OPTIONS}
		${_po_files_depend}
		COMMENT "Push source messages and translations to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	    ADD_DEPENDENCIES(zanata_push_trans pot_file)

	    # Zanata pull
	    ADD_CUSTOM_TARGET(zanata_pull
		COMMAND ${_yes}
		${ZANATA_CMD} pull ${_zanata_args} ${ZANATA_PULL_OPTIONS}
		COMMENT "Pull translations fro zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	ENDIF(NOT _manage_zanata_dependencies_missing)
    ENDMACRO(MANAGE_ZANATA serverUrl)


