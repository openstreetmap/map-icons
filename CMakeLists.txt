cmake_minimum_required(VERSION 2.6)

PROJECT(map-icons)

AUX_SOURCE_DIRECTORY(${CMAKE_SOURCE_DIR} ALL_SRC)
message(STATUS "ALL_SRC: ${ALL_SRC}")


# Find Compile Command
FIND_PACKAGE(Perl REQUIRED)
FIND_PROGRAM(COMPILE_EXECUTABLE
  NAMES compile_icons.pl 
  PATHS tools ${CMAKE_SOURCE_DIR}/tools
  )
message(STATUS "Compile Command: ${COMPILE_EXECUTABLE}")

# ---------------------- Set Variables
IF (NOT APPLICATION_NAME)
  MESSAGE(STATUS "${PROJECT_NAME} is used as APPLICATION_NAME")
  SET(APPLICATION_NAME ${PROJECT_NAME})
ENDIF (NOT APPLICATION_NAME)

message(STATUS "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}")

SET(SHARE_INSTALL_PREFIX
  "${CMAKE_INSTALL_PREFIX}/share"
  CACHE PATH "Base directory for files which go to share/"
  FORCE
  )

SET(ICON_INSTALL_DIR
  "${SHARE_INSTALL_PREFIX}/icons/map-icons"
  CACHE PATH "The icon install dir (default data/map-icons/)"
  FORCE
  )

# ---------------------- README
configure_file(README ${CMAKE_CURRENT_BINARY_DIR}/README COPYONLY)
configure_file(README.icons ${CMAKE_CURRENT_BINARY_DIR}/README.icons COPYONLY)
install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/README
  DESTINATION
    ${ICON_INSTALL_DIR}
)
install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/README.icons
  DESTINATION
    ${ICON_INSTALL_DIR}
)

# ---------------------- compile-build
ADD_CUSTOM_TARGET(all
  COMMAND ${PERL_EXECUTABLE} ${COMPILE_EXECUTABLE} --src-dir=${CMAKE_SOURCE_DIR} --dst-dir=${CMAKE_CURRENT_BINARY_DIR}
  COMMENT "compile Map-Icons"
  VERBATIM
  )
