
########################################################################
#
# TribitsExampleProject Tests
#
########################################################################


########################################################################
# Helper vars and macros
########################################################################


set(TribitsExampleProject_COMMON_CONFIG_ARGS
  ${COMMON_ENV_ARGS_PASSTHROUGH}
  -DTribitsExProj_ENABLE_Fortran=${${PROJECT_NAME}_ENABLE_Fortran}
  )


assert_defined(TPL_ENABLE_MPI)
if (TPL_ENABLE_MPI)
  set(TPL_MPI_FILE_TRACE
    "-- File Trace: TPL        INCLUDE    .*/core/std_tpls/FindTPLMPI.cmake")
  set(FINAL_ENABLED_TPLS "MPI HeaderOnlyTpl 2")
else()
  set(TPL_MPI_FILE_TRACE "")
  set(FINAL_ENABLED_TPLS "HeaderOnlyTpl 1")
endif()


if (EXISTS "${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject/.gitignore")
  set(REGEX_FOR_GITIGNORE "Only in .*/TribitsExampleProject: .gitignore")
else()
  set(REGEX_FOR_GITIGNORE)
endif()

print_var(CMAKE_CXX_COMPILER_VERSION)


if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 5.0)
    set(DEPRECATED_WARNING_1_STR
      "‘int SimpleCxx::HelloWorld::someOldFunc.. const’ is deprecated .declared at .*/TribitsExampleProject/packages/simple_cxx/src/SimpleCxx_HelloWorld.hpp:"
      )
    if (NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.5)
      # Only versions 4.5+ support this feature
      set(DEPRECATED_MSG_STR ".* .Just don't call this function at all please!")
    else()
      set(DEPRECATED_MSG_STR "")
    endif()
    set(DEPRECATED_WARNING_2_STR
      "‘int SimpleCxx::HelloWorld::someOldFunc2.. const’ is deprecated .declared at .*/TribitsExampleProject/packages/simple_cxx/src/SimpleCxx_HelloWorld.hpp:${DEPRECATED_MSG_STR}"
      )
  else()
    set(DEPRECATED_WARNING_1_STR
      ".*/TribitsExampleProject/packages/simple_cxx/src/SimpleCxx_HelloWorld.cpp:.*: warning: .*someOldFunc.* is deprecated"
      )
    set(DEPRECATED_WARNING_2_STR
      ".*/TribitsExampleProject/packages/simple_cxx/src/SimpleCxx_HelloWorld.cpp:.*: warning: .*someOldFunc2.* is deprecated: .Just don.t call this function at all please."
      )
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(DEPRECATED_WARNING_1_STR
    "simple_cxx/src/SimpleCxx_HelloWorld.hpp:.*:.*: note: 'someOldFunc' has been explicitly marked deprecated here"
    )
  set(DEPRECATED_MSG_STR
    "SIMPLECXX_DEPRECATED_MSG[(].Just don't call this function at all please..[)]")
else()
  message(SEND_ERROR "Error, the CMAKE_CXX_COMPILER_ID='${CMAKE_CXX_COMPILER_ID}'"
    " and CMAKE_CXX_COMPILER_VERSION='${CMAKE_CXX_COMPILER_VERSION}' is not covered"
    " for setting DEPRECATED_WARNING_1_STR!")
endif()

print_var(DEPRECATED_WARNING_1_STR)
print_var(DEPRECATED_MSG_STR)
print_var(DEPRECATED_WARNING_2_STR)

set(LabelsForSubprojects_CMND_AND_ARGS
  grep ARGS "^LabelsForSubprojects:" DartConfiguration.tcl)
set(LabelsForSubprojects_REGEX
  "LabelsForSubprojects: SimpleCxx[;]MixedLang[;]WithSubpackages[;]WrapExternal")


########################################################################


