# Unit test for ManageVariable
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageVariable)
SETTING_FILE_GET_VARIABLE(var_q_1 "VAR_Q_1" test/sample-setting.txt )
TEST_STR_MATCH(var_q_1 "Kudo")

SETTING_FILE_GET_ALL_VARIABLES(test/sample-setting.txt)
TEST_STR_MATCH(VAR_Q_1 "Kudo")
TEST_STR_MATCH(VAR_Q_2 "Kudo")
TEST_STR_MATCH(VAR_Q_3 "Kudo ")
TEST_STR_MATCH(VAR_Q_4 "Kudo;Good")

