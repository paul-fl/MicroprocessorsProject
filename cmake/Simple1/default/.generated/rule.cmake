function(Simple1_default_assemble_rule target)
    set(inputVar "${MP_CC};-c;${MP_EXTRA_AS_PRE};-mcpu=18F87K22;-mdfp=C:/Users/Joey/.mchp_packs/Microchip/PIC18F-K_DFP/1.8.249/xc8;-fno-short-double;-fno-short-float;-O0;-maddrqual=ignore;-mwarn=-3;-DXPRJ_default=default;-msummary=-psect,-class,+mem,-hex,-file;-ginhx32;-Wl,--data-init;-mno-keep-startup;-mno-download;-mno-default-config-bits;-std=c99;-gdwarf-3;-mstack=compiled:auto:auto:auto;${INSTRUMENTED_TRACE_OPTIONS}")
    string(REGEX REPLACE "[,]+" "," noDoubleCommas "${inputVar}")
    string(REGEX REPLACE ",$" "" noDanglingCommas "${noDoubleCommas}")
    target_compile_options(${target} PRIVATE "${noDanglingCommas}")
endfunction()
function(Simple1_default_assemblePreprocess_rule target)
    set(inputVar "-c;${MP_EXTRA_AS_PRE};-mcpu=18F87K22;-mdfp=C:/Users/Joey/.mchp_packs/Microchip/PIC18F-K_DFP/1.8.249/xc8;-fno-short-double;-fno-short-float;-O0;-maddrqual=ignore;-mwarn=-3;-DXPRJ_default=default;-msummary=-psect,-class,+mem,-hex,-file;-ginhx32;-Wl,--data-init;-mno-keep-startup;-mno-download;-mno-default-config-bits;-std=c99;-gdwarf-3;-mstack=compiled:auto:auto:auto;${INSTRUMENTED_TRACE_OPTIONS}")
    string(REGEX REPLACE "[,]+" "," noDoubleCommas "${inputVar}")
    string(REGEX REPLACE ",$" "" noDanglingCommas "${noDoubleCommas}")
    target_compile_options(${target} PRIVATE "${noDanglingCommas}")
endfunction()
function(Simple1_default_compile_rule target)
    set(inputVar "${MP_CC};${MP_EXTRA_CC_PRE};-mcpu=18F87K22;-c;-mdfp=C:/Users/Joey/.mchp_packs/Microchip/PIC18F-K_DFP/1.8.249/xc8;-fno-short-double;-fno-short-float;-O0;-maddrqual=ignore;-mwarn=-3;-DXPRJ_default=default;-msummary=-psect,-class,+mem,-hex,-file;-ginhx32;-Wl,--data-init;-mno-keep-startup;-mno-download;-mno-default-config-bits;-std=c99;-gdwarf-3;-mstack=compiled:auto:auto:auto;${INSTRUMENTED_TRACE_OPTIONS};${FUNCTION_LEVEL_PROFILING_OPTIONS}")
    string(REGEX REPLACE "[,]+" "," noDoubleCommas "${inputVar}")
    string(REGEX REPLACE ",$" "" noDanglingCommas "${noDoubleCommas}")
    target_compile_options(${target} PRIVATE "${noDanglingCommas}")
endfunction()
function(Simple1_default_link_rule target)
    set(inputVar "${MP_EXTRA_LD_PRE};-mcpu=18F87K22;-Wl,-Map=mem.map;-DXPRJ_default=default;-Wl,--defsym=__MPLAB_BUILD=1;-mdfp=C:/Users/Joey/.mchp_packs/Microchip/PIC18F-K_DFP/1.8.249/xc8;-fno-short-double;-fno-short-float;-O0;-maddrqual=ignore;-mwarn=-3;-msummary=-psect,-class,+mem,-hex,-file;-ginhx32;-Wl,--data-init;-mno-keep-startup;-mno-download;-mno-default-config-bits;-std=c99;-gdwarf-3;-mstack=compiled:auto:auto:auto;${INSTRUMENTED_TRACE_OPTIONS};${FUNCTION_LEVEL_PROFILING_OPTIONS};-Wl,--memorysummary,memoryfile.xml,")
    string(REGEX REPLACE "[,]+" "," noDoubleCommas "${inputVar}")
    string(REGEX REPLACE ",$" "" noDanglingCommas "${noDoubleCommas}")
    target_link_options(${target} PRIVATE "${noDanglingCommas}")
endfunction()
