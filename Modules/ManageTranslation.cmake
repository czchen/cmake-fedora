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
#   MANAGE_POT_FILE(<potFile> 
#       [SRCS <src> ...]
#       [PO_DIR <dir>]
#       [MO_DIR <dir>]
#       [NO_MO]
#	[LOCALES <locale> ... | SYSTEM_LOCALES]
#	[XGETTEXT_OPTIONS <opt> ...]
#       [MSGMERGE_OPTIONS <msgmergeOpt>]
#       [MSGFMT_OPTIONS <msgfmtOpt>]
#       [CLEAN]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Add a new pot file and source files that create the pot file.
#       It is mandatory if for multiple pot files.
#       By default, cmake-fedora will set the directory property
#       PROPERTIES CLEAN_NO_CUSTOM as "1" to prevent po files get cleaned
#       by "make clean". For this behavior to be effective, invoke this function
#       in the directory that contains generated PO file.
#       * Parameters:
#         + potFile: .pot file with path.
#         + SRCS src ... : Source files for xgettext to work on.
#         + PO_DIR dir: Directory of .po files.
#             This option is mandatory if .pot and associated .po files
#             are not in the same directory.
#           Default: Same directory of <potFile>.
#         + MO_DIR dir: Directory of .gmo files.
#           Default: Same with PO_DIR
#         + NO_MO: Skip the mo generation.
#             This is for documents that do not require MO.
#         + LOCALES locale ... : (Optional) Locale list to be generated.
#         + SYSTEM_LOCALES: (Optional) System locales from locale -a.
#         + XGETTEXT_OPTIONS opt ... : xgettext options.
#         + MSGMERGE_OPTIONS msgmergeOpt: (Optional) msgmerge options.
#           Default: ${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}, which is
#         + MSGFMT_OPTIONS msgfmtOpt: (Optional) msgfmt options.
#           Default: ${MANAGE_TRANSLATION_MSGFMT_OPTIONS}
#         + CLEAN: Clean the POT, PO, MO files when doing make clean
#             By default, cmake-fedora will set the directory property
#             PROPERTIES CLEAN_NO_CUSTOM as "1" to prevent po files get cleaned.
#             Specify "CLEAN" to override this behavior.
#         + COMMAND cmd ... : Non-xgettext command that create pot file.
#         + DEPENDS file ... : Files that pot file depends on.
#             SRCS files are already depended on, so no need to list here.
#       * Variables to cache:
#         + MANAGE_TRANSLATION_GETTEXT_POT_FILES: List of pot files.
#         + MANAGE_TRANSLATION_GETTEXT_PO_FILES: List of all po files.
#         + MANAGE_TRANSLATION_GETTEXT_MO_FILES: List of all mo filess.
#         + MANAGE_TRANSLATION_LOCALES: List of locales.
#
#   MANAGE_GETTEXT([ALL] 
#       [POT_FILE <potFile>]
#       [SRCS <src> ...]
#       [PO_DIR <dir>]
#       [MO_DIR <dir>]
#       [NO_MO]
#	[LOCALES <locale> ... | SYSTEM_LOCALES]
#	[XGETTEXT_OPTIONS <opt> ...]
#       [MSGMERGE_OPTIONS <msgmergeOpt>]
#       [MSGFMT_OPTIONS <msgfmtOpt>]
#       [CLEAN]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Manage Gettext support.
#       If no POT files were added, it invokes MANAGE_POT_FILE and manage .pot, .po and .gmo files.
#       This command creates targets for making the translation files.
#       So naturally, this command should be invoke after the last MANAGE_POT_FILE command.
#       The parameters are similar to the ones at MANAGE_POT_FILE, except:
#       * Parameters:
#         + ALL: (Optional) make target "all" depends on gettext targets.
#         + POT_FILE potFile: (Optional) pot files with path.
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#         Refer MANAGE_POT_FILE for rest of the parameters.
#       * Targets:
#         + pot_files: Generate pot files.
#         + mo_files: Converts po files to mo files.
#         + update_po: Update po files according to pot files.
#         + translation: Complete all translation tasks.
#       * Variables to cache:
#         + MANAGE_TRANSLATION_GETTEXT_POT_FILES: List of pot files.
#         + MANAGE_TRANSLATION_GETTEXT_PO_FILES: List of all po files.
#         + MANAGE_TRANSLATION_GETTEXT_MO_FILES: Lis of all mo filess.
#         + MANAGE_TRANSLATION_LOCALES: List of locales. 
#       * Variables to cache:
#         + MSGINIT_EXECUTABLE: the full path to the msginit tool.
#         + MSGMERGE_EXECUTABLE: the full path to the msgmerge tool.
#         + MSGFMT_EXECUTABLE: the full path to the msgfmt tool.
#         + XGETTEXT_EXECUTABLE: the full path to the xgettext.
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