function(TribitsExampleProject_ALL_ST_NoFortran  sharedOrStatic  serialOrMpi)

  set(testBaseName ${CMAKE_CURRENT_FUNCTION}_${sharedOrStatic}_${serialOrMpi})
  set(testName ${PACKAGE_NAME}_${testBaseName})
  set(testDir "${CMAKE_CURRENT_BINARY_DIR}/${testName}")

  if (sharedOrStatic STREQUAL "SHARED")
    set(BUILD_SHARED_LIBS_VAL ON)
    set(libExtRegex "[.]so[.].*")
  elseif (sharedOrStatic STREQUAL "STATIC")
    set(BUILD_SHARED_LIBS_VAL OFF)
    set(libExtRegex "[.]a")
  else()
    message(FATAL_ERROR "Invalid value sharedOrStatic='${sharedOrStatic}'!")
  endif()

  if (serialOrMpi STREQUAL "SERIAL")
    set(tplEnableMpiArg -DTPL_ENABLE_MPI=OFF)
    set(excludeIfNotTrueVarList "")
    set(TPL_MPI_FILE_TRACE "")
    set(FINAL_ENABLED_TPLS "HeaderOnlyTpl 1")
    set(TEST_MPI_1_SUFFIX "")
    set(TribitsExProj_SHARED_LIB_RPATH_COMMAND_REGEX "")
  elseif (serialOrMpi STREQUAL "MPI")
    set(tplEnableMpiArg -DTPL_ENABLE_MPI=ON)
    set(excludeIfNotTrueVarList "TriBITS_PROJECT_MPI_IS_ENABLED")
    set(TPL_MPI_FILE_TRACE
      "-- File Trace: TPL        INCLUDE    .*/core/std_tpls/FindTPLMPI.cmake")
    set(FINAL_ENABLED_TPLS "MPI HeaderOnlyTpl 2")
    set(TEST_MPI_1_SUFFIX "_MPI_1")
    set(TribitsExProj_SHARED_LIB_RPATH_COMMAND_REGEX
      "-Wl,-rpath,.*/${testName}/install/lib")
  else()
    message(FATAL_ERROR "Invalid value tplEnableMpiArg='${tplEnableMpiArg}'!")
  endif()

  tribits_add_advanced_test( ${testBaseName}
    OVERALL_WORKING_DIRECTORY TEST_NAME
    OVERALL_NUM_MPI_PROCS 1
    XHOSTTYPE Darwin
    EXCLUDE_IF_NOT_TRUE ${excludeIfNotTrueVarList}

    TEST_0
      MESSAGE "Do the initial configure (and test a lot of things at once)"
      CMND ${CMAKE_COMMAND}
      ARGS
        ${TribitsExampleProject_COMMON_CONFIG_ARGS}
        -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
        -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS_VAL}
        ${tplEnableMpiArg}
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DTribitsExProj_ENABLE_Fortran=OFF
        -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
        -DTribitsExProj_ENABLE_TESTS=ON
        -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
        -DTribitsExProj_TRACE_FILE_PROCESSING=ON
        -DTribitsExProj_ENABLE_CPACK_PACKAGING=ON
        -DTribitsExProj_DUMP_CPACK_SOURCE_IGNORE_FILES=ON
        -DTribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON
        -DTribitsExProj_DUMP_FORWARD_PACKAGE_DEPENDENCIES=ON
        -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
	-DWithSubpackagesA_SPECIAL_VALUE=5
        -DCMAKE_CXX_FLAGS=-DSIMPLECXX_SHOW_DEPRECATED_WARNINGS=1
        -DCMAKE_INSTALL_PREFIX=install
        ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
      PASS_REGULAR_EXPRESSION_ALL
        "Configuring TribitsExProj build directory"
        "-- PROJECT_SOURCE_DIR="
        "-- PROJECT_BINARY_DIR="
        "-- TribitsExProj_TRIBITS_DIR="
        "-- TriBITS_VERSION_STRING="
        "-- CMAKE_VERSION="
        "-- CMAKE_HOST_SYSTEM_NAME="
        "-- TribitsExProj_HOSTNAME="

        "NOTE: Setting TribitsExProj_ENABLE_WrapExternal=OFF because TribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES='ON'"
        "NOTE: Setting TribitsExProj_ENABLE_MixedLang=OFF because TribitsExProj_ENABLE_Fortran"

        "Package dependencies information:"
        "-- TribitsExProj_DEFINED_INTERNAL_TOPLEVEL_PACKAGES: SimpleCxx MixedLang WithSubpackages WrapExternal"
        "-- TribitsExProj_DEFINED_INTERNAL_PACKAGES: SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages WrapExternal"

        "-- SimpleCxx_LIB_DEFINED_DEPENDENCIES: HeaderOnlyTpl.R. SimpleTpl.O. MPI.O."
        "-- SimpleCxx_FORWARD_LIB_DEFINED_DEPENDENCIES: WithSubpackagesA.R. WithSubpackagesB.R."
        "-- MixedLang_FORWARD_LIB_DEFINED_DEPENDENCIES: WrapExternal.O."
        "-- MixedLang_FORWARD_TEST_DEFINED_DEPENDENCIES: WithSubpackagesB.O."
        "-- WithSubpackagesA_LIB_DEFINED_DEPENDENCIES: SimpleCxx.R."
        "-- WithSubpackagesA_FORWARD_LIB_DEFINED_DEPENDENCIES: WithSubpackagesB.O. WithSubpackagesC.R. WithSubpackages.R. WrapExternal.R."
        "-- WithSubpackagesB_LIB_DEFINED_DEPENDENCIES: SimpleCxx.R. WithSubpackagesA.O."
        "-- WithSubpackagesB_TEST_DEFINED_DEPENDENCIES: MixedLang.O."
        "-- WithSubpackagesB_FORWARD_LIB_DEFINED_DEPENDENCIES: WithSubpackagesC.R. WithSubpackages.O."
        "-- WithSubpackages_LIB_DEFINED_DEPENDENCIES: WithSubpackagesA.R. WithSubpackagesB.O. WithSubpackagesC.O."
        "-- WrapExternal_LIB_DEFINED_DEPENDENCIES: WithSubpackagesA.R. MixedLang.O."

	"Setting up export dependencies for all enabled packages ..."
        "-- SimpleCxx: No library dependencies!"
        "-- WithSubpackagesA_FULL_ENABLED_DEP_PACKAGES: SimpleCxx"
        "-- WithSubpackagesB_FULL_ENABLED_DEP_PACKAGES: WithSubpackagesA SimpleCxx"
        "-- WithSubpackagesC_FULL_ENABLED_DEP_PACKAGES: WithSubpackagesB WithSubpackagesA SimpleCxx"
        "-- WithSubpackages_FULL_ENABLED_DEP_PACKAGES: WithSubpackagesC WithSubpackagesB WithSubpackagesA SimpleCxx"

        "Explicitly enabled top-level packages on input .by user.:  0"
        "Explicitly disabled top-level packages on input .by user or by default.:  MixedLang WrapExternal 2"
        "Enabling all packages that are not currently disabled because of TribitsExProj_ENABLE_ALL_PACKAGES=ON "
        "Setting TribitsExProj_ENABLE_SimpleCxx=ON"
        "Setting TribitsExProj_ENABLE_WithSubpackages=ON"
        "Setting TPL_ENABLE_HeaderOnlyTpl=ON because SimpleCxx has a required dependence on HeaderOnlyTpl"
        "Set cache entries for optional packages/TPLs and tests/examples for packages actually enabled ..."

        "Dumping direct enabled dependencies for each package ..."
        "-- MPI: No enabled dependencies!"
        "-- HeaderOnlyTpl: No enabled dependencies!"
        "-- SimpleTpl: No enabled dependencies!"
        "-- SimpleCxx_LIB_ENABLED_DEPENDENCIES: HeaderOnlyTpl.R."
        "-- MixedLang: No enabled dependencies!"
        "-- WithSubpackagesA_LIB_ENABLED_DEPENDENCIES: SimpleCxx.R."
        "-- WithSubpackagesB_LIB_ENABLED_DEPENDENCIES: SimpleCxx.R. WithSubpackagesA.O."
        "-- WithSubpackagesC_LIB_ENABLED_DEPENDENCIES: WithSubpackagesA.R. WithSubpackagesB.R."
        "-- WithSubpackages_LIB_ENABLED_DEPENDENCIES: WithSubpackagesA.R. WithSubpackagesB.O. WithSubpackagesC.O."
        "-- WrapExternal: No enabled dependencies!"

        "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
        "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages 5"
        "Final set of enabled external packages/TPLs:  ${FINAL_ENABLED_TPLS}"
        "Final set of non-enabled top-level packages:  MixedLang WrapExternal 2"

        "Processing enabled external package/TPL: HeaderOnlyTpl"
        "-- File Trace: TPL        INCLUDE    .+/TribitsExampleProject/cmake/tpls/FindTPLHeaderOnlyTpl.cmake"
        "-- TPL_HeaderOnlyTpl_INCLUDE_DIRS='.+/examples/tpls/HeaderOnlyTpl'"

        "Performing Test HAVE_SIMPLECXX___INT64"
        "Configuring done"
        "Generating done"

        "Build files have been written to: .*ExamplesUnitTests/${testName}"
        "-- File Trace: PROJECT    INCLUDE    .*/TribitsExampleProject/Version.cmake"
        "-- File Trace: REPOSITORY INCLUDE    .*/TribitsExampleProject/cmake/CallbackSetupExtraOptions.cmake"
        "-- File Trace: REPOSITORY INCLUDE    .*/TribitsExampleProject/PackagesList.cmake"
        "-- File Trace: REPOSITORY INCLUDE    .*/TribitsExampleProject/TPLsList.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/simple_cxx/cmake/Dependencies.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/mixed_lang/cmake/Dependencies.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/with_subpackages/cmake/Dependencies.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/with_subpackages/a/cmake/Dependencies.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/with_subpackages/b/cmake/Dependencies.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/with_subpackages/c/cmake/Dependencies.cmake"
        "-- File Trace: PACKAGE    INCLUDE    .*/TribitsExampleProject/packages/wrap_external/cmake/Dependencies.cmake"
        "-- File Trace: PROJECT    CONFIGURE  .*/TribitsExampleProject/cmake/ctest/CTestCustom.cmake.in"
        "-- File Trace: REPOSITORY READ       .*/TribitsExampleProject/Copyright.txt"
        "-- File Trace: REPOSITORY INCLUDE    .*/TribitsExampleProject/Version.cmake"
        "${TPL_MPI_FILE_TRACE}"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/simple_cxx/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/simple_cxx/test/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/a/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/a/tests/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/b/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/b/tests/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/c/CMakeLists.txt"
        "-- File Trace: PACKAGE    ADD_SUBDIR .*/TribitsExampleProject/packages/with_subpackages/c/tests/CMakeLists.txt"
        "-- File Trace: REPOSITORY INCLUDE    .*/TribitsExampleProject/cmake/CallbackDefineRepositoryPackaging.cmake"
        "-- File Trace: PROJECT    INCLUDE    .*/TribitsExampleProject/cmake/CallbackDefineProjectPackaging.cmake"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_1
      MESSAGE "Make sure that 'LabelsForSubprojects' is set to list of packages"
      CMND ${LabelsForSubprojects_CMND_AND_ARGS}
      PASS_REGULAR_EXPRESSION "${LabelsForSubprojects_REGEX}"

    TEST_2
      MESSAGE "Build the default 'all' target using raw 'make'"
      CMND make ARGS ${CTEST_BUILD_FLAGS}
      PASS_REGULAR_EXPRESSION_ALL
        "Built target simplecxx"
        "${DEPRECATED_WARNING_1_STR}"
        "${DEPRECATED_WARNING_2_STR}"
        "Built target pws_a"
        "Built target pws_b"
        "Built target pws_c"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_3
      MESSAGE "Run all the tests with raw 'ctest'"
      CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
      PASS_REGULAR_EXPRESSION_ALL
        "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
        "WithSubpackagesA_test_of_a .* Passed"
        "WithSubpackagesB_test_of_b .* Passed"
        "WithSubpackagesC_test_of_c .* Passed"
        "WithSubpackagesC_test_of_c_util.* Passed"
        "100% tests passed, 0 tests failed out of 6"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_4
      MESSAGE "Create and configure a dummy project that calls"
        " find_package(WithSubpackages) from the build tree"
      CMND ${CMAKE_COMMAND}
      ARGS
        -DDUMMY_PROJECT_NAME=DummyProject
        -DDUMMY_PROJECT_DIR=dummy_client_of_build_WithSubpackages
        -DEXPORT_VAR_PREFIX=WithSubpackages
        -DFIND_PACKAGE_NAME=WithSubpackages
        -DCMAKE_PREFIX_PATH=../cmake_packages
        -DCMAKE_COMMAND=${CMAKE_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
      PASS_REGULAR_EXPRESSION_ALL
        "Calling: find_package[(]WithSubpackages REQUIRED COMPONENTS  OPTIONAL_COMPONENTS  [)]"
        "WithSubpackages_CMAKE_BUILD_TYPE = 'RELEASE'"
        "WithSubpackages_CXX_COMPILER = '${CMAKE_CXX_COMPILER_FOR_REGEX}'"
        "WithSubpackages_C_COMPILER = '${CMAKE_C_COMPILER_FOR_REGEX}'"
        "WithSubpackages_Fortran_COMPILER = ''"
        "WithSubpackages_FORTRAN_COMPILER = ''"
        "WithSubpackages_CXX_FLAGS = '.*'"
        "WithSubpackages_C_FLAGS = '.*'"
        "WithSubpackages_Fortran_FLAGS = '.*'"
        "WithSubpackages_EXTRA_LD_FLAGS = '.*'"
        "WithSubpackages_SHARED_LIB_RPATH_COMMAND = '.*'"
        "WithSubpackages_BUILD_SHARED_LIBS = '.*'"
        "WithSubpackages_LINKER = '.+'"
        "WithSubpackages_AR = '.+'"
        "WithSubpackages_INSTALL_DIR = .*/${testName}/install"
        "WithSubpackages_LIBRARIES = 'WithSubpackages::all_libs'"
        "WithSubpackages_MPI_LIBRARIES = ''"
        "WithSubpackages_MPI_LIBRARY_DIRS = ''"
        "WithSubpackages_MPI_INCLUDE_DIRS = ''"
        "WithSubpackages_MPI_EXEC = '${MPI_EXEC}'"
        "WithSubpackages_MPI_EXEC_MAX_NUMPROCS = '${MPI_EXEC_MAX_NUMPROCS}'"
        "WithSubpackages_MPI_EXEC_NUMPROCS_FLAG = '${MPI_EXEC_NUMPROCS_FLAG}'"
        "WithSubpackages_FOUND = '1'"
        "WithSubpackages::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackagesA::pws_a[;]WithSubpackagesA::all_libs[;]WithSubpackagesB::pws_b[;]WithSubpackagesB::all_libs[;]WithSubpackagesC::pws_c[;]WithSubpackagesC::all_libs'"
        "-- Configuring done"
        "-- Generating done"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_5
      MESSAGE "Grep the contents of the WithSubpackagesAConfig.cmake file in build dir"
      CMND cat ARGS cmake_packages/WithSubpackagesA/WithSubpackagesAConfig.cmake
      PASS_REGULAR_EXPRESSION_ALL
        "# Enables/Disables for upstream package dependencies"
        "set[(]WithSubpackagesA_ENABLE_SimpleCxx ON[)]"
        "# Exported cache variables"
        "set[(]WithSubpackages_ENABLE_DEBUG .OFF.[)]"
        "set[(]HAVE_WITHSUBPACKAGES_DEBUG .OFF.[)]"
        "set[(]WithSubpackagesA_SPECIAL_VALUE .5.[)]"

    TEST_6
      MESSAGE "Build 'install' target using raw 'make'"
      CMND make ARGS install ${CTEST_BUILD_FLAGS}
      PASS_REGULAR_EXPRESSION_ALL
        "Install configuration: .RELEASE."
        "Installing: .*/install/lib/external_packages/HeaderOnlyTpl/HeaderOnlyTplConfig.cmake"
        "Installing: .*/install/lib/external_packages/HeaderOnlyTpl/HeaderOnlyTplConfigVersion.cmake"
        "Installing: .+/install/include/TribitsExProj_version.h"
        "Installing: .+/install/lib/cmake/TribitsExProj/TribitsExProjConfig.cmake"
        "Installing: .+/install/lib/cmake/TribitsExProj/TribitsExProjConfigVersion.cmake"
        "Installing: .+/install/include/TribitsExProjConfig.cmake"
        "Installing: .+/install/lib/cmake/SimpleCxx/SimpleCxxConfig.cmake"
        "Installing: .+/install/lib/cmake/SimpleCxx/SimpleCxxTargets.cmake"
        "Installing: .+/install/lib/cmake/SimpleCxx/SimpleCxxTargets-release.cmake"
        "Installing: .+/install/lib/libsimplecxx${libExtRegex}"
        "Installing: .+/install/include/SimpleCxx_HelloWorld.hpp"
        "Installing: .+/install/lib/cmake/WithSubpackages/WithSubpackagesConfig.cmake"
        "Installing: .+/install/lib/libpws_a${libExtRegex}"
        "Installing: .+/install/include/A.hpp"
        "Installing: .+/install/lib/cmake/WithSubpackagesA/WithSubpackagesAConfig.cmake"
        "Installing: .+/install/lib/cmake/WithSubpackagesA/WithSubpackagesATargets.cmake"
        "Installing: .+/install/lib/cmake/WithSubpackagesA/WithSubpackagesATargets-release.cmake"
        "Installing: .+/install/lib/libpws_b${libExtRegex}"
        "Installing: .+/install/include/B.hpp"
        "Installing: .+/install/lib/cmake/WithSubpackagesB/WithSubpackagesBConfig.cmake"
        "Installing: .+/install/lib/cmake/WithSubpackagesB/WithSubpackagesBTargets.cmake"
        "Installing: .+/install/lib/cmake/WithSubpackagesB/WithSubpackagesBTargets-release.cmake"
        "Installing: .+/install/lib/libpws_c${libExtRegex}"
        "Installing: .+/install/include/wsp_c/C.hpp"
        "Installing: .+/install/lib/cmake/WithSubpackagesC/WithSubpackagesCConfig.cmake"
        "Installing: .+/install/lib/cmake/WithSubpackagesC/WithSubpackagesCTargets.cmake"
        "Installing: .+/install/lib/cmake/WithSubpackagesC/WithSubpackagesCTargets-release.cmake"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_7
      MESSAGE "Create and configure a dummy project that calls"
        " find_package(WithSubpackages) from the install tree"
      CMND ${CMAKE_COMMAND}
      ARGS
        -DDUMMY_PROJECT_NAME=DummyProject
        -DDUMMY_PROJECT_DIR=dummy_client_of_WithSubpackages
        -DEXPORT_VAR_PREFIX=WithSubpackages
        -DFIND_PACKAGE_NAME=WithSubpackages
        -DCMAKE_PREFIX_PATH=../install
        -DCMAKE_COMMAND=${CMAKE_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
      PASS_REGULAR_EXPRESSION_ALL
        "Calling: find_package[(]WithSubpackages REQUIRED COMPONENTS  OPTIONAL_COMPONENTS  [)]"
        "WithSubpackages_CMAKE_BUILD_TYPE = 'RELEASE'"
        "WithSubpackages_CXX_COMPILER = '${CMAKE_CXX_COMPILER_FOR_REGEX}'"
        "WithSubpackages_C_COMPILER = '${CMAKE_C_COMPILER_FOR_REGEX}'"
        "WithSubpackages_Fortran_COMPILER = ''"
        "WithSubpackages_FORTRAN_COMPILER = ''"
        "WithSubpackages_CXX_FLAGS = '.*'"
        "WithSubpackages_C_FLAGS = '.*'"
        "WithSubpackages_Fortran_FLAGS = '.*'"
        "WithSubpackages_EXTRA_LD_FLAGS = '.*'"
        "WithSubpackages_SHARED_LIB_RPATH_COMMAND = '.*'"
        "WithSubpackages_BUILD_SHARED_LIBS = '.*'"
        "WithSubpackages_LINKER = '.+'"
        "WithSubpackages_AR = '.+'"
        "WithSubpackages_INSTALL_DIR = '.+/install'"
        "WithSubpackages_LIBRARIES = 'WithSubpackages::all_libs'"
        "WithSubpackages_MPI_LIBRARIES = ''"
        "WithSubpackages_MPI_LIBRARY_DIRS = ''"
        "WithSubpackages_MPI_INCLUDE_DIRS = ''"
        "WithSubpackages_MPI_EXEC = '${MPI_EXEC}'"
        "WithSubpackages_MPI_EXEC_MAX_NUMPROCS = '${MPI_EXEC_MAX_NUMPROCS}'"
        "WithSubpackages_MPI_EXEC_NUMPROCS_FLAG = '${MPI_EXEC_NUMPROCS_FLAG}'"
        "WithSubpackages_FOUND = '1'"
        "WithSubpackages::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackagesA::pws_a[;]WithSubpackagesA::all_libs[;]WithSubpackagesB::pws_b[;]WithSubpackagesB::all_libs[;]WithSubpackagesC::pws_c[;]WithSubpackagesC::all_libs'"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_8
      MESSAGE "Create and configure a dummy project that calls"
        " find_package(TribitsExProj) with no components"
      CMND ${CMAKE_COMMAND}
      ARGS
        -DDUMMY_PROJECT_NAME=DummyProject
        -DDUMMY_PROJECT_DIR=dummy_client_of_TribitsExProj
        -DEXPORT_VAR_PREFIX=TribitsExProj
        -DFIND_PACKAGE_NAME=TribitsExProj
        -DCMAKE_PREFIX_PATH=../install
        -DCMAKE_COMMAND=${CMAKE_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
      PASS_REGULAR_EXPRESSION_ALL
        "DUMMY_PROJECT_NAME = 'DummyProject'"
        "DUMMY_PROJECT_DIR = 'dummy_client_of_TribitsExProj'"
        "EXPORT_VAR_PREFIX = 'TribitsExProj'"
        "CMAKE_COMMAND = '${CMAKE_COMMAND}"
        "Create the dummy client directory ..."
        "Create dummy dummy_client_of_TribitsExProj/CMakeLists.txt file ..."
        "Configure the dummy project to print the variables in .*/${testName}/dummy_client_of_TribitsExProj ..."
        "DUMMY_PROJECT_NAME = 'DummyProject'"
        "EXPORT_VAR_PREFIX = 'TribitsExProj'"
        "Calling: find_package[(]TribitsExProj REQUIRED COMPONENTS  OPTIONAL_COMPONENTS  [)]"
        "TribitsExProj_CMAKE_BUILD_TYPE = 'RELEASE'"
        "TribitsExProj_CXX_COMPILER = '${CMAKE_CXX_COMPILER_FOR_REGEX}'"
        "TribitsExProj_C_COMPILER = '${CMAKE_C_COMPILER_FOR_REGEX}'"
        "TribitsExProj_Fortran_COMPILER = ''"
        "TribitsExProj_FORTRAN_COMPILER = ''"
        "TribitsExProj_CXX_FLAGS = ''"
        "TribitsExProj_C_FLAGS = ''"
        "TribitsExProj_Fortran_FLAGS = ''"
        "TribitsExProj_EXTRA_LD_FLAGS = '" # This is non-empty on some platforms but we can't know what it is :-(
        "TribitsExProj_SHARED_LIB_RPATH_COMMAND = '${TribitsExProj_SHARED_LIB_RPATH_COMMAND_REGEX}'"
        "TribitsExProj_BUILD_SHARED_LIBS = '${BUILD_SHARED_LIBS_VAL}'"
        "TribitsExProj_LINKER = '.*'"
        "TribitsExProj_AR = '.*'"
        "TribitsExProj_INSTALL_DIR = '.*/${testName}/install'"
        "TribitsExProj_INCLUDE_DIRS = '.*/${testName}/install/include'"
        "TribitsExProj_LIBRARIES = 'WithSubpackages::all_libs;WithSubpackagesC::all_libs;WithSubpackagesB::all_libs;WithSubpackagesA::all_libs;SimpleCxx::all_libs'"
        "TribitsExProj_MPI_LIBRARIES = ''"
        "TribitsExProj_MPI_LIBRARY_DIRS = ''"
        "TribitsExProj_MPI_INCLUDE_DIRS = ''"
        "TribitsExProj_MPI_EXEC = '.*'"
        "TribitsExProj_MPI_EXEC_MAX_NUMPROCS = '[1-9]*'"  # Is null for an MPI build
        "TribitsExProj_MPI_EXEC_NUMPROCS_FLAG = '.*'"
        "TribitsExProj_PACKAGE_LIST = 'WithSubpackages[;]WithSubpackagesC[;]WithSubpackagesB[;]WithSubpackagesA[;]SimpleCxx'"
        "TribitsExProj_SELECTED_PACKAGE_LIST = 'WithSubpackages[;]WithSubpackagesC[;]WithSubpackagesB[;]WithSubpackagesA[;]SimpleCxx'"
        "TribitsExProj::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackages::all_libs[;]WithSubpackagesC::all_libs[;]WithSubpackagesB::all_libs[;]WithSubpackagesA::all_libs[;]SimpleCxx::all_libs'"
        "TribitsExProj::all_selected_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackages::all_libs[;]WithSubpackagesC::all_libs[;]WithSubpackagesB::all_libs[;]WithSubpackagesA::all_libs[;]SimpleCxx::all_libs'"
        "TribitsExProj_TPL_LIST = '${TribitsExProj_TPL_LIST}'"
        "-- Configuring done"
        "-- Generating done"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_9
      MESSAGE "Create and configure a dummy project that calls find_package(TribitsExProj)"
        " with required and optional components"
      CMND ${CMAKE_COMMAND}
      ARGS
        -DDUMMY_PROJECT_NAME=DummyProject
        -DDUMMY_PROJECT_DIR=dummy_client_of_TribitsExProj_with_components
        -DEXPORT_VAR_PREFIX=TribitsExProj
        -DFIND_PACKAGE_NAME=TribitsExProj
        -DFIND_PACKAGE_COMPONENTS=SimpleCxx,WithSubpackagesB
        -DFIND_PACKAGE_OPTIONAL_COMPONENTS=WithSubpackagesC,DoesNotExist,WithSubpackagesA
        -DCMAKE_PREFIX_PATH=../install
        -DCMAKE_COMMAND=${CMAKE_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
      PASS_REGULAR_EXPRESSION_ALL
        "Calling: find_package[(]TribitsExProj REQUIRED COMPONENTS SimpleCxx[;]WithSubpackagesB OPTIONAL_COMPONENTS WithSubpackagesC[;]DoesNotExist[;]WithSubpackagesA [)]"
        "TribitsExProj_PACKAGE_LIST = 'WithSubpackages[;]WithSubpackagesC[;]WithSubpackagesB[;]WithSubpackagesA[;]SimpleCxx'"
        "TribitsExProj_SELECTED_PACKAGE_LIST = 'SimpleCxx[;]WithSubpackagesB[;]WithSubpackagesC[;]WithSubpackagesA'"
        "TribitsExProj_SimpleCxx_FOUND = 'TRUE'"
        "TribitsExProj_WithSubpackagesB_FOUND = 'TRUE'"
        "TribitsExProj_WithSubpackagesC_FOUND = 'TRUE'"
        "TribitsExProj_DoesNotExist_FOUND = 'FALSE'"
        "TribitsExProj_WithSubpackagesA_FOUND = 'TRUE'"
        "TribitsExProj_FOUND = '1'"
        "TribitsExProj::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackages::all_libs[;]WithSubpackagesC::all_libs[;]WithSubpackagesB::all_libs[;]WithSubpackagesA::all_libs[;]SimpleCxx::all_libs'"
        "TribitsExProj::all_selected_libs  INTERFACE_LINK_LIBRARIES: 'SimpleCxx::all_libs[;]WithSubpackagesB::all_libs[;]WithSubpackagesC::all_libs[;]WithSubpackagesA::all_libs'"
        "-- Configuring done"
        "-- Generating done"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    TEST_10
      MESSAGE "Run find_package() from two different subdirs with related packages"
      WORKING_DIRECTORY find_package_two_dirs
      CMND ${CMAKE_COMMAND}
      ARGS
        -DCMAKE_PREFIX_PATH=${testDir}/install
        ${CMAKE_CURRENT_SOURCE_DIR}/find_package_two_dirs
      PASS_REGULAR_EXPRESSION_ALL
        "WithSubpackagesA_FOUND = '1'"
        "WithSubpackagesB_FOUND = '1'"
        "-- Configuring done"
        "-- Generating done"
      ALWAYS_FAIL_ON_NONZERO_RETURN

    )

endfunction()
#
# The above tests a *lot* of TriBITS functionality that may not be tested in
# any other system-level test.  Here is a list of things tested that may not
# be tested in any other such system-level test for TriBITS:
#
# * Tests TribitsExProj_TRACE_FILE_PROCESSING=ON and the output it produces
#
# * Tests TribitsExProj_ENABLE_CPACK_PACKAGING=ON and the output it produces
#
# * Tests TribitsExProj_DUMP_CPACK_SOURCE_IGNORE_FILES=ON and the output it produces
#
# * Tests TribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON and the output it
#   produces
#
# * Tests usage of <Package>Config.cmake files in the build tree (but just
#   that they load, does not link anything)
#
# * Tests installing with <Package>Config.cmake and <Project>Config.cmake
#   files
#
# * Tests calling find_package() with <Package>Config.cmake and
#   <Project>Config.cmake from the install tree and checks all of the data
#   provided by these.
#
# * Tests find_package(<Project> COMPONENTS ... OPTIONAL_COMPONENTS ...) with
#   missing optional components and verifies that they are excluded from the
#   <Project>::all_selected_libs target and the
#   <Project>_SELECTED_PACKAGE_LIST variable.
#
# * Test calling find_package(<Package>) from different subdirs for related
#   packages works (see TriBiTS GitHub issue #505).
#
# * Creates source tarball, untars it, and checks its contents removed
#
# * ???
#
#


TribitsExampleProject_ALL_ST_NoFortran(STATIC  SERIAL)
TribitsExampleProject_ALL_ST_NoFortran(SHARED  MPI)


########################################################################


tribits_add_advanced_test( TribitsExampleProject_NoFortran_reduced_tarball
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Darwin
  LIST_SEPARATOR <semicolon>

  TEST_0
    MESSAGE "Do the initial configure selecting the packages to go into the reduced tarball"
    WORKING_DIRECTORY BUILD
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
      -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_WithSubpackagesB=ON
      -DTribitsExProj_EXCLUDE_DISABLED_SUBPACKAGES_FROM_DISTRIBUTION=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DTribitsExProj_ENABLE_CPACK_PACKAGING=ON
      -DTribitsExProj_DUMP_CPACK_SOURCE_IGNORE_FILES=ON
      -DCPACK_SOURCE_IGNORE_FILES=LICENSE<semicolon>README.md
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackagesB WithSubpackages 4"
      "Final set of non-enabled top-level packages:  MixedLang WrapExternal 2"
      "Final set of non-enabled packages:  MixedLang WithSubpackagesC WrapExternal 3"
      "Exclude files when building source packages:"
      "/...git/"  # /[.]git/
      "...gitignore[$]"  # [.]gitignore$ 
      ".*/tribits/examples/TribitsExampleProject/cmake/ctest/"
      "-- Configuring done"
      "-- Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1
    MESSAGE "Create the tarball"
    WORKING_DIRECTORY BUILD
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND make ARGS package_source
    PASS_REGULAR_EXPRESSION_ALL
      "Run CPack packaging tool for source..."
      "CPack: Create package using TGZ"
      "CPack: Install projects"
      "CPack: - Install directory: .*/examples/TribitsExampleProject"
      "CPack: Create package"
      "CPack: - package: .*/BUILD/tribitsexproj-1.1-Source.tar.gz generated."
      "CPack: Create package using TBZ2"
      "CPack: Install projects"
      "CPack: - Install directory: .*/examples/TribitsExampleProject"
      "CPack: Create package"
      "CPack: - package: .*/BUILD/tribitsexproj-1.1-Source.tar.bz2 generated."
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2
    MESSAGE "Untar the tarball"
    CMND tar ARGS -xzvf BUILD/tribitsexproj-1.1-Source.tar.gz
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_3
    MESSAGE "Make sure right directories are excluded"
    CMND diff
    ARGS -qr
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
      tribitsexproj-1.1-Source
    PASS_REGULAR_EXPRESSION_ALL
      "Only in .*/TribitsExampleProject/cmake: ctest"
      ${REGEX_FOR_GITIGNORE}
      "Only in .*/TribitsExampleProject: .gitignore"
      "Only in .*/TribitsExampleProject: LICENSE"
      "Only in .*/TribitsExampleProject: README.md"
      "Only in .*/TribitsExampleProject/packages: mixed_lang"
      "Only in .*/TribitsExampleProject/packages: wrap_external"
      "Only in .*/TribitsExampleProject/packages/with_subpackages/b: ExcludeFromRelease.txt"
      "Only in .*/TribitsExampleProject/packages/with_subpackages/b/src: AlsoExcludeFromTarball.txt"
      "Only in .*/TribitsExampleProject/packages/with_subpackages: c"
    # NOTE: We don't check return code because diff returns nonzero

  TEST_4
    MESSAGE "Make empty base dir for packages/mixed_lang to trigger error"
    CMND ${CMAKE_COMMAND}
    ARGS -E make_directory tribitsexproj-1.1-Source/packages/mixed_lang

  TEST_5
    MESSAGE "Configure from the untarred reduced source tree"
    WORKING_DIRECTORY BUILD2
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
      -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ASSERT_DEFINED_DEPENDENCIES=WARNING
      ../tribitsexproj-1.1-Source
    PASS_REGULAR_EXPRESSION_ALL
      "CMake Warning at .*/tribits/core/package_arch/TribitsProcessPackagesAndDirsLists.cmake"
      "MixedLang: Package base directory"
      "'.*/tribitsexproj-1.1-Source/packages/mixed_lang'"
      "exists but the dependencies file"
      "'.*/tribitsexproj-1.1-Source/packages/mixed_lang/cmake/Dependencies.cmake'"
      "does [*]NOT[*] exist. Package is being ignored anyway."
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackagesB WithSubpackages 4"
      "Final set of non-enabled top-level packages:  0"
      "Final set of non-enabled packages:  0"
      "Processing enabled top-level package: SimpleCxx [(]Libs, Tests, Examples[)]"
      "Processing enabled top-level package: WithSubpackages [(]A, B, Tests, Examples[)]"
      "-- Configuring done"
      "-- Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_6
    MESSAGE "Build reduced project default 'all' target using raw 'make'"
    WORKING_DIRECTORY BUILD2
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target simplecxx"
      "Built target pws_a"
      "Built target pws_b"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_7
    MESSAGE "Run all the tests in reduced project with raw 'ctest'"
    WORKING_DIRECTORY BUILD2
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND ${CMAKE_CTEST_COMMAND} ARGS
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
      "SimpleCxx_HelloWorldProg${TEST_MPI_1_SUFFIX} .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "WithSubpackagesB_test_of_b .* Passed"
      "100% tests passed, 0 tests failed out of 4"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )
# NOTE: The above test checks that a reduced source tarball can be created and
# can be configured from the resourced source tree.


########################################################################


if (NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")

  execute_process(COMMAND whoami
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE  TribitsExProj_INSTALL_OWNING_USER)

  if ("${TribitsExProj_INSTALL_OWNING_GROUP}" STREQUAL "")
    execute_process(COMMAND id -gn
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE  TribitsExProj_INSTALL_OWNING_GROUP)
  endif()

endif()


if ( ${PROJECT_NAME}_ENABLE_Fortran )
  set(mixedLangHeaderRegex
    "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* MixedLang.hpp")
else()
  set(mixedLangHeaderRegex "")
endif()


tribits_add_advanced_test( TribitsExampleProject_install_perms
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Windows

  TEST_0
    MESSAGE "Copy TribitsExampleProject so we can change the source permissions"
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Make TribitsExampleProject source dir user rwX only!"
    CMND chmod
    ARGS -R g-rwx,o-rwx TribitsExampleProject

  TEST_2
    MESSAGE "Do initial configure with just libs not tests with default install settings"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_WithSubpackages=ON
      -DCMAKE_INSTALL_PREFIX=install_base/install
      -DTribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR=install_base
      -DTribitsExProj_MAKE_INSTALL_WORLD_READABLE=TRUE
      -DTribitsExProj_MAKE_INSTALL_GROUP_WRITABLE=TRUE
      -DTribitsExProj_MAKE_INSTALL_GROUP=${TribitsExProj_INSTALL_OWNING_GROUP}
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_3
    MESSAGE "Do make to build everything"
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_4
    MESSAGE "Make install with fixup of permissions"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install
    PASS_REGULAR_EXPRESSION_ALL
      ".*/install_base/install/include/wsp_c/C.hpp"
      ".*/install_base/install/lib/libpws_c.a"
      "0: Running: chgrp ${TribitsExProj_INSTALL_OWNING_GROUP} /.*/TriBITS_TribitsExampleProject_install_perms/install_base"
      "0: Running: chmod g[+]rwX,o[+]rX /.*/TriBITS_TribitsExampleProject_install_perms/install_base"
      "1: Running: chgrp -R ${TribitsExProj_INSTALL_OWNING_GROUP} /.*/TriBITS_TribitsExampleProject_install_perms/install_base/install"
      "1: Running: chmod -R g[+]rwX,o[+]rX /.*/TriBITS_TribitsExampleProject_install_perms/install_base/install"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_5
    MESSAGE "Check some installed directory permissions and the owning group"
    CMND ls ARGS -ld
      install_base
      install_base/install
      install_base/install/bin
      install_base/install/include
      install_base/install/lib
      install_base/install/share/WithSubpackagesB/stuff
    PASS_REGULAR_EXPRESSION_ALL
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/install"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/install/bin"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/install/include"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/install/lib"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/install/share/WithSubpackagesB/stuff"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_6
    MESSAGE "Check some installed file permissions"
    CMND ls ARGS -l
      install_base/install
      install_base/install/include
      install_base/install/include/wsp_c
      install_base/install/lib
      install_base/install/bin
      install_base/install/share/WithSubpackagesB/stuff
    PASS_REGULAR_EXPRESSION_ALL
      "${mixedLangHeaderRegex}"
      "[d]rwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* wsp_c"
      "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* C.hpp"
      "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* libpws_c.a"
      "[-]rwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* exec_script.sh"
      "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* regular_file.txt"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_7
    MESSAGE "Make sure that exec_script.sh is executable"
    CMND ./install_base/install/share/WithSubpackagesB/stuff/exec_script.sh
    PASS_REGULAR_EXPRESSION
      "exec_script.sh executed and returned this string"

  )
  # NOTE: The above test checks a few important things:
  #
  # * The CMake install machinery will actually create multiple base dirs
  #   under ${CMAKE_INSTALL_PREFIX} in case they don't already exist.
  #
  # * The group ownership actually will be set correctly starting with
  #   ${<Project>_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR} which is
  #   above ${CMAKE_INSTALL_PREFIX}.  This is needed to address systems where
  #   the group sticky bit is disabled (like we see on some SNL systems, see
  #   ATDV-241).
  #
  # * Even with the source directory permissions being 'rwx------' (i.e. 700),
  #   the files installed under share/WithSubpackagesB/stuff using
  #   install(DIRECTORY ... USE_SOURCE_PERMISSIONS) will actually have the
  #   correct group and other permissions set.


########################################################################


if ( ${PROJECT_NAME}_ENABLE_Fortran )
  set(mixedLangHeaderRegex
    "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* MixedLang.hpp")

else()
  set(mixedLangHeaderRegex "")
endif()

tribits_add_advanced_test( TribitsExampleProject_install_package_by_package_perms
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Windows

  TEST_0
    MESSAGE "Copy TribitsExampleProject so we can change the source permissions"
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Break the WithSubpackagesB so that it will not install"
    CMND ${CMAKE_CURRENT_SOURCE_DIR}/append_file_with_line.sh
    ARGS TribitsExampleProject/packages/with_subpackages/c/C.cpp
      "C.cpp is broken!"

  TEST_2
    MESSAGE "Make TribitsExampleProject source dir user rwX only!"
    CMND chmod
    ARGS -R g-rwx,o-rwx TribitsExampleProject

  TEST_3
    MESSAGE "Do initial configure with just libs not tests with default install settings"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_WithSubpackages=ON
      -DCMAKE_INSTALL_PREFIX=install_base/subdir/install
      -DTribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR=install_base
      -DTribitsExProj_MAKE_INSTALL_WORLD_READABLE=TRUE
      -DTribitsExProj_MAKE_INSTALL_GROUP_WRITABLE=TRUE
      -DTribitsExProj_MAKE_INSTALL_GROUP=${TribitsExProj_INSTALL_OWNING_GROUP}
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_4
    MESSAGE "Do make -k to build everything that will build"
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "C.cpp is broken"
      "packages/with_subpackages/c/CMakeFiles/pws_c.dir/C.cpp.o.*Error"
    ALWAYS_FAIL_ON_ZERO_RETURN

  TEST_5
    MESSAGE "Make install_pakage_by_package with fixup of permissions"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install_package_by_package
    PASS_REGULAR_EXPRESSION_ALL
      "The global install failed so resorting to package-by-package installs"
      ".*/install_base/subdir/install/include/B.hpp"
      ".*/install_base/subdir/install/lib/libpws_b.a"
      "0: Running: chgrp ${TribitsExProj_INSTALL_OWNING_GROUP} /.*/TriBITS_TribitsExampleProject_install_package_by_package_perms/install_base"
      "0: Running: chmod g[+]rwX,o[+]rX /.*/TriBITS_TribitsExampleProject_install_package_by_package_perms/install_base"
      "1: Running: chgrp ${TribitsExProj_INSTALL_OWNING_GROUP} /.*/TriBITS_TribitsExampleProject_install_package_by_package_perms/install_base/subdir"
      "1: Running: chmod g[+]rwX,o[+]rX /.*/TriBITS_TribitsExampleProject_install_package_by_package_perms/install_base/subdir"
      "2: Running: chgrp -R ${TribitsExProj_INSTALL_OWNING_GROUP} /.*/TriBITS_TribitsExampleProject_install_package_by_package_perms/install_base/subdir/install"
      "2: Running: chmod -R g[+]rwX,o[+]rX /.*/TriBITS_TribitsExampleProject_install_package_by_package_perms/install_base/subdir/install"
    ALWAYS_FAIL_ON_ZERO_RETURN

  TEST_6
    MESSAGE "Check some installed directory permissions and the owning group"
    CMND ls ARGS -ld
      install_base
      install_base/subdir
      install_base/subdir/install
      install_base/subdir/install/bin
      install_base/subdir/install/include
      install_base/subdir/install/lib
      install_base/subdir/install/share/WithSubpackagesB/stuff
    PASS_REGULAR_EXPRESSION_ALL
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/subdir"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/subdir/install"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/subdir/install/bin"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/subdir/install/include"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/subdir/install/lib"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* install_base/subdir/install/share/WithSubpackagesB/stuff"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_7
    MESSAGE "Check some installed file permissions"
    CMND ls ARGS -l
      install_base/subdir/install
      install_base/subdir/install/include
      install_base/subdir/install/lib
      install_base/subdir/install/bin
      install_base/subdir/install/share/WithSubpackagesB/stuff
    PASS_REGULAR_EXPRESSION_ALL
      "${mixedLangHeaderRegex}"
      "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* B.hpp"
      "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* libpws_b.a"
      "[-]rwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* exec_script.sh"
      "[-]rw-rw-r--.* .* ${TribitsExProj_INSTALL_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* regular_file.txt"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_8
    MESSAGE "Make sure that exec_script.sh is executable"
    CMND ./install_base/subdir/install/share/WithSubpackagesB/stuff/exec_script.sh
    PASS_REGULAR_EXPRESSION
      "exec_script.sh executed and returned this string"

  )
  # NOTE: In addition to the same checks performed by the test
  # TribitsExampleProject_install_perms described above, this above test also:
  #
  # * Ensures that the non-recursive group and permissions gets set on
  # * base-dirs.
  #
  # * Ensures that owning group and directory permissions get set even if
  #   there is a package install failure.  The other packages that did build
  #   correctly will get installed and all of the files and directories that
  #   did install will have the correct group and permissions.


########################################################################


if (NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(TribitsExProj_INSTALL_BASE_DIR "" CACHE FILEPATH
    "Path to a base directory that installs will be made into that is not owned by the current user but is in the same owning group and has group write access"
    )
  if (TribitsExProj_INSTALL_BASE_DIR)
    execute_process(COMMAND stat -c %U "${TribitsExProj_INSTALL_BASE_DIR}"
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE  TribitsExProj_INSTALL_BASE_OWNING_USER)
  endif()
  set(installBaseDir "${TribitsExProj_INSTALL_BASE_DIR}")
  set(installPrefixBaseDir
    "${installBaseDir}/TribitsExampleProject_install_perms_nonowning_base_dir")
  set(installPrefix
    "${installPrefixBaseDir}/install")
  if ("${TribitsExProj_INSTALL_BASE_OWNING_USER}"
    STREQUAL "${TribitsExProj_INSTALL_OWNING_USER}"
    )
    set(CHGRP_CHMOD_BASE_TEXT
      "0: Running: chgrp wg-sems-users-son ${${PROJECT_NAME}_INSTALL_BASE_DIR}"
      "0: Running: chmod g[+]rwX,o[+]rX ${${PROJECT_NAME}_INSTALL_BASE_DIR}")
  else()
    set(CHGRP_CHMOD_BASE_TEXT
      "0: NOTE: Not calling chgrp and chmod on ${installBaseDir} since owner '${TribitsExProj_INSTALL_BASE_OWNING_USER}' != current owner '${TribitsExProj_INSTALL_OWNING_USER}'!")
  endif()
endif()


########################################################################


tribits_add_advanced_test( TribitsExampleProject_install_perms_nonowning_base_dir
  OVERALL_WORKING_DIRECTORY TEST_NAME
  EXCLUDE_IF_NOT_TRUE TribitsExProj_INSTALL_BASE_DIR
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Windows

  TEST_0
    MESSAGE "Copy TribitsExampleProject so we can change the source permissions"
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Make TribitsExampleProject source dir user rwX only!"
    CMND chmod
    ARGS -R g-rwx,o-rwx TribitsExampleProject

  TEST_2
    MESSAGE "Remove existing intermediate base install if exists"
    CMND ${CMAKE_CURRENT_SOURCE_DIR}/remove-dir-if-exists.sh
    ARGS ${installPrefixBaseDir}

  TEST_3
    MESSAGE "Do initial configure with just libs not tests with default install settings"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_WithSubpackages=ON
      -DCMAKE_INSTALL_PREFIX=${installPrefix}
      -DTribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR=${installBaseDir}
      -DTribitsExProj_MAKE_INSTALL_WORLD_READABLE=TRUE
      -DTribitsExProj_MAKE_INSTALL_GROUP_WRITABLE=TRUE
      -DTribitsExProj_MAKE_INSTALL_GROUP=${TribitsExProj_INSTALL_OWNING_GROUP}
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_4
    MESSAGE "Do make to build everything"
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_5
    MESSAGE "Make install with fixup of permissions"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install
    PASS_REGULAR_EXPRESSION_ALL
      "${installPrefix}/include/wsp_c/C.hpp"
      "${installPrefix}/lib/libpws_c.a"
      "${CHGRP_CHMOD_BASE_TEXT}"
      "1: Running: chgrp ${TribitsExProj_INSTALL_OWNING_GROUP} ${installPrefixBaseDir}"
      "1: Running: chmod g[+]rwX,o[+]rX ${installPrefixBaseDir}"
      "2: Running: chgrp -R ${TribitsExProj_INSTALL_OWNING_GROUP} ${installPrefix}"
      "2: Running: chmod -R g[+]rwX,o[+]rX ${installPrefix}"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_6
    MESSAGE "Check some installed directory permissions and the owning group"
    CMND ls ARGS -ld
      ${installBaseDir}
      ${installPrefixBaseDir}
      ${installPrefix}
      ${installPrefix}/bin
      ${installPrefix}/include
      ${installPrefix}/lib
      ${installPrefix}/share/WithSubpackagesB/stuff
    PASS_REGULAR_EXPRESSION_ALL
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_BASE_OWNING_USER} *${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installBaseDir}"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} +${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installPrefixBaseDir}"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} +${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installPrefix}"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} +${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installPrefix}/bin"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} +${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installPrefix}/include"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} +${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installPrefix}/lib"
      "drwxrw[xs]r-x.* .* ${TribitsExProj_INSTALL_OWNING_USER} +${TribitsExProj_INSTALL_OWNING_GROUP} .* ${installPrefix}/share/WithSubpackagesB/stuff"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )
  # NOTE: The above test ensures that if a base dir under
  # ${TribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR} is not
  # owned by the current user then chgrp will not be run on it and will avoid
  # an error.


########################################################################


tribits_add_advanced_test( TribitsExampleProject_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR_not_base_dir
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Windows

  TEST_0
    MESSAGE "Configure with TribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR not a base dir of CMAKE_INSTALL_PREFIX "
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DCMAKE_INSTALL_PREFIX=install_base/install
      -DTribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR=non_base_dir
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "ERROR in TribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR"
      "TribitsExProj_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR=.*/TriBITS_TribitsExampleProject_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR_not_base_dir/non_base_dir"
      "is not a strict base dir of"
      "CMAKE_INSTALL_PREFIX=.*/TriBITS_TribitsExampleProject_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR_not_base_dir/install_base/install"
    ALWAYS_FAIL_ON_ZERO_RETURN

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_ST_NoFortran_enable_installation_testing
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Darwin

  TEST_0
    MESSAGE "Copy the TribitsExampleProject locally so we can move it after install"
    WORKING_DIRECTORY BUILD_LIBS
    CMND ${CMAKE_COMMAND}
    ARGS -E copy_directory
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
      TribitsExampleProject

  TEST_1
    MESSAGE "Do the initial configure of just the libraries"
    WORKING_DIRECTORY BUILD_LIBS/BUILD
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}_TribitsExampleProject_ALL_ST_NoFortran_enable_installation_testing/install
      ../TribitsExampleProject

  TEST_2
    MESSAGE "Do Make install "
    WORKING_DIRECTORY BUILD_LIBS/BUILD
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND make ARGS ${CTEST_BUILD_FLAGS} install

  TEST_3
    MESSAGE "Move BUILD_LIBS dir to a subdir to make sure install is independent of build and source tree"
    WORKING_DIRECTORY BUILD_LIBS_MOVED_BASE
    CMND mv ARGS ../BUILD_LIBS .

  TEST_4
    MESSAGE "Copy the TribitsExampleProject locally so we can remove some libs source and header files"
    WORKING_DIRECTORY BUILD_TESTS
    CMND ${CMAKE_COMMAND}
    ARGS -E copy_directory
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
      TribitsExampleProject

  TEST_5
    MESSAGE "Remove some lib source files from local TribitsExampleProject source tree"
    CMND rm ARGS
      BUILD_TESTS/TribitsExampleProject/packages/simple_cxx/src/SimpleCxx_HelloWorld.cpp
      BUILD_TESTS/TribitsExampleProject/packages/with_subpackages/a/A.cpp
      BUILD_TESTS/TribitsExampleProject/packages/with_subpackages/b/src/B.cpp
      BUILD_TESTS/TribitsExampleProject/packages/with_subpackages/c/C.cpp

  TEST_6
    MESSAGE "Break a lib header file in the source tree to ensure include path does not find them"
    CMND ${CMAKE_CURRENT_SOURCE_DIR}/append_line_to_files.sh ARGS "This header file is broken"
      BUILD_TESTS/TribitsExampleProject/packages/with_subpackages/a/A.hpp
      BUILD_TESTS/TribitsExampleProject/packages/with_subpackages/b/src/B.hpp
      BUILD_TESTS/TribitsExampleProject/packages/with_subpackages/c/wsp_c/C.hpp

  TEST_7
    MESSAGE "Do the configure of just the tests/examples pointing to existing install"
    WORKING_DIRECTORY BUILD_TESTS/BUILD
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DTribitsExProj_ENABLE_INSTALLATION_TESTING=ON
      -DTribitsExProj_INSTALLATION_DIR=${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}_TribitsExampleProject_ALL_ST_NoFortran_enable_installation_testing/install
      ../TribitsExampleProject

  TEST_8
    MESSAGE "Build 'all' target"
    WORKING_DIRECTORY BUILD_TESTS/BUILD
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND make ARGS ${CTEST_BUILD_FLAGS}

  TEST_9
    MESSAGE "Run all the tests with ctest"
    WORKING_DIRECTORY BUILD_TESTS/BUILD
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "WithSubpackagesB_test_of_b .* Passed"
      "WithSubpackagesC_test_of_c .* Passed"
      "WithSubpackagesC_test_of_c_util.* Passed"
      "100% tests passed, 0 tests failed out of 6"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )
# NOTE: Above is a very strong test that ensures that the
# <Project>_ENABLE_INSTALLATION_TESTING option works as it should.  It removes
# source files from the installation testing source tree which shows that
# those files are not being built.  It also leaves the library header files
# but it breaks them to ensure that they do not get selected therefore include
# dirs from the source tree are not added.  Since the include directories from
# the installed project are pulled in with -isystem, the -I for the local
# source tree would be searched first.  Therefore, this test shows that those
# -I directories are not added to the compile lines.  This above test also
# shows the installation of the non-Fortran packages in TribitsExampleProject
# works and is independent from the source and build trees.  If you comment
# out the cmake options TribitsExProj_ENABLE_INSTALLATION_TESTING and
# TribitsExProj_INSTALLATION_DIR you will see that build of the project fails
# because we removed some source files that are needed.  This proves that they
# are being used from the install tree!


########################################################################

tribits_add_advanced_test( TribitsExampleProject_ALL_ST_NoFortran_Ninja
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE  NINJA_EXE
  XHOSTTYPE Darwin

  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure with ninja"
    ARGS
      -GNinja
      -DTribitsExProj_WRITE_NINJA_MAKEFILES=OFF
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTPL_ENABLE_MPI=OFF
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_CPACK_PACKAGING=ON
      -DTribitsExProj_DUMP_CPACK_SOURCE_IGNORE_FILES=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DTribitsExProj_PARALLEL_COMPILE_JOBS_LIMIT=3
      -DTribitsExProj_PARALLEL_LINK_JOBS_LIMIT=2
      -DCMAKE_INSTALL_PREFIX=install
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
      "Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1
    MESSAGE "Verify TribitsExProj_PARALLEL_COMPILE_JOBS_LIMIT=3 has correct effect"
    CMND grep ARGS -A 1 compile_job_pool ${rulesNinjaFilePath}
    PASS_REGULAR_EXPRESSION
      "depth *= *3"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2
    MESSAGE "Verify TribitsExProj_PARALLEL_LINK_JOBS_LIMIT=2 has correct effect"
    CMND grep ARGS -A 1 link_job_pool ${rulesNinjaFilePath}
    PASS_REGULAR_EXPRESSION
      "depth *= *2"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_3 CMND ninja ARGS -j1 ${CTEST_BUILD_FLAGS}
    MESSAGE "Build the default 'all' target using raw 'ninja'"
    PASS_REGULAR_EXPRESSION_ALL
      "Linking CXX .* library .*simplecxx"
      "Linking CXX executable .*simplecxx-helloworld"
      "Linking CXX .* library .*pws_a"
      "Linking CXX .* library .*pws_b"
      "Linking CXX .* library .*pws_c"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  # ToDo: Add check of 'ninja" returns "ninja: no work to do"

  TEST_4 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "WithSubpackagesB_test_of_b .* Passed"
      "WithSubpackagesC_test_of_c .* Passed"
      "WithSubpackagesC_test_of_c_util.* Passed"
      "100% tests passed, 0 tests failed out of 6"

  TEST_5
      MESSAGE "Create and configure a dummy project that calls"
        " find_package(WithSubpackages) from the build tree"
      CMND ${CMAKE_COMMAND}
      ARGS
        -DDUMMY_PROJECT_NAME=DummyProject
        -DDUMMY_PROJECT_DIR=dummy_client_of_build_WithSubpackages
        -DEXPORT_VAR_PREFIX=WithSubpackages
        -DFIND_PACKAGE_NAME=WithSubpackages
        -DCMAKE_PREFIX_PATH=../cmake_packages
        -DCMAKE_COMMAND=${CMAKE_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
    PASS_REGULAR_EXPRESSION_ALL
      "WithSubpackages_INSTALL_DIR = '.*/TriBITS_TribitsExampleProject_ALL_ST_NoFortran_Ninja/install'"
      "WithSubpackages::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackagesA::pws_a[;]WithSubpackagesA::all_libs[;]WithSubpackagesB::pws_b[;]WithSubpackagesB::all_libs[;]WithSubpackagesC::pws_c[;]WithSubpackagesC::all_libs'"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_6 CMND ninja ARGS -j1 install ${CTEST_BUILD_FLAGS}
    MESSAGE "Build 'install' target using raw 'ninja'"
    PASS_REGULAR_EXPRESSION_ALL
      "Installing: .+/install/include/TribitsExProj_version.h"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_7
      MESSAGE "Create and configure a dummy project that calls"
        " find_package(WithSubpackages) from the install tree"
      CMND ${CMAKE_COMMAND}
      ARGS
        -DDUMMY_PROJECT_NAME=DummyProject
        -DDUMMY_PROJECT_DIR=dummy_client_of_WithSubpackages
        -DEXPORT_VAR_PREFIX=WithSubpackages
        -DFIND_PACKAGE_NAME=WithSubpackages
        -DCMAKE_PREFIX_PATH=../install
        -DCMAKE_COMMAND=${CMAKE_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
      PASS_REGULAR_EXPRESSION_ALL
        "Calling: find_package[(]WithSubpackages REQUIRED COMPONENTS  OPTIONAL_COMPONENTS  [)]"
        "WithSubpackages_FOUND = '1'"
        "WithSubpackages::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackagesA::pws_a[;]WithSubpackagesA::all_libs[;]WithSubpackagesB::pws_b[;]WithSubpackagesB::all_libs[;]WithSubpackagesC::pws_c[;]WithSubpackagesC::all_libs'"
      ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_8 CMND ninja ARGS -j1 package_source
    MESSAGE "Create the tarball"
    PASS_REGULAR_EXPRESSION_ALL
      "Run CPack packaging tool for source..."
      "CPack: - package: .*/ExamplesUnitTests/TriBITS_TribitsExampleProject_ALL_ST_NoFortran_Ninja/tribitsexproj-1.1-Source.tar.gz generated."
    ALWAYS_FAIL_ON_NONZERO_RETURN
    # Above should be 'make package_soruce' but the dummy makefiles don't
    # support that yet!

  TEST_9 CMND tar ARGS -xzf tribitsexproj-1.1-Source.tar.gz
    MESSAGE "Untar the tarball"

  TEST_10 CMND diff
     ARGS -qr
       ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
       tribitsexproj-1.1-Source
    MESSAGE "Make sure right directoires are excluced"
    PASS_REGULAR_EXPRESSION_ALL
      "Only in .*/TribitsExampleProject/cmake: ctest"
      ${REGEX_FOR_GITIGNORE}
      "Only in .*/TribitsExampleProject/packages: mixed_lang"
      "Only in .*/TribitsExampleProject/packages: wrap_external"
    # NOTE: We don't check the the return code form diff because it will
    # return nonzero if there are any differences

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_ST_NoFortran_Ninja_Makefiles
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE  NINJA_EXE
  XHOSTTYPE Darwin

  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure with ninja"
    ARGS
      -GNinja
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTPL_ENABLE_MPI=OFF
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_CPACK_PACKAGING=ON
      -DTribitsExProj_DUMP_CPACK_SOURCE_IGNORE_FILES=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DCMAKE_INSTALL_PREFIX=install
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
      "Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${MAKE_PARALLEL_ARG} ${CTEST_BUILD_FLAGS}
    MESSAGE "Build the default 'all' target using raw 'make'"
    PASS_REGULAR_EXPRESSION_ALL
      "Linking CXX .* library .*simplecxx"
      "Linking CXX executable .*simplecxx-helloworld"
      "Linking CXX .* library .*pws_a"
      "Linking CXX .* library .*pws_b"
      "Linking CXX .* library .*pws_c"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  # ToDo: Add check of 'make" returns "ninja: no work to do"

  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "WithSubpackagesB_test_of_b .* Passed"
      "WithSubpackagesC_test_of_c .* Passed"
      "WithSubpackagesC_test_of_c_util.* Passed"
      "100% tests passed, 0 tests failed out of 6"

  )


########################################################################


if (NOT ${PROJECT_NAME}_HOSTTYPE STREQUAL "Windows")

  set(minSecRegex "[0-9][0-9]*m[0-9][0-9]*[.][0-9][0-9]*s")

  tribits_add_advanced_test( TribitsExampleProject_ALL_PT_NoFortran_ConfigTiming
    OVERALL_WORKING_DIRECTORY TEST_NAME
    OVERALL_NUM_MPI_PROCS 1
    XHOSTTYPE Darwin

    TEST_0 CMND ${CMAKE_COMMAND}
      MESSAGE "Do the initial configure with basic configure timing"
      ARGS
        ${TribitsExampleProject_COMMON_CONFIG_ARGS}
        -DTribitsExProj_ENABLE_Fortran=OFF
        -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
        -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
        -DTribitsExProj_ENABLE_TESTS=ON
        -DTribitsExProj_ENABLE_CPACK_PACKAGING=ON
        -DTribitsExProj_ENABLE_CONFIGURE_TIMING=ON
        ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
      PASS_REGULAR_EXPRESSION_ALL
        "Total time to read in all dependencies files and build dependencies graph: ${minSecRegex}"
        "Total time to adjust package and TPL enables: ${minSecRegex}"
        "Total time to probe and setup the environment: ${minSecRegex}"
        "Total time to configure enabled external packages/TPLs: ${minSecRegex}"
        "Total time to configure enabled packages: ${minSecRegex}"
        "Total time to set up for CPack packaging: ${minSecRegex}"
        "Total time to configure TribitsExProj: ${minSecRegex}"
        "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
        "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackages 3"

    TEST_1 CMND ${CMAKE_COMMAND}
      MESSAGE "Reconfigure to test out timing of all packages"
      ARGS
        -DTribitsExProj_ENABLE_PACKAGE_CONFIGURE_TIMING=ON
        .
      PASS_REGULAR_EXPRESSION_ALL
        "Total time to read in all dependencies files and build dependencies graph: ${minSecRegex}"
        "Total time to adjust package and TPL enables: ${minSecRegex}"
        "Total time to probe and setup the environment: ${minSecRegex}"
        "Total time to configure enabled external packages/TPLs: ${minSecRegex}"
        "-- Total time to configure top-level package SimpleCxx: ${minSecRegex}"
        "-- Total time to configure top-level package WithSubpackages: ${minSecRegex}"
        "Total time to configure enabled packages: ${minSecRegex}"
        "Total time to set up for CPack packaging: ${minSecRegex}"
        "Total time to configure TribitsExProj: ${minSecRegex}"

    TEST_2 CMND ${CMAKE_COMMAND}
      MESSAGE "Reconfigure to test out timing of just one package"
      ARGS
        -DTribitsExProj_ENABLE_PACKAGE_CONFIGURE_TIMING=OFF
        -DSimpleCxx_PACKAGE_CONFIGURE_TIMING=ON
        .
      PASS_REGULAR_EXPRESSION_ALL
        "Total time to read in all dependencies files and build dependencies graph: ${minSecRegex}"
        "Total time to adjust package and TPL enables: ${minSecRegex}"
        "Total time to probe and setup the environment: ${minSecRegex}"
        "Total time to configure enabled external packages/TPLs: ${minSecRegex}"
        "-- Total time to configure top-level package SimpleCxx: ${minSecRegex}"
        "Total time to configure enabled packages: ${minSecRegex}"
        "Total time to set up for CPack packaging: ${minSecRegex}"
        "Total time to configure TribitsExProj: ${minSecRegex}"

    )

endif()


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_PT_NoFortran
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure (and test a lot of things at once)"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DCMAKE_CXX_FLAGS=-DSIMPLECXX_SHOW_DEPRECATED_WARNINGS=1
      -DTribitsExProj_SHOW_DEPRECATED_WARNINGS=OFF
      -DCMAKE_INSTALL_PREFIX=install
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "-- SimpleCxx: No library dependencies!"
      "-- WithSubpackagesA_FULL_ENABLED_DEP_PACKAGES: SimpleCxx"
      "-- WithSubpackages_FULL_ENABLED_DEP_PACKAGES: WithSubpackagesA SimpleCxx"
      "Explicitly enabled top-level packages on input .by user.:  0"
      "Explicitly disabled top-level packages on input .by user or by default.:  MixedLang WrapExternal 2"
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackages 3"
      "Final set of non-enabled top-level packages:  MixedLang WrapExternal 2"
      "Final set of non-enabled packages:  MixedLang WithSubpackagesB WithSubpackagesC WrapExternal 4"
  # NOTES: In the above test, we do a configure with
  # SIMPLECXX_SHOW_DEPRECATED_WARNINGS=1 and
  # TribitsExProj_SHOW_DEPRECATED_WARNINGS=OFF so that deprecated functions
  # are called but deprecated warnings for these functions are turned off.
  # This makes sure the macros XXX_DEPRECATED and XXX_DEPRECATED_MSG are
  # defined as tempy.

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}
    MESSAGE "Build the default 'all' target using raw 'make'"
    PASS_REGULAR_EXPRESSION_ALL
      "Built target simplecxx"
      "Built target pws_a"

  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "100% tests passed, 0 tests failed out of 3"

  TEST_3 CMND make ARGS install ${CTEST_BUILD_FLAGS}
    MESSAGE "Build 'install' target using raw 'make'"
    PASS_REGULAR_EXPRESSION_ALL
      "Installing: .+/install/lib/cmake/WithSubpackages/WithSubpackagesConfig.cmake"

  TEST_4 CMND ${CMAKE_COMMAND}
    ARGS
      -DDUMMY_PROJECT_NAME=DummyProject
      -DDUMMY_PROJECT_DIR=dummy_client_of_WithSubpackages
      -DEXPORT_VAR_PREFIX=WithSubpackages
      -DFIND_PACKAGE_NAME=WithSubpackages
      -DCMAKE_PREFIX_PATH=../install
      -DCMAKE_COMMAND=${CMAKE_COMMAND}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/RunDummyPackageClientBulid.cmake
    MESSAGE "Create and configure a dummy project that calls find_package(WithSubpackagesConfig)"
     "Calling: find_package[(]WithSubpackages REQUIRED COMPONENTS  OPTIONAL_COMPONENTS  [)]"
      "WithSubpackages::all_libs  INTERFACE_LINK_LIBRARIES: 'WithSubpackagesA::pws_a[;]WithSubpackagesB::pws_b[;]WithSubpackagesC::pws_c'"
      "-- Configuring done"
      "-- Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_ST
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "NOTE: Setting TribitsExProj_ENABLE_WrapExternal=OFF because "
      "Explicitly enabled top-level packages on input .by user.:  0"
      "Explicitly disabled top-level packages on input .by user or by default.:  WrapExternal 1"
      "Enabling all packages that are not currently disabled because of TribitsExProj_ENABLE_ALL_PACKAGES=ON "
      "Setting TribitsExProj_ENABLE_SimpleCxx=ON"
      "Setting TribitsExProj_ENABLE_MixedLang=ON"
      "Setting TribitsExProj_ENABLE_WithSubpackages=ON"
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages 3"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages 6"
      "Final set of non-enabled top-level packages:  WrapExternal 1"
      "Configuring done"
      "Generating done"
      "Build files have been written to: .*ExamplesUnitTests/TriBITS_TribitsExampleProject_ALL_ST"
  TEST_1
    MESSAGE "Grep MixedLangTargets.cmake to ensure INTERFACE library mixedlang_vector in all_libs"
    CMND grep ARGS -A 1 "set_target_properties.MixedLang::all_libs PROPERTIES" cmake_packages/MixedLang/MixedLangTargets.cmake
    PASS_REGULAR_EXPRESSION_ALL
      "INTERFACE_LINK_LIBRARIES .MixedLang::mixedlang_vector[;]MixedLang::mixedlang."
  TEST_2 CMND make
    MESSAGE "Build the default 'all' target using raw 'make'"
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target simplecxx"
      "Built target mixedlang"
      "Built target pws_a"
      "Built target pws_b"
      "Built target pws_c"
  TEST_3 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
      "MixedLang_RayTracerTests${TEST_MPI_1_SUFFIX} .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "WithSubpackagesB_test_of_b .* Passed"
      "WithSubpackagesB_test_of_b_mixed_lang.* Passed"
      "WithSubpackagesC_test_of_c_util.* Passed"
      "WithSubpackagesC_test_of_c .* Passed"
      "WithSubpackagesC_test_of_c_b_mixed_lang.* Passed"
      "100% tests passed, 0 tests failed out of 9"
  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_ST_LibPrefix
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=ON
      -DTribitsExProj_LIBRARY_NAME_PREFIX=tep_
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "NOTE: Setting TribitsExProj_ENABLE_WrapExternal=OFF because "
      "Explicitly enabled top-level packages on input .by user.:  0"
      "Explicitly disabled top-level packages on input .by user or by default.:  WrapExternal 1"
      "Enabling all packages that are not currently disabled because of TribitsExProj_ENABLE_ALL_PACKAGES=ON "
      "Setting TribitsExProj_ENABLE_SimpleCxx=ON"
      "Setting TribitsExProj_ENABLE_MixedLang=ON"
      "Setting TribitsExProj_ENABLE_WithSubpackages=ON"
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages 3"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages 6"
      "Final set of non-enabled top-level packages:  WrapExternal 1"
      "Configuring done"
      "Generating done"
      "Build files have been written to: .*ExamplesUnitTests/TriBITS_TribitsExampleProject_ALL_ST_LibPrefix"
  TEST_1 CMND make
    MESSAGE "Build the default 'all' target using raw 'make'"
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target tep_simplecxx"
      "Built target tep_mixedlang"
      "Built target tep_pws_a"
      "Built target tep_pws_b"
      "Built target tep_pws_c"
  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
      "MixedLang_RayTracerTests${TEST_MPI_1_SUFFIX} .* Passed"
      "WithSubpackagesA_test_of_a .* Passed"
      "WithSubpackagesB_test_of_b .* Passed"
      "WithSubpackagesB_test_of_b_mixed_lang.* Passed"
      "WithSubpackagesC_test_of_c_util.* Passed"
      "WithSubpackagesC_test_of_c .* Passed"
      "WithSubpackagesC_test_of_c_b_mixed_lang.* Passed"
      "100% tests passed, 0 tests failed out of 9"
  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_ST_LibUsage
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran

  TEST_0
    MESSAGE "Do the initial configure to get the package enables"
      " and the  env probe in place."
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=ON
      -DPython3_EXECUTABLE=
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "NOTE: Setting TribitsExProj_ENABLE_WrapExternal=OFF because Python3_EXECUTABLE=''"
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages 3"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages 6"
      "Configuring done"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  #
  # Testing passing libs to tribits_add_library()
  #

  TEST_1
    MESSAGE "Show deprecated warning when trying to link lib from upstream package."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_UPSTREAM_DEPLIBS_ERROR=ON
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'simplecxx' in DEPLIBS is not a lib in this package"
      "packages/with_subpackages/b/src/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_2
    MESSAGE "Show deprecated warning when passing a lib from this package through IMPORTEDLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_PKG_LIB_IMPORTEDLIBS_ERROR=ON
      -DSPKB_SHOW_UPSTREAM_DEPLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Lib 'pws_b' in IMPORTEDLIBS is in this package "
      "packages/with_subpackages/b/tests/testlib/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_3
    MESSAGE "Show deprecated warning when passing a lib from upstream"
      " package through IMPORTEDLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_UPSTREAM_PKG_LIB_IMPORTEDLIBS_ERROR=ON
      -DSPKB_SHOW_PKG_LIB_IMPORTEDLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Lib 'simplecxx' being passed through IMPORTEDLIBS"
      "TribitsExampleProject/packages/with_subpackages/b/cmake/Dependencies.cmake"
      "packages/with_subpackages/b/tests/testlib/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_4
    MESSAGE "Show deprecated warning when passing a TESTONLY lib through DEPLBIS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKC_SHOW_TESTONLY_DEPLBIS_ERROR=ON
      -DSPKB_SHOW_UPSTREAM_PKG_LIB_IMPORTEDLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'b_mixed_lang' in DEPLIBS is a TESTONLY lib "
      "TribitsExampleProject/packages/with_subpackages/c/cmake/Dependencies.cmake"
      "packages/with_subpackages/c/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_5
    MESSAGE "Show deprecated warning when passing a TESTONLY lib through IMPORTEDLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKC_SHOW_TESTONLY_IMPORTEDLIBS_ERROR=ON
      -DSPKC_SHOW_TESTONLY_DEPLBIS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'b_mixed_lang' in IMPORTEDLIBS is a TESTONLY lib"
      "packages/with_subpackages/c/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_6
    MESSAGE "Show deprecated warning when passing m through DEPLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_M_DEPLIBS_ERROR=ON
      -DSPKC_SHOW_TESTONLY_IMPORTEDLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'m' in DEPLIBS is not a lib defined in the current cmake "
      "packages/with_subpackages/b/src/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  #
  # Testing passing libs to tribits_add_executable()
  #

  TEST_7
    MESSAGE "Show error when trying to link an INSTALLABLE exec against a TESTONLY lib."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_TESTONLY_INSTALLABLE_ERROR=ON
      -DSPKB_SHOW_M_DEPLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "ERROR: TESTONLY lib 'b_test_utils' not allowed with INSTALLABLE executable"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Configuring incomplete, errors occurred!"

  TEST_8
    MESSAGE "Show error when trying to link against non-TESTONLY lib."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_NON_TESTONLY_LIB_ERROR=ON
      -DSPKB_SHOW_TESTONLY_INSTALLABLE_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      " ERROR: 'simplecxx' in TESTONLYLIBS not a TESTONLY lib"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Configuring incomplete, errors occurred!"

  TEST_9
    MESSAGE "Show error when trying to link package lib using TESTONLYLIBS"
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_IMPORTED_LIBS_THIS_PKG_ERROR=ON
      -DSPKB_SHOW_NON_TESTONLY_LIB_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "ERROR: Lib 'pws_b' in IMPORTEDLIBS is in this package"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Configuring incomplete, errors occurred!"

  TEST_10
    MESSAGE "Show deprecated warning when trying to link TESTONLY lib using DEBLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_TESTONLY_DEBLIBS_WARNING=ON
      -DSPKB_SHOW_IMPORTED_LIBS_THIS_PKG_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Passing TESTONLY lib 'b_mixed_lang' through DEPLIBS is deprecated"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_11
    MESSAGE "Show deprecated warning when trying to link non-TESTONLY lib using DEBLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_NONTESTONLY_DEBLIBS_WARNING=ON
      -DSPKB_SHOW_TESTONLY_DEBLIBS_WARNING=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Passing non-TESTONLY lib 'pws_b' through DEPLIBS is deprecated"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  TEST_12
    MESSAGE "Show deprecated warning when trying to link external lib using DEBLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_EXTERNAL_DEBLIBS_WARNING=ON
      -DSPKB_SHOW_NONTESTONLY_DEBLIBS_WARNING=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Passing external lib 'm' through DEPLIBS is deprecated"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_ST_LibUsage_LibPrefix
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran

  TEST_0
    MESSAGE "Do the initial configure to get the package enables"
      " and the  env probe in place."
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=ON
      -DTribitsExProj_ENABLE_WrapExternal=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      -DTribitsExProj_LIBRARY_NAME_PREFIX=tep_
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages 3"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages 6"
      "Configuring done"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  #
  # Testing passing libs to tribits_add_library()
  #

  TEST_1
    MESSAGE "Show deprecated warning when trying to link lib from upstream package."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_UPSTREAM_DEPLIBS_ERROR=ON
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'simplecxx' in DEPLIBS is not a lib in this package"
      "packages/with_subpackages/b/src/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  TEST_2
    MESSAGE "Show deprecated warning when passing a lib from this package through IMPORTEDLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_PKG_LIB_IMPORTEDLIBS_ERROR=ON
      -DSPKB_SHOW_UPSTREAM_DEPLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Lib 'pws_b' in IMPORTEDLIBS is in this package "
      "packages/with_subpackages/b/tests/testlib/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  TEST_3
    MESSAGE "Show deprecated warning when passing a lib from upstream"
      " package through IMPORTEDLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_UPSTREAM_PKG_LIB_IMPORTEDLIBS_ERROR=ON
      -DSPKB_SHOW_PKG_LIB_IMPORTEDLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Lib 'simplecxx' being passed through IMPORTEDLIBS"
      "TribitsExampleProject/packages/with_subpackages/b/cmake/Dependencies.cmake"
      "packages/with_subpackages/b/tests/testlib/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  TEST_4
    MESSAGE "Show deprecated warning when passing a TESTONLY lib through DEPLBIS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKC_SHOW_TESTONLY_DEPLBIS_ERROR=ON
      -DSPKB_SHOW_UPSTREAM_PKG_LIB_IMPORTEDLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'b_mixed_lang' in DEPLIBS is a TESTONLY lib "
      "TribitsExampleProject/packages/with_subpackages/c/cmake/Dependencies.cmake"
      "packages/with_subpackages/c/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  TEST_5
    MESSAGE "Show deprecated warning when passing a TESTONLY lib through IMPORTEDLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKC_SHOW_TESTONLY_IMPORTEDLIBS_ERROR=ON
      -DSPKC_SHOW_TESTONLY_DEPLBIS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'b_mixed_lang' in IMPORTEDLIBS is a TESTONLY lib"
      "packages/with_subpackages/c/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  TEST_6
    MESSAGE "Show deprecated warning when passing m through DEPLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_M_DEPLIBS_ERROR=ON
      -DSPKC_SHOW_TESTONLY_IMPORTEDLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "'m' in DEPLIBS is not a lib defined in the current cmake "
      "packages/with_subpackages/b/src/CMakeLists.txt:.* [(]tribits_add_library[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  #
  # Testing passing libs to tribits_add_executable()
  #

  TEST_7
    MESSAGE "Show error when trying to link an INSTALLABLE exec against a TESTONLY lib."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_TESTONLY_INSTALLABLE_ERROR=ON
      -DSPKB_SHOW_M_DEPLIBS_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "ERROR: TESTONLY lib 'b_test_utils' not allowed with INSTALLABLE executable"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Configuring incomplete, errors occurred!"

  TEST_8
    MESSAGE "Show error when trying to link against non-TESTONLY lib."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_NON_TESTONLY_LIB_ERROR=ON
      -DSPKB_SHOW_TESTONLY_INSTALLABLE_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      " ERROR: 'simplecxx' in TESTONLYLIBS not a TESTONLY lib"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Configuring incomplete, errors occurred!"

  TEST_9
    MESSAGE "Show error when trying to link package lib using TESTONLYLIBS"
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_IMPORTED_LIBS_THIS_PKG_ERROR=ON
      -DSPKB_SHOW_NON_TESTONLY_LIB_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "ERROR: Lib 'pws_b' in IMPORTEDLIBS is in this package"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Configuring incomplete, errors occurred!"

  TEST_10
    MESSAGE "Show deprecated warning when trying to link TESTONLY lib using DEBLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_TESTONLY_DEBLIBS_WARNING=ON
      -DSPKB_SHOW_IMPORTED_LIBS_THIS_PKG_ERROR=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Passing TESTONLY lib 'b_mixed_lang' through DEPLIBS is deprecated"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  TEST_11
    MESSAGE "Show deprecated warning when trying to link non-TESTONLY lib using DEBLIBS."
    CMND ${CMAKE_COMMAND}
    ARGS -DSPKB_SHOW_NONTESTONLY_DEBLIBS_WARNING=ON
      -DSPKB_SHOW_TESTONLY_DEBLIBS_WARNING=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Passing non-TESTONLY lib 'pws_b' through DEPLIBS is deprecated"
      "packages/with_subpackages/b/tests/CMakeLists.txt:.* [(]tribits_add_executable_and_test[)]"
      "Generating done"
      "Build files have been written to: .*/TriBITS_TribitsExampleProject_ALL_ST_LibUsage_LibPrefix"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_SimpleCxx_DEBUG_int64
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_DEBUG=ON
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DHAVE_SIMPLECXX___INT64=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx 1"
      "Configuring done"
      "Generating done"
  TEST_1 CMND make
    MESSAGE "Build the default 'all' target using raw 'make'"
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target simplecxx"
  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests${TEST_MPI_1_SUFFIX} .* Passed"
      "100% tests passed, 0 tests failed out of 2"
  )


tribits_add_advanced_test( TribitsExampleProject_CONFIGURE_OPTIONS_FILE
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure with no options file"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
      "Generating done"
  TEST_1 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the re-configure with user-defined configure options file"
    ARGS
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE=${CMAKE_CURRENT_LIST_DIR}/ConfigOptions1.cmake
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Reading in configuration options from .*/ConfigOptions1.cmake"
      "Included ConfigOptions1.cmake"
      "Generating done"
  TEST_2 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the re-configure with configure options file append"
    ARGS
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE=
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE_APPEND=${CMAKE_CURRENT_LIST_DIR}/ConfigOptions2.cmake
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Reading in configuration options from .*/ConfigOptions2.cmake"
      "Included ConfigOptions2.cmake"
      "Generating done"
  TEST_3 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the re-configure with configure options file and append"
    ARGS
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE=${CMAKE_CURRENT_LIST_DIR}/ConfigOptions1.cmake
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE_APPEND=${CMAKE_CURRENT_LIST_DIR}/ConfigOptions2.cmake
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Reading in configuration options from .*/ConfigOptions1.cmake"
      "Reading in configuration options from .*/ConfigOptions2.cmake"
      "Included ConfigOptions1.cmake"
      "Included ConfigOptions2.cmake"
      "Generating done"
  TEST_4 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the re-configure with two user configure options files"
    ARGS
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE=${CMAKE_CURRENT_LIST_DIR}/ConfigOptions1.cmake,${CMAKE_CURRENT_LIST_DIR}/ConfigOptions2.cmake
      -DTribitsExProj_CONFIGURE_OPTIONS_FILE_APPEND=
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Reading in configuration options from .*/ConfigOptions1.cmake"
      "Reading in configuration options from .*/ConfigOptions2.cmake"
      "Included ConfigOptions1.cmake"
      "Included ConfigOptions2.cmake"
      "Generating done"
  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_SKIP_CTEST_ADD_TEST_Project
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure with TribitsExProj_SKIP_CTEST_ADD_TEST=ON"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_TRACE_ADD_TEST=ON
      -DTribitsExProj_SKIP_CTEST_ADD_TEST=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackages 3"
      "SimpleCxx_HelloWorldTests: NOT added test because SimpleCxx_SKIP_CTEST_ADD_TEST='ON'[!]"
      "SimpleCxx_HelloWorldProg: NOT added test because SimpleCxx_SKIP_CTEST_ADD_TEST='ON'[!]"
      "WithSubpackagesA_test_of_a: NOT added test because WithSubpackages_SKIP_CTEST_ADD_TEST='ON'[!]"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}
    MESSAGE "Build the default 'all' target using raw 'make'"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "No tests were found"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_SKIP_CTEST_ADD_TEST_Package_Whitelist
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure with TribitsExProj_SKIP_CTEST_ADD_TEST=ON"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_TRACE_ADD_TEST=ON
      -DSimpleCxx_SKIP_CTEST_ADD_TEST=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackages 3"
      "SimpleCxx_HelloWorldTests: NOT added test because SimpleCxx_SKIP_CTEST_ADD_TEST='ON'[!]"
      "SimpleCxx_HelloWorldProg: NOT added test because SimpleCxx_SKIP_CTEST_ADD_TEST='ON'[!]"
      "WithSubpackagesA_test_of_a: Added test [(]BASIC, .*PROCESSORS=1[)][!]"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}
    MESSAGE "Build the default 'all' target using raw 'make'"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "1/1 Test #1: WithSubpackagesA_test_of_a .* Passed"
      "100% tests passed, 0 tests failed out of 1"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_SKIP_CTEST_ADD_TEST_Package_Blacklist
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0 CMND ${CMAKE_COMMAND}
    MESSAGE "Do the initial configure with TribitsExProj_SKIP_CTEST_ADD_TEST=ON"
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_TRACE_ADD_TEST=ON
      -DTribitsExProj_SKIP_CTEST_ADD_TEST=ON
      -DSimpleCxx_SKIP_CTEST_ADD_TEST=OFF
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackages 3"
      "SimpleCxx_HelloWorldTests.*: Added test [(]BASIC, .*PROCESSORS=1[)][!]"
      "SimpleCxx_HelloWorldProg.*: Added test [(]BASIC, .*PROCESSORS=1[)][!]"
      "WithSubpackagesA_test_of_a: NOT added test because WithSubpackages_SKIP_CTEST_ADD_TEST='ON'[!]"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}
    MESSAGE "Build the default 'all' target using raw 'make'"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    MESSAGE "Run all the tests with raw 'ctest'"
    PASS_REGULAR_EXPRESSION_ALL
      "1/2 Test #1: SimpleCxx_HelloWorldTests.* .* Passed"
      "2/2 Test #2: SimpleCxx_HelloWorldProg.* .* Passed"
      "100% tests passed, 0 tests failed out of 2"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  )


