include(InstallRequiredSystemLibraries)

# CPACK_CMAKE_GENERATOR              What CMake generator should be used if
#                                    the project is CMake project
#                                    Unix Makefiles
#
# CPACK_GENERATOR                    CPack generator to be used
#                                    STGZ;TGZ;TZ
#
# CPACK_INSTALL_CMAKE_PROJECTS       List of four values: Build directory,
#                                    Project Name, Project Component,
#                                    Directory in the package
#                                    /home/andy/vtk/CMake-bin;CMake;ALL;/
#
# CPACK_PACKAGE_DESCRIPTION_FILE     File used as a description of a project
#                                    /path/to/project/ReadMe.txt
#
# CPACK_PACKAGE_DESCRIPTION_SUMMARY  Description summary of a project
#                                    CMake is a build tool
# CPACK_PACKAGE_EXECUTABLES          Pair of project executable and label
#                                    ccmake;CMake
#
# CPACK_PACKAGE_FILE_NAME            Package file name without extension. Also
#                                    a directory of installer
#                                    cmake-2.5.0-Linux-i686
#
# CPACK_PACKAGE_INSTALL_DIRECTORY    Installation directory on the target
#                                    system
#                                    CMake 2.5
# CPACK_PACKAGE_INSTALL_REGISTRY_KEY Registry key used when installing this
#                                    project
#                                    CMake 2.5.0
#
# CPACK_PACKAGE_NAME                 Package name
#                                    CMake
#
# CPACK_PACKAGE_VENDOR               Package vendor name
#                                    Kitware
#
# CPACK_PACKAGE_VERSION              Package full version
#                                    2.5.0
#
# CPACK_PACKAGE_VERSION_MAJOR        Package Major Version
#                                    2
#
# CPACK_PACKAGE_VERSION_MINOR        Package Minor Version
#                                    5
#
# CPACK_PACKAGE_VERSION_PATCH        Package Patch Version
#                                    0
#
# CPACK_RESOURCE_FILE_LICENSE        License file for the project
#                                    /home/andy/vtk/CMake/Copyright.txt
#
# CPACK_RESOURCE_FILE_README         ReadMe file for the project
#                                    /home/andy/vtk/CMake/Templates/CPack.GenericDescription.txt
#
# CPACK_RESOURCE_FILE_WELCOME        Welcome file for the project
#                                    /home/andy/vtk/CMake/Templates/CPack.GenericWelcome.txt
#
# CPACK_SOURCE_GENERATOR             List of generators used for the source
#                                    package
#                                    TGZ;TZ
#
# CPACK_SOURCE_IGNORE_FILES          Pattern of files in the source tree that
#                                    won't be packaged
#                                    /CVS/;/[.]svn/;[.]swp$;\\.#;/#;~$;cscope.*;tags
#
# CPACK_SOURCE_PACKAGE_FILE_NAME     Name of the source package
#                                    cmake-2.5.0
#
# CPACK_SOURCE_STRIP_FILES           List of files in the source tree that will
#                                    be stripped
#
# CPACK_STRIP_FILES                  List of files to be stripped
#                                    bin/ccmake;bin/cmake;bin/cpack;bin/ctest
#
# CPACK_SYSTEM_NAME                  System name
#                                    Linux-i686
#
# CPACK_TOPLEVEL_TAG                 Directory for the installed
#                                    Linux-i686

### general settings
set(CPACK_PACKAGE_NAME "map-icons")
set(CPACK_PACKAGE_VENDOR "The OpenStreetMap Team")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Icons for Displaying Maps")

set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/COPYING")

### versions
set(CPACK_PACKAGE_VERSION "0.99svn${SVN_REVISION}")
set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "99svn${SVN_REVISION}")
set(CPACK_PACKAGE_VERSION_PATCH "")

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")

### system specific settings
if(WIN32 AND NOT UNIX)
  # There is a bug in NSI that does not handle full unix paths properly. Make
  # sure there is at least one set of four (4) backlasshes.
  set(CPACK_PACKAGE_EXECUTABLES "map-icons;Map-Icons")
  set(CPACK_PACKAGE_ICON "${CMAKE_SOURCE_DIR}/Utilities/Release\\\\InstallIcon.bmp")
  set(CPACK_NSIS_INSTALLED_ICON_NAME "map-icons.exe")
  set(CPACK_NSIS_DISPLAY_NAME "${CPACK_PACKAGE_INSTALL_DIRECTORY} ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")
  set(CPACK_NSIS_HELP_LINK "http:\\\\\\\\www.openstreetmap.cc")
  set(CPACK_NSIS_URL_INFO_ABOUT "http:\\\\\\\\www.openstreetmap.cc")
  set(CPACK_NSIS_CONTACT "info@openstreetmap.cc")
  set(CPACK_NSIS_MODIFY_PATH ON)
else(WIN32 AND NOT UNIX)
  set(CPACK_SOURCE_STRIP_FILES "")
endif(WIN32 AND NOT UNIX)

### source package settings
set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_SOURCE_IGNORE_FILES "~$;[.]swp$;/[.]svn/;[.]o$;.cvsignore;.#;.deps;tags;/build/;/m4/;debian/map-icons/;debuild.tmp;/logs/;[.]bak$;[.]a$;[.]la$;build-stamp;semantic.cache")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")

include(CPack)
