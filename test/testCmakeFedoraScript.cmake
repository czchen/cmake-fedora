# Unit test for CmakeFedoraScript
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)

FUNCTION(CMAKE_FEDORA_SCRIPT_CONFIGURE_FILE_TEST expected inputFile outputFile)
    MESSAGE("CMAKE_FEDORA_SCRIPT_CONFIGURE_FILE: ${expected}")
    EXECUTE_PROCESS(COMMAND cmake 
	-Dcmd=configure_file "-DinputFile=${inputFile}" 
	"-DoutputFile=${outputFile}" ${ARGN}
	-P Modules/CmakeFedoraScript.cmake
	)
    FILE(READ ${outputFile} v)
    STRING(STRIP "${v}" v)
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(CMAKE_FEDORA_SCRIPT_CONFIGURE_FILE_TEST expected cmd names)
CMAKE_FEDORA_SCRIPT_CONFIGURE_FILE_TEST("Name: cmake-fedora cmake-fedora" 
    ${CTEST_SCRIPT_DIRECTORY}/configure-file-project.txt 
    ${CMAKE_FEDORA_TMP_DIR}/configure-file-project.txt 
    -DPROJECT_NAME=cmake-fedora
    )
CMAKE_FEDORA_SCRIPT_CONFIGURE_FILE_TEST("Name: cmake-fedora \${PROJECT_NAME}" 
    ${CTEST_SCRIPT_DIRECTORY}/configure-file-project.txt 
    ${CMAKE_FEDORA_TMP_DIR}/configure-file-project.txt 
    -Dat_only=1
    -DPROJECT_NAME=cmake-fedora
    )


FUNCTION(CMAKE_FEDORA_SCRIPT_FIND_TEST expected cmd names)
    MESSAGE("CMAKE_FEDORA_SCRIPT_FIND: ${cmd}_${names}")
    EXECUTE_PROCESS(COMMAND cmake 
	-Dcmd=${cmd} "-Dnames=${names}" ${ARGN}
       	-P Modules/CmakeFedoraScript.cmake
	OUTPUT_VARIABLE v
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(CMAKE_FEDORA_SCRIPT_FIND_TEST expected cmd names)

CMAKE_FEDORA_SCRIPT_FIND_TEST("/usr/bin/cmake" "find_program" "cmake")
CMAKE_FEDORA_SCRIPT_FIND_TEST("" "find_program" "not exist" 
    "-Dverbose_level=${M_OFF}"
    )
CMAKE_FEDORA_SCRIPT_FIND_TEST("/etc/passwd" "find_file" "passwd" 
    "-Dpaths=/etc" "-Dno_default_path=1" 
    )
CMAKE_FEDORA_SCRIPT_FIND_TEST("" "find_file" "not exist"
    "-Dverbose_level=${M_OFF}" "-Dno_default_path=1" 
    )

FUNCTION(CMAKE_FEDORA_SCRIPT_MANAGE_FILE_CACHE_TEST expected cacheFile run)
    MESSAGE("CMAKE_FEDORA_SCRIPT_MANAGE_FILE_CACHE: ${cacheFile}")
    SET(_cacheDir "/tmp")
    FILE(REMOVE "${_cacheDir}/${cacheFile}")
    EXECUTE_PROCESS(COMMAND cmake 
	-Dcmd=manage_file_cache "-Dcache_file=${cacheFile}"
	"-Drun=${run}" -Dcache_dir=/tmp ${ARGN} 
	-P Modules/CmakeFedoraScript.cmake
	OUTPUT_VARIABLE v
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(CMAKE_FEDORA_SCRIPT_MANAGE_FILE_CACHE_TEST expected     cachefile run)

CMAKE_FEDORA_SCRIPT_MANAGE_FILE_CACHE_TEST("Hi" "Hi" "echo 'Hi'")
CMAKE_FEDORA_SCRIPT_MANAGE_FILE_CACHE_TEST("Hello" "Hello" "echo 'Hi' |  sed -e \"s/Hi/Hello/\"")

FUNCTION(CMAKE_FEDORA_SCRIPT_GET_VARIBLE_TEST expected var)
    MESSAGE("CMAKE_FEDORA_SCRIPT_GET_VARIBLE_TEST: ${var}")
    EXECUTE_PROCESS(COMMAND cmake 
	-Dcmd=get_variable "-Dvar=${var}"
	-P Modules/CmakeFedoraScript.cmake
	OUTPUT_VARIABLE v
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(CMAKE_FEDORA_SCRIPT_GET_VARIBLE_TEST expected var)
CMAKE_FEDORA_SCRIPT_GET_VARIBLE_TEST("$ENV{HOME}/.cache/cmake-fedora/" "LOCAL_CACHE_DIR")
