cmake_minimum_required(VERSION 3.26.0)

include(FetchContent)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/FindOrCloneDependency.cmake")
    include(FindOrCloneDependency REQUIRED)
    set(CUSTOM_DEP_HANDLER_INCLUDED TRUE)
else()
    message(WARNING "DependencyManagement: FindOrCloneDependency.cmake not found.")
    set(CUSTOM_DEP_HANDLER_INCLUDED FALSE)
endif()
