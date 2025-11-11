cmake_minimum_required(VERSION 3.26.0)

# tools
set(CLANG_EXECUTABLE "" CACHE FILEPATH "Path to clang executable")
set(BPFTOOL_EXECUTABLE "" CACHE FILEPATH "Path to bpftool executable")
set(SHELL_EXECUTABLE "" CACHE FILEPATH "Path to shell executable")

if (CLANG_EXECUTABLE)
    set(CLANG ${CLANG_EXECUTABLE})
else ()
    find_program(CLANG clang REQUIRED)
endif ()

if (BPFTOOL_EXECUTABLE)
    set(BPFTOOL ${BPFTOOL_EXECUTABLE})
else ()
    find_program(BPFTOOL bpftool REQUIRED)
endif ()

if (SHELL_EXECUTABLE)
    set(SHELL ${SHELL_EXECUTABLE})
else ()
    find_program(SHELL sh REQUIRED)
endif ()

execute_process(
        COMMAND ${BPFTOOL} --version
        OUTPUT_VARIABLE BPFTOOL_VERSION
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

if (NOT BPFTOOL_VERSION VERSION_GREATER_EQUAL "5.7")
    message(WARNING "bpftool version (${BPFTOOL_VERSION}) is older than recommended 5.7+, may cause incompatibilities")
endif ()