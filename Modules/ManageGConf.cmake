# - GConf relative targets such as install/unstall schemas.
# This module finds gconftool-2 or gconftool for GConf manipulation.
#
# Defines the following macros:
#   MANAGE_GCONF_SCHEMAS([FILE <schemasFile>] 
#       [INSTALL_DIR <dir>] [CONFIG_SOURCE <source>)
#     - Process schemas file.
#       * Parameters:
#         + FILE <schemasFile>: (Optional) See GCONF_SCHEMAS_FILE.
#           If not specified, it will determined by following order:
#           "GCONF_SCHEMAS_FILE"
#           "${SYSCONF_DIR}/gconf/schemas
#         + INSTALL_DIR <dir>: (Optional) See GCONF_INSTALL_DIR.
#         + CONFIG_SOURCE <source>: (Optional) See GCONF_CONFIG_SOURCE.
#       * Reads and defined following variables:
#         + GCONF_SCHEMAS_FILE: Schema file.
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.schemas
#         + GCONF_SCHEMAS_INSTALL_DIR: Directory the 
#           schemas file installed to
#	    Default: ${SYSCONF_INSTALL_DIR}/gconf/schemas
#         + GCONF_CONFIG_SOURCE: Configuration source.
#           Default: "" (Use the system default)   
#       * Defines following targets:
#         + install_schemas: install schemas
#         + uninstall_schemas: uninstall schemas
#

IF(DEFINED _MANAGE_GCONF_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_GCONF_CMAKE_)
SET(_MANAGE_GCONF_CMAKE_ DEFINED)
INCLUDE(ManageDependency)
MANAGE_DEPENDENCY(REQUIRES GCONF2 REQUIRED FEDORA_NAME "GConf2")
MANAGE_DEPENDENCY(BUILD_REQUIRES GCONF2 REQUIRED 
    PKG_CONFIG "gconf-2.0" FEDORA_NAME "GConf2" DEVEL
    )
MANAGE_DEPENDENCY(REQUIRES_PRE GCONF2 REQUIRED 
    FEDORA_NAME "GConf2"
    )
MANAGE_DEPENDENCY(REQUIRES_PREUN GCONF2 REQUIRED 
    FEDORA_NAME "GConf2"
    )
MANAGE_DEPENDENCY(REQUIRES_POST GCONF2 REQUIRED 
    FEDORA_NAME "GConf2"
    )

MACRO(MANAGE_GCONF_SCHEMAS)
    INCLUDE(ManageVersion)
    SET(_validOptions "FILE" "INSTALL_DIR" "CONFIG_SOURCE")
    VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})

    ## Determine GCONF_SCHEMA_FILE
    IF(NOT "${_opt_FILE}" STREQUAL "")
	SET(GCONF_SCHEMAS_FILE ${_opt_FILE})
    ELSEIF("${GCONF_SCHEMAS_FILE}" STREQUAL "")
	SET(GCONF_SCHEMAS_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.schemas")
    ENDIF(NOT "${_opt_FILE}" STREQUAL "")

    GET_FILENAME_COMPONENT(_gconf_schemas_basename ${GCONF_SCHEMAS_FILE} NAME)

    ## Determine GCONF_SCHEMAS_INSTALL_DIR
    IF(NOT "${_opt_INSTALL_DIR}" STREQUAL "")
	SET(GCONF_SCHEMAS_INSTALL_DIR ${_opt_INSTALL_DIR})
    ELSEIF("${GCONF_SCHEMAS_INSTALL_DIR}" STREQUAL "")
	IF("${SYSCONF_INSTALL_DIR}" STREQUAL "")
	    SET(GCONF_SCHEMAS_INSTALL_DIR  "${SYSCONF_DIR}/gconf/schemas")
	ELSE("${SYSCONF_INSTALL_DIR}" STREQUAL "")
	    SET(GCONF_SCHEMAS_INSTALL_DIR  "${SYSCONF_INSTALL_DIR}/gconf/schemas")
	ENDIF("${SYSCONF_INSTALL_DIR}" STREQUAL "")
    ENDIF(NOT "${_opt_INSTALL_DIR}" STREQUAL "")

    ## Determine GCONF_CONFIG_SOURCE
    IF(NOT "${_opt_CONFIG_SOURCE}" STREQUAL "")
	SET(GCONF_CONFIG_SOURCE ${_opt_INSTALL_DIR})
    ELSEIF("${GCONF_CONFIG_SOURCE}" STREQUAL "")
	SET(GCONF_CONFIG_SOURCE "")
    ENDIF(NOT "${_opt_CONFIG_SOURCE}" STREQUAL "")

    ADD_CUSTOM_TARGET(uninstall_schemas
	COMMAND GCONF_CONFIG_SOURCE=${GCONF_CONFIG_SOURCE}
	${GCONF2_EXECUTABLE} --makefile-uninstall-rule
	${GCONF_SCHEMAS_INSTALL_DIR}/${_gconf_schemas_basename}
	COMMENT "Uninstalling schemas"
	)

    ADD_CUSTOM_TARGET(install_schemas
	COMMAND cmake -E copy ${GCONF_SCHEMAS_FILE} ${GCONF_SCHEMAS_INSTALL_DIR}/${_gconf_schemas_basename}
	COMMAND GCONF_CONFIG_SOURCE=${GCONF_CONFIG_SOURCE}
	${GCONF2_EXECUTABLE} --makefile-install-rule
	${GCONF_SCHEMAS_INSTALL_DIR}/${_gconf_schemas_basename}
	DEPENDS ${GCONF_SCHEMAS_FILE}
	COMMENT "Installing schemas"
	)

    MANAGE_FILE_INSTALL(SYSCONF ${GCONF_SCHEMAS_FILE}
	DEST_SUBDIR "gconf/schemas")
ENDMACRO(MANAGE_GCONF_SCHEMAS)


