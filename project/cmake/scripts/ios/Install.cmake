# IOS packaging

set(BUNDLE_RESOURCES ${CORE_SOURCE_DIR}/xbmc/platform/darwin/ios/Default-568h@2x.png
                     ${CORE_SOURCE_DIR}/xbmc/platform/darwin/ios/Default-667h@2x.png
                     ${CORE_SOURCE_DIR}/xbmc/platform/darwin/ios/Default-736h@3x.png
                     ${CORE_SOURCE_DIR}/xbmc/platform/darwin/ios/Default-Landscape-736h@3x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon29x29.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon29x29@2x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon40x40.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon40x40@2x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon50x50.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon50x50@2x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon57x57.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon57x57@2x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon60x60.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon60x60@2x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon72x72.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon72x72@2x.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon76x76.png
                     ${CORE_SOURCE_DIR}/tools/darwin/packaging/media/ios/rounded/AppIcon76x76@2x.png)

if(CMAKE_GENERATOR STREQUAL Xcode)
  set(RESOURCE_LOCATION ${APP_NAME}.app)
else()
  set(RESOURCE_LOCATION ".")
endif()

target_sources(${APP_NAME_LC} PRIVATE ${BUNDLE_RESOURCES})
foreach(file IN LISTS BUNDLE_RESOURCES)
  set_source_files_properties(${file} PROPERTIES MACOSX_PACKAGE_LOCATION ${RESOURCE_LOCATION})
endforeach()

target_sources(${APP_NAME_LC} PRIVATE ${CORE_SOURCE_DIR}/xbmc/platform/darwin/ios/English.lproj/InfoPlist.strings)
set_source_files_properties(${CORE_SOURCE_DIR}/xbmc/platform/darwin/ios/English.lproj/InfoPlist.strings PROPERTIES MACOSX_PACKAGE_LOCATION "${RESOURCE_LOCATION}/English.lproj")

# Options for code signing propagated as env vars to Codesign.command via Xcode
set(IOS_CODE_SIGN_IDENTITY "" CACHE STRING "Code Sign Identity")
if(IOS_CODE_SIGN_IDENTITY)
  set_target_properties(${APP_NAME_LC} PROPERTIES XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED TRUE
                                                  XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ${IOS_CODE_SIGN_IDENTITY})
endif()

add_custom_command(TARGET ${APP_NAME_LC} POST_BUILD
    # TODO: Remove in sync with CopyRootFiles-ios expecting the ".bin" file
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${APP_NAME_LC}>
                                     $<TARGET_FILE_DIR:${APP_NAME_LC}>/${APP_NAME}.bin

    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/DllPaths_generated.h
                                     ${CMAKE_BINARY_DIR}/xbmc/DllPaths_generated.h
    COMMAND "ACTION=build"
            "TARGET_BUILD_DIR=$<TARGET_FILE_DIR:${APP_NAME_LC}>/.."
            "TARGET_NAME=${APP_NAME}.app"
            "APP_NAME=${APP_NAME}"
            "PRODUCT_NAME=${APP_NAME}"
            "WRAPPER_EXTENSION=app"
            "SRCROOT=${CMAKE_BINARY_DIR}"
            ${CORE_SOURCE_DIR}/tools/darwin/Support/CopyRootFiles-ios.command
    COMMAND "XBMC_DEPENDS=${DEPENDS_PATH}"
            "TARGET_BUILD_DIR=$<TARGET_FILE_DIR:${APP_NAME_LC}>/.."
            "TARGET_NAME=${APP_NAME}.app"
            "APP_NAME=${APP_NAME}"
            "PRODUCT_NAME=${APP_NAME}"
            "FULL_PRODUCT_NAME=${APP_NAME}.app"
            "WRAPPER_EXTENSION=app"
            "SRCROOT=${CMAKE_BINARY_DIR}"
            ${CORE_SOURCE_DIR}/tools/darwin/Support/copyframeworks-ios.command
    COMMAND "XBMC_DEPENDS_ROOT=${NATIVEPREFIX}/.."
            "PLATFORM_NAME=${PLATFORM}"
            "CODESIGNING_FOLDER_PATH=$<TARGET_FILE_DIR:${APP_NAME_LC}>"
            "BUILT_PRODUCTS_DIR=$<TARGET_FILE_DIR:${APP_NAME_LC}>/.."
            "WRAPPER_NAME=${APP_NAME}.app"
            "APP_NAME=${APP_NAME}"
            ${CORE_SOURCE_DIR}/tools/darwin/Support/Codesign.command
)

set(DEPENDS_ROOT_FOR_XCODE ${NATIVEPREFIX}/..)
configure_file(${CORE_SOURCE_DIR}/tools/darwin/packaging/ios/mkdeb-ios.sh.in
               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/ios/mkdeb-ios.sh @ONLY)
configure_file(${CORE_SOURCE_DIR}/tools/darwin/packaging/migrate_to_kodi_ios.sh.in
               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/migrate_to_kodi_ios.sh @ONLY)

add_custom_target(deb
    COMMAND sh ./mkdeb-ios.sh ${CORE_BUILD_CONFIG}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tools/darwin/packaging/ios)
add_dependencies(deb ${APP_NAME_LC})