########################################################################

tribits_add_advanced_test( TribitsExampleProject_EnableWithSubpackagesB_EnableWithsubpackagesTests
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  XHOSTTYPE "Darwin"

  TEST_0
    MESSAGE "Configure enabling a subpackage and parent package tests"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_WithSubpackagesB=ON
      -DWithSubpackages_ENABLE_TESTS=ON
       -DTribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Enabling subpackage tests/examples based on parent package tests/examples enables"
      "-- Setting WithSubpackages_ENABLE_EXAMPLES=ON because WithSubpackages_ENABLE_TESTS=ON"
      "-- Setting WithSubpackagesB_ENABLE_TESTS=ON because parent package WithSubpackages_ENABLE_TESTS=ON"
      "-- Setting WithSubpackagesB_ENABLE_EXAMPLES=ON because parent package WithSubpackages_ENABLE_EXAMPLES=ON"
      "-- WithSubpackagesB_TEST_ENABLED_DEPENDENCIES: MixedLang"
      "-- WithSubpackagesB_TEST_DEFINED_DEPENDENCIES: MixedLang"
      "Processing enabled top-level package: WithSubpackages [(]A, B, Tests, Examples[)]"
      "Configuring done"
      "Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}

  TEST_2 CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "WithSubpackagesB_test_of_b [.]* *Passed"
      "WithSubpackagesB_test_of_b_mixed_lang.* [.]* *Passed"
      "100% tests passed, 0 tests failed out of 2"

  )
