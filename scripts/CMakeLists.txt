SET(EXECUTABLES 
    cmake-fedora-changelog 
    cmake-fedora-fedpkg 
    cmake-fedora-koji 
    cmake-fedora-newprj 
    koji-build-scratch
)

MANAGE_FILE_INSTALL(BIN ${EXECUTABLES})

