INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)
INCLUDE(ManageZanata)

FUNCTION(ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE_TEST expStr str)
    MESSAGE("ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE_TEST(${expStr})")
    ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE(opt "${str}")
    TEST_STR_MATCH(opt "${expStr}")
ENDFUNCTION(ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE_TEST)

ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE_TEST("username" "username")
ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE_TEST("pushType" "push-type")
ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE_TEST("disableSslCert" "disable-ssl-cert")

#######################################
# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND
#
FUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST expect zanataExecutable)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST(${expect})")
    MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(v "${zanataExecutable}")
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:push" "/usr/bin/mvn")  
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/mvn;-B;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:push;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/" "/usr/bin/mvn" YES ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ )

#######################################
# ZANATA_BEST_MATCH_LOCALES
#
FUNCTION(ZANATA_BEST_MATCH_LOCALES_TEST expect serverLocales clientLocales)
    MESSAGE("# ZANATA_BEST_MATCH_LOCALES_TEST(${expect})")
    ZANATA_BEST_MATCH_LOCALES(v "${serverLocales}" "${clientLocales}")
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(ZANATA_BEST_MATCH_LOCALES_TEST)

ZANATA_BEST_MATCH_LOCALES_TEST("de-DE,de;fr,fr_FR;lt-LT,lt_LT;lv,lv;zh-Hans,zh_CN"
    "de-DE;fr;lt-LT;lv;zh-Hans" "de;fr_BE;fr_FR;lt_LT;zh_CN;zh_TW")

ZANATA_BEST_MATCH_LOCALES_TEST("sr-Cyrl,sr_RS;sr-Latn,sr_RS@latin;zh-Hans,zh_CN;zh-Hant-TW,zh_TW"
    "sr-Latn;sr-Cyrl;zh-Hans;zh-Hant-TW" 
    "de;fr_BE;fr_FR;lt_LT;sr_RS@latin;zh_CN;zh_TW;sr_RS;sr;sr@ije")

ZANATA_BEST_MATCH_LOCALES_TEST("kw,kw;kw-GB,kw_GB" "kw;kw-GB" "kw")

