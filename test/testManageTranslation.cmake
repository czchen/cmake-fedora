INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)
INCLUDE(ManageTranslation)

FUNCTION(MANAGE_GETTEXT_LOCALES_TEST testName expLanguageList poDir)
    MESSAGE("MANAGE_POT_FILE_TEST(${testName})")
    SET(localeList "")
    MANAGE_GETTEXT_LOCALES(localeList poDir ${ARGN})
    TEST_STR_MATCH(localeList "${expLanguageList}")
ENDFUNCTION()


MANAGE_GETTEXT_LOCALES_TEST("LOCALES zh_CN;zh_TW" "zh_CN;zh_TW" "test/data/po" LOCALES zh_CN zh_TW)
EXECUTE_PROCESS(
    COMMAND locale -a 
    COMMAND grep -e "^[a-z]*_[A-Z]*$"
    COMMAND sort -u 
    COMMAND xargs 
    COMMAND sed -e "s/ /;/g"
    OUTPUT_VARIABLE _sysLocales
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
MANAGE_GETTEXT_LOCALES_TEST("SYSTEM_LOCALES" "${_sysLocales}" "test/data/po" SYSTEM_LOCALES)

MANAGE_GETTEXT_LOCALES_TEST("Detect locales" "de_DE;es_ES;fr_FR;it_IT" "test/data/po")

FUNCTION(MANAGE_POT_FILE_TEST expPoDir potFile)
    MESSAGE("MANAGE_POT_FILE_TEST(${expPoDir} ${potFile})")
    VARIABLE_PARSE_ARGN(_o ${MANAGE_POT_FILE_VALID_OPTIONS} ${ARGN})
    MANAGE_POT_FILE_SET_VARS(cmdList msgmergeOpts msgfmtOpts locales poDir moDir srcs depends cleanVar ${potFile} ${ARGN})
    TEST_STR_MATCH(poDir "${expPoDir}")
ENDFUNCTION(MANAGE_POT_FILE_TEST)

SET(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_SOURCE_DIR})
MANAGE_POT_FILE_TEST("${CMAKE_CURRENT_BINARY_DIR}" 
    "${CMAKE_CURRENT_BINARY_DIR}/ibus-chewing.pot" 
    SYSTEM_LOCALES
    SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src1.c
    )
MANAGE_POT_FILE_TEST("${CMAKE_CURRENT_BINAR
Y_DIR}/test/data/po" 
    "${CMAKE_CURRENT_BINARY_DIR}/test/data/po/ibus-chewing.pot"  
    SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src1.c 
    PO_DIR "${CMAKE_CURRENT_BINARY_DIR}/test/data/po"
    )


