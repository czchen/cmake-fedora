# Test for CmakeFedoraFedpkg
INCLUDE(test/testCommon.cmake)
INCLUDE(ManageMessage)

SET(CMAKE_FEDORA_FEDPKG_CMD "scripts/cmake-fedora-fedpkg")

MESSAGE("CMAKE_FEDORA_FEDPKG_HELP: ")
EXECUTE_PROCESS(COMMAND ${CMAKE_FEDORA_FEDPKG_CMD}
    OUTPUT_VARIABLE v
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
IF(NOT v MATCHES "cmake-fedora-fedpkg")
    MESSAGE(SEND_ERROR "Failed to print help.")
ENDIF(NOT v MATCHES "cmake-fedora-fedpkg")

