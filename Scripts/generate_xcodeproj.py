#!/usr/bin/env python3
"""Regenerates DontPress.xcodeproj/project.pbxproj and the shared scheme.

The project uses Xcode 16 file-system-synchronized groups, so adding a source file
to DontPress/, DontPressTests/ or DontPressUITests/ needs no project edits.
"""
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PROJ = os.path.join(ROOT, "DontPress.xcodeproj")

def i(n): return f"D0A7{n:020X}"

PROJECT, MAIN_GROUP, PRODUCTS = i(1), i(2), i(3)
APP, TESTS, UITESTS = i(10), i(11), i(12)                     # native targets
APP_REF, TESTS_REF, UITESTS_REF = i(20), i(21), i(22)         # product refs
APP_SYNC, TESTS_SYNC, UITESTS_SYNC = i(30), i(31), i(32)      # synchronized groups
APP_SRC, APP_FW, APP_RES = i(40), i(41), i(42)
T_SRC, T_FW, T_RES = i(43), i(44), i(45)
U_SRC, U_FW, U_RES = i(46), i(47), i(48)
PROJ_CFGLIST, APP_CFGLIST, T_CFGLIST, U_CFGLIST = i(50), i(51), i(52), i(53)
PROJ_DEBUG, PROJ_RELEASE = i(60), i(61)
APP_DEBUG, APP_RELEASE = i(62), i(63)
T_DEBUG, T_RELEASE = i(64), i(65)
U_DEBUG, U_RELEASE = i(66), i(67)
T_DEP, U_DEP, T_PROXY, U_PROXY = i(70), i(71), i(72), i(73)

BUNDLE_ID = "com.davidpitchkhadze.dontpress"   # chosen for the owner; cannot be changed after the app record is created in App Store Connect

def settings(d):
    return "\n".join(f"\t\t\t\t{k} = {v};" for k, v in d.items())

proj_common = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_VERSION": "5.0",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
}
proj_debug = dict(proj_common, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": '(\n\t\t\t\t\t"DEBUG=1",\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t)',
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG $(inherited)"',
    "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
})
proj_release = dict(proj_common, **{
    "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
    "ENABLE_NS_ASSERTIONS": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
    "MTL_ENABLE_DEBUG_INFO": "NO",
})

app_common = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ENABLE_PREVIEWS": "YES",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": '""',
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": '"DON\'T PRESS"',
    "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
    "INFOPLIST_KEY_LSApplicationCategoryType": '"public.app-category.entertainment"',
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UILaunchScreen_BackgroundColor": "LaunchBackground",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UIUserInterfaceStyle": "Dark",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks")',
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
    "SUPPORTS_MACCATALYST": "NO",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1",
}
test_common = {
    "BUNDLE_LOADER": '"$(TEST_HOST)"',
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": '""',
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID + ".tests",
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "TARGETED_DEVICE_FAMILY": "1",
    "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/DontPress.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DontPress"',
}
uitest_common = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": '""',
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID + ".uitests",
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "TARGETED_DEVICE_FAMILY": "1",
    "TEST_TARGET_NAME": "DontPress",
}

def cfg(id_, name, d):
    return f"\t\t{id_} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{settings(d)}\n\t\t\t}};\n\t\t\tname = {name};\n\t\t}};\n"

def phase(kind, id_, name):
    return f"\t\t{id_} /* {name} */ = {{\n\t\t\tisa = {kind};\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n"

def cfglist(id_, kind, name, dbg, rel):
    return (f"\t\t{id_} /* Build configuration list for {kind} \"{name}\" */ = {{\n\t\t\tisa = XCConfigurationList;\n"
            f"\t\t\tbuildConfigurations = (\n\t\t\t\t{dbg} /* Debug */,\n\t\t\t\t{rel} /* Release */,\n\t\t\t);\n"
            f"\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n")

def target(id_, name, ref, sync, src, fw, res, cl, ptype, deps=()):
    dep = "".join(f"\t\t\t\t{d},\n" for d in deps)
    return (f"\t\t{id_} /* {name} */ = {{\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = {cl};\n"
            f"\t\t\tbuildPhases = (\n\t\t\t\t{src} /* Sources */,\n\t\t\t\t{fw} /* Frameworks */,\n\t\t\t\t{res} /* Resources */,\n\t\t\t);\n"
            f"\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n{dep}\t\t\t);\n"
            f"\t\t\tfileSystemSynchronizedGroups = (\n\t\t\t\t{sync},\n\t\t\t);\n\t\t\tname = {name};\n"
            f"\t\t\tpackageProductDependencies = (\n\t\t\t);\n\t\t\tproductName = {name};\n\t\t\tproductReference = {ref};\n\t\t\tproductType = \"{ptype}\";\n\t\t}};\n")

