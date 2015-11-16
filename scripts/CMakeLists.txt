SET(EXECUTABLES 
    cmake-fedora-fedpkg 
    cmake-fedora-koji 
    cmake-fedora-newprj
    cmake-fedora-pkgdb 
    cmake-fedora-zanata
    koji-build-scratch
)

MANAGE_FILE_INSTALL(BIN ${EXECUTABLES})

