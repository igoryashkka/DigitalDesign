# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "C:\\Users\\user\\Documents\\dd_ihor\\DigitalDesign\\DF4\\ws_vitis\\platform_xsa\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\sleep.h"
  "C:\\Users\\user\\Documents\\dd_ihor\\DigitalDesign\\DF4\\ws_vitis\\platform_xsa\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xiltimer.h"
  "C:\\Users\\user\\Documents\\dd_ihor\\DigitalDesign\\DF4\\ws_vitis\\platform_xsa\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xtimer_config.h"
  "C:\\Users\\user\\Documents\\dd_ihor\\DigitalDesign\\DF4\\ws_vitis\\platform_xsa\\microblaze_0\\standalone_microblaze_0\\bsp\\lib\\libxiltimer.a"
  )
endif()
