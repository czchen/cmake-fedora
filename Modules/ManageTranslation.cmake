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
#   USE_GETTEXT [ALL] SRC src1 [src2 [...]]
#	LOCALE locale1 [locale2 [...]]
#	[POTFILE potfile]
#	[XGETTEXTOPT xgettextOpt]]
#	)
#   - Provide Gettext support like generate .pot file and
#     a target "translations" which converts given input po
#     files into the binary output mo files. If the "ALL" option is used, the
#     translations will also be created when building with "make all"
#     Arguments:
#     + ALL: (Optional) target "translations" is included when building with
#       "make all"
#     + SRC src1 [src2 [...]]: File list of source code that contains msgid.
#     + LOCALE locale1 [local2 [...]]: Locale list to be generated.
#       Currently, only the format: lang_Region (such as fr_FR) is supported.
#     + POTFILE potFile: (optional) pot file to be referred.
#       Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#     + XGETTEXTOPT xgettextOpt: (optional) xgettext_options.
#       Default: ${XGETTEXT_OPTIONS_C}
#     Defines following variables:
#     + GETTEXT_MSGMERGE_EXECUTABLE: the full path to the msgmerge tool.
#     + GETTEXT_MSGFMT_EXECUTABLE: the full path to the msgfmt tool.
#     + XGETTEXT_EXECUTABLE: the full path to the xgettext.
#     Targets:
#     + pot_file: Generate the pot_file.
#     + translations: Converts input po files into the binary output mo files.
#


