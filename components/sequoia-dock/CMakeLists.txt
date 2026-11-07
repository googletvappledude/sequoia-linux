cmake_minimum_required(VERSION 3.20)
project(sequoia-dock VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Qml Gui)
find_package(LayerShellQt REQUIRED)

qt_add_executable(sequoia-dock src/main.cpp)
qt_add_qml_module(sequoia-dock URI SequoiaDock VERSION 1.0
    QML_FILES qml/Main.qml qml/DockItem.qml)
target_link_libraries(sequoia-dock PRIVATE Qt6::Quick Qt6::Qml Qt6::Gui LayerShellQt::Interface)
install(TARGETS sequoia-dock RUNTIME DESTINATION bin)
