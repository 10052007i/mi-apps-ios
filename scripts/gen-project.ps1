param(
    [string]$ProjectDir = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$projectDir = (Resolve-Path -LiteralPath $ProjectDir).Path
$appName = "BarEvents"
$sourceRoot = Join-Path $projectDir $appName
if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "No se encontró $sourceRoot"
}

$script:idCounter = 0
function New-ObjectId {
    param([string]$Prefix = "A3")
    $script:idCounter++
    return "{0}{1:D22}" -f $Prefix, $script:idCounter
}

$swiftFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter *.swift -File | Sort-Object FullName
if ($swiftFiles.Count -eq 0) { throw "No hay archivos .swift en $sourceRoot" }

$relative = @{}
foreach ($file in $swiftFiles) {
    $relative[$file.FullName] = [IO.Path]::GetRelativePath($sourceRoot, $file.FullName).Replace('\', '/')
}

$dirs = [System.Collections.Generic.SortedSet[string]]::new()
[void]$dirs.Add("")
foreach ($rel in $relative.Values) {
    $dir = [IO.Path]::GetDirectoryName($rel).Replace('\', '/')
    while ($dir) {
        [void]$dirs.Add($dir)
        $dir = [IO.Path]::GetDirectoryName($dir)
        if ($dir -eq ".") { break }
    }
    if ($dir -eq ".") { [void]$dirs.Add("") }
}

$groupIds = @{}
foreach ($dir in $dirs) {
    $groupIds[$dir] = New-ObjectId "A4"
}

$fileIds = @{}
$buildIds = @{}
foreach ($file in $swiftFiles) {
    $fileIds[$file.FullName] = New-ObjectId "A5"
    $buildIds[$file.FullName] = New-ObjectId "A6"
}

$assetsPath = Join-Path $sourceRoot "Assets.xcassets"
$infoPath = Join-Path $sourceRoot "Info.plist"
$assetsRef = New-ObjectId "A5"
$assetsBuild = New-ObjectId "A6"
$infoRef = New-ObjectId "A5"

$productRef = "B10000000000000000000004"
$rootGroupId = "B10000000000000000000002"
$productGroupId = "B10000000000000000000003"
$targetId = "B10000000000000000000001"
$frameworkPhase = "B10000000000000000000005"
$sourcesPhase = "B10000000000000000000006"
$resourcesPhase = "B10000000000000000000007"
$projectObject = "B10000000000000000000008"
$projectConfigList = "B10000000000000000000009"
$targetConfigList = "B1000000000000000000000A"
$debugProject = "B1000000000000000000000B"
$releaseProject = "B1000000000000000000000C"
$debugTarget = "B1000000000000000000000D"
$releaseTarget = "B1000000000000000000000E"

$buildLines = foreach ($file in $swiftFiles) {
    "`t`t$($buildIds[$file.FullName]) /* $($file.Name) in Sources */ = {isa = PBXBuildFile; fileRef = $($fileIds[$file.FullName]) /* $($file.Name) */; };"
}
$buildLines += "`t`t$assetsBuild /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = $assetsRef /* Assets.xcassets */; };"

$refLines = foreach ($file in $swiftFiles) {
    "`t`t$($fileIds[$file.FullName]) /* $($file.Name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $($file.Name); sourceTree = ""<group>""; };"
}
$refLines += "`t`t$assetsRef /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = ""<group>""; };"
$refLines += "`t`t$infoRef /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = ""<group>""; };"
$refLines += "`t`t$productRef /* $appName.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = $appName.app; sourceTree = BUILT_PRODUCTS_DIR; };"

$groupLines = @()
foreach ($dir in $dirs) {
    $children = @()
    $filesHere = $swiftFiles | Where-Object {
        [IO.Path]::GetDirectoryName($relative[$_.FullName]).Replace('\', '/') -eq $dir
    }
    foreach ($file in $filesHere) {
        $children += "`t`t`t`t$($fileIds[$file.FullName]) /* $($file.Name) */,"
    }
    $childDirs = $dirs | Where-Object {
        if ($_ -eq $dir -or $_ -eq "") { return $false }
        [IO.Path]::GetDirectoryName($_).Replace('\', '/') -eq $dir
    }
    foreach ($child in $childDirs) {
        $children += "`t`t`t`t$($groupIds[$child]) /* $([IO.Path]::GetFileName($child)) */,"
    }
    if ($dir -eq "") {
        $children += "`t`t`t`t$assetsRef /* Assets.xcassets */,"
        $children += "`t`t`t`t$infoRef /* Info.plist */,"
        $groupName = $appName
        $groupPath = $appName
    } else {
        $groupName = [IO.Path]::GetFileName($dir)
        $groupPath = [IO.Path]::GetFileName($dir)
    }
    $groupLines += "`t`t$($groupIds[$dir]) /* $groupName */ = {"
    $groupLines += "`t`t`tisa = PBXGroup;"
    $groupLines += "`t`t`tchildren = ("
    $groupLines += $children
    $groupLines += "`t`t`t);"
    $groupLines += "`t`t`tpath = $groupPath;"
    $groupLines += "`t`t`tsourceTree = ""<group>"";"
    $groupLines += "`t`t};"
}

$sourceFileLines = foreach ($file in $swiftFiles) {
    "`t`t`t`t$($buildIds[$file.FullName]) /* $($file.Name) in Sources */,"
}

$template = @'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
__BUILD_FILES__
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
__FILE_REFS__
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		__FRAMEWORK_PHASE__ /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		__ROOT_GROUP__ = {
			isa = PBXGroup;
			children = (
				__APP_GROUP__,
				__PRODUCT_GROUP__ /* Products */,
			);
			sourceTree = "<group>";
		};
__GROUPS__
		__PRODUCT_GROUP__ /* Products */ = {
			isa = PBXGroup;
			children = (
				__PRODUCT_REF__ /* __APP_NAME__.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		__TARGET__ /* __APP_NAME__ */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = __TARGET_CONFIG_LIST__ /* Build configuration list for PBXNativeTarget "__APP_NAME__" */;
			buildPhases = (
				__SOURCES_PHASE__ /* Sources */,
				__FRAMEWORK_PHASE__ /* Frameworks */,
				__RESOURCES_PHASE__ /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = __APP_NAME__;
			productName = __APP_NAME__;
			productReference = __PRODUCT_REF__ /* __APP_NAME__.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		__PROJECT_OBJECT__ /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					__TARGET__ = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = __PROJECT_CONFIG_LIST__ /* Build configuration list for PBXProject "__APP_NAME__" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = __ROOT_GROUP__;
			productRefGroup = __PRODUCT_GROUP__ /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				__TARGET__ /* __APP_NAME__ */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		__RESOURCES_PHASE__ /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				__ASSETS_BUILD__ /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		__SOURCES_PHASE__ /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
__SOURCE_FILES__
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		__DEBUG_PROJECT__ /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		__RELEASE_PROJECT__ /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		__DEBUG_TARGET__ /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "__APP_NAME__/Info.plist";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.cibertec.velvetgilt;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		__RELEASE_TARGET__ /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "__APP_NAME__/Info.plist";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.cibertec.velvetgilt;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		__PROJECT_CONFIG_LIST__ /* Build configuration list for PBXProject "__APP_NAME__" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				__DEBUG_PROJECT__ /* Debug */,
				__RELEASE_PROJECT__ /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		__TARGET_CONFIG_LIST__ /* Build configuration list for PBXNativeTarget "__APP_NAME__" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				__DEBUG_TARGET__ /* Debug */,
				__RELEASE_TARGET__ /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = __PROJECT_OBJECT__ /* Project object */;
}
'@

$text = $template
$replacements = @{
    "__APP_NAME__" = $appName
    "__BUILD_FILES__" = ($buildLines -join "`r`n")
    "__FILE_REFS__" = ($refLines -join "`r`n")
    "__GROUPS__" = ($groupLines -join "`r`n")
    "__SOURCE_FILES__" = ($sourceFileLines -join "`r`n")
    "__ROOT_GROUP__" = $rootGroupId
    "__APP_GROUP__" = "$($groupIds['']) /* $appName */"
    "__PRODUCT_GROUP__" = $productGroupId
    "__PRODUCT_REF__" = $productRef
    "__TARGET__" = $targetId
    "__FRAMEWORK_PHASE__" = $frameworkPhase
    "__SOURCES_PHASE__" = $sourcesPhase
    "__RESOURCES_PHASE__" = $resourcesPhase
    "__PROJECT_OBJECT__" = $projectObject
    "__PROJECT_CONFIG_LIST__" = $projectConfigList
    "__TARGET_CONFIG_LIST__" = $targetConfigList
    "__DEBUG_PROJECT__" = $debugProject
    "__RELEASE_PROJECT__" = $releaseProject
    "__DEBUG_TARGET__" = $debugTarget
    "__RELEASE_TARGET__" = $releaseTarget
    "__ASSETS_BUILD__" = $assetsBuild
}
foreach ($key in $replacements.Keys) {
    $text = $text.Replace($key, $replacements[$key])
}

$pbxDir = Join-Path $projectDir "$appName.xcodeproj"
New-Item -ItemType Directory -Force -Path $pbxDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $pbxDir "project.pbxproj"), $text, $utf8)

$schemeDir = Join-Path $pbxDir "xcshareddata\xcschemes"
New-Item -ItemType Directory -Force -Path $schemeDir | Out-Null
$scheme = @"
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "$targetId"
               BuildableName = "$appName.app"
               BlueprintName = "$appName"
               ReferencedContainer = "container:$appName.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$targetId"
            BuildableName = "$appName.app"
            BlueprintName = "$appName"
            ReferencedContainer = "container:$appName.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$targetId"
            BuildableName = "$appName.app"
            BlueprintName = "$appName"
            ReferencedContainer = "container:$appName.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"@
[IO.File]::WriteAllText((Join-Path $schemeDir "$appName.xcscheme"), $scheme, $utf8)

Write-Host "Generado $pbxDir con $($swiftFiles.Count) archivos Swift."
