# Unit test for ManageVariable
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageFile)

MACRO(GIT_GLOB_TO_CMAKE_REGEX_TEST input expected)
    SET(caseName "${input}")
    GIT_GLOB_TO_CMAKE_REGEX(v "${input}")
    MESSAGE("Test case: ${caseName}")
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


