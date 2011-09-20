# - Software Translation support
# This module supports software translation by:
#   1) Creates gettext related targets.
#   2) Communicate to Zanata servers.
#
# The Gettext part of this module is from FindGettext.cmake of cmake,
# but it is included here because:
#  1. Bug of GETTEXT_CREATE_TRANSLATIONS make it unable to be include in 'All'
#  2. It does not support xgettext
#
# Defines following variables:
#   + XGETTEXT_OPTIONS_C: Usual xgettext options for C programs.
#
# Defines following macros:
#   GETTEXT_CREATE_POT([potFile]
#     [OPTIONS xgettext_options]
#     SRC list_of_source_files
#   )
#   - Generate .pot file.
#     Arguments:
#     + potFile: pot file to be generated.
#       Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#     + xgettext_options: (optional) xgettext_options.
#       Default: No options.
#     + list_of_source_files: List of source files that contains msgid.
#     Targets:
#     + pot_file: Generate a pot file with the file name specified in potFile.
#     Defines:
#
#   GETTEXT_CREATE_TRANSLATIONS ( [potFile] [ALL] locale1 ... localeN
#     [COMMENT comment] )
#   - This will create a target "translations" which converts given input po
#     files into the binary output mo files. If the ALL option is used, the
#     translations will also be created when building with "make all"
#     Arguments:
#     + potFile: pot file to be referred.
#       Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#     + ALL: (Optional) target "translations" is included when building with
#       "make all"
#     + locale1 ... localeN: locale to be built.
#     + comment: (Optional) Comment for target "translations".
#     Targets:
#     + translations: Converts input po files into the binary output mo files.
#
#   USE_GETTEXT [ALL] SRCS src1 [src2 [...]]
#	LOCALES locale1 [locale2 [...]]
#	[POTFILE potfile]
#	[XGETTEXT_OPTIONS xgettextOpt]]
#	)
#   - Provide Gettext support like generate .pot file and
#     a target "translations" which converts given input po
#     files into the binary output mo files. If the "ALL" option is used, the
#     translations will also be created when building with "make all"
#     Arguments:
#     + ALL: (Optional) target "translations" is included when building with
#       "make all"
#     + SRCS src1 [src2 [...]]: File list of source code that contains msgid.
#     + LOCALE locale1 [local2 [...]]: Locale list to be generated.
#       Currently, only the format: lang_Region (such as fr_FR) is supported.
#     + POTFILE potFile: (optional) pot file to be referred.
#       Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#     + XGETTEXT_OPTIONS xgettextOpt: (optional) xgettext_options.
#       Default: ${XGETTEXT_OPTIONS_C}
#     Defines following variables:
#     + GETTEXT_MSGMERGE_EXECUTABLE: the full path to the msgmerge tool.
#     + GETTEXT_MSGFMT_EXECUTABLE: the full path to the msgfmt tool.
#     + XGETTEXT_EXECUTABLE: the full path to the xgettext.
#     Targets:
#     + pot_file: Generate the pot_file.
#     + gmo_files: Converts input po files into the binary output mo files.
#
#   USE_ZANATA(serverUrl [ALL_FOR_PUSH] [ALL_FOR_PUSH_TRANS] [ALL_FOR_PULL]
#     [OPTIONS options])
#   - Use Zanata (was flies) as translation service.
#     Note that value for --project-id, --project-version, --project-name,
#     --project-version, --url, --project-config, --push-trans
#     are automatically generated.
#     Arguments:
#     + serverUrl: The URL of Zanata server
#     + ALL_FOR_PUSH: (Optional) "make all" invokes targets "zanata_push"
#     + ALL_FOR_PUSH_TRANS: (Optional) "make all" invokes targets "zanata_push_trans"
#     + ALL_FOR_PULL: (Optional) "make all" invokes targets "zanata_pull"
#     + OPTIONS options: (Optional) Options to be pass to zanata.
#       Note that PROJECT_NAME is passed as --project-id,
#       and PRJ_VER is passed as --project-version
#     Targets:
#     + zanata_project_create: Create project with PROJECT_NAME in zanata
#       server.
#     + zanata_version_create: Create version PRJ_VER in zanata server.
#     + zanata_push: Push source messages to zanata server
#     + zanata_push_trans: Push source messages and translations to zanata server.
#     + zanata_pull: Pull translations from zanata server.
#