IF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)
    SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
    SET(XGETTEXT_OPTIONS_C
	--language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s
	--package-name=${PROJECT_NAME} --package-version=${PRJ_VER})


    #========================================
    # GETTEXT support

    MACRO(USE_GETTEXT_INIT)
	FIND_PROGRAM(XGETTEXT_EXECUTABLE xgettext)
	IF(XGETTEXT_EXECUTABLE STREQUAL "XGETTEXT_EXECUTABLE-NOTFOUND")
	    MESSAGE(FATAL_ERROR "xgettext not found!")
	ENDIF(XGETTEXT_EXECUTABLE STREQUAL "XGETTEXT_EXECUTABLE-NOTFOUND")

	FIND_PROGRAM(GETTEXT_MSGMERGE_EXECUTABLE msgmerge)
	IF(GETTEXT_MSGMERGE_EXECUTABLE STREQUAL "GETTEXT_MSGMERGE_EXECUTABLE-NOTFOUND")
	    MESSAGE(FATAL_ERROR "msgmerge not found!")
	ENDIF(GETTEXT_MSGMERGE_EXECUTABLE STREQUAL "GETTEXT_MSGMERGE_EXECUTABLE-NOTFOUND")

	FIND_PROGRAM(GETTEXT_MSGFMT_EXECUTABLE msgfmt)
	IF(GETTEXT_MSGFMT_EXECUTABLE STREQUAL "GETTEXT_MSGFMT_EXECUTABLE-NOTFOUND")
	    MESSAGE(FATAL_ERROR "msgfmt not found!")
	ENDIF(GETTEXT_MSGFMT_EXECUTABLE STREQUAL "GETTEXT_MSGFMT_EXECUTABLE-NOTFOUND")

    ENDMACRO(USE_GETTEXT_INIT)

    MACRO(USE_GETTEXT)
	USE_GETTEXT_INIT()
	SET(_failed 0)
	SET(_stage)
	SET(_all)
	SET(_src_list)
	SET(_src_list_abs)
	SET(_locale_list)
	SET(_potFile)
	SET(_xgettext_option_list)
	#   USE_GETTEXT [ALL] SRC src1 [src2 [...]]
	#	LOCALE locale1 [locale2 [locale3 [...]]]
	#	[XGETTEXTOPT xgettextOpt [opt1 [opt2 [...]]]]
	#	[POTFILE potfile]
	FOREACH(_arg ${ARGN})
	    IF(_arg STREQUAL "ALL")
		SET(_all "ALL")
	    ELSEIF(_arg STREQUAL "SRC")
		SET(_stage "SRC")
	    ELSEIF(_arg STREQUAL "LOCALE")
		SET(_stage "LOCALE")
	    ELSEIF(_arg STREQUAL "XGETTEXTOPT")
		SET(_stage "XGETTEXTOPT")
	    ELSEIF(_arg STREQUAL "POTFILE")
		SET(_stage "POTFILE")
	    ELSE(_arg STREQUAL "ALL")
		IF(_stage STREQUAL "SRCS")
		    FILE(RELATIVE_PATH _relFile ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${_arg})
		    LIST(APPEND _src_list ${_relFile})

		    GET_FILENAME_COMPONENT(_absFile ${_arg} ABSOLUTE)
		    LIST(APPEND _src_list_abs ${_absFile})
		ELSEIF(_stage STREQUAL "LOCALE")
		    LIST(APPEND _locale_list ${_arg})
		ELSEIF(_stage STREQUAL "LOCALE")
		    LIST(APPEND _locale_list ${_arg})
		ELSEIF(_stage STREQUAL "XGETEXTOPT")
		    LIST(APPEND _xgetttext_option_list ${_arg})
		ELSEIF(_stage STREQUAL "POTFILE")
		    SET(_potFile "${_arg}")
		ELSE(_stage STREQUAL "SRCS")
		    MESSAGE("[Warning] USE_GETTEXT: not recognizing arg	${_arg}")
		    SET(_potFile ${_arg})
		ENDIF(_stage STREQUAL "OPTIONS")
	    ENDIF(_arg STREQUAL "OPTIONS")
	ENDFOREACH(_arg ${_args} ${ARGN})

	# Default values
	IF(_xgettext_option_list STREQUAL "")
	    SET(_xgettext_option_list XGETTEXT_OPTIONS_C
	ENDIF(_xgettext_option_list STREQUAL "")

	IF("${_potFile}" STREQUAL "")
	    SET(_potFile "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot")
	ENDIF("${_potFile}" STREQUAL "")

	#MESSAGE("${XGETTEXT_EXECUTABLE} ${_xgettext_option_list} -o ${_potFile} ${_src_list}")
	ADD_CUSTOM_COMMAND(OUTPUT ${_potFile}
	    COMMAND ${XGETTEXT_EXECUTABLE} ${_xgettext_option_list} -o ${_potFile} ${_src_list}
	    DEPENDS ${_src_list_abs}
	    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
	    COMMENT "Extract translatable messages to ${_potFile}"
	    )

	ADD_CUSTOM_TARGET(pot_file ${_all}
	    DEPENDS ${_potFile}
	    )

	### Generating translation
	SET(_gmoFile_list)
	GET_FILENAME_COMPONENT(_potBasename ${_potFile} NAME_WE)
	GET_FILENAME_COMPONENT(_potDir ${_potFile} PATH)
	GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)
	GET_FILENAME_COMPONENT(_absPotDir ${_absPotFile} PATH)
	FOREACH (_locale ${locale_list})
	    SET(_gmoFile ${_absPotDir}/${_locale}.gmo)
	    SET(_absFile ${_absPotDir}/${_locale}.po)
	    ADD_CUSTOM_COMMAND(	OUTPUT ${_gmoFile}
		COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --quiet --update --backup=none -s ${_absFile} ${_potFile}
		COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_absFile}
		DEPENDS ${_potFile} ${_absFile}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Generating ${_locale} translation"
		)

		#MESSAGE("_absFile=${_absFile} _absPotDir=${_absPotDir} _lang=${_lang} curr_bin=${CMAKE_CURRENT_BINARY_DIR}")
		INSTALL(FILES ${_gmoFile} DESTINATION share/locale/${_locale}/LC_MESSAGES RENAME ${_potBasename}.mo)
		LIST(APPEND _gmoFile_list ${_gmoFile})
	    ENDIF(_currentLang STREQUAL "ALL")
	ENDFOREACH (_locale)

	ADD_CUSTOM_TARGET(translations ${_all}
	    DEPENDS ${_gmoFiles}
	    COMMENT "Generate translation"
	    )
    ENDMACRO(USE_GETTEXT)


    #========================================
    # ZANATA support
    MACRO(USE_ZANATA serverUrl [ALL]
	    [SRCDIR srcdir] [TRANSDIR transdir] [DSTDIR
	    dstdir])
	FIND_PROGRAM(ZANATA_CMD zanata)
	SET(_failed 0)
	IF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND)
	    SET(_failed 1)
	    MESSAGE("Program zanata is not found! Disable Zanata support.")
	    MESSAGE("  Install zanata-python-client to enable.")
	ENDIF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND)

	IF(EXISTS ${CMAKE_SOURCE_DIR}/zanata.xml.in)
	    SET(ZANATA_SERVER ${serverUrl})
	    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/zanata.xml.in
		${CMAKE_BINARY_DIR}/zanata.xml @ONLY)
	ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/zanata.xml.in)

	IF(EXISTS ${CMAKE_BINARY_DIR}/zanata.xml)
	    SET(_zanata_xml ${CMAKE_BINARY_DIR}/zanata.xml)
	ELSEIF(EXISTS ${CMAKE_SOURCE_DIR}/zanata.xml)
	    SET(_zanata_xml ${CMAKE_SOURCE_DIR}/zanata.xml)
	ELSE(EXISTS ${CMAKE_BINARY_DIR}/zanata.xml)
	    SET(_failed 1)
	    SET(_zanata_xml "")
	    MESSAGE("zanata.xml is not found! Disable Zanata support")
	ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/zanata.xml)

	IF(NOT EXISTS $ENV{HOME}/.config/zanata.ini)
	    SET(_failed 1)
	    MESSAGE("~/.config/zanata.in  is not found! Disable Zanata support")
	ENDIF(NOT EXISTS $ENV{HOME}/.zanata.ini)

	IF(_failed EQUAL 0)
	    # Parsing arguments
	    SET(_srcDir)
	    SET(_transDir)
	    SET(_dstDir)
	    SET(_all)
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "SRCDIR")
		    SET(_stage "SRCDIR")
		ELSEIF(_arg STREQUAL "TRANSDIR")
		    SET(_stage "TRANSDIR")
		ELSEIF(_arg STREQUAL "DSTDIR")
		    SET(_stage "DSTDIR")
		ELSEIF(_arg STREQUAL "ALL")
		    SET(_stage "ALL")
		    SET(_all "ALL")
		ELSE(_arg STREQUAL "SRCDIR")
		    IF(_stage STREQUAL "SRCDIR")
			SET(_srcDir "--srcdir=${_arg}")
		    ELSEIF(_stage STREQUAL "TRANSDIR")
			SET(_transDir "--transDir=${_arg}")
		    ELSEIF(_stage STREQUAL "DSTDIR")
			SET(_dstDir "--dstDir=${_arg}")
		    ENDIF(_stage STREQUAL "SRCDIR")
		ENDIF(_arg STREQUAL "SRCDIR")
	    ENDFOREACH(_arg ${ARGN})

	    SET(_zanata_args --url=${serverURL} --project-id=${PROJECT_NAME})
	    ADD_CUSTOM_TARGET(zanata_project_create
		COMMAND ${ZANATA_CMD} project create ${PROJECT_NAME} --url=${serverURL}
		--project-name="${PROJECT_NAME}" --project-desc="${PRJ_SUMMARY}"
		COMMENT "Create project translation on Zanata server ${serverUrl}"
		VERBATIM
		)
	    ADD_CUSTOM_TARGET(zanata_version_create ${_all}
		COMMAND ${ZANATA_CMD} project create ${PRJ_VER} ${_zanata_args}
		"
		COMMENT "Create version ${PRJ_VER} on Zanata server ${serverUrl}"
		VERBATIM
		)
	    ADD_CUSTOM_TARGET(zanata_po_push ${_all}
		COMMAND ${ZANATA_CMD} po push ${_zanata_args} --project-version=${PRJ_VER}
		${_srcDir} ${_transDir}
		COMMENT "Push the pot files for version ${PRJ_VER}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(zanata_po_push pot_file)
	    ADD_CUSTOM_TARGET(zanata_po_push_import_po ${_all}
		COMMAND ${ZANATA_CMD} po push ${_zanata_args} --project-version=${PRJ_VER}
		${_srcDir} ${_transDir} --import-po
		COMMENT "Push the pot and po files for version ${PRJ_VER}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(zanata_po_push pot_file)

	    ADD_CUSTOM_TARGET(zanata_po_pull
		COMMAND ${ZANATA_CMD} po pull ${_zanata_args} --project-version=${PRJ_VER}
		${_dstDir}
		COMMENT "Pull the pot files for version ${PRJ_VER}"
		VERBATIM
		)
	ENDIF(_failed EQUAL 0)
    ENDMACRO(USE_ZANATA serverUrl)

    MACRO(MANAGE_TRANSLATION LANG

ENDIF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)