# NOTE: The above test covers one of the use cases for the the defect
# described in TriBITSPub/TriBITS#510.  This shows that only the tests for
# WithSubpackagesB are enabled and run and not for any of the other
# subpackages of of the parent package WithSubpackages


########################################################################


tribits_add_advanced_test( TribitsExampleProject_EnableWithSubpackagesB_EnableWithsubpackagesExamples
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  XHOSTTYPE "Darwin"

  TEST_0
    MESSAGE "Configure enabling a subpackage and parent package examples"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_WithSubpackagesB=ON
      -DWithSubpackages_ENABLE_EXAMPLES=ON
       -DTribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Enabling subpackage tests/examples based on parent package tests/examples enables"
      "-- Setting WithSubpackagesB_ENABLE_EXAMPLES=ON because parent package WithSubpackages_ENABLE_EXAMPLES=ON"
      "-- WithSubpackagesB_TEST_ENABLED_DEPENDENCIES: MixedLang"
      "-- WithSubpackagesB_TEST_DEFINED_DEPENDENCIES: MixedLang"
      "Processing enabled top-level package: WithSubpackages [(]A, B, Examples[)]"
      "Configuring done"
      "Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}

  TEST_2 CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "No tests were found"

  )
# NOTE: The above test ensures that
# WithSubpackagesB_TEST_ENABLED_DEPENDENCIES=MixedLang gets set but that the
# tests are not actually run because only examples where enabled.  This was
# not a use case for the Trilinos failures reported in TriBITSPub/TriBITS#510
# but this is a valid use case that needs to be supported and tested.


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ST_EnableSimpleCxx_EnableWithSubpackagesB_EnableTests_DisableWithsubpackagesTests
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  XHOSTTYPE "Darwin"

  TEST_0
    MESSAGE "Configure while disabling WithSubPackages tests and examples"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DTribitsExProj_ENABLE_WithSubpackagesB=ON
      -DWithSubpackages_ENABLE_TESTS=OFF
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Disabling subpackage tests/examples based on parent package tests/examples disables ..."
      "-- Setting WithSubpackages_ENABLE_EXAMPLES=OFF because WithSubpackages_ENABLE_TESTS=OFF"
      "-- Setting WithSubpackagesB_ENABLE_TESTS=OFF because parent package WithSubpackages_ENABLE_TESTS=OFF"
      "-- Setting WithSubpackagesB_ENABLE_EXAMPLES=OFF because parent package WithSubpackages_ENABLE_EXAMPLES=OFF"
      "Enabling all tests and/or examples that have not been explicitly disabled because TribitsExProj_ENABLE_.TESTS,EXAMPLES.=ON ..."
      "-- Setting SimpleCxx_ENABLE_TESTS=ON"
      "-- Setting SimpleCxx_ENABLE_EXAMPLES=ON"
      "Processing enabled top-level package: SimpleCxx [(]Libs, Tests, Examples[)]"
      "-- Performing Test HAVE_SIMPLECXX___INT64"
      "-- Performing Test HAVE_SIMPLECXX___INT64 - Failed"
      "Processing enabled top-level package: MixedLang [(]Libs[)]"
      "Processing enabled top-level package: WithSubpackages [(]A, B[)]"
      "Configuring done"
      "Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}

  TEST_2 CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx_HelloWorldTests.* [.]+ +Passed"
      "SimpleCxx_HelloWorldProg.* [.]+ +Passed"
      "100% tests passed, 0 tests failed out of 2"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ST_EnableMixedLang_EnableAllForwardDepPackages
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  XHOSTTYPE "Darwin"

  TEST_0
    MESSAGE "Configure enabling an upstream package and enableee forward dep packages"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_MixedLang=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_ALL_FORWARD_DEP_PACKAGES=ON
      -DTribitsExProj_DUMP_PACKAGE_DEPENDENCIES=ON
      -DTribitsExProj_DUMP_FORWARD_PACKAGE_DEPENDENCIES=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Sweep backward enabling all forward test dependent packages because TribitsExProj_ENABLE_ALL_FORWARD_DEP_PACKAGES=ON"
      "-- Setting TribitsExProj_ENABLE_WithSubpackagesB=ON because TribitsExProj_ENABLE_MixedLang=ON"
      "Enabling all tests and/or examples that have not been explicitly disabled because TribitsExProj_ENABLE_.TESTS,EXAMPLES.=ON"
      "-- Setting MixedLang_ENABLE_TESTS=ON"
      "-- Setting MixedLang_ENABLE_EXAMPLES=ON"
      "-- Setting WithSubpackagesB_ENABLE_TESTS=ON"
      "-- Setting WithSubpackagesB_ENABLE_EXAMPLES=ON"
      "-- WithSubpackagesB_TEST_ENABLED_DEPENDENCIES: MixedLang"
      "-- WithSubpackagesB_TEST_DEFINED_DEPENDENCIES: MixedLang"
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages 3"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackages 5"
      "Processing enabled top-level package: MixedLang [(]Libs, Tests, Examples[)]"
      "Processing enabled top-level package: WithSubpackages [(]A, B, Tests, Examples[)]"
      "Configuring done"
      "Generating done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}

  TEST_2 CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "MixedLang_RayTracerTests.* [.]* *Passed"
      "WithSubpackagesB_test_of_b [.]* *Passed"
      "WithSubpackagesB_test_of_b_mixed_lang.* [.]* *Passed"
      "100% tests passed, 0 tests failed out of 3"
  )
