cmake_minimum_required(VERSION 3.26.0 FATAL_ERROR)

message(FATAL_ERROR "CPP does not working now")

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    include(ClangKernelOptions REQUIRED)
    include(ClangKernelDefinitions REQUIRED)
else ()
    message(FATAL_ERROR "Unsupported compiler toolchain")
endif ()

function(add_cpp_kernel_module MODULE_NAME MODULE_SRC_DIR)
    set(MODULE_SOURCE_FILES ${ARGN})

    add_library(${MODULE_NAME}-obj OBJECT ${MODULE_SOURCE_FILES})

    target_include_directories(${MODULE_NAME}-obj PUBLIC
            ${MODULE_SRC_DIR}/include
    )

    target_include_directories(${MODULE_NAME}-obj PRIVATE
            ${KERNEL_HEADERS_DIRECTORY}/include
    )

    target_precompile_headers(${MODULE_NAME}-obj PUBLIC
            ${KERNEL_HEADERS_DIRECTORY}/include/linux/kconfig.h
    )

    # Define the target and add the OBJECT library as a dependency
    add_custom_target(${MODULE_NAME})
    add_dependencies(${MODULE_NAME} ${MODULE_NAME}-obj)

    # Find the directory which contains the object files
    set(OBJECT_FILES_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${MODULE_NAME}-obj.dir")

    # Set the directory for the build files
    set(KERNEL_MODULE_BUILD_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${MODULE_NAME}-build-files)

    # Generate the Kbuild file on the POST_BUILD event
    add_custom_command(
            TARGET ${MODULE_NAME}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND}
            -DMODULE_NAME=${MODULE_NAME}
            -DOBJECT_FILES_DIRECTORY=${OBJECT_FILES_DIRECTORY}
            -DBINARY_DIRECTORY=${KERNEL_MODULE_BUILD_DIRECTORY}
            -P ${CMAKE_SOURCE_DIR}/cmake/GenerateKBuild.cmake
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating the Kbuild file."
            VERBATIM
    )

    # Invoke make to build the kernel module
    add_custom_command(
            TARGET ${MODULE_NAME}
            POST_BUILD
            COMMAND make -C ${KERNEL_BUILD_DIRECTORY} M=${KERNEL_MODULE_BUILD_DIRECTORY} modules
            WORKING_DIRECTORY ${KERNEL_MODULE_BUILD_DIRECTORY}
            COMMENT "Building the kernel module."
            VERBATIM
    )
endfunction()
