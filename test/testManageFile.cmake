# Unit test for ManageVariable
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageFile)

MACRO(GIT_GLOB_TO_CMAKE_REGEX_TEST input expected)
    SET(caseName "${input}")
    GIT_GLOB_TO_CMAKE_REGEX(v "${input}")
    MESSAGE("GIT_GLOB_TO_CMAKE_REGEX: ${caseName}")
    IF(NOT "${v}" STREQUAL "${expected}")
	MESSAGE(SEND_ERROR "|${v}| <> |${expected}|")
    ENDIF(NOT "${v}" STREQUAL "${expected}")
ENDMACRO(GIT_GLOB_TO_CMAKE_REGEX_TEST input expected)

GIT_GLOB_TO_CMAKE_REGEX_TEST("*.so" "[^/]*\\\\\\\\.so$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("*~" "[^/]*~$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("*.sw[op]" "[^/]*\\\\\\\\.sw[op]$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("ChangeLog" "ChangeLog$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("CMakeCache.txt" "CMakeCache\\\\\\\\.txt$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("CMakeFiles/" "/CMakeFiles/")
GIT_GLOB_TO_CMAKE_REGEX_TEST("cmake_*install.cmake" "cmake_[^/]*install\\\\\\\\.cmake$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("*NO_PACK*" "[^/]*NO_PACK[^/]*$")
GIT_GLOB_TO_CMAKE_REGEX_TEST("SPECS/RPM-ChangeLog" "SPECS/RPM-ChangeLog$")

## MANAGE_FILE_CACHE_TEST
MANAGE_CMAKE_FEDORA_CONF(_cmake_fedora_conf
    VERBOSE_LEVEL ${M_OFF}
    ERROR_MSG "Failed to find cmake-fedora.conf"
    )
IF(${_cmake_fedora_conf})
    SET(HOME "$ENV{HOME}")
    SETTING_FILE_GET_ALL_VARIABLES(${_cmake_fedora_conf})
ENDIF(${_cmake_fedora_conf})

# Don't use existing file, as it will be clean up
MACRO(MANAGE_FILE_CACHE_TEST expected file)
    SET(caseName "${expected}_${file}")
    MESSAGE("MANAGE_FILE_EXPIRY: ${caseName}")
    MANAGE_FILE_CACHE(v ${file} CACHE_DIR /tmp ${ARGN})
    IF(NOT "${v}" STREQUAL "${expected}")
	MESSAGE(SEND_ERROR "|${v}| <> |${expected}|")
    ENDIF(NOT "${v}" STREQUAL "${expected}")
ENDMACRO(MANAGE_FILE_CACHE_TEST expected file)
MANAGE_FILE_CACHE_TEST("Hi" "simple" COMMAND echo "Hi")
MANAGE_FILE_CACHE_TEST("Bye" "piped" COMMAND echo "Hi" COMMAND sed -e "s/Hi/Bye/")

# Don't use existing file, as it will be clean up
MACRO(MANAGE_FILE_EXPIRY_TEST expected file expireSecond)
    SET(caseName "${expected}_${file}")
    IF("${expected}" STREQUAL "NOT_EXIST")
	FILE(REMOVE "${file}")
    ELSEIF("${expected}" STREQUAL "NOT_EXPIRED")
	FILE(WRITE "${file}" "NOT_EXPIRED")
    ELSEIF("${expected}" STREQUAL "EXPIRED")
	FILE(WRITE "${file}" "EXPIRED")
	EXECUTE_PROCESS(COMMAND sleep ${expireSecond} )
    ELSEIF("${expected}" STREQUAL "ERROR")
    ELSE("${expected}" STREQUAL "NOT_EXIST")
    ENDIF("${expected}" STREQUAL "NOT_EXIST")
    MESSAGE("MANAGE_FILE_EXPIRY: ${caseName}")
    MANAGE_FILE_EXPIRY(v ${file} ${expireSecond})
    FILE(REMOVE ${file})
    IF(NOT "${v}" STREQUAL "${expected}")
	MESSAGE(SEND_ERROR "|${v}| <> |${expected}|")
    ENDIF(NOT "${v}" STREQUAL "${expected}")
ENDMACRO(MANAGE_FILE_EXPIRY_TEST expected file expireSecond)

MANAGE_FILE_EXPIRY_TEST("NOT_EXIST" cmake_fedora_NOT_EXIST 5)
MANAGE_FILE_EXPIRY_TEST("NOT_EXPIRED" cmake_fedora_NOT_EXPIRED 5)
MANAGE_FILE_EXPIRY_TEST("EXPIRED" cmake_fedora_EXPIRED 5)