# NOTE: The above test covers one of the failure modes reported in
# TriBITSPub/TriBITS#510 that resulted in missing test dependencies.


########################################################################


tribits_add_advanced_test( TribitsExampleProject_WrapExternal
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  XHOSTTYPE "Darwin"

  TEST_0
    MESSAGE "Copy TribitsExampleProject so that we can modify it."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1 CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_DEBUG=OFF
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      -DTribitsExProj_ENABLE_WrapExternal=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Explicitly enabled top-level packages on input .by user.:  WrapExternal 1"
      "Explicitly disabled top-level packages on input .by user or by default.:  0"
      "Setting TribitsExProj_ENABLE_WithSubpackagesA=ON because WrapExternal has a required dependence on WithSubpackagesA"
      "Setting TribitsExProj_ENABLE_MixedLang=ON because WrapExternal has an optional dependence on MixedLang"
      "Setting TribitsExProj_ENABLE_SimpleCxx=ON because WithSubpackagesA has a required dependence on SimpleCxx"
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages WrapExternal 4"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackages WrapExternal 5"
      "Final set of non-enabled top-level packages:  0"
      "Final set of non-enabled packages:  WithSubpackagesB WithSubpackagesC 2"
      "This package has no unfiltered binary files so consider out of date"
      "Configuring done"
      "Generating done"
      "Build files have been written to: .*ExamplesUnitTests/TriBITS_TribitsExampleProject_WrapExternal"
  TEST_2 CMND make ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target WrapExternal_run_external_func"
  TEST_3 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    PASS_REGULAR_EXPRESSION_ALL
      "WrapExternal_run_external_func${TEST_MPI_1_SUFFIX} .* Passed"
      "100% tests passed, 0 tests failed out of 1"

  TEST_4 CMND sleep ARGS 1s
     MESSAGE "Sleep for 1 sec for systems were time stamps are only accurate to 1 sec"
  TEST_5 CMND touch
     ARGS TribitsExampleProject/packages/with_subpackages/a/A.cpp
     MESSAGE "Test that changing upstream source will trigger rebuild"
  TEST_6 CMND ${CMAKE_COMMAND} ARGS TribitsExampleProject
      -DWrapExternal_SHOW_MOST_RECENT_FILES=TRUE
     MESSAGE "Recofigure with changed upstream source"
    PASS_REGULAR_EXPRESSION_ALL
      "Most recent file in ./packages/with_subpackages/ is ./a/A.cpp"
      "Overall most recent modified file is in ./packages/with_subpackages/ and is ./a/A.cpp"
      "The upstream package source file ./a/A.cpp is more recent than this package's binary file ./WrapExternal_run_external_func.exe"
      "Blowing away WrapExternal build dir external_func/ so it will build from scratch"
  TEST_7 CMND make ARGS ${CTEST_BUILD_FLAGS}
    MESSAGE "Rebuild only exteranl_func"
    PASS_REGULAR_EXPRESSION_ALL
      "Built target simplecxx"
      "Built target mixedlang"
      "Built target pws_a"
      "Generating external_func/libexternal_func.a"
      "Linking CXX executable WrapExternal_run_external_func.exe"

  TEST_8 CMND sleep ARGS 1s
     MESSAGE "Sleep for 1 sec for systems were time stamps are only accurate to 1 sec"
  TEST_9 CMND ${CMAKE_COMMAND}
     ARGS  -DSimpleCxx_ENABLE_DEBUG=ON  -DWrapExternal_SHOW_MOST_RECENT_FILES=FALSE
       TribitsExampleProject
     MESSAGE "Recofigure changing the debug mode to trigger rebuild"
    PASS_REGULAR_EXPRESSION_ALL
      "The upstream package binary file ./src/SimpleCxx_config.h is more recent than this package's binary file ./WrapExternal_run_external_func.exe"
      "Blowing away WrapExternal build dir external_func/ so it will build from scratch"
  TEST_10 CMND make ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Generating external_func/libexternal_func.a"
      "Linking CXX executable WrapExternal_run_external_func.exe"

  TEST_11 CMND sleep ARGS 1s
     MESSAGE "Sleep for 1 sec for systems were time stamps are only accurate to 1 sec"
  TEST_12 CMND touch
     ARGS TribitsExampleProject/packages/wrap_external/external_func/configure.py
     MESSAGE "Test that changing the external file will trigger rebuild"
  TEST_13 CMND ${CMAKE_COMMAND} ARGS TribitsExampleProject
     MESSAGE "Recofigure with changes external file"
    PASS_REGULAR_EXPRESSION_ALL
      "The this package's source file ./external_func/configure.py is more recent than this package's binary file ./WrapExternal_run_external_func.exe"
      "Blowing away WrapExternal build dir external_func/ so it will build from scratch"
  TEST_14 CMND make ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Generating external_func/libexternal_func.a"
      "Linking CXX executable WrapExternal_run_external_func.exe"

  TEST_15 CMND ${CMAKE_COMMAND} ARGS TribitsExampleProject
     MESSAGE "Recofigure with no changes that will not do anything"
    PASS_REGULAR_EXPRESSION_ALL
      "This package's most recent binary file (./WrapExternal_run_external_func.exe|./external_func/libexternal_func.a) is more recent than its upstream package source or binary files or this package's source files"
  TEST_16 CMND make ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target build_external_func"
      "Built target WrapExternal_run_external_func"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_NoFortran_WrapExternal_VerboseConfigure
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0
    MESSAGE "Do a verbose configure and check that the packages coupling variables are correct."
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_DEBUG=OFF
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_VERBOSE_CONFIGURE=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages WrapExternal 3"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages WrapExternal 6"

      "HeaderOnlyTpl_INCLUDE_DIRS='.+/examples/tpls/HeaderOnlyTpl'"
      "-- TPL_HeaderOnlyTpl_INCLUDE_DIRS='.+/examples/tpls/HeaderOnlyTpl'"

      "SimpleCxx_LIBRARIES='SimpleCxx::simplecxx'"

      "WithSubpackagesA_LIBRARIES='WithSubpackagesA::pws_a'"

      "WithSubpackagesB_LIBRARIES='WithSubpackagesB::pws_b'"

      "WithSubpackagesC_LIBRARIES='WithSubpackagesC::pws_c'"

      "WithSubpackages_LIBRARIES='WithSubpackagesC::pws_c[;]WithSubpackagesB::pws_b[;]WithSubpackagesA::pws_a'"

      "WrapExternal_LIBRARIES='external_func[;]WithSubpackagesA::pws_a'"

      "pws_b_TARGET_NAME='pws_b'"
      "b_test_TARGET_NAME='WithSubpackagesB_b_test'"
      "test_of_b_TEST_NAME='WithSubpackagesB_test_of_b'"
      "c_util_TEST_NAME='WithSubpackagesC_test_of_c_util${TEST_MPI_1_SUFFIX}'"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Darwin

  TEST_0
    MESSAGE "Copy TribitsExampleProject so that we can modify it."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Copy the with_subpackages package dir to base dir."
    CMND cp
    ARGS -r TribitsExampleProject/packages/with_subpackages/
      TribitsExampleProject/.

  TEST_2
    MESSAGE "Remove the packages/with_subpackages package dir."
    CMND rm
    ARGS -r TribitsExampleProject/packages/with_subpackages/

  TEST_3
    MESSAGE "Override with_packages/ source dir and configure"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_DEBUG=OFF
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_VERBOSE_CONFIGURE=ON
      -DWithSubpackages_SOURCE_DIR_OVERRIDE=with_subpackages
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages WrapExternal 3"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages WrapExternal 6"
      "-- NOTE: WithSubpackages_SOURCE_DIR_OVERRIDE='with_subpackages' is overriding default path 'packages/with_subpackages'"
      "-- File Trace: PACKAGE    INCLUDE    .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/cmake/Dependencies[.]cmake"
      "-- File Trace: PACKAGE    INCLUDE    .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/a/cmake/Dependencies[.]cmake"
      "-- File Trace: PACKAGE    INCLUDE    .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/b/cmake/Dependencies[.]cmake"
      "-- File Trace: PACKAGE    INCLUDE    .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/c/cmake/Dependencies[.]cmake"
      "-- WithSubpackages_BINARY_DIR='.*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/with_subpackages'"
      "-- WithSubpackages_SOURCE_DIR='.*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages'"
      "-- WithSubpackages_BINARY_DIR='.*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/with_subpackages'"
      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/CMakeLists[.]txt"
      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/a/CMakeLists[.]txt"
      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/a/tests/CMakeLists[.]txt"

      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/b/CMakeLists[.]txt"
      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/b/tests/CMakeLists[.]txt"

      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/c/CMakeLists[.]txt"
      "-- File Trace: PACKAGE    ADD_SUBDIR .*/TriBITS_TribitsExampleProject_ALL_NoFortran_OverridePackageSourceDir/TribitsExampleProject/with_subpackages/c/tests/CMakeLists[.]txt"

  TEST_4 CMND make
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target WithSubpackagesC_c_test"

  TEST_5 CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "100% tests passed, 0 tests failed out of 7"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_HeaderOnlyTpl_FailThenPass
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0
    MESSAGE "Do the initial configure with a bad TPL find path"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      #-DTribitsExProj_VERBOSE_CONFIGURE=ON
      -DHeaderOnlyTpl_INCLUDE_DIRS=/path_does_not_exist
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Processing enabled external package/TPL: HeaderOnlyTpl .enabled by SimpleCxx, disable with -DTPL_ENABLE_HeaderOnlyTpl=OFF."
      "-- Searching for headers in HeaderOnlyTpl_INCLUDE_DIRS='/path_does_not_exist'"
      "-- TIP: If the TPL 'HeaderOnlyTpl' is on your system then you can set:"
      "-DHeaderOnlyTpl_INCLUDE_DIRS='<dir0>[;]<dir1>[;]...'"
      "-DTPL_HeaderOnlyTpl_INCLUDE_DIRS='<dir0>[;]<dir1>[;]...'"
      "-- ERROR: Failed finding all of the parts of TPL 'HeaderOnlyTpl' .see above., Aborting!"
      "-- NOTE: The find module file for this failed TPL 'HeaderOnlyTpl' is:"
      "     .*/TribitsExampleProject/cmake/tpls/FindTPLHeaderOnlyTpl.cmake"
      "   which is pointed to in the file:"
      "     .*/TribitsExampleProject/TPLsList.cmake"
      "TIP: One way to get past the configure failure for the"
      "TPL 'HeaderOnlyTpl' is to simply disable it with:"
      "  -DTPL_ENABLE_HeaderOnlyTpl=OFF"
      "which will disable it and will recursively disable all of the"
      "downstream packages that have required dependencies on it, including"
      "the package 'SimpleCxx' which triggered its enable."
      "When you reconfigure, just grep the cmake stdout for 'HeaderOnlyTpl'"
      "and then follow the disables that occur as a result to see what impact"
      "this TPL disable has on the configuration of TribitsExProj."
      "CMake Error at .+/TribitsProcessEnabledTpls[.]cmake:[0-9]+ [(]message[)]:"
      "  ERROR: TPL_HeaderOnlyTpl_NOT_FOUND=TRUE, aborting!"
      "Call Stack .most recent call first.:"
      "-- Configuring incomplete, errors occurred!"

  TEST_1
    MESSAGE "Reconfigure now fining the TPL correctly"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DHeaderOnlyTpl_INCLUDE_DIRS=${${PROJECT_NAME}_TRIBITS_DIR}/examples/tpls/HeaderOnlyTpl
      #-DTribitsExProj_VERBOSE_CONFIGURE=ON
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Processing enabled external package/TPL: HeaderOnlyTpl .enabled by SimpleCxx, disable with -DTPL_ENABLE_HeaderOnlyTpl=OFF."
      "-- Searching for headers in HeaderOnlyTpl_INCLUDE_DIRS='.*/tribits/examples/tpls/HeaderOnlyTpl'"
      "Found header '.*/tribits/examples/tpls/HeaderOnlyTpl/?/HeaderOnlyTpl_stuff.hpp'"
      "Found TPL 'HeaderOnlyTpl' include dirs '.*/tribits/examples/tpls/HeaderOnlyTpl'"
      "TPL_HeaderOnlyTpl_INCLUDE_DIRS='.*/tribits/examples/tpls/HeaderOnlyTpl'"
      "Configuring done"
      "Generating done"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_HeaderOnlyTpl_HardEnable_Fail
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0
    MESSAGE "Do the initial configure with a bad TPL find path"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      #-DTribitsExProj_VERBOSE_CONFIGURE=ON
      -DTPL_ENABLE_HeaderOnlyTpl=ON
      -DHeaderOnlyTpl_INCLUDE_DIRS=/path_does_not_exist
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Processing enabled external package/TPL: HeaderOnlyTpl .enabled explicitly, disable with -DTPL_ENABLE_HeaderOnlyTpl=OFF."
      "TIP: Even though the TPL 'HeaderOnlyTpl' was explicitly enabled in input,"
      "it can be disabled with:"
      "  -DTPL_ENABLE_HeaderOnlyTpl=OFF"
      "which will disable it and will recursively disable all of the"
      "downstream packages that have required dependencies on it."
      "When you reconfigure, just grep the cmake stdout for 'HeaderOnlyTpl'"
      "and then follow the disables that occur as a result to see what impact"
      "this TPL disable has on the configuration of TribitsExProj."
      "-- ERROR: Failed finding all of the parts of TPL 'HeaderOnlyTpl' .see above., Aborting!"
      "CMake Error at .+/TribitsProcessEnabledTpls[.]cmake:[0-9]+ [(]message[)]:"
      "  ERROR: TPL_HeaderOnlyTpl_NOT_FOUND=TRUE, aborting!"
      "Call Stack .most recent call first.:"
      "-- Configuring incomplete, errors occurred!"
  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_InsertedPkg
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Darwin

  TEST_0
    MESSAGE "Copy TribitsExampleProject so that we can copy in ExternalPkg."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Configure to get the compiler options"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_DEBUG=OFF
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
      "Generating done"

  TEST_2
    MESSAGE "Configure asserting existence of missing InsertedPkg"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DInsertedPkg_ALLOW_MISSING_EXTERNAL_PACKAGE=FALSE
      .
    PASS_REGULAR_EXPRESSION_ALL
      "Error, the package InsertedPkg dependencies file '.+/TribitsExampleProject/InsertedPkg/cmake/Dependencies.cmake' does [*]NOT[*] exist!"
      "CMake Error at .+/TribitsProcessPackagesAndDirsLists.cmake:[0-9]+ [(]message[)]:"
      "Configuring incomplete, errors occurred!"

  TEST_3
    MESSAGE "Copy TargetDefinesPkg to base dir."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/InsertedPkg
      TribitsExampleProject/.


  TEST_4
    MESSAGE "Configure all packages"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_TESTS=ON
     .
    PASS_REGULAR_EXPRESSION_ALL
      "Setting TribitsExProj_ENABLE_InsertedPkg=ON"
      "Final set of enabled top-level packages:  SimpleCxx InsertedPkg .+"
      "Final set of enabled packages:  SimpleCxx InsertedPkg .+"
      "Configuring done"
      "Generating done"

  TEST_5 CMND make
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target externalpkg"
      "Linking CXX executable InsertedPkg_test.exe"

  TEST_6 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    PASS_REGULAR_EXPRESSION_ALL
      "InsertedPkg_test${TEST_MPI_1_SUFFIX} [.]+   Passed"
      "100% tests passed, 0 tests failed out of"

  # ToDo: Add usage of InsertedPkg in downstream package.

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_SimpleTpl
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1
  EXCLUDE_IF_NOT_TRUE ${PROJECT_NAME}_ENABLE_Fortran
  XHOSTTYPE Darwin

  TEST_0
    MESSAGE "Configure with SimpleTpl enabled"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_Fortran=ON
      -DTPL_ENABLE_MPI=OFF
      -DTPL_ENABLE_SimpleTpl=ON
      -DSimpleTpl_INCLUDE_DIRS=${SimpleTpl_install_STATIC_DIR}/install/include
      -DSimpleTpl_LIBRARY_DIRS=${SimpleTpl_install_STATIC_DIR}/install/lib
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx MixedLang WithSubpackages WrapExternal 4"
      "Final set of enabled packages:  SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages WrapExternal 7"
      "Final set of enabled external packages/TPLs:  HeaderOnlyTpl SimpleTpl 2"
      "TPL_SimpleTpl_LIBRARIES='.*/TriBITS_SimpleTpl_install_STATIC/install/lib/libsimpletpl.a'"
      "TPL_SimpleTpl_INCLUDE_DIRS='.*/TriBITS_SimpleTpl_install_STATIC/install/include'"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_1 CMND make ARGS ${CTEST_BUILD_FLAGS}

  TEST_2 CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "100% tests passed, 0 tests failed out of"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  ADDED_TEST_NAME_OUT TribitsExampleProject_SimpleTpl_NAME
  )
