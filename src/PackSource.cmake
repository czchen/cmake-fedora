# - Pack source helper module
# By default CPack pack everything under the source directory, this is usually
# undesirable. We avoid this by using the sane default ignore list.
#
# Read and Defines following variable:
#   PACK_SOURCE_IGNORE_FILES_DEFAULT: Default list of file patterns
#     that are normally exclude from the source package.
#     Override it by setting it before INCLUDE(PackSource).
# Defines following target:
#     pack_remove_old: Remove old source package files.
# Defines following macro:
#   PACK_SOURCE(var outputDir [generator])
#   - Pack source files as <projectName>-<PRJ_VER>-Source.<packFormat>,
#     Arguments:
#     + var: The filename of source package is outputted to this var.
#            Path is excluded.
#     + outputDir: Directory to write source tarball.
#     + generator: (Optional) Method to make tarball. Basically this argument
#       is passed as CPACK_GENERATOR. Default to TGZ.
#     Variable to be read:
#     + PROJECT_NAME: Project name
#     + VENDOR: Organization that issue this project.
#     + PRJ_VER: Project version
#     + PRJ_SUMMARY: (Optional) Project summary
#     + PACK_SOURCE_IGNORE_FILES: A list of regex filename pattern to indicate
#       the files to be excluded. Note that cmake generated file
#       (PACK_SOURCE_IGNORE_FILE_CMAKE) is already in this list.
#     Target:
#     + pack_src: Pack source files like package_source.
#       This target depends on version_check.
#     + clean_pack_src: Remove all source packages.
#     + clean_old_pack_src: Remove all old source package.
#       This target depends on version_check.
#
#
IF(NOT DEFINED _PACK_SOURCE_CMAKE_)
    SET (_PACK_SOURCE_CMAKE_ "DEFINED")
    SET(PACK_SOURCE_IGNORE_FILES_DEFAULT
	"/\\\\.svn/"  "/CVS/" "/\\\\.git/"  "\\\\.gitignore$" "/\\\\.hg/"
	"/\\\\.hgignore$"
	"~$" "\\\\.swp$" "\\\\.log$" "\\\\.bak$" "\\\\.old$"
	"\\\\.gmo$" "\\\\.cache$"
	"\\\\.tar.gz$" "\\\\.tar.bz2$" "/src/config\\\\.h$" "NO_PACK")

    SET(PACK_SOURCE_IGNORE_FILES_CMAKE "/CMakeFiles/" "_CPack_Packages/" "/Testing/"
	"\\\\.directory$" "CMakeCache\\\\.txt$"
	"/install_manifest.txt$"
	"/cmake_install\\\\.cmake$" "/cmake_uninstall\\\\.cmake$""/CPack.*\\\\.cmake$" "/CTestTestfile\\\\.cmake$"
	"Makefile$"
	)

    SET(PACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES}
	${PACK_SOURCE_IGNORE_FILES_CMAKE} ${PACK_SOURCE_IGNORE_FILES_DEFAULT})

    INCLUDE(ManageVersion)

    MACRO(PACK_SOURCE var outputDir)
	#MESSAGE("PACK_SOURCE_IGNORE_FILES=${PACK_SOURCE_IGNORE_FILES}")

	IF(PRJ_VER STREQUAL "")
	    MESSAGE(FATAL_ERROR "PRJ_VER not defined")
	ENDIF(PRJ_VER STREQUAL "")
	IF(${ARGV3})
	    SET(CPACK_GENERATOR "${ARGV3}")
	ELSE(${ARGV3})
	    SET(CPACK_GENERATOR "TGZ")
	ENDIF(${ARGV3})
	SET(CPACK_SOURCE_GENERATOR ${CPACK_GENERATOR})
	IF(${CPACK_GENERATOR} STREQUAL "TGZ")
	    SET(_pack_source_ext "tar.gz")
	ELSEIF(${CPACK_GENERATOR} STREQUAL "TBZ2")
	    SET(_pack_source_ext "tar.bz2")
	ELSEIF(${CPACK_GENERATOR} STREQUAL "ZIP")
	    SET(_pack_source_ext "zip")
	ENDIF(${CPACK_GENERATOR} STREQUAL "TGZ")

	SET(CPACK_SOURCE_IGNORE_FILES ${PACK_SOURCE_IGNORE_FILES})
	SET(CPACK_PACKAGE_VERSION ${PRJ_VER})

	# Get relative path of outputDir
	FILE(RELATIVE_PATH _outputDir_rel ${CMAKE_BINARY_DIR} ${outputDir})
	#MESSAGE("#_outputDir_rel=${_outputDir_rel}")

	IF(EXISTS ${CMAKE_SOURCE_DIR}/COPYING)
	    SET(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/README)
	ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/COPYING)

	IF(EXISTS ${CMAKE_SOURCE_DIR}/README)
	    SET(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_SOURCE_DIR}/README)
	ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/README)

	IF(DEFINED PRJ_SUMMARY)
	    SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PRJ_SUMMARY}")
	ENDIF(DEFINED PRJ_SUMMARY)

	SET(CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PRJ_VER}-Source")
	SET(${var} "${CPACK_SOURCE_PACKAGE_FILE_NAME}.${_pack_source_ext}")

	SET(CPACK_PACKAGE_VENDOR "${VENDOR}")

	INCLUDE(CPack)

	ADD_CUSTOM_COMMAND(OUTPUT "${_outputDir_rel}/${${var}}"
	   COMMAND make pack_src
	   DEPENDS ChangeLog ${RELEASE_FILE}
	   COMMENT "Packing the source"
	    )

	IF("${_outputDir_rel}" STREQUAL ".")
	    ADD_CUSTOM_TARGET(pack_src
		COMMAND make package_source
		DEPENDS ChangeLog
		)
	ELSE("${_outputDir_rel}" STREQUAL ".")
	    ADD_CUSTOM_TARGET(pack_src
		COMMAND make package_source
		COMMAND cmake -E copy ${${var}} "${_outputDir_rel}/"
		COMMAND cmake -E remove ${${var}}
		DEPENDS ChangeLog
		)
	ENDIF("${_outputDir_rel}" STREQUAL ".")

	ADD_DEPENDENCIES(pack_src version_check)

	ADD_CUSTOM_TARGET(clean_old_pack_src
	    COMMAND find .
	    -name '${PROJECT_NAME}*.${_pack_source_ext}' ! -name '${PROJECT_NAME}-${PRJ_VER}-*.${_pack_source_ext}'
	    -print -delete
	    COMMENT "Cleaning old source packages"
	    )

	ADD_DEPENDENCIES(clean_old_pack_src version_check)

	ADD_CUSTOM_TARGET(clean_pack_src
	    COMMAND find .
	    -name '${PROJECT_NAME}*.${_pack_source_ext}'
	    -print -delete
	    COMMENT "Cleaning all source packages"
	    )
    ENDMACRO(PACK_SOURCE var outputDir)


ENDIF(NOT DEFINED _PACK_SOURCE_CMAKE_)

