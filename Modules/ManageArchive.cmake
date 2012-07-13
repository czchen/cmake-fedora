# - Pack source helper module
# By default CPack pack everything under the source directory, this is usually
# undesirable. We avoid this by using the sane default ignore list.
#
# Includes:
#   ManageVersion
#   CPack
#
# Included by:
#   PackRPM
#
# Read and Defines following variable:
#   SOURCE_ARCHIVE_IGNORE_FILES_DEFAULT: Default list of file patterns
#     that are normally exclude from the source package.
#     Override it by setting it before INCLUDE(PackSource).
# Defines following target:
#     pack_remove_old: Remove old source package files.
# Defines following macro:
#   SOURCE_ARCHIVE(outputDir [generator])
#   - Pack source files as <projectName>-<PRJ_VER>-Source.<packFormat>,
#     Arguments:
#     + outputDir: Directory to write source archive.
#     + generator: (Optional) Method to make archive. Basically this argument
#       is passed as CPACK_GENERATOR. Default to TGZ.
#     Read following variables:
#     + PROJECT_NAME: Project name
#     + VENDOR: Organization that issue this project.
#     + PRJ_VER: Project version
#     + PRJ_SUMMARY: (Optional) Project summary
#     + SOURCE_ARCHIVE_IGNORE_FILES: A list of regex filename pattern
#       that should be excluded from source archive file.
#       (SOURCE_ARCHIVE_IGNORE_FILE_CMAKE) is already in this list.
#     Define following variables:
#     + SOURCE_ARCHIVE_CONTENTS: List of files to be packed to archive.
#     + SOURCE_ARCHIVE_FILE_EXTENSION: File extension of the source package
#       files.
#     + SOURCE_ARCHIVE_NAME: Name of source archive (without path)
#     + SOURCE_ARCHIVE_FILE: Path to source archive file
#     Target:
#     + pack_src: Pack source files like package_source.
#     + clean_pack_src: Remove all source archives.
#     + clean_old_pack_src: Remove all old source package.
#
#
IF(NOT DEFINED _MANAGE_ARCHIVE_CMAKE_)
    SET (_MANAGE_ARCHIVE_CMAKE_ "DEFINED")
    SET(SOURCE_ARCHIVE_IGNORE_FILES_DEFAULT
	"/\\\\.svn/"  "/CVS/" "/\\\\.git/"  "\\\\.gitignore$" "/\\\\.hg/"
	"/\\\\.hgignore$"
	"~$" "\\\\.swp$" "\\\\.log$" "\\\\.bak$" "\\\\.old$"
	"\\\\.gmo$" "\\\\.cache$"
	"\\\\.tar.gz$" "\\\\.tar.bz2$" "/src/config\\\\.h$" "NO_PACK")

    SET(SOURCE_ARCHIVE_IGNORE_FILES_CMAKE "/CMakeFiles/" "_CPack_Packages/" "/Testing/"
	"\\\\.directory$" "CMakeCache\\\\.txt$"
	"/install_manifest.txt$"
	"/cmake_install\\\\.cmake$" "/cmake_uninstall\\\\.cmake$""/CPack.*\\\\.cmake$" "/CTestTestfile\\\\.cmake$"
	"Makefile$"
	)

    SET(SOURCE_ARCHIVE_IGNORE_FILES ${SOURCE_ARCHIVE_IGNORE_FILES}
	${SOURCE_ARCHIVE_IGNORE_FILES_CMAKE} ${SOURCE_ARCHIVE_IGNORE_FILES_DEFAULT})

    INCLUDE(ManageVersion)

    # Internal:  SOURCE_ARCHIVE_GET_CONTENTS()
    #   - Return all source file to be packed.
    #     This is called by SOURCE_ARCHIVE(),
    #     So no need to call it again.
    FUNCTION(SOURCE_ARCHIVE_GET_CONTENTS )
	SET(_filelist "")
	FILE(GLOB_RECURSE _ls "*")
	STRING(REPLACE "\\\\" "\\" _ignore_files "${SOURCE_ARCHIVE_IGNORE_FILES}")
	FOREACH(_file ${_ls})
	    SET(_matched 0)
	    FOREACH(filePattern ${_ignore_files})
		#MESSAGE("filePattern=${filePattern}")
		IF(NOT _matched)
		    IF(_file MATCHES "${filePattern}")
			SET(_matched 1)
		    ENDIF(_file MATCHES "${filePattern}")
		ENDIF(NOT _matched)
	    ENDFOREACH(filePattern ${_ignore_files})
	    IF(NOT _matched)
		FILE(RELATIVE_PATH _file ${CMAKE_SOURCE_DIR} "${_file}")
		#MESSAGE("_file=${_file}")
		LIST(APPEND _filelist "${_file}")
	    ENDIF(NOT _matched)
	ENDFOREACH(_file ${_ls})
	SET(SOURCE_ARCHIVE_CONTENTS CACHE STRING "Source archive file list" FORCE)
	#MESSAGE("SOURCE_ARCHIVE_IGNORE_FILES=${_ignore_files}")
    ENDFUNCTION(SOURCE_ARCHIVE_GET_CONTENTS var)

    MACRO(PACK_SOURCE_ARCHIVE outputDir)
	#MESSAGE("SOURCE_ARCHIVE_IGNORE_FILES=${SOURCE_ARCHIVE_IGNORE_FILES}")
	IF(PRJ_VER STREQUAL "")
	    MESSAGE(FATAL_ERROR "PRJ_VER not defined")
	ENDIF(PRJ_VER STREQUAL "")
	IF(${ARGV2})
	    SET(CPACK_GENERATOR "${ARGV2}")
	ELSE(${ARGV2})
	    SET(CPACK_GENERATOR "TGZ")
	ENDIF(${ARGV2})
	SET(CPACK_SOURCE_GENERATOR ${CPACK_GENERATOR})
	IF(${CPACK_GENERATOR} STREQUAL "TGZ")
	    SET(SOURCE_ARCHIVE_FILE_EXTENSION "tar.gz")
	ELSEIF(${CPACK_GENERATOR} STREQUAL "TBZ2")
	    SET(SOURCE_ARCHIVE_FILE_EXTENSION "tar.bz2")
	ELSEIF(${CPACK_GENERATOR} STREQUAL "ZIP")
	    SET(SOURCE_ARCHIVE_FILE_EXTENSION "zip")
	ENDIF(${CPACK_GENERATOR} STREQUAL "TGZ")

	SET(CSOURCE_ARCHIVE_IGNORE_FILES ${SOURCE_ARCHIVE_IGNORE_FILES})
	SET(CPACK_PACKAGE_VERSION ${PRJ_VER})

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
	SET(SOURCE_ARCHIVE_NAME "${CPACK_SOURCE_PACKAGE_FILE_NAME}.${SOURCE_ARCHIVE_FILE_EXTENSION}" CACHE STRING "Source archive name" FORCE)
	SET(SOURCE_ARCHIVE_FILE "${outputDir}/${SOURCE_ARCHIEVE_NAME}" CACHE FILEPATH "Source archive file" FORCE)

	SET(CPACK_PACKAGE_VENDOR "${VENDOR}")
	SOURCE_ARCHIVE_GET_CONTENTS()

	INCLUDE(CPack)

	# Get relative path of outputDir
	FILE(RELATIVE_PATH _outputDir_rel ${CMAKE_BINARY_DIR} ${outputDir})
	#MESSAGE("#_outputDir_rel=${_outputDir_rel}")

	IF("${_outputDir_rel}" STREQUAL ".")
	    ADD_CUSTOM_TARGET_COMMAND(pack_src
		OUTPUT "${SOURCE_ARCHIVE_FILE}"
		COMMAND make package_source
		DEPENDS  ${SOURCE_ARCHIVE_CONTENTS}
		COMMENT "Pack the source: ${SOURCE_ARCHIVE_FILE}"
		)
	ELSE("${_outputDir_rel}" STREQUAL ".")
	    FILE(MAKE_DIRECTORY ${outputDir})
	    ADD_CUSTOM_TARGET_COMMAND(pack_src
		OUTPUT "${SOURCE_ARCHIVE_FILE}"
		COMMAND make package_source
		COMMAND cmake -E copy ${${var}} "${_outputDir_rel}/"
		COMMAND cmake -E remove ${${var}}
		DEPENDS ${SOURCE_ARCHIVE_CONTENTS} ${_outputDir_rel}
		COMMENT "Pack the source: ${SOURCE_ARCHIVE_FILE}"
		)
	ENDIF("${_outputDir_rel}" STREQUAL ".")

	ADD_CUSTOM_TARGET(clean_old_pack_src
	    COMMAND find .
	    -name '${PROJECT_NAME}*.${SOURCE_ARCHIVE_FILE_EXTENSION}' ! -name '${PROJECT_NAME}-${PRJ_VER}-*.${SOURCE_ARCHIVE_FILE_EXTENSION}'
	    -print -delete
	    COMMENT "Cleaning old source archives"
	    )

	ADD_DEPENDENCIES(clean_old_pack_src changelog )

	ADD_CUSTOM_TARGET(clean_pack_src
	    COMMAND find .
	    -name '${PROJECT_NAME}*.${SOURCE_ARCHIVE_FILE_EXTENSION}'
	    -print -delete
	    COMMENT "Cleaning all source archives"
	    )
    ENDMACRO(PACK_SOURCE_ARCHIVE outputDir)

ENDIF(NOT DEFINED _MANAGE_ARCHIVE_CMAKE_)