# NOTE: The above test checks that the TribitsExampleProject test suite passes
# when the SimpleTpl TPL is enabled.

if (TribitsExampleProject_SimpleTpl_NAME)
  set_tests_properties(${TribitsExampleProject_SimpleTpl_NAME}
    PROPERTIES DEPENDS ${SimpleTpl_install_STATIC_NAME} )
endif()


########################################################################


tribits_add_advanced_test( TribitsExampleProject_TargetDefinesPkg
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0
    MESSAGE "Copy TribitsExampleProject so that we can copy in TargetDefinesPkg."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Configure to get the compiler options"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_DEBUG=OFF
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
      "Generating done"

  TEST_2
    MESSAGE "Copy TargetDefinesPkg to base dir."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TargetDefinesPkg
      TribitsExampleProject/.

  TEST_3
    MESSAGE "Configure just TargetDefinesPkg"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DTribitsExProj_EXTRA_REPOSITORIES=TargetDefinesPkg
      -DTribitsExProj_ENABLE_TargetDefinesPkg=ON
      -DTribitsExProj_ENABLE_TESTS=ON
     .
    PASS_REGULAR_EXPRESSION_ALL
      "Passing extra defines through 'DEFINES'"
      "Final set of enabled top-level packages:  TargetDefinesPkg 1"
      "Final set of enabled packages:  TargetDefinesPkg 1"
      "Configuring done"
      "Generating done"

  TEST_4 CMND make
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target targetdefinespkg"
      "Linking CXX executable TargetDefinesPkg_testcasedefault1"
      "Linking CXX executable TargetDefinesPkg_testcase_deprecated_default2"

  TEST_5 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    PASS_REGULAR_EXPRESSION_ALL
      "TargetDefinesPkg_testcasedefault1.* Passed"
      "TargetDefinesPkg_testcase_deprecated_default2.* Passed"
      "100% tests passed, 0 tests failed out of 8"

  )


