include("${CMAKE_CURRENT_LIST_DIR}/rule.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/file.cmake")
set(Simple1_default_library_list )
# Handle files with suffix (s|as|asm|AS|ASM|As|aS|Asm) 
if(Simple1_default_FILE_GROUP_assemble)
    add_library(Simple1_default_assemble OBJECT ${Simple1_default_FILE_GROUP_assemble})
    Simple1_default_assemble_rule(Simple1_default_assemble)
    list(APPEND Simple1_default_library_list "$<TARGET_OBJECTS:Simple1_default_assemble>")
endif()

# Handle files with suffix S 
if(Simple1_default_FILE_GROUP_assemblePreprocess)
    add_library(Simple1_default_assemblePreprocess OBJECT ${Simple1_default_FILE_GROUP_assemblePreprocess})
    Simple1_default_assemblePreprocess_rule(Simple1_default_assemblePreprocess)
    list(APPEND Simple1_default_library_list "$<TARGET_OBJECTS:Simple1_default_assemblePreprocess>")
endif()

# Handle files with suffix [cC] 
if(Simple1_default_FILE_GROUP_compile)
    add_library(Simple1_default_compile OBJECT ${Simple1_default_FILE_GROUP_compile})
    Simple1_default_compile_rule(Simple1_default_compile)
    list(APPEND Simple1_default_library_list "$<TARGET_OBJECTS:Simple1_default_compile>")
endif()

if (BUILD_LIBRARY)
        message(STATUS "Building LIBRARY")
        add_library(${Simple1_default_image_name} ${Simple1_default_library_list})
        foreach(lib ${Simple1_default_FILE_GROUP_link})
        target_link_libraries(${Simple1_default_image_name} PRIVATE ${CMAKE_CURRENT_LIST_DIR} /${lib})
        endforeach()
        add_custom_command(
            TARGET ${Simple1_default_image_name}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${Simple1_default_output_dir}
    COMMAND ${CMAKE_COMMAND} -E copy lib${Simple1_default_image_name}.a ${Simple1_default_output_dir}/${Simple1_default_original_image_name})
else()
    message(STATUS "Building STANDARD")
    add_executable(${Simple1_default_image_name} ${Simple1_default_library_list})
    foreach(lib ${Simple1_default_FILE_GROUP_link})
    target_link_libraries(${Simple1_default_image_name} PRIVATE ${CMAKE_CURRENT_LIST_DIR}/${lib})
endforeach()
    Simple1_default_link_rule(${Simple1_default_image_name})
    
add_custom_command(
    TARGET ${Simple1_default_image_name}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${Simple1_default_output_dir}
    COMMAND ${CMAKE_COMMAND} -E copy ${Simple1_default_image_name} ${Simple1_default_output_dir}/${Simple1_default_original_image_name})
endif()