IF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)
    SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
    SET(XGETTEXT_OPTIONS_C
	--language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s
	--package-name=${PROJECT_NAME} --package-version=${PRJ_VER})
    INCLUDE(ManageMessage)


    #========================================
    # GETTEXT support

    MACRO(USE_GETTEXT_INIT)
	FIND_PROGRAM(XGETTEXT_EXECUTABLE xgettext)
	IF(XGETTEXT_EXECUTABLE STREQUAL "XGETTEXT_EXECUTABLE-NOTFOUND")
	    SET(_gettext_dependency_missing 1)
	    M_MSG(${M_OFF} "xgettext not found! gettext support disabled.")
	ENDIF(XGETTEXT_EXECUTABLE STREQUAL "XGETTEXT_EXECUTABLE-NOTFOUND")

	FIND_PROGRAM(GETTEXT_MSGMERGE_EXECUTABLE msgmerge)
	IF(GETTEXT_MSGMERGE_EXECUTABLE STREQUAL "GETTEXT_MSGMERGE_EXECUTABLE-NOTFOUND")
	    SET(_gettext_dependency_missing 1)
	    M_MSG(${M_OFF} "msgmerge not found! gettext support disabled.")
	ENDIF(GETTEXT_MSGMERGE_EXECUTABLE STREQUAL "GETTEXT_MSGMERGE_EXECUTABLE-NOTFOUND")

	FIND_PROGRAM(GETTEXT_MSGFMT_EXECUTABLE msgfmt)
	IF(GETTEXT_MSGFMT_EXECUTABLE STREQUAL "GETTEXT_MSGFMT_EXECUTABLE-NOTFOUND")
	    SET(_gettext_dependency_missing 1)
	    M_MSG(${M_OFF} "msgfmt not found! gettext support disabled.")
	ENDIF(GETTEXT_MSGFMT_EXECUTABLE STREQUAL "GETTEXT_MSGFMT_EXECUTABLE-NOTFOUND")

    ENDMACRO(USE_GETTEXT_INIT)

    MACRO(USE_GETTEXT)
	SET(_gettext_dependency_missing 0)
	USE_GETTEXT_INIT()
	IF(${_gettext_dependency_missing} EQUAL 0)
	    SET(_stage)
	    SET(_all)
	    SET(_src_list)
	    SET(_src_list_abs)
	    SET(_locale_list)
	    SET(_potFile)
	    SET(_xgettext_option_list)
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "ALL")
		    SET(_all "ALL")
		ELSEIF(_arg STREQUAL "SRCS")
		    SET(_stage "SRCS")
		ELSEIF(_arg STREQUAL "LOCALES")
		    SET(_stage "LOCALES")
		ELSEIF(_arg STREQUAL "XGETTEXT_OPTIONS")
		    SET(_stage "XGETTEXT_OPTIONS")
		ELSEIF(_arg STREQUAL "POTFILE")
		    SET(_stage "POTFILE")
		ELSE(_arg STREQUAL "ALL")
		    IF(_stage STREQUAL "SRCS")
			FILE(RELATIVE_PATH _relFile ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${_arg})
			LIST(APPEND _src_list ${_relFile})
			GET_FILENAME_COMPONENT(_absFile ${_arg} ABSOLUTE)
			LIST(APPEND _src_list_abs ${_absFile})
		    ELSEIF(_stage STREQUAL "LOCALES")
			LIST(APPEND _locale_list ${_arg})
		    ELSEIF(_stage STREQUAL "XGETTEXT_OPTIONS")
			LIST(APPEND _xgettext_option_list ${_arg})
		    ELSEIF(_stage STREQUAL "POTFILE")
			SET(_potFile "${_arg}")
		    ELSE(_stage STREQUAL "SRCS")
			M_MSG(${M_WARN} "USE_GETTEXT: not recognizing arg ${_arg}")
		    ENDIF(_stage STREQUAL "SRCS")
		ENDIF(_arg STREQUAL "ALL")
	    ENDFOREACH(_arg ${_args} ${ARGN})

	    # Default values
	    IF(_xgettext_option_list STREQUAL "")
		SET(_xgettext_option_list ${XGETTEXT_OPTIONS_C})
	    ENDIF(_xgettext_option_list STREQUAL "")

	    IF("${_potFile}" STREQUAL "")
		SET(_potFile "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot")
	    ENDIF("${_potFile}" STREQUAL "")

	    M_MSG(${M_INFO2} "XGETTEXT=${XGETTEXT_EXECUTABLE} ${_xgettext_option_list} -o ${_potFile} ${_src_list}")
	    ADD_CUSTOM_COMMAND(OUTPUT ${_potFile}
		COMMAND ${XGETTEXT_EXECUTABLE} ${_xgettext_option_list} -o ${_potFile} ${_src_list}
		DEPENDS ${_src_list_abs}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Extract translatable messages to ${_potFile}"
		)

	    ADD_CUSTOM_TARGET(pot_file ${_all}
		DEPENDS ${_potFile}
		)

	    ### Generating gmo files
	    SET(_gmoFile_list)
	    GET_FILENAME_COMPONENT(_potBasename ${_potFile} NAME_WE)
	    GET_FILENAME_COMPONENT(_potDir ${_potFile} PATH)
	    GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)
	    GET_FILENAME_COMPONENT(_absPotDir ${_absPotFile} PATH)
	    FOREACH(_locale ${_locale_list})
		SET(_gmoFile ${_absPotDir}/${_locale}.gmo)
		SET(_absFile ${_absPotDir}/${_locale}.po)
		ADD_CUSTOM_COMMAND(	OUTPUT ${_gmoFile}
		    COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --quiet --update --backup=none
		    -s ${_absFile} ${_potFile}
		    COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_absFile}
		    DEPENDS ${_potFile} ${_absFile}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		    COMMENT "Generating ${_locale} translation"
		    )

		#MESSAGE("_absFile=${_absFile} _absPotDir=${_absPotDir} _lang=${_lang} curr_bin=${CMAKE_CURRENT_BINARY_DIR}")
		INSTALL(FILES ${_gmoFile} DESTINATION share/locale/${_locale}/LC_MESSAGES RENAME ${_potBasename}.mo)
		LIST(APPEND _gmoFile_list ${_gmoFile})
	    ENDFOREACH(_locale ${_locale_list})
	    M_MSG(${M_INFO2} "_gmoFile_list=${_gmoFile_list}")

	    ADD_CUSTOM_TARGET(gmo_files ${_all}
		DEPENDS ${_gmoFile_list}
		COMMENT "Generate gmo files for translation"
		)
	ENDIF(${_gettext_dependency_missing} EQUAL 0)
    ENDMACRO(USE_GETTEXT)


    #========================================
    # ZANATA support
    MACRO(USE_ZANATA serverUrl)
	SET(ZANATA_SERVER "${serverUrl}")
	SET(ZANATA_XML_SEARCH_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR}
	    ${CMAKE_CURRENT_SOURCE_DIR}/po ${CMAKE_SOURCE_DIR}/po)
	FIND_PROGRAM(ZANATA_CMD zanata)
	SET(_failed 0)
	IF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")
	    SET(_failed 1)
	    M_MSG(${M_OFF} "zanata (python client) not found! zanata support disabled.")
	ENDIF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")

	IF(NOT EXISTS $ENV{HOME}/.config/zanata.ini)
	    SET(_failed 1)
	    M_MSG(${M_OFF} "~/.config/zanata.ini is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS $ENV{HOME}/.config/zanata.ini)

	SET(_zanata_xml "")
	FIND_PATH(_zanata_xml_in_dir "zanata.xml.in" PATHS ${ZANATA_XML_SEARCH_PATH})
	IF(NOT "${_zanata_xml_in_dir}" MATCHES "NOTFOUND")
	    SET(_zanata_xml_in ${_zanata_xml_in_dir}/zanata.xml.in)
	    M_MSG(${M_INFO1} "USE_ZANATA:_zanata_xml_in=${_zanata_xml_in}")
	    SET(_zanata_xml ${_zanata_xml_in_dir}/zanata.xml)
	    CONFIGURE_FILE(${_zanata_xml_in} ${_zanata_xml} @ONLY)
	ENDIF(NOT "${_zanata_xml_in_dir}" MATCHES "NOTFOUND")

	IF(NOT "${_zanata_xml}" STREQUAL "")
	    FIND_PATH(_zanata_xml_dir "zanata.xml" PATHS ${ZANATA_XML_SEARCH_PATH})
	    IF(NOT "${_zanata_xml_dir}" MATCHES "NOTFOUND")
		SET(_zanata_xml "${_zanata_xml_dir}/zanata.xml")
	    ELSE(NOT "${_zanata_xml_dir}" MATCHES "NOTFOUND")
		SET(_failed 1)
		M_MSG(${M_OFF} "zanata.xml not found in ${ZANATA_XML_SEARCH_PATH}! zanata support disabled.")
	    ENDIF(NOT "${_zanata_xml_dir}" MATCHES "NOTFOUND")
	ENDIF(NOT "${_zanata_xml}" STREQUAL "")

	IF(_failed EQUAL 0)
	    M_MSG(${M_INFO1} "USE_ZANATA:_zanata_xml=${_zanata_xml}")
	    # Parsing arguments
	    SET(_miscOpts "")
	    SET(_pushOpts "")
	    SET(_pullOpts "")
	    SET(_projTypeOpt "")
	    SET(_stage "")
	    SET(_allForPush "")
	    SET(_allForPushTrans "")
	    SET(_allForPull "")
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "OPTIONS")
		    SET(_stage "${_arg}")
		ELSEIF(_arg STREQUAL "ALL_FOR_PUSH")
		    SET(_allForPush "ALL")
		ELSEIF(_arg STREQUAL "ALL_FOR_PUSH_TRANS")
		    SET(_allForPushTrans "ALL")
		ELSEIF(_arg STREQUAL "ALL_FOR_PUSH")
		    SET(_allForPull "ALL")
		ELSE(_arg STREQUAL "OPTIONS")
		    IF(_stage STREQUAL "OPTIONS")
			IF(_arg MATCHES "^--project-type=")
			    SET(_projTypeOpt ${_arg})
			ELSEIF(_arg MATCHES "^--.*dir=")
			    LIST(APPEND _pushOpts ${_arg})
			    LIST(APPEND _pullOpts ${_arg})
			ELSEIF(_arg MATCHES "^--merge")
			    LIST(APPEND _pushOpts ${_arg})
			ELSEIF(_arg MATCHES "^--no-copytrans")
			    LIST(APPEND _pushOpts ${_arg})
			ELSE(_arg MATCHES "^--project-type=")
			    LIST(APPEND _miscOpts ${_arg})
			ENDIF(_arg MATCHES "^--project-type=")
		    ENDIF(_stage STREQUAL "OPTIONS")
		ENDIF(_arg STREQUAL "SRCDIR")
	    ENDFOREACH(_arg ${ARGN})

	    IF(_projTypeOpt STREQUAL "")
		SET(_projTypeOpt "--project-type=gettext")
	    ENDIF(_projTypeOpt STREQUAL "")

	    SET(_zanata_args --url=${ZANATA_SERVER}
		--project-config=${_zanata_xml})

	    ADD_CUSTOM_TARGET(zanata_project_create
		COMMAND ${ZANATA_CMD} project create ${PROJECT_NAME} ${_zanata_args}
		"--project-name=${PROJECT_NAME}" "--project-desc=${PRJ_SUMMARY}"
		COMMENT "Create project translation on Zanata server ${serverUrl}"
		VERBATIM
		)
	    ADD_CUSTOM_TARGET(zanata_version_create
		COMMAND ${ZANATA_CMD} version create
		${PRJ_VER} ${_zanata_args} --project-id=${PROJECT_NAME}
		COMMENT "Create version ${PRJ_VER} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    # Zanata push
	    ADD_CUSTOM_TARGET(zanata_push ${_allForPush}
		COMMAND yes |
		${ZANATA_CMD} push ${_zanata_args}
		--project-id=${PROJECT_NAME}
		--project-version=${PRJ_VER}
		${_pushOpts}
		${_projTypeOpt}
		${_miscOpts}
		COMMENT "Push source messages of version ${PRJ_VER}"
	       	"to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(zanata_push pot_file)

	    # Zanata push with translation
	    ADD_CUSTOM_TARGET(zanata_push_trans ${_allForPushTrans}
		COMMAND yes |
		${ZANATA_CMD} push ${_zanata_args}
		--project-id=${PROJECT_NAME}
		--project-version=${PRJ_VER}
		--push-trans
		${_pushOpts}
		${_projTypeOpt}
		${_miscOpts}
		COMMENT "Push source messages and translations of version ${PRJ_VER}"
		"to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	    ADD_DEPENDENCIES(zanata_push_trans pot_file)

	    # Zanata pull
	    ADD_CUSTOM_TARGET(zanata_pull ${_allForPull}
		COMMAND yes |
		${ZANATA_CMD} pull ${_zanata_args}
		--project-id=${PROJECT_NAME}
		--project-version=${PRJ_VER}
		${_projTypeOpt}
		${_miscOpts}
		COMMENT "Pull translations of version ${PRJ_VER}"
		"from zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	ENDIF(_failed EQUAL 0)
    ENDMACRO(USE_ZANATA serverUrl)

ENDIF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)

