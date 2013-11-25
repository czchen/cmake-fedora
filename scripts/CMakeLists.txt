SET(EXECUTABLES cmake-fedora-fedpkg 
    cmake-fedora-koji 
    cmake-fedora-newprj 
    koji-build-scratch
    )
SET(LIBEXEC_FUNCTIONS cmake-fedora-functions)

MANAGE_FILE_INSTALL(BIN ${EXECUTABLES})
MANAGE_FILE_INSTALL(LIBEXEC ${LIBEXEC_FUNCTIONS})