########################################################################


tribits_add_advanced_test( TribitsExampleProject_MixedSharedStaticLibs_shared
  OVERALL_WORKING_DIRECTORY TEST_NAME
  EXCLUDE_IF_NOT_TRUE IS_REAL_LINUX_SYSTEM
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Darwin

  TEST_0
    MESSAGE "Copy TribitsExampleProject so that we can copy in MixedSharedStaticLibs."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Configure to get the compiler options"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DBUILD_SHARED_LIBS=ON
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_DEBUG=OFF
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "BUILD_SHARED_LIBS=.ON."
      "Configuring done"
      "Generating done"

  TEST_2
    MESSAGE "Copy MixedSharedStaticLibs to base dir."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/MixedSharedStaticLibs
      TribitsExampleProject/.

  TEST_3
    MESSAGE "Configure SimpleCxx and MixedSharedStaticLibs"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DTribitsExProj_EXTRA_REPOSITORIES=MixedSharedStaticLibs
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DTribitsExProj_ENABLE_MixedSharedStaticLibs=ON
      -DTribitsExProj_ENABLE_TESTS=ON
     .
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx MixedSharedStaticLibs 2"
      "Final set of enabled packages:  SimpleCxx MixedSharedStaticLibsSharedOnly MixedSharedStaticLibsStaticOnly MixedSharedStaticLibsStaticExec MixedSharedStaticLibs 5"
      "Configuring done"
      "Generating done"

  TEST_4 CMND make
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Built target static_only_lib"
      "Linking CXX shared library libsimplecxx.so"  # Shared because of BULID_SHARED_LIBS=ON
      "Linking CXX shared library libshared_only_lib.so" # Always shared
      "Built target shared_only_lib"
      "Linking CXX static library libstatic_only_lib.a" # Always static
      "Built target static_only_lib"
      "Linking CXX executable MixedSharedStaticLibsSharedOnly_test"
      "Linking CXX executable MixedSharedStaticLibsStaticExec_test"

  TEST_5 CMND ls ARGS packages/simple_cxx/src
    PASS_REGULAR_EXPRESSION_ALL
      "libsimplecxx[.]so"
      "libsimplecxx[.]so[.]01"
      "libsimplecxx[.]so[.]1[.]1"

  TEST_6 CMND ls ARGS MixedSharedStaticLibs/shared_only
    PASS_REGULAR_EXPRESSION_ALL
      "libshared_only_lib[.]so"
      "libshared_only_lib[.]so[.]01"
      "libshared_only_lib[.]so[.]1[.]1"

  TEST_7 CMND ls ARGS MixedSharedStaticLibs/static_only
    PASS_REGULAR_EXPRESSION_ALL
      "libstatic_only_lib[.]a"

  TEST_8 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    PASS_REGULAR_EXPRESSION_ALL
      "MixedSharedStaticLibsSharedOnly_test.* Passed"
      "MixedSharedStaticLibsStaticExec_test.* Passed"
      "100% tests passed, 0 tests failed out of 4"

  )
  # NOTE: The above test make sure that you can build a static library with
  # tribits_add_library( ... STATIC ...) in project that is defaulted to use
  # shared libs with BUILD_SHARED_LIBS=ON.  This also tests that the correct
  # soversion links are created as well.


########################################################################


tribits_add_advanced_test( TribitsExampleProject_MixedSharedStaticLibs_static
  OVERALL_WORKING_DIRECTORY TEST_NAME
  EXCLUDE_IF_NOT_TRUE IS_REAL_LINUX_SYSTEM
  OVERALL_NUM_MPI_PROCS 1
  XHOSTTYPE Darwin

  TEST_0
    MESSAGE "Copy TribitsExampleProject so that we can copy in MixedSharedStaticLibs."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Configure to get the compiler options"
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DBUILD_SHARED_LIBS=OFF
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_DEBUG=OFF
      TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "BUILD_SHARED_LIBS=.OFF."
      "Configuring done"
      "Generating done"

  TEST_2
    MESSAGE "Copy MixedSharedStaticLibs to base dir."
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/MixedSharedStaticLibs
      TribitsExampleProject/.

  TEST_3
    MESSAGE "Configure SimpleCxx and MixedSharedStaticLibs"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DTribitsExProj_EXTRA_REPOSITORIES=MixedSharedStaticLibs
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DTribitsExProj_ENABLE_MixedSharedStaticLibs=ON
      -DTribitsExProj_ENABLE_TESTS=ON
     .
    PASS_REGULAR_EXPRESSION_ALL
      "Final set of enabled top-level packages:  SimpleCxx MixedSharedStaticLibs 2"
      "Final set of enabled packages:  SimpleCxx MixedSharedStaticLibsSharedOnly MixedSharedStaticLibsStaticOnly MixedSharedStaticLibsStaticExec MixedSharedStaticLibs 5"
      "Configuring done"
      "Generating done"

  TEST_4 CMND make
    ARGS ${CTEST_BUILD_FLAGS}
    PASS_REGULAR_EXPRESSION_ALL
      "Linking CXX static library libsimplecxx.a"   # Shared because of BULID_SHARED_LIBS=OFF
      "Linking CXX shared library libshared_only_lib.so" # Always shared
      "Built target shared_only_lib"
      "Linking CXX static library libstatic_only_lib.a" # Always static
      "Built target static_only_lib"
      "Linking CXX executable MixedSharedStaticLibsSharedOnly_test"
      "Linking CXX executable MixedSharedStaticLibsStaticExec_test"
  TEST_5 CMND ${CMAKE_CTEST_COMMAND} ARGS -VV
    PASS_REGULAR_EXPRESSION_ALL
      "MixedSharedStaticLibsSharedOnly_test.* Passed"
      "MixedSharedStaticLibsStaticExec_test.* Passed"
      "100% tests passed, 0 tests failed out of 4"

  )
  # NOTE: The above test make sure that you can build a shared library with
  # tribits_add_library( ... SHARED ...) in project that is defaulted to use
  # static libs with BUILD_SHARED_LIBS=OFF.


########################################################################


tribits_add_advanced_test( TribitsExampleProject_DisableWithSubpackagesB_EnableWithSubpackagesB
  OVERALL_WORKING_DIRECTORY TEST_NAME
  OVERALL_NUM_MPI_PROCS 1

  TEST_0
    MESSAGE "Just do dependency analysis to test enabling of parent package"
     " with enabled subpackages even if is disabled"
    CMND ${CMAKE_COMMAND}
    ARGS
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=OFF
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF
      -DTribitsExProj_SHORTCIRCUIT_AFTER_DEPENDENCY_HANDLING=ON
      -DTribitsExProj_ENABLE_WithSubpackagesA=OFF
      -DTribitsExProj_ENABLE_WithSubpackagesB=ON
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Explicitly enabled packages on input .by user.:  WithSubpackagesB 1"
      "-- Setting TribitsExProj_ENABLE_WrapExternal=OFF because WrapExternal has a required library dependence on disabled package WithSubpackagesA"
      "Enabling all optional intra-package enables <TRIBITS_PACKAGE>_ENABLE_<DEPPACKAGE> that are not currently disabled if both sets of packages are enabled [.][.][.]"
      "-- NOT setting WithSubpackagesB_ENABLE_MixedLang=ON since MixedLang is NOT enabled at this point!"
      "Enabling the shell of non-enabled parent packages [(]mostly for show[)] that have at least one subpackage enabled [.][.][.]"
      "-- Setting TribitsExProj_ENABLE_WithSubpackages=ON because TribitsExProj_ENABLE_WithSubpackagesB=ON"
      "Final set of enabled top-level packages:  SimpleCxx WithSubpackages 2"
      "Final set of enabled packages:  SimpleCxx WithSubpackagesB WithSubpackages 3"

  )
# NOTE: The above test is the *only* test that we have that checks that a
# parent package is enabled at the end if any of its subpackages are enabled!
# This is also the only test that looks for the output that an optional
# package enable is not set.


########################################################################


tribits_add_advanced_test( TribitsExampleProject_compiler_flags
  OVERALL_WORKING_DIRECTORY  TEST_NAME
  OVERALL_NUM_MPI_PROCS  1
  EXCLUDE_IF_NOT_TRUE  IS_REAL_LINUX_SYSTEM  COMPILER_IS_GNU
    ${PROJECT_NAME}_ENABLE_Fortran  NINJA_EXE

  TEST_0
    MESSAGE "Configure by setting targets compiler flags for some packages"
    CMND ${CMAKE_COMMAND}
    ARGS
      -GNinja
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_PRINT_PACKAGE_COMPILER_FLAGS=ON
      -DCMAKE_C_FLAGS=-O2
      -DCMAKE_CXX_FLAGS=-Og
      -DCMAKE_Fortran_FLAGS=-Ofast
      -DSimpleCxx_C_FLAGS="--scxx-c-flags1 --scxx-c-flags2"
      -DSimpleCxx_CXX_FLAGS="--scxx-cxx-flags1 --scxx-cxx-flags2"
      -DSimpleCxx_Fortran_FLAGS="--scxx-f-flags1 --scxx-f-flags2"
      -DMixedLang_Fortran_FLAGS="--ml-f-flags1 --ml-f-flags2"
      -DWithSubpackages_C_FLAGS="--wsp-c-flags1 --wsp-c-flags2"
      -DWithSubpackages_CXX_FLAGS="--wsp-cxx-flags1 --wsp-cxx-flags2"
      -DWithSubpackages_Fortran_FLAGS="--wsp-f-flags1 --wsp-f-flags2"
      -DWithSubpackagesB_C_FLAGS="--wspb-c-flags1 --wspb-c-flags2"
      -DWithSubpackagesB_CXX_FLAGS="--wspb-cxx-flags1 --wspb-cxx-flags2"
      -DWithSubpackagesB_Fortarn_FLAGS="--wspb-f-flags1 --wspb-f-flags2"
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "-- SimpleCxx: CMAKE_C_FLAGS=.  -pedantic -Wall -Wno-long-long -std=c99  *-O2 --scxx-c-flags1 --scxx-c-flags2."
      "-- SimpleCxx: CMAKE_C_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- SimpleCxx: CMAKE_CXX_FLAGS=.  -pedantic -Wall -Wno-long-long -Wwrite-strings -Wshadow -Woverloaded-virtual  *-Og --scxx-cxx-flags1 --scxx-cxx-flags2."
      "-- SimpleCxx: CMAKE_CXX_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- SimpleCxx: CMAKE_Fortran_FLAGS=. *-Ofast --scxx-f-flags1 --scxx-f-flags2."
      "-- SimpleCxx: CMAKE_Fortran_FLAGS_RELEASE=.-O3."
      "-- Performing Test HAVE_SIMPLECXX___INT64"
      "-- Performing Test HAVE_SIMPLECXX___INT64 - Failed"
      "-- MixedLang: CMAKE_C_FLAGS=.  -pedantic -Wall -Wno-long-long -std=c99."
      "-- MixedLang: CMAKE_C_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- MixedLang: CMAKE_CXX_FLAGS=.  -pedantic -Wall -Wno-long-long -Wwrite-strings -Wshadow -Woverloaded-virtual  *-Og."
      "-- MixedLang: CMAKE_CXX_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- MixedLang: CMAKE_Fortran_FLAGS=. *-Ofast ."
      "-- MixedLang: CMAKE_Fortran_FLAGS_RELEASE=.-O3."
      "-- WithSubpackages: CMAKE_C_FLAGS=. -pedantic -Wall -Wno-long-long -std=c99  *-O2 --wsp-c-flags1 --wsp-c-flags2."
      "-- WithSubpackages: CMAKE_C_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackages: CMAKE_CXX_FLAGS=. -pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2."
      "-- WithSubpackages: CMAKE_CXX_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackages: CMAKE_Fortran_FLAGS=. *-Ofast --wsp-f-flags1 --wsp-f-flags2."
      "-- WithSubpackages: CMAKE_Fortran_FLAGS_RELEASE=.-O3."
      "-- WithSubpackagesA: CMAKE_C_FLAGS=. -pedantic -Wall -Wno-long-long -std=c99  *-O2 --wsp-c-flags1 --wsp-c-flags2."
      "-- WithSubpackagesA: CMAKE_C_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackagesA: CMAKE_CXX_FLAGS=. -pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2."
      "-- WithSubpackagesA: CMAKE_CXX_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackagesA: CMAKE_Fortran_FLAGS=. *-Ofast --wsp-f-flags1 --wsp-f-flags2."
      "-- WithSubpackagesA: CMAKE_Fortran_FLAGS_RELEASE=.-O3."
      "-- WithSubpackagesB: CMAKE_C_FLAGS=. -pedantic -Wall -Wno-long-long -std=c99  *-O2 --wsp-c-flags1 --wsp-c-flags2 --wspb-c-flags1 --wspb-c-flags2."
      "-- WithSubpackagesB: CMAKE_C_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackagesB: CMAKE_CXX_FLAGS=. -pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2 --wspb-cxx-flags1 --wspb-cxx-flags2."
      "-- WithSubpackagesB: CMAKE_CXX_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackagesB: CMAKE_Fortran_FLAGS=. *-Ofast --wsp-f-flags1 --wsp-f-flags2."
      "-- WithSubpackagesB: CMAKE_Fortran_FLAGS_RELEASE=.-O3."
      "-- WithSubpackagesC: CMAKE_C_FLAGS=. -pedantic -Wall -Wno-long-long -std=c99  *-O2 --wsp-c-flags1 --wsp-c-flags2."
      "-- WithSubpackagesC: CMAKE_C_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackagesC: CMAKE_CXX_FLAGS=. -pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2."
      "-- WithSubpackagesC: CMAKE_CXX_FLAGS_RELEASE=.-O3 -DNDEBUG."
      "-- WithSubpackagesC: CMAKE_Fortran_FLAGS=. *-Ofast --wsp-f-flags1 --wsp-f-flags2."
      "-- WithSubpackagesC: CMAKE_Fortran_FLAGS_RELEASE=.-O3."
    ALWAYS_FAIL_ON_NONZERO_RETURN
  # NOTE: Above, we have to use real compiler options for CMAKE_<LANG>_FLAGS
  # or the configure-time checks will not even work.  We can only use dummy
  # compiler options for the packages themselves.

  TEST_1
    MESSAGE "Build a SimpleCxx C++ file and check the compiler operations (we know build will fail)"
    CMND ${CMAKE_COMMAND} ARGS --build . -v --target packages/simple_cxx/src/CMakeFiles/simplecxx.dir/SimpleCxx_HelloWorld.cpp.o
    PASS_REGULAR_EXPRESSION_ALL
      "-pedantic -Wall -Wno-long-long -Wwrite-strings -Wshadow -Woverloaded-virtual  *-Og --scxx-cxx-flags1 --scxx-cxx-flags2 -O3 -DNDEBUG *-std=c[+][+]11"

  TEST_2
    MESSAGE "Build a MixedLang Fortran file and check the compiler operations (we know build will fail)"
    CMND ${CMAKE_COMMAND} ARGS --build . -v --target packages/mixed_lang/src/CMakeFiles/mixedlang.dir/Parameters.f90.o
    PASS_REGULAR_EXPRESSION_ALL
      "--ml-f-flags1 --ml-f-flags2 -O3"
    FAIL_REGULAR_EXPRESSION
      "--wspb-cxx-flags1 --wspb-cxx-flags2"

  TEST_3
    MESSAGE "Build a WithSubpackagesA C++ file and check the compiler operations (we know build will fail)"
    CMND ${CMAKE_COMMAND} ARGS --build . -v --target packages/with_subpackages/a/CMakeFiles/pws_a.dir/A.cpp.o
    PASS_REGULAR_EXPRESSION_ALL
      "-pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2 -O3 -DNDEBUG *-std=c[+][+]11"
    FAIL_REGULAR_EXPRESSION
      "--wspb-cxx-flags1 --wspb-cxx-flags2"
    # NOTE: Above regexes ensures that flags for WithSubpackagesB are not listed

  TEST_4
    MESSAGE "Build a WithSubpackagesB C++ file and check the compiler operations (we know build will fail)"
    CMND ${CMAKE_COMMAND} ARGS --build . -v --target packages/with_subpackages/b/src/CMakeFiles/pws_b.dir/B.cpp.o
    PASS_REGULAR_EXPRESSION_ALL
      "-pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2 --wspb-cxx-flags1 --wspb-cxx-flags2 -O3 -DNDEBUG *-std=c[+][+]11"
      # NOTE: Above regex ensures subpackage flags come after parent package flags

  TEST_5
    MESSAGE "Build a WithSubpackagesC C++ file and check the compiler operations (we know build will fail)"
    CMND ${CMAKE_COMMAND} ARGS --build . -v --target packages/with_subpackages/c/CMakeFiles/pws_c.dir/C.cpp.o
    PASS_REGULAR_EXPRESSION_ALL
      "-pedantic -Wall -Wno-long-long -Wwrite-strings  *-Og --wsp-cxx-flags1 --wsp-cxx-flags2 -O3 -DNDEBUG *-std=c[+][+]11"
    FAIL_REGULAR_EXPRESSION
      "--wspb-cxx-flags1 --wspb-cxx-flags2"
    # NOTE: Above regexes ensures that flags for WithSubpackagesB are not listed

  )
# NOTE: The above tests checks the compiler flags that are set by TriBITS for
# the various use cases.  This is a hard test to make portable because we
# really need to check that the compiler options are set all the way down.  To
# make this more portable, we only do this on Linux systems and only with GCC.
#
# We actually build known targets with 'make VERBOSE=1 <target>' and then grep
# the output to make sure the compiler flags drill down all the way to the
# actual targets.
#
# Note that we expect that as TriBITS evolves that the exact compiler options
# we be changed.  But that is okay.
#
# NOTE: Above, we had to switch to Ninja and 'cmake --build . -v [--target
# <target>] in order to get verbose output when run inside of a cmake -S
# script with CMake 3.23-rc2.  Not sure why this is but this is better anyway.


###################################################################################


