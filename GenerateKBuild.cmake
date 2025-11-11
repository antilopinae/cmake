cmake_minimum_required(VERSION 3.26.0 FATAL_ERROR)

function(generate_linker_scripts BINARY_DIRECTORY)
    # Generate a script to support constructors
    file(WRITE ${BINARY_DIRECTORY}/init-array.lds
            "SECTIONS {\n"
            "    .init_array : {\n"
            "        init_array_start = .;\n"
            "        *(.init_array);\n"
            "        init_array_end = .;\n"
            "    }\n"
            "}\n")
endfunction()

generate_linker_scripts(BINARY_DIRECTORY)

# Create a list of object files
file(GLOB_RECURSE OBJECT_FILES "${OBJECT_FILES_DIRECTORY}/*.o")

# Find the relative path to the object files (for Kbuild)
file(RELATIVE_PATH RELATIVE_OBJECTS_PATH ${BINARY_DIRECTORY} ${OBJECT_FILES_DIRECTORY})

# Write the Kbuild file
list(JOIN OBJECT_FILES " " OBJECT_FILES_FORMATTED)
string(REPLACE "${OBJECT_FILES_DIRECTORY}" "${RELATIVE_OBJECTS_PATH}" OBJECT_FILES_FORMATTED "${OBJECT_FILES_FORMATTED}")

file(WRITE ${BINARY_DIRECTORY}/Kbuild
        "# Module name: ${MODULE_NAME}.ko\n"
        "obj-m += ${MODULE_NAME}.o\n"
        "# Module objects\n"
        "${MODULE_NAME}-y := ${OBJECT_FILES_FORMATTED}\n"
        "KBUILD_LDFLAGS := -T ${BINARY_DIRECTORY}/init-array.lds\n"
)

# Create the necessary files for Kbuild
foreach (FILE_PATH ${OBJECT_FILES})
    # Get the filename components
    get_filename_component(FILE_DIRECTORY ${FILE_PATH} DIRECTORY)
    get_filename_component(FILE_NAME ${FILE_PATH} NAME)

    # Create the cmd file
    file(TOUCH ${FILE_DIRECTORY}/.${FILE_NAME}.cmd)
endforeach ()

