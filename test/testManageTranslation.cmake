INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)
INCLUDE(ManageTranslation)

FUNCTION(ADD_POT_FILE_TEST expPoDir potFile)
    MESSAGE("ADD_POT_FILE_TEST(${expPoDir} ${potFile})")
    VARIABLE_PARSE_ARGN(_o ${ADD_POT_FILE_VALID_OPTIONS} ${ARGN})
    ADD_POT_FILE_SET_VARS(cmdList poDir depends ${potFile} ${ARGN})
    TEST_STR_MATCH(poDir "${expPoDir}")
ENDFUNCTION(ADD_POT_FILE_TEST)

SET(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_SOURCE_DIR})
ADD_POT_FILE_TEST("${CMAKE_CURRENT_BINARY_DIR}" 
    "${CMAKE_CURRENT_BINARY_DIR}/ibus-chewing.pot" 
    SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src1.c
    )
ADD_POT_FILE_TEST("po" 
    "po/ibus-chewing.pot"  
    SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src1.c 
    PO_DIR "po"
    )


FUNCTION(MANAGE_GETTEXT_LOCALES_TEST testName expLanguageList)
    MESSAGE("ADD_POT_FILE_TEST(${testName})")
    SET(localeList "")
    MANAGE_GETTEXT_LOCALES(localeList ${ARGN})
    TEST_STR_MATCH(localeList "${expLanguageList}")
ENDFUNCTION()


MANAGE_GETTEXT_LOCALES_TEST("LOCALES zh_CN;zh_TW" "zh_CN;zh_TW" LOCALES zh_CN zh_TW)
EXECUTE_PROCESS(
    COMMAND locale -a 
    COMMAND grep -e "^[a-z]*_[A-Z]*$"
    COMMAND sort -u 
    COMMAND xargs 
    COMMAND sed -e "s/ /;/g"
    OUTPUT_VARIABLE _sysLocales
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
MANAGE_GETTEXT_LOCALES_TEST("SYSTEM_LOCALES" "${_sysLocales}" SYSTEM_LOCALES)

SET(MANAGE_TRANSLATION_GETTEXT_POT_FILES "test/data/po/project.pot")
SET(MANAGE_TRANSLATION_GETTEXT_POT_FILE_project_PO_DIR "test/data/po")
MANAGE_GETTEXT_LOCALES_TEST("Detect locales" "de_DE;es_ES;fr_FR;it_IT" )

