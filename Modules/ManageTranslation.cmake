# - Manage Translation
# This module supports software translation by:
#   Creates gettext related targets.
#   Communicate to Zanata servers.
#
# By calling MANAGE_GETTEXT(), following variables are available in cache:
#   - MANAGE_TRANSLATION_LOCALES: Locales that would be processed.
#
# Included Modules:
#   - ManageArchive
#   - ManageDependency
#   - ManageFile
#   - ManageMessage
#   - ManageString
#   - ManageVariable
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
#       [PO_DIR <dir>]
#	[XGETTEXT_OPTIONS <opt> ...]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Add a new pot file and source files that create the pot file.
#        Useful for multiple pot files.
#       * Parameters:
#         + potFile: .pot file with path.
#         + SRCS src ... : Source files for xgettext to work on.
#         + PO_DIR dir: Directory of .po files.
#             This option is mandatory if .pot and associated .po files
#             are not in the same directory.
#           Default: Same directory of <potFile>.
#         + XGETTEXT_OPTIONS opt ... : xgettext options.
#         + COMMAND cmd ... : Non-xgettext command that create pot file.
#         + DEPENDS file ... : Files that pot file depends on.
#             SRCS files are already depended on, so no need to list here.
#       * Variables to cache:
#         + MANAGE_TRANSLATION_GETTEXT_POT_FILES: List of pot file.
#         + MANAGE_TRANSLATION_GETTEXT_POT_FILE_<potFile>_PO_DIR:
#             Directory of po files which associated with <potFile>.
#
#   MANAGE_GETTEXT([ALL] 
#       [POT_FILE <potFile>]
#       [SRCS <src> ...]
#       [PO_DIR <dir>]
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
#         + POT_FILE potFile: (Optional) pot files with path.
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#         + SRCS src ... : (Optional) Source files for xgettext to work
#             on.
#         + PO_DIR dir: Directory of .po files.
#             This option is mandatory if .pot and associated .po files
#             are not in the same directory.
#           Default: Same directory of <potFile>.
#         + LOCALES locale ... : (Optional) Locale list to be generated.
#         + SYSTEM_LOCALES: (Optional) System locales from locale -a.
#         + MSGFMT_OPTIONS msgfmtOpt: (Optional) msgfmt options.
#           Default: ${MANAGE_TRANSLATION_MSGFMT_OPTIONS}
#         + MSGMERGE_OPTIONS msgmergeOpt: (Optional) msgmerge options.
#           Default: ${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}, which is
#         + XGETTEXT_OPTIONS xgettextOpt: (Optional) xgettext options.
#           Default: ${XGETTEXT_OPTIONS_C}
#         + COMMAND cmd ... : Non-xgettext command that create pot file.
#         + DEPENDS file ... : Files that pot file depends on.
#             SRCS files are already depended on, so no need to list here.
#       * Targets:
#         + pot_files: Generate pot files.
#         + gmo_files: Converts po files to mo files.
#         + update_po: Update po files according to pot files.
#       * Variables read:
#         + MANAGE_GETTEXT_POT_FILES: 
#            (Optional) List of pot file.
#       * Variables to cache:
#         + MSGINIT_CMD: the full path to the msginit tool.
#         + MSGMERGE_CMD: the full path to the msgmerge tool.
#         + MSGFMT_CMD: the full path to the msgfmt tool.
#         + XGETTEXT_CMD: the full path to the xgettext.
#         + MANAGE_LOCALES: Locales to be processed.
#

IF(DEFINED _MANAGE_TRANSLATION_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_TRANSLATION_CMAKE_)
SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
INCLUDE(ManageArchive)
INCLUDE(ManageMessage)
INCLUDE(ManageFile)
INCLUDE(ManageDependency)
INCLUDE(ManageString)
INCLUDE(ManageVariable)

SET(XGETTEXT_OPTIONS_COMMON --from-code=UTF-8 --indent
    --sort-by-file
    )

