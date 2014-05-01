# Unit test for ManageFile
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageFile)

FUNCTION(FIND_PROGRAM_ERROR_HANDLING_TEST expected)
    MESSAGE("FIND_PROGRAM_ERROR_HANDLING: ${expected}")
    SET(v "")
    FIND_PROGRAM_ERROR_HANDLING(v FIND_ARGS ${ARGN})
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(FIND_PROGRAM_ERROR_HANDLING_TEST expected)
FIND_PROGRAM_ERROR_HANDLING_TEST("/usr/bin/cmake" cmake)
FIND_PROGRAM_ERROR_HANDLING_TEST("/usr/bin/rpmbuild" NAMES rpmbuild rpmbuild-md5)

FUNCTION(GIT_GLOB_TO_CMAKE_REGEX_TEST expected input)
    MESSAGE("GIT_GLOB_TO_CMAKE_REGEX: ${input}")
    GIT_GLOB_TO_CMAKE_REGEX(v "${input}")
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(GIT_GLOB_TO_CMAKE_REGEX_TEST input expected)

GIT_GLOB_TO_CMAKE_REGEX_TEST("[^/]*\\\\.so$" "*.so")
GIT_GLOB_TO_CMAKE_REGEX_TEST("[^/]*~$" "*~" )
GIT_GLOB_TO_CMAKE_REGEX_TEST("[^/]*\\\\.sw[op]$" "*.sw[op]")
GIT_GLOB_TO_CMAKE_REGEX_TEST("ChangeLog$" "ChangeLog")
GIT_GLOB_TO_CMAKE_REGEX_TEST("CMakeCache\\\\.txt$" "CMakeCache.txt" )
GIT_GLOB_TO_CMAKE_REGEX_TEST("/CMakeFiles/" "CMakeFiles/")
GIT_GLOB_TO_CMAKE_REGEX_TEST("cmake_[^/]*install\\\\.cmake$" 
    "cmake_*install.cmake" )
GIT_GLOB_TO_CMAKE_REGEX_TEST("[^/]*NO_PACK[^/]*$" "*NO_PACK*")
GIT_GLOB_TO_CMAKE_REGEX_TEST("SPECS/RPM-ChangeLog$" "SPECS/RPM-ChangeLog" )

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
FUNCTION(MANAGE_FILE_CACHE_TEST expected file)
    MESSAGE("MANAGE_FILE_CACHE: ${expected}_${file}")
    MANAGE_FILE_CACHE(v ${file} CACHE_DIR /tmp ${ARGN})
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(MANAGE_FILE_CACHE_TEST expected file)
MANAGE_FILE_CACHE_TEST("Hi" "simple" COMMAND echo "Hi")
MANAGE_FILE_CACHE_TEST("Bye" "piped" COMMAND echo "Hi" COMMAND sed -e "s/Hi/Bye/")

# Don't use existing file, as it will be clean up
FUNCTION(MANAGE_FILE_EXPIRY_TEST expected file expireSecond)
    MESSAGE("MANAGE_FILE_EXPIRY: ${expected}_${file}")
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
    MANAGE_FILE_EXPIRY(v ${file} ${expireSecond})
    FILE(REMOVE ${file})
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(MANAGE_FILE_EXPIRY_TEST expected file expireSecond)

MANAGE_FILE_EXPIRY_TEST("NOT_EXIST" cmake_fedora_NOT_EXIST 5)
MANAGE_FILE_EXPIRY_TEST("NOT_EXPIRED" cmake_fedora_NOT_EXPIRED 5)
MANAGE_FILE_EXPIRY_TEST("EXPIRED" cmake_fedora_EXPIRED 5)