SET(_gettext_dependency_missing 0)

#######################################
# GETTEXT support
#

FUNCTION(MANAGE_GETTEXT_INIT)
    IF(DEFINED MSGINIT_EXECUTABLE)
	RETURN()
    ENDIF(DEFINED MSGINIT_EXECUTABLE)
    MANAGE_DEPENDENCY(BUILD_REQUIRES GETTEXT REQUIRED)
    MANAGE_DEPENDENCY(BUILD_REQUIRES FINDUTILS REQUIRED)
    MANAGE_DEPENDENCY(REQUIRES GETTEXT REQUIRED)


    FOREACH(_name "xgettext" "msgmerge" "msgfmt" "msginit")
	STRING(TOUPPER "${_name}" _cmd)
	FIND_PROGRAM_ERROR_HANDLING(${_cmd}_EXECUTABLE
	    ERROR_MSG " gettext support is disabled."
	    ERROR_VAR _gettext_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    "${_name}"
	    )
	M_MSG(${M_INFO1} "${_cmd}_EXECUTABLE=${${_cmd}_EXECUTABLE}")
    ENDFOREACH(_name "xgettext" "msgmerge" "msgfmt")
    SET(MANAGE_TRANSLATION_GETTEXT_POT_FILES "" CACHE INTERNAL "POT files")
    SET(MANAGE_TRANSLATION_GETTEXT_PO_FILES "" CACHE INTERNAL "PO files")
    SET(MANAGE_TRANSLATION_GETTEXT_MO_FILES "" CACHE INTERNAL "MO files")
    SET(MANAGE_TRANSLATION_LOCALES "" CACHE INTERNAL "Translation locales")
ENDFUNCTION(MANAGE_GETTEXT_INIT)

SET(MANAGE_POT_FILE_VALID_OPTIONS "SRCS" "PO_DIR" "MO_DIR" "NO_MO" "LOCALES" "SYSTEM_LOCALES" 
    "XGETTEXT_OPTIONS" "MSGMERGE_OPTIONS" "MSGFMT_OPTIONS" "CLEAN" "COMMAND" "DEPENDS"
    )

