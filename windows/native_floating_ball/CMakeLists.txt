cmake_minimum_required(VERSION 3.20)
project(native_floating_ball LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_definitions(-DUNICODE -D_UNICODE)

add_executable(native_floating_ball WIN32
  src/app.cpp
  src/ball_wnd.cpp
  src/ball_wnd.h
  src/gif_player.cpp
  src/gif_player.h
  src/bubble_wnd.cpp
  src/bubble_wnd.h
)

target_include_directories(native_floating_ball PRIVATE src)

target_link_libraries(native_floating_ball
  PRIVATE d2d1 dwrite windowscodecs Dwmapi user32 gdi32 ole32 oleaut32
)

if (MSVC)
  target_compile_options(native_floating_ball PRIVATE /W4 /permissive-)
endif()
