# This a sample CMakeLists.txt for compiling plug for Switchboard
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)

# Set the Properties of your Plug

# Set the Name of the plug, should be an executable command, lowercase, no spaces 
set (PLUGNAME "about")
# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "system")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "About")
set (PLUGDESCRIPTION "About")
# The symbolic name of the Icon to use for the plug
set (PLUGICON "help-info")

project (${PLUGNAME})

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/switchboard")
set (PKGDATADIR "${DATADIR}/system/pantheon-${PLUGNAME}")
set (GETTEXT_PACKAGE "${PLUGNAME}-plug")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (plug.plugin ${CMAKE_BINARY_DIR}/${PLUGNAME}.plugin)
install (FILES ${CMAKE_BINARY_DIR}/${PLUGNAME}.plugin DESTINATION ${PKGDATADIR})
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Files
file (GLOB resources "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

# Traslation stuff
add_subdirectory (po)
# Info-plug
install (FILES ${resources} DESTINATION ${PKGDATADIR})

add_subdirectory(src)