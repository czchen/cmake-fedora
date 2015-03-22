INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)
INCLUDE(ManageZanata)

FUNCTION(ZANATA_STRING_DASH_TO_CAMEL_CASE_TEST expStr str)
    MESSAGE("ZANATA_STRING_DASH_TO_CAMEL_CASE_TEST(${expStr})")
    ZANATA_STRING_DASH_TO_CAMEL_CASE(opt "${str}")
    TEST_STR_MATCH(opt "${expStr}")
ENDFUNCTION(ZANATA_STRING_DASH_TO_CAMEL_CASE_TEST)

ZANATA_STRING_DASH_TO_CAMEL_CASE_TEST("username" "username")
ZANATA_STRING_DASH_TO_CAMEL_CASE_TEST("pushType" "push-type")

#######################################
# MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND
#
FUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST expect zanataExecutable)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST(${expect})")
    MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND(v "${zanataExecutable}" ${ARGN})
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:put-version" "/usr/bin/mvn")  
MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/mvn;-B;-X;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:put-version;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/;-Dzanata.versionProject=prj;-Dzanata.versionSlug=master" "/usr/bin/mvn" YES DEBUG ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ PROJECT prj VERSION master)
MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/zanata-cli;put-version" "/usr/bin/zanata-cli")  
MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/zanata-cli;-B;-e;put-version;--disable-ssl-cert;--url;https://fedora.zanata.org/;--version-project;prj;--version-slug;master" "/usr/bin/zanata-cli" YES ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ PROJECT prj VERSION master)

#######################################
# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND
#
FUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST expect zanataExecutable)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST(${expect})")
    MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(v "${zanataExecutable}" ${ARGN})
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:push" "/usr/bin/mvn")  
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/mvn;-B;-X;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:push;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/" "/usr/bin/mvn" YES DEBUG ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ )
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/zanata-cli;push" "/usr/bin/zanata-cli")  
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/zanata-cli;-B;-e;push;--disable-ssl-cert;--url;https://fedora.zanata.org/" "/usr/bin/zanata-cli" YES ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ )

#######################################
# MANAGE_ZANATA_OBTAIN_PULL_COMMAND
#
FUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST expect zanataExecutable)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST(${expect})")
    MANAGE_ZANATA_OBTAIN_PULL_COMMAND(v "${zanataExecutable}" ${ARGN})
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:pull" "/usr/bin/mvn")  
MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST("/usr/bin/mvn;-B;-X;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:pull;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/;-Dzanata.createSkeletons;-Dzanata.encodeTabs=true" "/usr/bin/mvn" YES ERRORS DEBUG DISABLE_SSL_CERT URL https://fedora.zanata.org/ CREATE_SKELETONS ENCODE_TABS "true")

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