tribits_add_advanced_test( TribitsExampleProject_extra_link_flags
  OVERALL_WORKING_DIRECTORY  TEST_NAME
  OVERALL_NUM_MPI_PROCS  1
  EXCLUDE_IF_NOT_TRUE  IS_REAL_LINUX_SYSTEM  ${PROJECT_NAME}_ENABLE_Fortran
    NINJA_EXE

  TEST_0
    MESSAGE "Configure by setting <Project>_EXTRA_LINK_FLAGS"
    CMND ${CMAKE_COMMAND}
    ARGS
      -GNinja
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_Fortran=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTPL_ENABLE_SimpleTpl=ON
      -DSimpleTpl_INCLUDE_DIRS=${SimpleTpl_install_STATIC_DIR}/install/include
      -DSimpleTpl_LIBRARY_DIRS=${SimpleTpl_install_STATIC_DIR}/install/lib
      -DTribitsExProj_EXTRA_LINK_FLAGS="-lgfortran -ldl"
      ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Processing enabled external package/TPL: TribitsExProjTribitsLastLib"
      "TPL_TribitsExProjTribitsLastLib_LIBRARIES='-lgfortran[;]-ldl'"
    ALWAYS_FAIL_ON_NONZERO_RETURN
  # NOTE: Above, we use two libraries to ensure that the logic in TriBITS can
  # handle these correctly.

  TEST_1
    MESSAGE "Build verbose to check the link lines"
    CMND ${CMAKE_COMMAND} ARGS --build . -v
    PASS_REGULAR_EXPRESSION_ALL
      "-o packages/simple_cxx/src/simplecxx-helloworld .* packages/simple_cxx/src/libsimplecxx.a +${SimpleTpl_install_STATIC_DIR}/install/lib/libsimpletpl.a +-lgfortran +-ldl"
      "-o packages/mixed_lang/test/MixedLang_RayTracerTests.exe  packages/mixed_lang/src/libmixedlang.a +-lgfortran +-ldl"
      "-o packages/with_subpackages/c/c_util +packages/with_subpackages/b/src/libpws_b.a +packages/with_subpackages/a/libpws_a.a +packages/simple_cxx/src/libsimplecxx.a +${SimpleTpl_install_STATIC_DIR}/install/lib/libsimpletpl.a +-lgfortran +-ldl"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  ADDED_TEST_NAME_OUT TribitsExampleProject_extra_link_flags_NAME
  )
  # NOTE: The above test ensures that <Project>_EXTRA_LINK_FLAGS is handled
  # correctly.  Note that the package MixedLang has no TPL dependencies so
  # that fact that the extra libs gets tacked on to the end proves that they
  # get sets even for packages without TPLs.  The package SimpleCxx that
  # depends on SimpleTPL proves that the extra libs get tacked on after the
  # TPL's libs.  Also, the fact that the extra libs are tacked on at the very
  # end of the link like for the 'c_util' exec shows that CMake is respecting
  # the dependency of libmixedlang.a on these extra libs.  This test also
  # shows that TriBITS and CMake do a good job of not listing the same libs
  # more than once.

if (TribitsExampleProject_extra_link_flags_NAME)
  set_tests_properties(${TribitsExampleProject_extra_link_flags_NAME}
    PROPERTIES DEPENDS ${SimpleTpl_install_STATIC_NAME} )
endif()


###################################################################################


tribits_add_advanced_test( TribitsExampleProject_External_SimpleCxx
  OVERALL_WORKING_DIRECTORY  TEST_NAME
  OVERALL_NUM_MPI_PROCS  1
  EXCLUDE_IF_NOT_TRUE  ${PROJECT_NAME}_ENABLE_Fortran  IS_REAL_LINUX_SYSTEM

  TEST_0
    MESSAGE "Copy TribitsExampleProject so we can change it"
    CMND cp
    ARGS -r ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .
#    CMND ln
#    ARGS -s ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Configure to just build and install just SimpleCxx"
    CMND ${CMAKE_COMMAND}
    WORKING_DIRECTORY Build_SimpleCxx
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DCMAKE_INSTALL_PREFIX=../install/simple_cxx
      -DTribitsExProj_SKIP_INSTALL_PROJECT_CMAKE_CONFIG_FILES=TRUE
      -DTPL_ENABLE_MPI=OFF
      -DTPL_ENABLE_SimpleTpl=ON
      -DSimpleTpl_INCLUDE_DIRS=${SimpleTpl_install_STATIC_DIR}/install/include
      -DSimpleTpl_LIBRARY_DIRS=${SimpleTpl_install_STATIC_DIR}/install/lib
      ../TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2
    MESSAGE "Build just SimpleCxx"
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    WORKING_DIRECTORY Build_SimpleCxx
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_3
    MESSAGE "Install just SimpleCxx"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install
    WORKING_DIRECTORY Build_SimpleCxx
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_4
    MESSAGE "Make sure only SimpleCxxConfig.cmake was installed"
    CMND ls ARGS install/simple_cxx/lib/cmake
    PASS_REGULAR_EXPRESSION_ALL
      "SimpleCxx"
    FAIL_REGULAR_EXPRESSION
      "TribitsExProj"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_5
    MESSAGE "Remove the build directory for SimpleCxx"
    CMND ${CMAKE_COMMAND} ARGS -E rm -R Build_SimpleCxx

  TEST_6
    MESSAGE "Remove the source directory for SimpleCxx"
    CMND ${CMAKE_COMMAND} ARGS -E rm -R
      TribitsExampleProject/packages/simple_cxx/CMakeLists.txt
      TribitsExampleProject/packages/simple_cxx/src
      TribitsExampleProject/packages/simple_cxx/test

  TEST_7
    MESSAGE "Configure rest of TribitsExampleProject against pre-installed SimpleCxx"
    CMND ${CMAKE_COMMAND}
    WORKING_DIRECTORY Build
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF # Allow WrapExternal enable
      -DTPL_ENABLE_SimpleCxx=ON
      -DCMAKE_PREFIX_PATH=../install/simple_cxx
      -DTPL_ENABLE_MPI=OFF
      -DTPL_ENABLE_SimpleTpl=ON
      ../TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Adjust the set of internal and external packages:"
      "-- Treating internal package SimpleCxx as EXTERNAL because TPL_ENABLE_SimpleCxx=ON"
      "-- NOTE: SimpleTpl is directly upstream from a TriBITS-compliant external package SimpleCxx"
      "-- NOTE: HeaderOnlyTpl is directly upstream from a TriBITS-compliant external package SimpleCxx"

      "Final set of enabled top-level packages:  MixedLang WithSubpackages WrapExternal 3"
      "Final set of enabled packages:  MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages WrapExternal 6"
      "Final set of non-enabled top-level packages:  0"
      "Final set of non-enabled packages:  0"
      "Final set of enabled top-level external packages/TPLs:  HeaderOnlyTpl SimpleTpl SimpleCxx 3"
      "Final set of enabled external packages/TPLs:  HeaderOnlyTpl SimpleTpl SimpleCxx 3"
      "Final set of non-enabled top-level external packages/TPLs:  MPI 1"
      "Final set of non-enabled external packages/TPLs:  MPI 1"

      "Getting information for all enabled TriBITS-compliant or upstream external packages/TPLs in reverse order [.][.][.]"
      "Processing enabled external package/TPL: SimpleCxx [(]enabled explicitly, disable with -DTPL_ENABLE_SimpleCxx=OFF[)]"
      "-- Calling find_package[(]SimpleCxx[)] for TriBITS-compliant external package"
      "-- Found SimpleCxx_DIR='.*/TriBITS_TribitsExampleProject_External_SimpleCxx/install/simple_cxx/lib[0-9]*/cmake/SimpleCxx'"
      "Processing enabled external package/TPL: SimpleTpl [(]enabled explicitly, disable with -DTPL_ENABLE_SimpleTpl=OFF[)]"
      "-- The external package/TPL SimpleTpl was defined by a downstream TriBITS-compliant external package already processed"
      "Processing enabled external package/TPL: HeaderOnlyTpl [(]enabled by SimpleCxx, disable with -DTPL_ENABLE_HeaderOnlyTpl=OFF[)]"
      "-- The external package/TPL HeaderOnlyTpl was defined by a downstream TriBITS-compliant external package already processed"

      "Getting information for all remaining enabled external packages/TPLs [.][.][.]"

      "Configuring individual enabled TribitsExProj packages [.][.][.]"
      "Processing enabled top-level package: MixedLang [(]Libs, Tests, Examples[)]"
      "Processing enabled top-level package: WithSubpackages [(]A, B, C, Tests, Examples[)]"
      "Processing enabled top-level package: WrapExternal [(]Libs, Tests, Examples[)]"

      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_8
    MESSAGE "Build TribitsExampleProject"
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    WORKING_DIRECTORY Build
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_9
    MESSAGE "Run all the tests with ctest"
    WORKING_DIRECTORY Build
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "100% tests passed, 0 tests failed out of 8"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  ADDED_TEST_NAME_OUT TribitsExampleProject_External_SimpleCxx_NAME
  )
# NOTE: The above test is a strong check that SimpleCxx is built and installed
# first and then is used in the later build of the rest of
# TribitsExampleProject.  If you comment out -DTPL_ENABLE_SimpleCxx=ON, then
# it will not build!  This test also uniquely tests a few other TriBITS features:
#
# * <Project>_SKIP_INSTALL_PROJECT_CMAKE_CONFIG_FILES (ensures the directory
# * install/simple_cxx/lib/cmake/TribitsExProj does not get created and
# * therefore the file TribitsExProjConfig.cmake does not get installed).


if (TribitsExampleProject_External_SimpleCxx_NAME)
  set_tests_properties(${TribitsExampleProject_External_SimpleCxx_NAME}
    PROPERTIES DEPENDS ${SimpleTpl_install_STATIC_NAME} )
endif()


################################################################################


tribits_add_advanced_test( TribitsExampleProject_External_Package_by_Package
  OVERALL_WORKING_DIRECTORY  TEST_NAME
  OVERALL_NUM_MPI_PROCS  1
  EXCLUDE_IF_NOT_TRUE  ${PROJECT_NAME}_ENABLE_Fortran  IS_REAL_LINUX_SYSTEM
  LIST_SEPARATOR <semicolon>

  TEST_0
    MESSAGE "Link TribitsExampleProject so it is easy to access"
    CMND ln
    ARGS -s ${${PROJECT_NAME}_TRIBITS_DIR}/examples/TribitsExampleProject .

  TEST_1
    MESSAGE "Configure to build and install just SimpleCxx"
    WORKING_DIRECTORY Build_SimpleCxx
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_SimpleCxx=ON
      -DCMAKE_INSTALL_PREFIX=../install_simplecxx
      -DTribitsExProj_SKIP_INSTALL_PROJECT_CMAKE_CONFIG_FILES=TRUE
      -DTPL_ENABLE_MPI=OFF
      -DTPL_ENABLE_SimpleTpl=ON
      -DSimpleTpl_INCLUDE_DIRS=${SimpleTpl_install_STATIC_DIR}/install/include
      -DSimpleTpl_LIBRARY_DIRS=${SimpleTpl_install_STATIC_DIR}/install/lib
      ../TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_2
    MESSAGE "Build and install just SimpleCxx"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install
    WORKING_DIRECTORY Build_SimpleCxx
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_3
    MESSAGE "Configure to build and install just MixedLang"
    WORKING_DIRECTORY Build_MixedLang
    CMND ${CMAKE_COMMAND}
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_MixedLang=ON
      -DCMAKE_INSTALL_PREFIX=../install_mixedlang
      -DTribitsExProj_SKIP_INSTALL_PROJECT_CMAKE_CONFIG_FILES=TRUE
      -DTPL_ENABLE_MPI=OFF
      ../TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_4
    MESSAGE "Build and install just MixedLang"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install
    WORKING_DIRECTORY Build_MixedLang
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_5
    MESSAGE "Configure to build and install just WithSubpackages against pre-installed SimpleCxx and MixedLang"
    CMND ${CMAKE_COMMAND}
    WORKING_DIRECTORY Build_WithSubpackages
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_WithSubpackages=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DCMAKE_INSTALL_PREFIX=../install_withsubpackages
      -DTribitsExProj_SKIP_INSTALL_PROJECT_CMAKE_CONFIG_FILES=TRUE
      -DTPL_ENABLE_MPI=OFF
      -DTPL_ENABLE_SimpleTpl=ON
      -DTPL_ENABLE_SimpleCxx=ON
      -DTPL_ENABLE_MixedLang=ON
      -DCMAKE_PREFIX_PATH=../install_simplecxx<semicolon>../install_mixedlang
      ../TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Adjust the set of internal and external packages:"
      "-- Treating internal package MixedLang as EXTERNAL because TPL_ENABLE_MixedLang=ON"
      "-- Treating internal package SimpleCxx as EXTERNAL because TPL_ENABLE_SimpleCxx=ON"
      "-- NOTE: SimpleTpl is directly upstream from a TriBITS-compliant external package SimpleCxx"
      "-- NOTE: HeaderOnlyTpl is directly upstream from a TriBITS-compliant external package SimpleCxx"
      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_6
    MESSAGE "Build and install just WithSubpackages"
    CMND make ARGS ${CTEST_BUILD_FLAGS} install
    WORKING_DIRECTORY Build_WithSubpackages
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_7
    MESSAGE "Test WithSubpackages"
    WORKING_DIRECTORY Build_WithSubpackages
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "WithSubpackagesA_test_of_a [.]* +Passed"
      "WithSubpackagesB_test_of_b [.]* +Passed"
      "WithSubpackagesB_test_of_b_mixed_lang [.]* +Passed"
      "WithSubpackagesC_test_of_c_util [.]* +Passed"
      "WithSubpackagesC_test_of_c [.]*   Passed"
      "WithSubpackagesC_test_of_c_b_mixed_lang ...   Passed"
      "100% tests passed, 0 tests failed out of 6"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  TEST_8
    MESSAGE "Configure rest of TribitsExampleProject against pre-installed SimpleCxx, MixedLang, and WithSubpackages"
    CMND ${CMAKE_COMMAND}
    WORKING_DIRECTORY Build
    ARGS
      ${TribitsExampleProject_COMMON_CONFIG_ARGS}
      -DTribitsExProj_TRIBITS_DIR=${${PROJECT_NAME}_TRIBITS_DIR}
      -DTribitsExProj_ENABLE_SECONDARY_TESTED_CODE=ON
      -DTribitsExProj_ENABLE_ALL_PACKAGES=ON
      -DTribitsExProj_ENABLE_TESTS=ON
      -DTribitsExProj_ENABLE_INSTALL_CMAKE_CONFIG_FILES=OFF # Allow WrapExternal enable
      -DTPL_ENABLE_MixedLang=ON
      -DTPL_ENABLE_WithSubpackages=ON
      -DCMAKE_PREFIX_PATH=../install_withsubpackages<semicolon>../install_mixedlang
      -DTPL_ENABLE_MPI=OFF
      -DTPL_ENABLE_SimpleTpl=ON
      ../TribitsExampleProject
    PASS_REGULAR_EXPRESSION_ALL
      "Adjust the set of internal and external packages:"
      "-- Treating internal package WithSubpackages as EXTERNAL because TPL_ENABLE_WithSubpackages=ON"
      "-- Treating internal package WithSubpackagesA as EXTERNAL because downstream package WithSubpackages being treated as EXTERNAL"
      "-- Treating internal package WithSubpackagesB as EXTERNAL because downstream package WithSubpackages being treated as EXTERNAL"
      "-- Treating internal package WithSubpackagesC as EXTERNAL because downstream package WithSubpackages being treated as EXTERNAL"
      "-- Treating internal package SimpleCxx as EXTERNAL because downstream package WithSubpackagesB being treated as EXTERNAL"
      "-- Treating internal package MixedLang as EXTERNAL because TPL_ENABLE_MixedLang=ON"
      "-- NOTE: SimpleTpl is indirectly upstream from a TriBITS-compliant external package"
      "-- NOTE: HeaderOnlyTpl is indirectly upstream from a TriBITS-compliant external package"

      "Final set of enabled top-level packages:  WrapExternal 1"
      "Final set of enabled packages:  WrapExternal 1"
      "Final set of non-enabled top-level packages:  0"
      "Final set of non-enabled packages:  0"
      "Final set of enabled top-level external packages/TPLs:  HeaderOnlyTpl SimpleTpl SimpleCxx MixedLang WithSubpackages 5"
      "Final set of enabled external packages/TPLs:  HeaderOnlyTpl SimpleTpl SimpleCxx MixedLang WithSubpackagesA WithSubpackagesB WithSubpackagesC WithSubpackages 8"
      "Final set of non-enabled top-level external packages/TPLs:  MPI 1"
      "Final set of non-enabled external packages/TPLs:  MPI 1"

      "Getting information for all enabled TriBITS-compliant or upstream external packages/TPLs in reverse order [.][.][.]"
      "Processing enabled external package/TPL: WithSubpackages [(]enabled explicitly, disable with -DTPL_ENABLE_WithSubpackages=OFF[)]"
      "-- Calling find_package[(]WithSubpackages[)] for TriBITS-compliant external package"
      "Processing enabled external package/TPL: MixedLang [(]enabled explicitly, disable with -DTPL_ENABLE_MixedLang=OFF[)]"
      "-- Found WithSubpackages_DIR='.*/TriBITS_TribitsExampleProject_External_Package_by_Package/install_withsubpackages/lib[0-9]*/cmake/WithSubpackages'"
      "-- Calling find_package[(]MixedLang[)] for TriBITS-compliant external package"
      "-- Found MixedLang_DIR='.*/TriBITS_TribitsExampleProject_External_Package_by_Package/install_mixedlang/lib[0-9]*/cmake/MixedLang'"
      "Processing enabled external package/TPL: SimpleCxx [(]enabled explicitly, disable with -DTPL_ENABLE_SimpleCxx=OFF[)]"
      "-- The external package/TPL SimpleCxx was defined by a downstream TriBITS-compliant external package already processed"
      "Processing enabled external package/TPL: SimpleTpl [(]enabled explicitly, disable with -DTPL_ENABLE_SimpleTpl=OFF[)]"
      "-- The external package/TPL SimpleTpl was defined by a downstream TriBITS-compliant external package already processed"
      "Processing enabled external package/TPL: HeaderOnlyTpl [(]enabled by SimpleCxx, disable with -DTPL_ENABLE_HeaderOnlyTpl=OFF[)]"
      "-- The external package/TPL HeaderOnlyTpl was defined by a downstream TriBITS-compliant external package already processed"

      "Getting information for all remaining enabled external packages/TPLs [.][.][.]"

      "Configuring individual enabled TribitsExProj packages [.][.][.]"
      "Processing enabled top-level package: WrapExternal [(]Libs, Tests, Examples[)]"

      "Configuring done"
    ALWAYS_FAIL_ON_NONZERO_RETURN
    # NOTE: Above, we don't need to look in install_simplecxx for SimpleCxx
    # because that will get found through WithSubpackages.  But we do need to
    # look for MixedLang because the libraries for WithSubpackages does not
    # actually depend on MixedLang so we need to add where to find it.

  TEST_9
    MESSAGE "Build rest of TribitsExampleProject"
    CMND make ARGS ${CTEST_BUILD_FLAGS}
    WORKING_DIRECTORY Build
    SKIP_CLEAN_WORKING_DIRECTORY

  TEST_10
    MESSAGE "Run all the remaining tests with ctest"
    WORKING_DIRECTORY Build
    SKIP_CLEAN_WORKING_DIRECTORY
    CMND ${CMAKE_CTEST_COMMAND}
    PASS_REGULAR_EXPRESSION_ALL
      "WrapExternal_run_external_func [.]* +Passed"
      "100% tests passed, 0 tests failed out of 1"
    ALWAYS_FAIL_ON_NONZERO_RETURN

  ADDED_TEST_NAME_OUT TribitsExampleProject_External_Package_by_Package_NAME
  )
# NOTE: The above test is a strong check that packages can be installed
# individually in stages on top of each other and that we are correctly
# writing wrapper <Package>Config.cmake files for TriBITS-compliant
# external packages (in this case for WithSubpackagesAConfig.cmake to
# include).


if (TribitsExampleProject_External_Package_by_Package_NAME)
  set_tests_properties(${TribitsExampleProject_External_Package_by_Package_NAME}
    PROPERTIES DEPENDS ${SimpleTpl_install_STATIC_NAME} )
endif()