## Internal
FUNCTION(MANAGE_POT_FILE_SET_VARS cmdListVar msgmergeOptsVar msgfmtOptsVar localesVar poDirVar moDirVar srcsVar dependsVar cleanVar potFile)
    VARIABLE_PARSE_ARGN(_o MANAGE_POT_FILE_VALID_OPTIONS ${ARGN})
    IF("${_o_COMMAND}" STREQUAL "")
	LIST(APPEND ${cmdListVar} ${XGETTEXT_EXECUTABLE})
	IF(NOT _o_XGETTEXT_OPTIONS)
	    SET(_o_XGETTEXT_OPTIONS 
		"${MANAGE_TRANSLATION_XGETTEXT_OPTIONS}"
		)
	ENDIF()
	LIST(APPEND ${cmdListVar} ${_o_XGETTEXT_OPTIONS})
	IF("${_o_SRCS}" STREQUAL "")
	    M_MSG(${M_WARN} 
		"MANAGE_POT_FILE: xgettext: No SRCS for ${potFile}"
		)
	ENDIF()
	LIST(APPEND ${cmdListVar} -o ${potFile}
	    "--package-name=${PROJECT_NAME}"
	    "--package-version=${PRJ_VER}"
	    "--msgid-bugs-address=${MAINTAINER}"
	    ${_o_SRCS}
	    )
    ELSE()
	LIST(APPEND ${cmdListVar} ${_o_COMMAND})
    ENDIF()
    LIST(APPEND ${srcsVar} ${_o_SRCS})
    LIST(APPEND ${dependsVar} ${_o_DEPENDS})

    GET_FILENAME_COMPONENT(_potDir "${potFile}" PATH)
    IF("${_o_PO_DIR}" STREQUAL "")
	SET(_o_PO_DIR "${_potDir}")
    ENDIF()
    MESSAGE("###PO_DIR=${_o_PO_DIR}")
    SET(${poDirVar} "${_o_PO_DIR}" PARENT_SCOPE)

    MANAGE_GETTEXT_LOCALES(_locales "${_o_PO_DIR}" ${ARGN})
    SET(${localesVar} "${_locales}" PARENT_SCOPE)

    IF(NOT "${_o_MSGMERGE_OPTIONS}" STREQUAL "")
	SET(_o_MSGMERGE_OPTIONS "${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}")
    ENDIF()
    SET(${msgmergeOptVar} "${_o_MSGMERGE_OPTIONS}" PARENT_SCOPE)

    IF(NOT "${_o_MSGFMT_OPTIONS}" STREQUAL "")
	SET(_o_MSGFMT_OPTIONS "${MANAGE_TRANSLATION_MSGFMT_OPTIONS}")
    ENDIF()
    SET(${msgfmtOptVar} "${_o_MSGFMT_OPTIONS}" PARENT_SCOPE)

    IF(DEFINED _o_CLEAN)
	SET(${cleanVar} 1 PARENT_SCOPE)
    ELSE()
	SET(${cleanVar} 0 PARENT_SCOPE)
    ENDIF()

    IF(DEFINED _o_NO_MO)
	SET(${moDirVar} "" PARENT_SCOPE)
    ELSEIF("${_o_MO_DIR}" STREQUAL "")
	SET(${moDirVar} "${_o_PO_DIR}" PARENT_SCOPE)
    ELSE()
	SET(${moDirVar} "${_o_MO_DIR}" PARENT_SCOPE)
    ENDIF()
    IF(NOT cleanVar)
	SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")
    ENDIF()
ENDFUNCTION(MANAGE_POT_FILE_SET_VARS)

FUNCTION(MANAGE_POT_FILE potFile)
    IF(_gettext_dependency_missing)
	RETURN()
    ENDIF(_gettext_dependency_missing)
    MANAGE_POT_FILE_SET_VARS(cmdList msgmergeOpts msgfmtOpts locales poDir moDir srcs depends cleanVar "${potFile}" ${ARGN})

    ADD_CUSTOM_COMMAND(OUTPUT ${potFile}
	COMMAND ${cmdList}
	DEPENDS ${srcs} ${depends}
	COMMENT "${potFile}: ${cmdList}"
	)

    ## Not only POT, but also PO and MO as well
    FOREACH(_l ${locales})
	ADD_CUSTOM_COMMAND(OUTPUT ${poDir}/${_l}.po
	    COMMAND ${MSGMERGE_EXECUTABLE} ${MSGMERGE_OPTIONS}  
	    )
    ENDFOREACH(_l)
    ADD_CUSTOM_COMMAND(OUTPUT 
	MANAGE_GETTEXT_LOCALES localeListVar poDir)
    LIST(APPEND MANAGE_TRANSLATION_GETTEXT_POT_FILES ${potFile})
    SET(MANAGE_TRANSLATION_GETTEXT_POT_FILES
	"${MANAGE_TRANSLATION_GETTEXT_POT_FILES}"
	CACHE INTERNAL "List of pot files"
	)

    ## In case potFile is not in source control
    SOURCE_ARCHIVE_CONTENTS_ADD("${potFile}")

    GET_FILENAME_COMPONENT(_potName "${potFile}" NAME_WE)
    SET(MANAGE_TRANSLATION_GETTEXT_POT_FILE_${_potName}_PO_DIR "${poDir}")
