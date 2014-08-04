# Test with actual projects
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)

FUNCTION(PROJECT_TEST_COMMAND prjDir cmdStr)
    EXECUTE_PROCESS(COMMAND eval "${cmdStr}"
	WORKING_DIRECTORY "${prjDir}"
	OUTPUT_VARIABLE _out
	ERROR_VARIABLE _err
	RESULT_VARIABLE _ret
	)
    IF(NOT _ret EQUAL 0)
	M_MSG(${M_ERROR} "${project} failed with ${cmdStr}:")
	M_MSG(${M_ERROR} "STDOUT=${_out}")
	M_MSG(${M_ERROR} "STDERR=${_err}")
    ENDIF()
ENDFUNCTION(PROJECT_TEST_COMMAND)

FUNCTION(PROJECT_TEST project)
    SET(prjDir "test/projects/${project}")
    IF(NOT EXISTS "${prjDir}")
	M_MSG(${M_OFF} "${project} does not exist, skip")
	RETURN()
    ENDIF()
    PROJECT_TEST_COMMAND(${prjDir} "${CMAKE_COMMAND} -DCMAKE_FEDORA_ENABLE_FEDORA_BUILD=1 .")
ENDFUNCTION(PROJECT_TEST)

PROJECT_TEST(ibus-chewing)


