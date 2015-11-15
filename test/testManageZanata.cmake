INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)
INCLUDE(ManageZanata)
SET(PROJECT_NAME "cmake-fedora")

#######################################
# ZANATA_JSON_GET_VALUE
#
FUNCTION(ZANATA_JSON_GET_VALUE_TEST expStr key str)
    MESSAGE("ZANATA_JSON_GET_VALUE_TEST(${expStr})")
    ZANATA_JSON_GET_VALUE(opt "${key}" "${str}")
    TEST_STR_MATCH(opt "${expStr}")
ENDFUNCTION(ZANATA_JSON_GET_VALUE_TEST)

ZANATA_JSON_GET_VALUE_TEST("Gettext" "projectType" "{\"id\":\"master\",\"status\":\"ACTIVE\",\"projectType\":\"Gettext\"}")
ZANATA_JSON_GET_VALUE_TEST("3.5" "id" "{\"id\":\"3.5\",\"status\":\"ACTIVE\",\"projectType\":\"Gettext\"}")

#######################################
# ZANATA_JSON_TO_ARRAY
#
FUNCTION(ZANATA_JSON_TO_ARRAY_TEST expStr str)
    MESSAGE("ZANATA_JSON_TO_ARRAY_TEST(${expStr})")
    ZANATA_JSON_TO_ARRAY(opt "${str}")
    TEST_STR_MATCH(opt "${expStr}")
ENDFUNCTION(ZANATA_JSON_TO_ARRAY_TEST)

ZANATA_JSON_TO_ARRAY_TEST("{\"localeId\":\"sq\",\"displayName\":\"Albanian\"};{\"localeId\":\"ast\",\"displayName\":\"Asturian\"};{\"localeId\":\"zh-TW\",\"displayName\":\"Chinese (Taiwan)\"}" 
    "[{\"localeId\":\"sq\",\"displayName\":\"Albanian\"},{\"localeId\":\"ast\",\"displayName\":\"Asturian\"},{\"localeId\":\"zh-TW\",\"displayName\":\"Chinese (Taiwan)\"}]")

#######################################
# ZANATA_REST_GET_PROJECT_VERSION_TYPE
#
FUNCTION(ZANATA_REST_GET_PROJECT_VERSION_TYPE_TEST expStr url project version)
    MESSAGE("ZANATA_REST_GET_PROJECT_VERSION_TYPE_TEST(${expStr} ${url} ${project} ${version})")
    ZANATA_REST_GET_PROJECT_VERSION_TYPE(actual "${url}" "${project}" "${version}")
    TEST_STR_MATCH(actual "${expStr}")
ENDFUNCTION(ZANATA_REST_GET_PROJECT_VERSION_TYPE_TEST)

ZANATA_REST_GET_PROJECT_VERSION_TYPE_TEST("Gettext" "https://fedora.zanata.org/" "ibus-chewing" master)


#######################################
# ZANATA_STRING_DASH_TO_CAMEL_CASE
#
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
FUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST expect)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST(${expect})")
    UNSET(ZANATA_PROJECT CACHE)
    UNSET(ZANATA_VERSION CACHE)
    UNSET(ZANATA_CLIENT_EXECUTABLE CACHE)
    ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP(_o ${ARGN})
    MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND(v _o)
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:put-version;-Dzanata.versionProject=cmake-fedora;-Dzanata.versionSlug=master" 
    ZANATA_EXECUTABLE "/usr/bin/mvn" 
    )  
MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/mvn;-B;-X;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:put-version;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/;-Dzanata.versionProject=prj;-Dzanata.versionSlug=master" 
    ZANATA_EXECUTABLE "/usr/bin/mvn" YES DEBUG ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ PROJECT prj VERSION master
    )
MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/zanata-cli;put-version;--version-project;cmake-fedora;--version-slug;master"  ZANATA_EXECUTABLE "/usr/bin/zanata-cli")  
MANAGE_ZANATA_OBTAIN_PUT_VERSION_COMMAND_TEST("/usr/bin/zanata-cli;-B;-e;put-version;--url;https://fedora.zanata.org/;--disable-ssl-cert;--version-project;prj;--version-slug;release" 
    https://fedora.zanata.org/ ZANATA_EXECUTABLE "/usr/bin/zanata-cli" YES ERRORS DISABLE_SSL_CERT  PROJECT prj VERSION release
    )

#######################################
# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND
#
FUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST expect)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST(${expect})")
    UNSET(ZANATA_PROJECT CACHE)
    UNSET(ZANATA_VERSION CACHE)
    UNSET(ZANATA_CLIENT_EXECUTABLE CACHE)
    ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP(_o ${ARGN})
    MANAGE_ZANATA_OBTAIN_PUSH_COMMAND(v _o)
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:push" CLIENT_COMMAND "/usr/bin/mvn")  
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/mvn;-B;-X;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:push;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/"
    YES DEBUG ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/  CLIENT_COMMAND "/usr/bin/mvn"
    )
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("zanata-cli;push"  CLIENT_COMMAND "zanata-cli")  
MANAGE_ZANATA_OBTAIN_PUSH_COMMAND_TEST("/usr/bin/zanata-cli;-B;-e;push;--disable-ssl-cert;--url;https://fedora.zanata.org/" 
    CLIENT_COMMAND "/usr/bin/zanata-cli" YES ERRORS DISABLE_SSL_CERT URL https://fedora.zanata.org/ 
    )

#######################################
# MANAGE_ZANATA_OBTAIN_PULL_COMMAND
#
FUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST expect)
    MESSAGE("# MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST(${expect})")
    UNSET(ZANATA_PROJECT CACHE)
    UNSET(ZANATA_VERSION CACHE)
    UNSET(ZANATA_CLIENT_EXECUTABLE CACHE)
    ZANATA_CMAKE_OPTIONS_PARSE_OPTIONS_MAP(_o ${ARGN})
    MANAGE_ZANATA_OBTAIN_PULL_COMMAND(v _o)
    TEST_STR_MATCH(v "${expect}")
ENDFUNCTION(MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST)

MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST("/usr/bin/mvn;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:pull" 
    ZANATA_EXECUTABLE "/usr/bin/mvn"
    )  
MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST("/usr/bin/mvn;-B;-X;-e;${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:pull;-Dzanata.disableSSLCert;-Dzanata.url=https://fedora.zanata.org/;-Dzanata.createSkeletons;-Dzanata.encodeTabs=true" 
    YES ERRORS DEBUG DISABLE_SSL_CERT ZANATA_EXECUTABLE "/usr/bin/mvn" URL https://fedora.zanata.org/ CREATE_SKELETONS ENCODE_TABS "true"
    )
MANAGE_ZANATA_OBTAIN_PULL_COMMAND_TEST("/usr/bin/zanata-cli;pull;--src-dir;po;--trans-dir;po_out" 
    ZANATA_EXECUTABLE "/usr/bin/zanata-cli" SRC_DIR po TRANS_DIR po_out
    )

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