ENDFUNCTION(MANAGE_POT_FILE)

## Internal
# MANAGE_GETTEXT_GET_PO_FILES(<var> <pot>)
#   - Get the po file list associate to the given pot
#     * Parameters:
#       + var: Returns po file list related to pot.
#       + pot: .pot file.
FUNCTION(MANAGE_GETTEXT_GET_PO_FILES var pot)
    IF("${MANAGE_TRANSLATION_LOCALES}" STREQUAL "")
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
	    EXECUTE_PROCESS(COMMAND ${MSGINIT_EXECUTABLE}
		--output ${_po} --input ${pot}
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

SET(MANAGE_GETTEXT_LOCALES_VALID_OPTIONS "LOCALES" "SYSTEM_LOCALES")
## Internal
FUNCTION(MANAGE_GETTEXT_LOCALES localeListVar poDir)
    VARIABLE_PARSE_ARGN(_o MANAGE_GETTEXT_LOCALES_VALID_OPTIONS ${ARGN})
    IF(NOT "${_o_LOCALES}" STREQUAL "")
	## Locale is defined
	SET(${localeListVar} "${_o_LOCALES}" PARENT_SCOPE)
    ELSEIF(DEFINED _o_SYSTEM_LOCALES)
	EXECUTE_PROCESS(
	    COMMAND locale -a 
	    COMMAND grep -e "^[a-z]*_[A-Z]*$"
	    COMMAND sort -u 
	    COMMAND xargs 
	    COMMAND sed -e "s/ /;/g"
	    OUTPUT_VARIABLE _o_LOCALES
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	SET(${localeListVar} "${_o_LOCALES}" PARENT_SCOPE)
    ELSE()
	## LOCALES is not specified, detect now
	EXECUTE_PROCESS(
	    COMMAND find ${poDir} -name "*.po" -printf "%f\n"
	    COMMAND sed -e "s/.po//g"
	    COMMAND sort -u
	    COMMAND xargs
	    COMMAND sed -e "s/ /;/g"
	    OUTPUT_VARIABLE _o_LOCALES
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	LIST(APPEND _o_LOCALES ${_locales})
	IF("${_o_LOCALES}" STREQUAL "")
	    ## Failed to find any locale
	    M_MSG(${M_ERROR} "MANAGE_GETTEXT: Failed to detect locales. Please either specify LOCALES or SYSTEM_LOCALES.")
	ENDIF()
	SET(${localeListVar} "${_o_LOCALES}" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION(MANAGE_GETTEXT_LOCALES)

FUNCTION(MANAGE_GETTEXT)
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
	VARIABLE_TO_ARGN(_addPotFileOptList _o MANAGE_POT_FILE_VALID_OPTIONS)
	## Add new pot file
	MANAGE_POT_FILE("${_potFile}" ${_addPotFileOptList})
    ENDIF(_potFile)

    ## Locales
    SET(_validLocaleOptList
	"LOCALES" "SYSTEM_LOCALES"
	)
    VARIABLE_TO_ARGN(_manageGettextLocaleOptList _o MANAGE_GETTEXT_LOCALES_VALID_OPTIONS)
    SET(localeList "")
    MANAGE_GETTEXT_LOCALES(localeList ${_manageGettextLocaleOptList})
    SET(MANAGE_TRANSLATION_LOCALES "${localeList}" CACHE INTERNAL
	"Locales"
	)

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
		COMMAND ${MSGMERGE_EXECUTABLE} 
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
		COMMAND ${MSGFMT_EXECUTABLE} 
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

