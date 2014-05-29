# - Manage RPM Script
# RPM related scripts to be invoked in command line.

MACRO(MANAGE_RPM_SCRIPT_PRINT_USAGE)
    MESSAGE(
	"Manage RPM script: This script is not recommend for end users
  cmake -Dcmd=spec -Dspec=<project.spec> -Dspec_in=<project.spec.in>
      -Dmanifests=<path/install_manifests.txt>
      -Drelease=<path/RELEASE-NOTES.txt>
      -Dprj_info=<path/prj_info.cmake>
      -Dpkg_name=PACKAGE_NAME
      [\"-D<var>=<value>\"]
      -P <CmakeModulePath>/ManageRPMScript.cmake
    Make project spec file according to spec_in and CMakeCache.txt.   
      Note: Please pass the necessary variables via -Dvar=VALUE,
        e.g. -DPROJECT_NAME=cmake-fedora

  cmake -Dcmd=spec_manifests
      -Dmanifests=<path/install_manifests.txt>
      -Dpkg_name=PACKAGE_NAME
      [\"-Dconfig_replace=<file1;file2>\"]
      [\"-D<var>=<value>\"]
      -P <CmakeModulePath>/ManageRPMScript.cmake
    Convert install_manifests.txt to part of a SPEC file.
      Options:
        -Dconfig_replace: List of configure files that should use
	  %config instead of %config(noreplace)
      Note: Please pass the necessary variables via -Dvar=VALUE,
        e.g. -DPROJECT_NAME=cmake-fedora
    
  cmake -Dcmd=spec_changelog
      -Dmanifests=<path/install_manifests.txt>
      -Drelease=<path/RELEASE-NOTES.txt>
      -Dprj_info=<path/prj_info.cmake>
      -Dpkg_name=PACKAGE_NAME
      [\"-D<var>=<value>\"]
      -P <CmakeModulePath>/ManageRPMScript.cmake
    Convert RELEASE-NOTES.txt to ChangeLog a SPEC file.
      Note: Please pass the necessary variables via -Dvar=VALUE,
        e.g. -DPROJECT_NAME=cmake-fedora

   cmake -Dcmd=make_manifests
     [\"-Dtmp_dir=<dir>\"]
     Make install_manifests.txt.
       Options:
       -Dtmp_dir: Directory for tempory files. 
         Default is /tmp/cmake-fedora

"
)
ENDMACRO(MANAGE_RPM_SCRIPT_PRINT_USAGE)

MACRO(MANIFEST_TO_STRING strVar manifestsFile)
    SET(_validOptions "CONFIG_REPLACE")
    VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})

    FILE(STRINGS ${manifestsFile} _filesInManifests)
    SET(_docList "")
    SET(_fileList "")
    SET(_hasTranslation 0)
    FOREACH(_file ${_filesInManifests})
	SET(_addToFileList 1)
	STRING(REPLACE "${pkg_name}" "%{name}" _file "${_file}")
	IF("${_file}" MATCHES "^/usr/bin/")
	    STRING(REGEX REPLACE "^/usr/bin/" "%{_bindir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/sbin/")
	    STRING(REGEX REPLACE "^/usr/sbin/" "%{_sbindir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/libexec/")
	    STRING(REGEX REPLACE "^/usr/libexec/" "%{_libexecdir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/lib")
	    STRING(REGEX REPLACE "^/usr/lib(64)?/" "%{_libdir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/include/")
	    STRING(REGEX REPLACE "^/usr/include/" "%{_includedir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/etc/rc.d/init.d/")
	    STRING(REGEX REPLACE "^/etc/rc.d/init.d/" "%{_initrddir}/" _f "${_file}")
	ELSEIF("${_file}" MATCHES "^/etc/")
	    STRING(REGEX REPLACE "^/etc/" "" _f "${_file}")
	    SET(_found 0)
	    FOREACH(_o _opt_CONFIG_REPLACE)
		IF(_o STREQUAL _f)
		    SET(_found 1)
		    BREAK()
		ENDIF()
	    ENDFOREACH(_o)
	    IF(_found)
		SET(_file "%config %{_sysconfdir}/${_f}")
		STRING(REGEX REPLACE "^/etc/" "%config %{_sysconfdir}/" _file ${_file})
	    ELSE()
		SET(_file "%config(noreplace) %{_sysconfdir}/${_f}")
	    ENDIF()
	ELSEIF("${_file}" MATCHES "^/usr/share/info/")
	    STRING(REGEX REPLACE "^/usr/share/info/" "%{_infodir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/share/doc/")
	    SET(_addToFileList 0)
	    STRING(REGEX REPLACE "^/usr/share/doc/%{name}[^/]*/" "" _file ${_file})
	    LIST(APPEND _docList ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/share/man/")
	    STRING(REGEX REPLACE "^/usr/share/man/" "%{_mandir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/share/")
	    IF(_file MATCHES "^/usr/share/locale/")
		SET(_hasTranslation 1)
	    ENDIF()
	    STRING(REGEX REPLACE "^/usr/share/" "%{_datadir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/var/lib/")
	    STRING(REGEX REPLACE "^/var/lib/" "%{_sharedstatedir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/var/")
	    STRING(REGEX REPLACE "^/var/" "%{_localstatedir}/" _file ${_file})
	ELSE()
	    M_MSG(${M_ERROR} "ManageRPMScript: Unhandled file: ${_file}")
	ENDIF()

	IF(_addToFileList)
	    LIST(APPEND _fileList "${_file}")
	ENDIF(_addToFileList)
    ENDFOREACH(_file ${_filesInManifests})
    IF(_hasTranslation)
	STRING_APPEND(${strVar} "%find_lang %{name}\n" "\n")
	STRING_APPEND(${strVar} "%files -f %{name}.lang" "\n")
    ELSE()
	STRING_APPEND(${strVar} "%files" "\n")
    ENDIF()
    # Append %doc
    STRING_JOIN(_docStr " " ${_docList})
    STRING_APPEND(${strVar} "%doc ${_docStr}" "\n")

    # Append rest of files
    LIST(SORT _fileList)
    FOREACH(_f ${_fileList})
	STRING_APPEND(${strVar} "${_f}" "\n")
    ENDFOREACH(_f ${_fileList})
ENDMACRO(MANIFEST_TO_STRING strVar manifests)

FUNCTION(SPEC_MANIFESTS)
    IF(NOT manifests)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Dmanifests=<install_manifests.txt>\"")
    ENDIF()
    IF(NOT pkg_name)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dpkg_name=<package_name>")
    ENDIF()
    SET(RPM_FAKE_INSTALL_DIR "/tmp/cmake-fedora-fake-install")
    EXECUTE_PROCESS(COMMAND make DESTDIR=${RPM_FAKE_INSTALL_DIR} install)
    MANIFEST_TO_STRING(mStr ${manifests})
    M_OUT("${mStr}")
ENDFUNCTION(SPEC_MANIFESTS)

MACRO(LOAD_PRJ_INFO)
    IF(NOT prj_info)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dprj_info=<prj_info.cmake>")
    ENDIF()
    INCLUDE(${prj_info} RESULT_VARIABLE prj_info_path)
    IF(prj_info_path STREQUAL "NOTFOUND")
	MESSAGE(SEND_ERROR "prj_info.cmake cannot be found")
    ENDIF()
ENDMACRO(LOAD_PRJ_INFO)

MACRO(CHANGELOG_TO_STRING strVar)
    FILE(STRINGS "${release}" _releaseLines)

    SET(_changeItemSection 0)
    SET(_changeLogThis "")
    ## Parse release file
    FOREACH(_line ${_releaseLines})
	IF(_changeItemSection)
	    ### Append lines in change section
	    STRING_APPEND(_changeLogThis "${_line}" "\n")
	ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
	    ### Start the change section
	    SET(_changeItemSection 1)
	ENDIF()
    ENDFOREACH(_line ${_releaseLines})

    FIND_PROGRAM_ERROR_HANDLING(CMAKE_FEDORA_KOJI_CMD
	FIND_ARGS NAMES cmake-fedora-koji
	PATHS  ${CMAKE_FEDORA_ADDITIONAL_SCRIPT_PATH}
	)

    SET(CMAKE_FEDORA_TMP_DIR "/tmp")
    SET(RPM_CHANGELOG_TMP_FILE "${CMAKE_FEDORA_TMP_DIR}/${pkg_name}.changelog")

    EXECUTE_PROCESS(
	COMMAND ${CMAKE_FEDORA_KOJI_CMD} newest-changelog "${pkg_name}" | tail -n +2
	OUTPUT_VARIABLE _changeLogPrev
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)

    SET(${strVar} "%changelog")
    STRING_APPEND(${strVar} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}-${RPM_RELEASE_NO}" "\n")
    STRING_APPEND(${strVar} "${_changeLogThis}\n" "\n")
    STRING_APPEND(${strVar} "${_changeLogPrev}" "\n")
ENDMACRO(CHANGELOG_TO_STRING strVar)

FUNCTION(SPEC_CHANGELOG)
    IF(NOT release)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Drelease=<RELEASE-NOTES.txt>\"")
    ENDIF()
    IF(NOT pkg_name)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dpkg_name=<package_name>")
    ENDIF()
    LOAD_PRJ_INFO()
    CHANGELOG_TO_STRING(_changeLogStr)
    M_OUT("${_changeLogStr}")
ENDFUNCTION(SPEC_CHANGELOG)

FUNCTION(RPM_SPEC_STRING_ADD var str)
    IF("${ARGN}" STREQUAL "FRONT")
	STRING_PREPEND(${var} "${str}" "\n")
	SET(pos "${ARGN}")
    ELSE("${ARGN}" STREQUAL "FRONT")
	STRING_APPEND(${var} "${str}" "\n")
    ENDIF("${ARGN}" STREQUAL "FRONT")
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(RPM_SPEC_STRING_ADD var str)

FUNCTION(RPM_SPEC_STRING_ADD_DIRECTIVE var directive attribute content)
    SET(_str "%${directive}")
    IF(NOT attribute STREQUAL "")
	STRING_APPEND(_str " ${attribute}")
    ENDIF(NOT attribute STREQUAL "")

    IF(NOT content STREQUAL "")
	STRING_APPEND(_str "\n${content}")
    ENDIF(NOT content STREQUAL "")
    STRING_APPEND(_str "\n")
    RPM_SPEC_STRING_ADD(${var} "${_str}" ${ARGN})
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(RPM_SPEC_STRING_ADD_DIRECTIVE var directive attribute content)

FUNCTION(RPM_SPEC_STRING_ADD_TAG var tag attribute value)
    IF("${attribute}" STREQUAL "")
	SET(_str "${tag}:")
    ELSE("${attribute}" STREQUAL "")
	SET(_str "${tag}(${attribute}):")
    ENDIF("${attribute}" STREQUAL "")
    STRING_PADDING(_str "${_str}" ${RPM_SPEC_TAG_PADDING})
    STRING_APPEND(_str "${value}")
    RPM_SPEC_STRING_ADD(${var} "${_str}" ${ARGN})
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(RPM_SPEC_STRING_ADD_TAG var tag attribute value)

# Not exactly a header, but the first half
MACRO(SPEC_WRITE_HEADER)
    ## Summary
    RPM_SPEC_STRING_ADD_TAG(RPM_SPEC_SUMMARY_OUTPUT
	"Summary" "" "${PRJ_SUMMARY}"
	)
    SET(_lang "")
    FOREACH(_sT ${SUMMARY_TRANSLATIONS})
	IF(_lang STREQUAL "")
	    SET(_lang "${_sT}")
	ELSE(_lang STREQUAL "")
	    RPM_SPEC_STRING_ADD_TAG(RPM_SPEC_SUMMARY_OUTPUT
		"Summary" "${lang}" "${PRJ_SUMMARY}"
		)
	    SET(_lang "")
	ENDIF(_lang STREQUAL "")
    ENDFOREACH(_sT ${SUMMARY_TRANSLATIONS})

    ## Url
    SET(RPM_SPEC_URL_OUTPUT "${RPM_SPEC_URL}")

    ## Source
    SET(_buf "")
    SET(_i 0)
    FOREACH(_s ${RPM_SPEC_SOURCES})
	RPM_SPEC_STRING_ADD_TAG(_buf "Source${_i}" "" "${_s}")
	MATH(EXPR _i ${_i}+1)
    ENDFOREACH(_s ${RPM_SPEC_SOURCES})
    RPM_SPEC_STRING_ADD(RPM_SPEC_SOURCE_OUTPUT "${_buf}" FRONT)

    ## Requires (and BuildRequires)
    SET(_buf "")
    FOREACH(_s ${BUILD_REQUIRES})
	RPM_SPEC_STRING_ADD_TAG(_buf "BuildRequires" "" "${_s}")
    ENDFOREACH(_s ${RPM_SPEC_SOURCES})

    FOREACH(_s ${REQUIRES})
	RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "" "${_s}")
    ENDFOREACH(_s ${RPM_SPEC_SOURCES})
    RPM_SPEC_STRING_ADD(RPM_SPEC_REQUIRES_OUTPUT "${_buf}" FRONT)

    ## Description
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_DESCRIPTION_OUTPUT
	"description" "" "${PRJ_DESCRIPTION}"
	)
    SET(_lang "")
    FOREACH(_sT ${DESCRIPTION_TRANSLATIONS})
	IF(_lang STREQUAL "")
	    SET(_lang "${_sT}")
	ELSE(_lang STREQUAL "")
	    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_DESCRIPTION_OUTPUT
		"description" "-l ${_lang}" "${_sT}" "\n"
		)
	    SET(_lang "")
	ENDIF(_lang STREQUAL "")
    ENDFOREACH(_sT ${DESCRIPTION_TRANSLATIONS})

    ## Header
    ## %{_build_arch}
    IF("${BUILD_ARCH}" STREQUAL "")
	EXECUTE_PROCESS(COMMAND ${RPM_CMD} -E "%{_build_arch}"
	    OUTPUT_VARIABLE _RPM_BUILD_ARCH
	    OUTPUT_STRIP_TRAILING_WHITESPACE)
	SET(RPM_BUILD_ARCH "${_RPM_BUILD_ARCH}" 
	    CACHE STRING "RPM Arch")
    ELSE("${BUILD_ARCH}" STREQUAL "")
	SET(RPM_BUILD_ARCH "${BUILD_ARCH}" 
	    CACHE STRING "RPM Arch")
	RPM_SPEC_STRING_ADD_TAG(RPM_SPEC_HEADER_OUTPUT
	    "BuildArch" "" "${BUILD_ARCH}"
	    )
    ENDIF("${BUILD_ARCH}" STREQUAL "")

    ## Build
    IF(NOT RPM_SPEC_BUILD_OUTPUT)
	SET(RPM_SPEC_BUILD_OUTPUT
	    "%cmake ${RPM_SPEC_CMAKE_FLAGS} .
make ${RPM_SPEC_MAKE_FLAGS}"
	    )
    ENDIF(NOT RPM_SPEC_BUILD_OUTPUT)

    ## Install
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_INSTALL_SECTION_OUTPUT
	"install" "" "rm -rf %{buildroot}
