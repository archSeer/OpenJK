cmake_minimum_required(VERSION 2.8.8)
# For checks in subdirectories
set(InOpenJK TRUE)

#    Project name
project("OpenJK")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

#    Customizable options
option(BuildJK2Support "Build JK2 support" OFF)

option(BuildMPEngine "Whether to create projects for the MP client (openjk.exe)" ON)
option(BuildMPDed "Whether to create projects for the MP dedicated server (openjkded.exe)" ON)
option(BuildMPGame "Whether to create projects for the MP server-side gamecode (jampgamex86.dll)" ON)
option(BuildMPCGame "Whether to create projects for the MP clientside gamecode (cgamex86.dll)" ON)
option(BuildMPUI "Whether to create projects for the MP UI code (uix86.dll)" ON)
option(BuildSPEngine "Whether to create projects for the SP engine (openjk_sp.exe)" ON)
option(BuildSPGame "Whether to create projects for the SP gamecode (jagamex86.dll)" ON)
# (mrw) jk2 has some weird PCH fuckery I cannot replicate with cmake without too much work
set(BuildJK2SPGame OFF)
#option(BuildJK2SPGame "Whether to create projects for the jk2 sp gamecode mod (jk2gamex86.dll)" ON)

# Customizable libraries
if(WIN32)
	option(UseInternalOpenAL "Whether to use the included OpenAL instead of a locally installed one" ON)
	option(UseInternalZlib "Whether to use the included zlib instead of a locally installed one" ON)
endif(WIN32)

if(WIN32)
	option(UseInternalPNG "Whether to use the included libpng instead of a locally installed one" ON)
else(WIN32)
	option(UseInternalPNG "Whether to use the included libpng instead of a locally installed one" OFF)
endif(WIN32)

if(APPLE)
	option(MakeApplicationBundles "Whether to build .app application bundles for engines built" ON)
else(APPLE)
	set(MakeApplicationBundles OFF)
endif(APPLE)

option(PackageDir "Where to place the installer/package." "${CMAKE_SOURCE_DIR}/package")

# Custom CMake Modules needed
list(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_SOURCE_DIR}/CMakeModules")

# Arch Suffix
if (CMAKE_SIZEOF_VOID_P MATCHES "8")
	if (WIN32)
		set(Architecture "x86_64")
		set(WIN64 TRUE)
	else (WIN32)
		set(Architecture "x86_64")
	endif(WIN32)
else (CMAKE_SIZEOF_VOID_P MATCHES "8")
	if (WIN32)
		set(Architecture "x86")
		set(WIN64 FALSE)
	else (WIN32)
		set(Architecture "i386")
	endif(WIN32)
endif (CMAKE_SIZEOF_VOID_P MATCHES "8")

message("Architecture is ${Architecture}")

# Current Git SHA1 hash
include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)
# TODO: actually use the Git SHA1 for something?
message("Git revision is ${GIT_SHA1}")

# Binary names
set(SPEngine "openjk_sp.${Architecture}")
set(SPGame "jagame${Architecture}")
set(SPRDVanillaRenderer "rdsp-vanilla_${Architecture}")
set(JK2SPGame "jk2game${Architecture}")
set(MPEngine "openjk.${Architecture}")
set(MPVanillaRenderer "rd-vanilla_${Architecture}")
set(MPDed "openjkded.${Architecture}")
set(MPGame "jampgame${Architecture}")
set(MPCGame "cgame${Architecture}")
set(MPUI "ui${Architecture}")
# Library names
set(MPBotLib "botlib")

# Paths
set(SPDir "${CMAKE_SOURCE_DIR}/code")
set(MPDir "${CMAKE_SOURCE_DIR}/codemp")
set(JK2SPDir "${CMAKE_SOURCE_DIR}/codeJK2")

# Common settings
if(WIN32)
	if(WIN64)
		if(MSVC)
			set(SharedDefines "WIN64" "_WINDOWS" "_CRT_SECURE_NO_WARNINGS")
		else(MSVC)
			set(SharedDefines "WIN64" "_WINDOWS")
		endif(MSVC)
	else(WIN64)
		if(MSVC)
			set(SharedDefines "WIN32" "_WINDOWS" "_CRT_SECURE_NO_WARNINGS")
		else(MSVC)
			set(SharedDefines "WIN32" "_WINDOWS")
		endif(MSVC)
	endif(WIN64)
else(WIN32)
	if (APPLE)
		set(SharedDefines "MACOS_X")
	#	set(SharedDefines "MACOS_X" "_M_IX86")
	#else(APPLE)
	#	set(SharedDefines "__linux__" "_M_IX86")
	endif()

	# removes the -rdynamic flag at linking (which causes crashes for some reason)
	set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
	set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

	# additional flags for debug configuration
	set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -ggdb")
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -ggdb")

	if("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wno-comment -fvisibility=hidden")
	elseif("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
		# No nested block comments
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wno-comment")
	endif()

	if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
		# Disable invalid offsetof, and deprecated writable strings warnings
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-invalid-offsetof -Wno-write-strings -Wno-comment -fvisibility=hidden -fvisibility-inlines-hidden")
	elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
		# Disable nested block comments, and deprecated writable strings warnings
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-deprecated-writable-strings -Wno-comment")
	endif()

	if (NOT CMAKE_BUILD_TYPE)
		message("No build type selected, default to RELEASE")
		set(CMAKE_BUILD_TYPE "RELEASE")
	endif()
endif()

# Settings
if(NOT BuildJK2Support)
	set(SharedDefines ${SharedDefines} "__NO_JK2")
endif()

set(OpenJKLibDir "${CMAKE_SOURCE_DIR}/lib")

set(DebugDefines "_DEBUG")
set(ReleaseDefines "NDEBUG" "FINAL_BUILD")

#    Add projects
add_subdirectory(${SPDir})
if(BuildJK2SPGame)
	add_subdirectory("${JK2SPDir}/game")
endif(BuildJK2SPGame)
add_subdirectory(${MPDir})

#    CPack for installer creation
# TODO: Which version are we?
set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "1")
set(CPACK_PACKAGE_VERSION_PATCH "0")
# I'm just not appending the version for now
set(CPACK_PACKAGE_FILE_NAME "OpenJK-${CMAKE_SYSTEM_NAME}-${Architecture}")

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "An improved Jedi Academy")
set(CPACK_PACKAGE_VENDOR "JACoders")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_PACKAGE_DIRECTORY ${PACKAGE_DIR})
set(CPACK_BINARY_ZIP ON) # always create at least a zip file
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY 0) # prevent additional directory in zip

include(CPack)
