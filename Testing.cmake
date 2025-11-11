cmake_minimum_required(VERSION 3.26.0 FATAL_ERROR)

enable_testing()

find_package(GTest CONFIG REQUIRED)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")
find_package(CUnit REQUIRED)
