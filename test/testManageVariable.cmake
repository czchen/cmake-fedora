# Unit test for ManageVariable
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageVariable)
SETTING_FILE_GET_VARIABLE(var_q_1 "VAR_Q_1" ${CTEST_SOURCE_DIRECTORY}/test/sample-setting.txt )
TEST_STR_MATCH(var_q_1 "Kudo")
SETTING_FILE_GET_VARIABLE(var_q_4 "VAR_Q_4" ${CTEST_SOURCE_DIRECTORY}/test/sample-setting.txt )
TEST_STR_MATCH(var_q_4 "Kudo\;Good")

SETTING_FILE_GET_ALL_VARIABLES(${CTEST_SOURCE_DIRECTORY}/test/sample-setting.txt)
TEST_STR_MATCH(VAR_Q_1 "Kudo")
TEST_STR_MATCH(VAR_Q_2 "Kudo")
TEST_STR_MATCH(VAR_Q_3 "Kudo ")
TEST_STR_MATCH(VAR_Q_4 "Kudo\;Good")

# Test whether ${var} is successfully substitute
SETTING_FILE_GET_ALL_VARIABLES(${CTEST_SOURCE_DIRECTORY}/test/sample-setting2.txt)
TEST_STR_MATCH(BASE_URL "http://example.com/")
TEST_STR_MATCH(FLIES_PATH "flies" )
TEST_STR_MATCH(FLIES_URL "http://example.com/flies")

# Test whether ${var} is kept
SETTING_FILE_GET_ALL_VARIABLES(${CTEST_SOURCE_DIRECTORY}/test/sample-setting2.txt ESCAPE_VARIABLE)
TEST_STR_MATCH(BASE_URL "http://example.com/")
TEST_STR_MATCH(FLIES_PATH "flies" )
TEST_STR_MATCH(FLIES_URL "\\\${BASE_URL}\\\${FLIES_PATH}")