def proxy(id_, remote_info, name):
    return (f"\t\t{id_} /* PBXContainerItemProxy */ = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {PROJECT} /* Project object */;\n"
            f"\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {APP};\n\t\t\tremoteInfo = {name};\n\t\t}};\n")

def dep(id_, proxy_id):
    return (f"\t\t{id_} /* PBXTargetDependency */ = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {APP} /* DontPress */;\n\t\t\ttargetProxy = {proxy_id} /* PBXContainerItemProxy */;\n\t\t}};\n")

def fileref(id_, name, ptype):
    return f"\t\t{id_} /* {name} */ = {{isa = PBXFileReference; explicitFileType = {ptype}; includeInIndex = 0; path = {name}; sourceTree = BUILT_PRODUCTS_DIR; }};\n"

def sync(id_, path):
    return f"\t\t{id_} /* {path} */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\tpath = {path};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n"

out = ["// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n\n"]
out.append("/* Begin PBXContainerItemProxy section */\n" + proxy(T_PROXY, "", "DontPress") + proxy(U_PROXY, "", "DontPress") + "/* End PBXContainerItemProxy section */\n\n")
out.append("/* Begin PBXFileReference section */\n" + fileref(APP_REF, "DontPress.app", "wrapper.application") + fileref(TESTS_REF, "DontPressTests.xctest", "wrapper.cfbundle") + fileref(UITESTS_REF, "DontPressUITests.xctest", "wrapper.cfbundle") + "/* End PBXFileReference section */\n\n")
out.append("/* Begin PBXFileSystemSynchronizedRootGroup section */\n" + sync(APP_SYNC, "DontPress") + sync(TESTS_SYNC, "DontPressTests") + sync(UITESTS_SYNC, "DontPressUITests") + "/* End PBXFileSystemSynchronizedRootGroup section */\n\n")
out.append("/* Begin PBXFrameworksBuildPhase section */\n" + phase("PBXFrameworksBuildPhase", APP_FW, "Frameworks") + phase("PBXFrameworksBuildPhase", T_FW, "Frameworks") + phase("PBXFrameworksBuildPhase", U_FW, "Frameworks") + "/* End PBXFrameworksBuildPhase section */\n\n")
out.append(f"/* Begin PBXGroup section */\n\t\t{MAIN_GROUP} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{APP_SYNC} /* DontPress */,\n\t\t\t\t{TESTS_SYNC} /* DontPressTests */,\n\t\t\t\t{UITESTS_SYNC} /* DontPressUITests */,\n\t\t\t\t{PRODUCTS} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n"
           f"\t\t{PRODUCTS} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{APP_REF} /* DontPress.app */,\n\t\t\t\t{TESTS_REF} /* DontPressTests.xctest */,\n\t\t\t\t{UITESTS_REF} /* DontPressUITests.xctest */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n/* End PBXGroup section */\n\n")
out.append("/* Begin PBXNativeTarget section */\n"
           + target(APP, "DontPress", APP_REF, APP_SYNC, APP_SRC, APP_FW, APP_RES, APP_CFGLIST, "com.apple.product-type.application")
           + target(TESTS, "DontPressTests", TESTS_REF, TESTS_SYNC, T_SRC, T_FW, T_RES, T_CFGLIST, "com.apple.product-type.bundle.unit-test", [T_DEP])
           + target(UITESTS, "DontPressUITests", UITESTS_REF, UITESTS_SYNC, U_SRC, U_FW, U_RES, U_CFGLIST, "com.apple.product-type.bundle.ui-testing", [U_DEP])
           + "/* End PBXNativeTarget section */\n\n")
