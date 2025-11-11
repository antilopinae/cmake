cmake_minimum_required(VERSION 3.26.0 FATAL_ERROR)

execute_process(COMMAND uname -r
        OUTPUT_VARIABLE ANT_UNAME_R
        OUTPUT_STRIP_TRAILING_WHITESPACE)

message(STATUS "Detected kernel release: ${ANT_UNAME_R}")

set(KERNEL_BUILD_DIRECTORY "" CACHE INTERNAL "Path to kernel src")

set(LOCAL_KERNEL_BUILD_DIR "/lib/modules/${ANT_UNAME_R}/build")
set(USE_LOCAL_KERNEL_BUILD_DIR FALSE)

if (EXISTS "${LOCAL_KERNEL_BUILD_DIR}")
    message(STATUS "Found kernel build dir: ${LOCAL_KERNEL_BUILD_DIR} — will use system headers")
    set(USE_LOCAL_KERNEL_BUILD_DIR TRUE)
endif ()

if (NOT USE_LOCAL_KERNEL_BUILD_DIR)
    message(FATAL_ERROR "Not found kernel build dir")
#    string(REGEX MATCH "([0-9]+\\.[0-9]+\\.[0-9]+)" _ MATCHED ${ANT_UNAME_R})
#    if (MATCHED)
#        set(ANT_KERNEL_VERSION ${CMAKE_MATCH_1})
#        message(STATUS "Extracted semantic kernel version: ${ANT_KERNEL_VERSION}")
#    else ()
#        message(FATAL_ERROR "Cannot extract semantic X.Y.Z from ${ANT_UNAME_R}; set kernel version manually")
#    endif ()
#
#    set(ANT_KERNEL_TARBALL "linux-${ANT_KERNEL_VERSION}.tar.xz")
#    set(ANT_KERNEL_URL "https://cdn.kernel.org/pub/linux/kernel/v6.x/${ANT_KERNEL_TARBALL}")
#
#    ExternalProject_Add(kernel-download-src
#            URL ${ANT_KERNEL_URL}
#            PREFIX ${CMAKE_BINARY_DIR}/kernel-src
#            CONFIGURE_COMMAND ""
#            BUILD_COMMAND make -C <SOURCE_DIR> defconfig && make -C <SOURCE_DIR> vmlinux -j${CMAKE_BUILD_PARALLEL_LEVEL}
#            BUILD_BYPRODUCTS <SOURCE_DIR>/vmlinux
#            INSTALL_COMMAND ""
#    )
#
#    ExternalProject_Get_Property(kernel-download-src SOURCE_DIR)
#    set(KERNEL_BUILD_DIRECTORY ${SOURCE_DIR} CACHE INTERNAL "Path to kernel build src")
#
#    add_custom_target(kernel-headers ALL
#            DEPENDS ${SOURCE_DIR}/vmlinux
#            COMMENT "Kernel vmlinux will be available at: ${SOURCE_DIR}"
#    )
#
#    add_dependencies(kernel-headers kernel-download-headers)
else ()
    set(KERNEL_BUILD_DIRECTORY ${LOCAL_KERNEL_BUILD_DIR} CACHE INTERNAL "Path to kernel build src")
    add_custom_target(kernel-headers ALL
            COMMENT "Using system kernel headers at ${KERNEL_BUILD_DIRECTORY}"
    )
endif ()

if (USE_LOCAL_KERNEL_BUILD_DIR)
    if (NOT EXISTS "${KERNEL_BUILD_DIRECTORY}/Makefile")
        message(FATAL_ERROR "Kernel build dir ${KERNEL_BUILD_DIRECTORY} has no Makefile. Install linux-headers for your kernel.")
    endif ()
endif ()

set(KERNEL_HEADERS_DIRECTORY "${KERNEL_BUILD_DIRECTORY}" CACHE INTERNAL "Path to kernel headers")

