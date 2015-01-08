INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)
INCLUDE(ManageTranslation)

FUNCTION(LOCALE_PARSE_STRING_TEST expLanguage expScript expCountry expModifier str)
    MESSAGE("LOCALE_PARSE_STRING_TEST(${str})")
    LOCALE_PARSE_STRING(language script country modifier "${str}")
    TEST_STR_MATCH(language "${expLanguage}")
    TEST_STR_MATCH(script "${expScript}")
    TEST_STR_MATCH(country "${expCountry}")
    TEST_STR_MATCH(modifier "${expModifier}")
ENDFUNCTION(LOCALE_PARSE_STRING_TEST)

LOCALE_PARSE_STRING_TEST("fr" "" "" "" "fr")
LOCALE_PARSE_STRING_TEST("de" "" "DE"  "" "de_DE")
LOCALE_PARSE_STRING_TEST("bem" "" "ZM" "" "bem_ZM")
LOCALE_PARSE_STRING_TEST("zh" "Hans" "" "" "zh-Hans")
LOCALE_PARSE_STRING_TEST("zh" "Hant" "" "" "zh-Hant")
LOCALE_PARSE_STRING_TEST("zh" "Hant" "TW" ""  "zh-Hant-TW")
LOCALE_PARSE_STRING_TEST("sr" "Latn" "" "" "sr-Latn")
LOCALE_PARSE_STRING_TEST("sr" "Cyrl" "" ""  "sr-Cyrl")
LOCALE_PARSE_STRING_TEST("sr" "" "RS" "latin" "sr_RS@latin")
LOCALE_PARSE_STRING_TEST("eo" "" "" ""  "eo")
LOCALE_PARSE_STRING_TEST("nb" "" "NO" "" "nb_NO")

FUNCTION(MANAGE_GETTEXT_LOCALES_TEST testName expLanguageList detectedPoDir workDir )
    MESSAGE("MANAGE_GETTEXT_LOCALES_TEST(${testName}): ${expLanguageList}")
    SET(localeList "")
    IF(NOT "${detectedPoDir}" STREQUAL "0")
	SET(extArgs "DETECT_PO_DIR" "dDir")
    ENDIF()
    MANAGE_GETTEXT_LOCALES(localeList WORKING_DIRECTORY ${workDir} ${extArgs} ${ARGN})
    TEST_STR_MATCH(localeList "${expLanguageList}")
    IF(NOT "${detectedPoDir}" STREQUAL "0")
	TEST_STR_MATCH(dDir "${detectedPoDir}")
    ENDIF()
ENDFUNCTION()


MANAGE_GETTEXT_LOCALES_TEST("LOCALES specified" "zh_CN;zh_TW" "0" "test/data/po" LOCALES zh_CN zh_TW)
EXECUTE_PROCESS(
    COMMAND ls -1 /usr/share/locale/
    COMMAND grep -e "^[a-z]*\\(_[A-Z]*\\)\\?\\(@.*\\)\\?$"
    COMMAND sort -u 
    COMMAND xargs 
    COMMAND sed -e "s/ /;/g"
    OUTPUT_VARIABLE _sysLocales
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
MANAGE_GETTEXT_LOCALES_TEST("SYSTEM_LOCALES" "${_sysLocales}" "0" "test/data/po" SYSTEM_LOCALES)

MANAGE_GETTEXT_LOCALES_TEST("Detect locales" "de_DE;es_ES;fr_FR;it_IT" "" "test/data/po")


MANAGE_GETTEXT_LOCALES_TEST("Detect locales" "de-DE;de_CH;ko;sr@latin;zh-Hans;zh_TW" "po" "test/data/podir" )

FUNCTION(MANAGE_POT_FILE_TEST expPoDir potFile)
    MESSAGE("MANAGE_POT_FILE_TEST(${expPoDir} ${potFile})")
    VARIABLE_PARSE_ARGN(_o ${MANAGE_POT_FILE_VALID_OPTIONS} ${ARGN})
    MANAGE_POT_FILE_SET_VARS(cmdList msgmergeOpts msgfmtOpts poDir moDir allClean srcs depends 
	"${potFile}" ${ARGN}
	)
    TEST_STR_MATCH(poDir "${expPoDir}")
ENDFUNCTION(MANAGE_POT_FILE_TEST)

IF(NOT CMAKE_CURRENT_BINARY_DIR)
    IF(CMAKE_CURRENT_SOURCE_DIR)
	SET(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ELSEIF(CMAKE_SOURCE_DIR)
	SET(CMAKE_CURRENT_BINARY_DIR "${CMAKE_SOURCE_DIR}")
    ELSE()
	SET(CMAKE_CURRENT_BINARY_DIR "$ENV{PWD}")
    ENDIF()
ENDIF()
MANAGE_POT_FILE_TEST("${CMAKE_CURRENT_BINARY_DIR}" 
    "${CMAKE_CURRENT_BINARY_DIR}/ibus-chewing.pot" 
    SYSTEM_LOCALES
    SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src1.c
    )
MANAGE_POT_FILE_TEST("${CMAKE_CURRENT_BINARY_DIR}/test/data/po" 
    "${CMAKE_CURRENT_BINARY_DIR}/test/data/po/ibus-chewing.pot"  
    SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src1.c 
    PO_DIR "${CMAKE_CURRENT_BINARY_DIR}/test/data/po"
    )

FUNCTION(MANAGE_GETTEXT_DETECT_POT_DIR_TEST expPotDir)
    MESSAGE("MANAGE_GETTEXT_DETECT_POT_DIR_TEST(${expPotDir} ${ARGN})")
    MANAGE_GETTEXT_DETECT_POT_DIR(potDir ${ARGN})
    TEST_STR_MATCH(potDir "${expPotDir}")
ENDFUNCTION(MANAGE_GETTEXT_DETECT_POT_DIR_TEST)

MANAGE_GETTEXT_DETECT_POT_DIR_TEST("pot" WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/test/data/podir/")

