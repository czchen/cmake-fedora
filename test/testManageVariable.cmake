# Unit test for ManageVariable
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageVariable)
SETTING_FILE_GET_VARIABLE(var_q_1 "VAR_Q_1" ${CTEST_SCRIPT_DIRECTORY}/sample-setting.txt )
TEST_STR_MATCH(var_q_1 "Kudo")
SETTING_FILE_GET_VARIABLE(var_q_4 "VAR_Q_4" test/sample-setting.txt )
TEST_STR_MATCH(var_q_4 "Kudo\;Good")
SETTING_FILE_GET_VARIABLE(var_q_5 "VAR_Q_5" test/sample-setting.txt )
TEST_STR_MATCH(var_q_5 "")

SETTING_FILE_GET_VARIABLE(var_q_4_noescape_sc "VAR_Q_4" test/sample-setting.txt
    NOESCAPE_SEMICOLON)
TEST_STR_MATCH(var_q_4_noescape_sc "Kudo;Good")
#MESSAGE("var_q_4_noescape_sc=|${var_q_4_noescape_sc}|")

SETTING_FILE_GET_VARIABLE(var_slash_1 "VAR_SLASH_1" test/sample-setting.txt)
TEST_STR_MATCH(var_slash_1 "With 2 SLASHES")

SETTING_FILE_GET_ALL_VARIABLES(test/sample-setting.txt)
TEST_STR_MATCH(VAR_Q_1 "Kudo")
TEST_STR_MATCH(VAR_Q_2 "Kudo")
TEST_STR_MATCH(VAR_Q_3 "Kudo ")
TEST_STR_MATCH(VAR_Q_4 "Kudo\;Good")
TEST_STR_MATCH(VAR_Q_5 "")

# Test whether back-slash is well handled
TEST_STR_MATCH(VAR_SLASH_2 "TestSLASH")
TEST_STR_MATCH(VAR_SLASH_3 "Will \n and \nOK?")


# Test whether ${var} is successfully substitute
SETTING_FILE_GET_ALL_VARIABLES(test/sample-setting2.txt)
TEST_STR_MATCH(BASE_URL "http://example.com/")
TEST_STR_MATCH(FLIES_PATH "flies" )
TEST_STR_MATCH(FLIES_URL "http://example.com/flies")

# Test whether ${var} is kept
SETTING_FILE_GET_ALL_VARIABLES(test/sample-setting2.txt ESCAPE_VARIABLE)
TEST_STR_MATCH(BASE_URL "http://example.com/")
TEST_STR_MATCH(FLIES_PATH "flies" )
TEST_STR_MATCH(FLIES_URL "\\\${BASE_URL}\\\${FLIES_PATH}")

SET(_valid_options "GITIGNORE" "INCLUDE")
VARIABLE_PARSE_ARGN(_opt _valid_options "GITIGNORE" ".gitignore" 
    "INCLUDE" ".pot")
IF(NOT "${_opt}" STREQUAL "")
    MESSAGE(SEND_ERROR "_opt should be empty instead of |${_opt}|")
ENDIF(NOT "${_opt}" STREQUAL "")
IF(NOT _opt_GITIGNORE STREQUAL ".gitignore")
    MESSAGE(SEND_ERROR "_opt_GITGNORE should be '.gitignore'")
ENDIF(NOT _opt_GITIGNORE STREQUAL ".gitignore")
IF(NOT _opt_INCLUDE STREQUAL ".pot")
    MESSAGE(SEND_ERROR "_opt_INCLUDE should be '.pot'")
ENDIF(NOT _opt_INCLUDE STREQUAL ".pot")