make install DESTDIR=%{buildroot}"
        )

    RPM_SPEC_STRING_ADD(RPM_SPEC_INSTALL_SECTION_OUTPUT
    "# We install document using doc 
rm -fr %{buildroot}%{_docdir}/*")

    SET(_replaceList "")
    FOREACH(_f ${FILE_INSTALL_SYSCONF_LIST})
	LIST(APPEND _replaceList "/etc/${_f}")
    ENDFOREACH(_f ${FILE_INSTALL_SYSCONF_LIST})
    FOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_LIST})
	LIST(APPEND _replaceList "/etc/${PROJECT_NAME}/${_f}")
    ENDFOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_LIST})

    IF(_replaceList)
	LIST(INSERT _replaceList 0 "CONFIG_REPLACE")
    ENDIF(_replaceList)
ENDMACRO(SPEC_WRITE_HEADER)

FUNCTION(SPEC_MAKE)
    IF(NOT manifests)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Dmanifests=<install_manifests.txt>\"")
    ENDIF()
    IF(NOT release)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Drelease=<RELEASE-NOTES.txt>\"")
    ENDIF()
    IF(NOT pkg_name)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dpkg_name=<package_name>")
    ENDIF()
    IF(NOT prj_info)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dprj_info=<prj_info.cmake>")
    ENDIF()
    LOAD_PRJ_INFO()
    SPEC_WRITE_HEADER()
    MANIFEST_TO_STRING(RPM_SPEC_FILES_SECTION_OUTPUT ${manifests} ${_replaceList})
    CHANGELOG_TO_STRING(RPM_SPEC_CHANGELOG_SECTION_OUTPUT)
    CONFIGURE_FILE(${spec_in} ${spec} @ONLY)
ENDFUNCTION(SPEC_MAKE)

FUNCTION(MAKE_MANIFESTS)
    IF(NOT tmp_dir)
	SET(tmp_dir "/tmp/cmake-fedora")
    ENDIF(NOT tmp_dir)
    EXECUTE_PROCESS(COMMAND make install DESTDIR=${tmp_dir})
ENDFUNCTION(MAKE_MANIFESTS)

SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
SET(CMAKE_FEDORA_ADDITIONAL_SCRIPT_PATH ${CMAKE_SOURCE_DIR}/scripts ${CMAKE_SOURCE_DIR}/cmake-fedora/scripts)
LIST(APPEND CMAKE_MODULE_PATH 
    ${CMAKE_CURRENT_SOURCE_DIR}/Modules ${CMAKE_SOURCE_DIR}/Modules
    ${CMAKE_SOURCE_DIR}/cmake-fedora/Modules 
    ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR} )

INCLUDE(ManageMessage RESULT_VARIABLE MANAGE_MODULE_PATH)
IF(MANAGE_MODULE_PATH STREQUAL "NOTFOUND")
    MESSAGE(FATAL_ERROR "ManageMessage.cmake cannot be found in ${CMAKE_MODULE_PATH}")
ENDIF()
INCLUDE(ManageString)
INCLUDE(ManageVariable)
CMAKE_FEDORA_CONF_GET_ALL_VARIABLES()
INCLUDE(DateTimeFormat)
IF(NOT DEFINED cmd)
    MANAGE_RPM_SCRIPT_PRINT_USAGE()
ELSE()
    IF("${cmd}" STREQUAL "spec")
	IF(NOT spec)
	    MANAGE_RPM_SCRIPT_PRINT_USAGE()
	    M_MSG(${M_FATAL} "Requires -Dspec=<file.spec>")
	ENDIF(NOT spec)
	SPEC_MAKE()
    ELSEIF("${cmd}" STREQUAL "spec_manifests")
	SPEC_MANIFESTS()
    ELSEIF("${cmd}" STREQUAL "spec_changelog")
	SPEC_CHANGELOG()
    ELSEIF("${cmd}" STREQUAL "make_manifests")
	MAKE_MANIFESTS()
    ELSE()
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
    ENDIF()
ENDIF()