out.append(f"/* Begin PBXProject section */\n\t\t{PROJECT} /* Project object */ = {{\n\t\t\tisa = PBXProject;\n\t\t\tattributes = {{\n\t\t\t\tBuildIndependentTargetsInParallel = 1;\n\t\t\t\tLastSwiftUpdateCheck = 1600;\n\t\t\t\tLastUpgradeCheck = 1600;\n\t\t\t\tTargetAttributes = {{\n\t\t\t\t\t{APP} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t}};\n\t\t\t\t\t{TESTS} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t\tTestTargetID = {APP};\n\t\t\t\t\t}};\n\t\t\t\t\t{UITESTS} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t\tTestTargetID = {APP};\n\t\t\t\t\t}};\n\t\t\t\t}};\n\t\t\t}};\n"
           f"\t\t\tbuildConfigurationList = {PROJ_CFGLIST};\n\t\t\tcompatibilityVersion = \"Xcode 14.0\";\n\t\t\tdevelopmentRegion = en;\n\t\t\thasScannedForEncodings = 0;\n\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t);\n\t\t\tmainGroup = {MAIN_GROUP};\n\t\t\tminimizedProjectReferenceProxies = 1;\n\t\t\tpreferredProjectObjectVersion = 77;\n\t\t\tproductRefGroup = {PRODUCTS} /* Products */;\n\t\t\tprojectDirPath = \"\";\n\t\t\tprojectRoot = \"\";\n\t\t\ttargets = (\n\t\t\t\t{APP} /* DontPress */,\n\t\t\t\t{TESTS} /* DontPressTests */,\n\t\t\t\t{UITESTS} /* DontPressUITests */,\n\t\t\t);\n\t\t}};\n/* End PBXProject section */\n\n")
out.append("/* Begin PBXResourcesBuildPhase section */\n" + phase("PBXResourcesBuildPhase", APP_RES, "Resources") + phase("PBXResourcesBuildPhase", T_RES, "Resources") + phase("PBXResourcesBuildPhase", U_RES, "Resources") + "/* End PBXResourcesBuildPhase section */\n\n")
out.append("/* Begin PBXSourcesBuildPhase section */\n" + phase("PBXSourcesBuildPhase", APP_SRC, "Sources") + phase("PBXSourcesBuildPhase", T_SRC, "Sources") + phase("PBXSourcesBuildPhase", U_SRC, "Sources") + "/* End PBXSourcesBuildPhase section */\n\n")
out.append("/* Begin PBXTargetDependency section */\n" + dep(T_DEP, T_PROXY) + dep(U_DEP, U_PROXY) + "/* End PBXTargetDependency section */\n\n")
out.append("/* Begin XCBuildConfiguration section */\n"
           + cfg(PROJ_DEBUG, "Debug", proj_debug) + cfg(PROJ_RELEASE, "Release", proj_release)
           + cfg(APP_DEBUG, "Debug", app_common) + cfg(APP_RELEASE, "Release", app_common)
           + cfg(T_DEBUG, "Debug", test_common) + cfg(T_RELEASE, "Release", test_common)
           + cfg(U_DEBUG, "Debug", uitest_common) + cfg(U_RELEASE, "Release", uitest_common)
           + "/* End XCBuildConfiguration section */\n\n")
out.append("/* Begin XCConfigurationList section */\n"
           + cfglist(PROJ_CFGLIST, "PBXProject", "DontPress", PROJ_DEBUG, PROJ_RELEASE)
           + cfglist(APP_CFGLIST, "PBXNativeTarget", "DontPress", APP_DEBUG, APP_RELEASE)
           + cfglist(T_CFGLIST, "PBXNativeTarget", "DontPressTests", T_DEBUG, T_RELEASE)
           + cfglist(U_CFGLIST, "PBXNativeTarget", "DontPressUITests", U_DEBUG, U_RELEASE)
           + "/* End XCConfigurationList section */\n")
out.append(f"\t}};\n\trootObject = {PROJECT} /* Project object */;\n}}\n")

os.makedirs(PROJ, exist_ok=True)
open(os.path.join(PROJ, "project.pbxproj"), "w").write("".join(out))

scheme_dir = os.path.join(PROJ, "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
def ref(id_, name, product):
    return f'<BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{id_}" BuildableName = "{product}" BlueprintName = "{name}" ReferencedContainer = "container:DontPress.xcodeproj"></BuildableReference>'
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            {ref(APP, "DontPress", "DontPress.app")}
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference skipped = "NO">
            {ref(TESTS, "DontPressTests", "DontPressTests.xctest")}
         </TestableReference>
         <TestableReference skipped = "NO">
            {ref(UITESTS, "DontPressUITests", "DontPressUITests.xctest")}
         </TestableReference>
      </Testables>
      <StoreKitConfigurationFileReference identifier = "../../DontPress.storekit"></StoreKitConfigurationFileReference>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         {ref(APP, "DontPress", "DontPress.app")}
      </BuildableProductRunnable>
      <StoreKitConfigurationFileReference identifier = "../../DontPress.storekit"></StoreKitConfigurationFileReference>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         {ref(APP, "DontPress", "DontPress.app")}
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"></ArchiveAction>
</Scheme>
'''
open(os.path.join(scheme_dir, "DontPress.xcscheme"), "w").write(scheme)
print("generated")
