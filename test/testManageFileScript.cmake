# Unit test for ManageFileScript
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)

FUNCTION(MANAGE_FILE_SCRIPT_FIND_TEST expected cmd names)
    MESSAGE("MANAGE_FILE_SCRIPT_FIND: ${cmd}_${names}")
    EXECUTE_PROCESS(COMMAND cmake 
	-Dcmd=${cmd} "-Dnames=${names}" ${ARGN}
       	-P Modules/ManageFileScript.cmake
	OUTPUT_VARIABLE v
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(MANAGE_FILE_SCRIPT_FIND_TEST expected cmd names)

MANAGE_FILE_SCRIPT_FIND_TEST("/usr/bin/cmake" "find_program" "cmake")
MANAGE_FILE_SCRIPT_FIND_TEST("" "find_program" "not exist" 
    "-Dverbose_level=${M_OFF}"
    )
MANAGE_FILE_SCRIPT_FIND_TEST("/etc/passwd" "find_file" "passwd" 
    "-Dpaths=/etc" "-Dno_default_path=1" 
    )
MANAGE_FILE_SCRIPT_FIND_TEST("" "find_file" "not exist"
    "-Dverbose_level=${M_OFF}" "-Dno_default_path=1" 
    )

FUNCTION(MANAGE_FILE_SCRIPT_MANAGE_FILE_CACHE_TEST expected cacheFile run)
    MESSAGE("MANAGE_FILE_SCRIPT_MANAGE_FILE_CACHE: ${cacheFile}")
    SET(_cacheDir "/tmp")
    FILE(REMOVE "${_cacheDir}/${cacheFile}")
    EXECUTE_PROCESS(COMMAND cmake 
	-Dcmd=manage_file_cache "-Dcache_file=${cacheFile}"
	"-Drun=${run}" -Dcache_dir=/tmp ${ARGN} 
	-P Modules/ManageFileScript.cmake
	OUTPUT_VARIABLE v
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    TEST_STR_MATCH(v "${expected}")
ENDFUNCTION(MANAGE_FILE_SCRIPT_MANAGE_FILE_CACHE_TEST expected     cachefile run)

MANAGE_FILE_SCRIPT_MANAGE_FILE_CACHE_TEST("Hi" "Hi" "echo 'Hi'")
MANAGE_FILE_SCRIPT_MANAGE_FILE_CACHE_TEST("Hello" "Hello" "echo 'Hi' |  sed -e \"s/Hi/Hello/\"")

