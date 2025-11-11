if (NOT DEFINED KERNEL_HEADERS_DIR)
    message(FATAL_ERROR "KERNEL_SRC_DIR Not defined.")
endif ()

add_compile_options(
        # Disable exceptions
        -fno-exceptions
        # Disable RTTI
        -fno-rtti
        # Disable PIE to avoid "Unknown rela relocation: 42" errors with R_X86_64_REX_GOTPCRELX TODO: this is probably avoidable
        -fno-pie
        # Include kconfig
        -include ${KERNEL_HEADERS_DIR}/include/linux/kconfig.h
)
