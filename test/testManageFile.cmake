# Unit test for ManageFile
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageFile)

FUNCTION(FIND_PROGRAM_ERROR_HANDLING_TEST testname expected)
    MESSAGE("FIND_PROGRAM_ERROR_HANDLING: ${testname} ${expected}")
    FIND_PROGRAM_ERROR_HANDLING(${testname} ${ARGN})
    IF("${expected}" STREQUAL "")
	IF(NOT "${${testname}}" STREQUAL "${testname}-NOTFOUND")
	    MESSAGE(SEND_ERROR "v=|${v}| instead of ${testname}-NOTFOUND")
	ENDIF(NOT "${${testname}}" STREQUAL "${testname}-NOTFOUND")
    ELSE("${expected}" STREQUAL "")
	TEST_STR_MATCH("${testname}" "${expected}")
    ENDIF("${expected}" STREQUAL "")
ENDFUNCTION(FIND_PROGRAM_ERROR_HANDLING_TEST)

EXECUTE_PROCESS(COMMAND which cmake OUTPUT_VARIABLE CMAKE_CMD OUTPUT_STRIP_TRAILING_WHITESPACE)
FIND_PROGRAM_ERROR_HANDLING_TEST(cmake "${CMAKE_CMD}" FIND_ARGS cmake)

EXECUTE_PROCESS(COMMAND which rpmbuild OUTPUT_VARIABLE RPMBUILD_CMD OUTPUT_STRIP_TRAILING_WHITESPACE)
FIND_PROGRAM_ERROR_HANDLING_TEST(rpmbuild "${RPMBUILD_CMD}" FIND_ARGS NAMES rpmbuild rpmbuild-md5)
FIND_PROGRAM_ERROR_HANDLING_TEST(p-not-exist "" VERBOSE_LEVEL ${M_OFF} FIND_ARGS "p-not-exist" )
FIND_PROGRAM_ERROR_HANDLING_TEST(cmake-fedora-koji "${CTEST_HOME_DIR}/scripts/cmake-fedora-koji" FIND_ARGS "cmake-fedora-koji" PATHS "${CTEST_SOURCE_DIRECTORY}/scripts" NO_DEFAULT_PATH )

FUNCTION(FIND_FILE_ERROR_HANDLING_TEST testname expected)
    MESSAGE("FIND_FILE_ERROR_HANDLING: ${testname} ${expected}")
    FIND_FILE_ERROR_HANDLING(${testname} ${ARGN})
    IF("${expected}" STREQUAL "")
	IF(NOT "${${testname}}" STREQUAL "${testname}-NOTFOUND")
	    MESSAGE(SEND_ERROR "v=|${v}| instead of ${testname}-NOTFOUND")
	ENDIF(NOT "${${testname}}" STREQUAL "${testname}-NOTFOUND")
    ELSE("${expected}" STREQUAL "")
	TEST_STR_MATCH("${testname}" "${expected}")
    ENDIF("${expected}" STREQUAL "")
ENDFUNCTION(FIND_FILE_ERROR_HANDLING_TEST)
FIND_FILE_ERROR_HANDLING_TEST(passwd "/etc/passwd" FIND_ARGS passwd
    PATHS /etc  NO_DEFAULT_PATH)
FIND_FILE_ERROR_HANDLING_TEST(fstab "/etc/fstab" FIND_ARGS NAMES fstab
    PATHS /etc  NO_DEFAULT_PATH)
FIND_FILE_ERROR_HANDLING_TEST(f-not-exist "" VERBOSE_LEVEL ${M_OFF} 
    FIND_ARGS "f-not-exist" PATHS "/etc" NO_DEFAULT_PATH)

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

MESSAGE("MANAGE_CMAKE_FEDORA_CONF_TEST:")
MANAGE_CMAKE_FEDORA_CONF(_cmake_fedora_conf
    VERBOSE_LEVEL ${M_ERROR}
    ERROR_MSG "Failed to find cmake-fedora.conf"
    )
IF(NOT _cmake_fedora_conf MATCHES ".*cmake-fedora\\.conf")
    NESSAGE(SEND_ERROR "cmake-fedora.conf not found. _cmake_fedora_conf=${_cmake_fedora_conf}")
ENDIF()

IF(${_cmake_fedora_conf})
    SET(HOME "$ENV{HOME}")
    SETTING_FILE_GET_ALL_VARIABLES(${_cmake_fedora_conf})
ENDIF(${_cmake_fedora_conf})

## MANAGE_FILE_CACHE_TEST
# Don't use existing file, as it will be clean up
FUNCTION(MANAGE_FILE_CACHE_TEST expected file)
    MESSAGE("MANAGE_FILE_CACHE: ${expected}_${file}")
    MANAGE_FILE_CACHE(v ${file} CACHE_DIR /tmp ${ARGN})
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(MANAGE_FILE_CACHE_TEST expected file)
MANAGE_FILE_CACHE_TEST("Hi" "simple" COMMAND echo "Hi")
MANAGE_FILE_CACHE_TEST("Bye" "piped" COMMAND echo "Hi" COMMAND sed -e "s/Hi/Bye/")

## MANAGE_FILE_COMMON_DIR_TEST
FUNCTION(MANAGE_FILE_COMMON_DIR_TEST expected file)
    MESSAGE("MANAGE_FILE_COMMON_DIR: ${expected}: ${file} ${ARGN}" )
    MANAGE_FILE_COMMON_DIR(v ${file} ${ARGN})
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(MANAGE_FILE_COMMON_DIR_TEST expected file)
MANAGE_FILE_COMMON_DIR_TEST("po" "po/zh_CN.po" "po" "po/" "po/test/zh_TW.po" )
MANAGE_FILE_COMMON_DIR_TEST("" "po/a.pot" "b.pot")

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

MANAGE_FILE_EXPIRY_TEST("NOT_EXIST" /tmp/cmake_fedora_NOT_EXIST 5)
MANAGE_FILE_EXPIRY_TEST("NOT_EXPIRED" /tmp/cmake_fedora_NOT_EXPIRED 5)
MANAGE_FILE_EXPIRY_TEST("EXPIRED" /tmp/cmake_fedora_EXPIRED 5)