SET(XGETTEXT_OPTIONS_C ${XGETTEXT_OPTIONS_COMMON} 
    --language=C     
    --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s 
    --keyword=gettext --keyword=dgettext:2
    --keyword=dcgettext:2 --keyword=ngettext:1,2
    --keyword=dngettext:2,3 --keyword=dcngettext:2,3
    --keyword=gettext_noop --keyword=pgettext:1c,2
    --keyword=dpgettext:2c,3 --keyword=dcpgettext:2c,3
    --keyword=npgettext:1c,2,3 --keyword=dnpgettext:2c,3,4 
    --keyword=dcnpgettext:2c,3,4.
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

SET(_gettext_dependency_missing 0)

#######################################
# GETTEXT support
#

MACRO(MANAGE_GETTEXT_INIT)
    IF(DEFINED XGETTEXT_CMD)
	RETURN()
    ENDIF(DEFINED XGETTEXT_CMD)
    FOREACH(_name "xgettext" "msgmerge" "msgfmt" "msginit")
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

	ADD_CUSTOM_COMMAND(OUTPUT ${potFile}
	    COMMAND ${XGETTEXT_CMD} ${_o_XGETTEXT_OPTIONS} 
	    -o ${potFile}
	    --package-name=${PROJECT_NAME} 
	    --package-version=${PRJ_VER} ${_o_SRCS}
	    --msgid-bugs-address=${MAINTAINER}
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
    LIST(APPEND MANAGE_TRANSLATION_GETTEXT_POT_FILES ${potFile})
    SET(MANAGE_TRANSLATION_GETTEXT_POT_FILES
	"${MANAGE_TRANSLATION_GETTEXT_POT_FILES}"
	CACHE INTERNAL "List of pot files"
	)

    ## In case potFile is not in source control
    SOURCE_ARCHIVE_CONTENTS_ADD("${potFile}")

    GET_FILENAME_COMPONENT(_potName "${potFile}" NAME_WE)
    GET_FILENAME_COMPONENT(_potDir "${potFile}" PATH)
    IF(_o_PO_DIR STREQUAL "")
	SET(_o_PO_DIR "${potDir}")
    ENDIF()
    GET_FILENAME_COMPONENT(_potName "${potFile}" NAME_WE)
    SET(MANAGE_TRANSLATION_GETTEXT_POT_FILE_${_potName}_PO_DIR
	"${_o_PO_DIR}" CACHE INTERNAL "PO dir for ${_potName}"
	)
ENDFUNCTION(ADD_POT_FILE)

## Internal
# MANAGE_GETTEXT_GET_PO_FILES(<var> <pot>)
#   - Get the po file list associate to the given pot
#     * Parameters:
#       + var: Returns po file list related to pot.
#       + pot: .pot file.
FUNCTION(MANAGE_GETTEXT_GET_PO_FILES var pot)
    IF("${MANAGE_TRANSLATION_LOCALES}" STREQUAl "")
	M_MSG(${M_ERROR} "MANAGE_GETTEXT_GET_PO_FILES: MANAGE_TRANSLATION_LOCALES is empty. Specify locale by either LOCALES or SYSTEM_LOCALES")
	RETURN()
    ENDIF("${MANAGE_TRANSLATION_LOCALES}" STREQUAl "")
    GET_FILENAME_COMPONENT(_potName "${potFile}" NAME_WE)
    SET(_list "")
    FOREACH(_l ${MANAGE_TRANSLATION_LOCALES})
	SET(_po 
	    "${MANAGE_TRANSLATION_GETTEXT_POT_FILE_${_potName}_PO_DIR}/${_l}.po"
	    )
	IF(NOT EXISTS ${_po})
	    EXECUTE_PROCESS(COMMAND ${MSGINIT_CMD} -
		-output ${_po} --input ${pot}
		RESULT_VARIABLE _ret
		)
	    IF(NOT _ret EQUAL 0)
		M_MSG(${M_ERROR} 
		    "MANAGE_GETTEXT_GET_PO_FILES: Failed to create ${_po}"
		    )
		RETURN()
	    ENDIF()
	ENDIF()
	LIST(APPEND _list "${_po}")
    ENDFOREACH(_l)
    SET(${var} "${_list}" PARENT_SCOPE)
ENDFUNCTION(MANAGE_GETTEXT_GET_PO_FILES)

## Internal
MACRO(MANAGE_GETTEXT_LOCALES potDirList)
    IF(NOT "${_o_LOCALES}" STREQUAL "")
	## Locale is defined
    ELSEIF(DEFINED _o_SYSTEM_LOCALES)
	EXECUTE_PROCESS(
	    COMMAND locale -a | grep -e '^[a-z]*_[A_Z]*$' | xargs | sed -e 's/ /;/g'
	    OUTPUT_VARIABLE _o_LOCALES
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
    ELSE(NOT DEFINED _o_SYSTEM_LOCALES)
	## LOCALES is not specified, detect now
	FOREACH(_potDir ${potDirList})
	    EXECUTE_PROCESS(
		COMMAND find ${_potDir} -name "*.po" -printf '%f ' | sed -e 's/.po /;/g'
		OUTPUT_VARIABLE _locales
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	    LIST(APPEND _o_LOCALES ${_locales})
	ENDFOREACH(_potDir)
	LIST(REMOVE_DUPLICATES ${_o_LOCALES})
	IF("${_o_LOCALES}" STREQUAL "")
	    ## Failed to find any locale
	    M_MSG(${M_ERROR} "MANAGE_GETTEXT: Failed to detect locales, specify SYSTEM_LOCALES in MANAGE_GETTEXT to use locales available in your system")
	ENDIF()
    ENDIF()
    SET(MANAGE_TRANSLATION_LOCALES "${_o_LOCALES}" CACHE INTERNAL
	"Locales"
	)
ENDMACRO(MANAGE_GETTEXT_LOCALES)

FUNCTION(MANAGE_GETTEXT)
    MANAGE_DEPENDENCY(BUILD_REQUIRES GETTEXT REQUIRED)
    MANAGE_DEPENDENCY(BUILD_REQUIRES FINDUTILS REQUIRED)
    MANAGE_DEPENDENCY(REQUIRES GETTEXT REQUIRED)
    MANAGE_GETTEXT_INIT()
    IF(_gettext_dependency_missing)
	RETURN()
    ENDIF(_gettext_dependency_missing)

    SET(_validOptions 
	"SRCS" "PO_DIR" "XGETTEXT_OPTIONS" "COMMAND" "DEPENDS"
	"ALL" "LOCALES" "SYSTEM_LOCALES" "POT_FILE"
	"MSGFMT_OPTIONS" "MSGMERGE_OPTIONS"
	)
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})
    IF(DEFINED _o_ALL)
	SET(_all "ALL")
    ELSE()
	SET(_all "")
    ENDIF(DEFINED _o_ALL)

    ## Pot file
    SET(_potFile "")
    IF("${_o_POT_FILE}" STREQUAL "")
	IF("${MANAGE_TRANSLATION_GETTEXT_POT_FILES}" STREQUAL "")
	    SET(_potFile 
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot"
		)
	ENDIF()
    ELSE()
	## POT_FILE is specified
	SET(_potFile "${_o_POT_FILE}")
    ENDIF()
    IF(_potFile)
	SET(_validAddPotFileOptList
	    "SRCS" "PO_DIR" "XGETTEXT_OPTIONS" "COMMAND" "DEPENDS"
	    )
	VARIABLE_TO_ARGN(_addPotFileOptList _o _validAddPotFileOptList)
	## Add new pot file
	ADD_POT_FILE("${_potFile}" ${_addPotFileOptList})
    ENDIF(_potFile)

    ## Locales
    SET(_potDirList "")
    FOREACH(_pot ${MANAGE_TRANSLATION_GETTEXT_POT_FILES})
	GET_FILENAME_COMPONENT(_potDir "${_pot}" PATH)
	LIST(APPEND _potDirList "${_potDir}")
    ENDFOREACH(_pot)
    MANAGE_GETTEXT_LOCALES(_potDirList)

    ## Other options
    FOREACH(_oName "MSGFMT" "MSGMERGE")
	IF(NOT _o_${_oName}_OPTIONS)
	    SET(_o_${_oName}_OPTIONS 
		"${MANAGE_TRANSLATION_${_oName}_OPTIONS}"
		)
	ENDIF(NOT _o_${_oName}_OPTIONS)
    ENDFOREACH(_oName)

    ## Make all pot files
    ADD_CUSTOM_TARGET(pot_file
	DEPENDS ${MANAGE_TRANSLATION_GETTEXT_POT_FILES}
	COMMENT "pot_file: ${MANAGE_TRANSLATION_GETTEXT_POT_FILES}"
	)

    ## For each pot files
    SET(_gmoFileList "")
    FOREACH(_pot ${MANAGE_TRANSLATION_GETTEXT_POT_FILES})
	GET_FILENAME_COMPONENT(_potName "${_pot}" NAME_WE)
	MANAGE_GETTEXT_GET_PO_FILES(_poFileList ${_pot})
	FOREACH(_po ${_poFileList})
	    GET_FILENAME_COMPONENT(_poFile ${_po} NAME)
	    SET(_poDir
		"${MANAGE_TRANSLATION_GETTEXT_POT_FILE_${_potName}_PO_DIR}"
		)
	    STRING(REPLACE ".po" "" _loc "${_poFile}")

	    ### Create and update  po files
	    ADD_CUSTOM_COMMAND(OUTPUT ${_po}
		COMMAND ${MSGMERGE_CMD} 
		${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}
	       	--lang=${_loc} 	${_po} ${_pot}
		DEPENDS ${_pot}
		COMMENT "po: ${_po} from ${_pot}"
		)
	    SET(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_loc}.gmo)

	    ### Generate gmo files
	    FILE(RELATIVE_PATH _poR 
		"${CMAKE_CURRENT_SOURCE_DIR}" "${_po}")
	    GET_FILENAME_COMPONENT(_poDirR "${_poR}" PATH)
	    SET(_gmo "${CMAKE_CURRENT_BINARY_DIR}/${_poDirR}/${_loc}.gmo")
	    ADD_CUSTOM_COMMAND(OUTPUT ${_gmo}
		COMMAND ${MSGFMT_CMD} 
		${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}
                -o ${_gmo} ${_po}
		DEPENDS ${_po}
		COMMENT "gmo: ${_gmo}"
		)
	    LIST(APPEND _gmoFileList "${_gmo}")

	    ### Install gmo
	    INSTALL(FILES ${_gmo} DESTINATION 
		${DATA_DIR}/locale/${_locale}/LC_MESSAGES 
		RENAME ${_potName}.mo
		)
	ENDFOREACH(_po ${_poFileList})
    ENDFOREACH(_pot ${MANAGE_TRANSLATION_GETTEXT_POT_FILES})

    ADD_CUSTOM_TARGET(gmo_files ${_all}
	DEPENDS ${_gmoFileList}
	COMMENT "gmo_files"
	)

    ADD_CUSTOM_TARGET(translations ${_all}
	COMMENT "translations: Making translations"
	)
    ADD_DEPENDENCIES(translations gmo_files)
ENDFUNCTION(MANAGE_GETTEXT)