#[==[
set(KERNEL_HEADERS_DIRECTORY "${CMAKE_BINARY_DIR}/kernel-headers" CACHE INTERNAL "Path to kernel headers")


# Copy the required header files
execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${KERNEL_BUILD_DIRECTORY}/include
        ${KERNEL_HEADERS_DIRECTORY}/include
)

execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${KERNEL_BUILD_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include
        ${KERNEL_HEADERS_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include
)

# Modify header files which aren't C++ conformant
function(_replace_in_file FILE_PATH REGEX REPLACEMENT)
    if (NOT EXISTS ${FILE_PATH})
        message(FATAL_ERROR "Attempted to replace data in ${FILE_PATH} which does not exist.")
    endif()

    file(READ ${FILE_PATH} FILE_DATA)
    string(REGEX REPLACE "${REGEX}" "${REPLACEMENT}" FILE_DATA "${FILE_DATA}")
    file(WRITE ${FILE_PATH} "${FILE_DATA}")
endfunction()

if (CMAKE_SYSTEM_PROCESSOR STREQUAL "x86" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(PROCESSOR_ARCHITECTURE "x86")
else()
    set(PROCESSOR_ARCHITECTURE "x64")
#    message(FATAL_ERROR "Unsupported platform architecture.")
endif()

_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/stddef.h
        "enum {\n\tfalse\t= 0,\n\ttrue\t= 1\n};" "")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/types.h
        "typedef _Bool\t+bool;" "")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/init.h
        "offset_to_ptr\\(entry\\)" "reinterpret_cast<initcall_t>(offset_to_ptr(entry))")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/const.h
        "void" "int")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/list.h
        "new" "new_head")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/list.h
        "(entry|old|h)->(prev|first|pprev|next) = NULL;" "\\1->\\2 = reinterpret_cast<decltype(\\1->\\2)>(NULL);")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/list.h
        "(n|entry)->(next|prev|pprev) = LIST_POISON([0-9]+);" "\\1->\\2 = reinterpret_cast<decltype(\\1->\\2)>(LIST_POISON\\3);")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/poison.h
        "void" "char")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/build_bug.h
        "\\(\\(int\\)\\(sizeof\\(struct \\{ int\\:\\(\\-\\!\\!\\(e\\)\\)\\; \\}\\)\\)\\)"
        "0") # TODO: find a proper fix if possible
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/string.h
        "new" "replacement")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/bitmap.h
        "new" "replacement")
#[=[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/math.h
        "#define abs" "\n#define abs_unused")]=]
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/linux/atomic/atomic-long.h
        "new" "new_value")
#[[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/asm-generic/bitops/find.h
        "NULL" "reinterpret_cast<const unsigned long*>(0)")]]
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/asm-generic/bitops/le.h
        "NULL" "reinterpret_cast<const unsigned long*>(0)")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/asm-generic/bitops/le.h
        "test_bit\\(nr \\^ BITOP_LE_SWIZZLE, addr\\)" "test_bit(nr ^ BITOP_LE_SWIZZLE, reinterpret_cast<const unsigned long*>(addr))")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/asm-generic/bitops/le.h
        "bit\\(addr" "bit(reinterpret_cast<const unsigned long*>(addr)")
_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/include/asm-generic/bitops/le.h
        ", addr" ", reinterpret_cast<volatile unsigned long*>(addr)")
#[[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include/asm/bitops.h
        "\\(void \\*\\)\\(addr\\)" "reinterpret_cast<volatile char*>(addr)")]]
#[[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include/asm/atomic.h
        "new" "new_value")]]
#[[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include/asm/atomic64_64.h
        "new" "new_value")]]
#[[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include/asm/cmpxchg.h
        "new" "new_value")]]
#[[_replace_in_file(${KERNEL_HEADERS_DIRECTORY}/arch/${PROCESSOR_ARCHITECTURE}/include/asm/string_64.h
        "(dst|src) \\+ 8" "reinterpret_cast<char*>(\\1) + 8")]]

]==]

