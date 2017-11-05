param
(
    [String[]]$Packages,
    [String]$Operation,
    [String[]]$RequestedAVDs
)

<#
Download and install Android SDK
#>
Function Invoke-InteractiveProcess([String]$FilePath, [string[]]$ArgumentList)
{
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = $ArgumentList
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)

    return $process
} 


# Android helper functions
Function Get-AndroidHomeFromRegistry
{
    $ProgramFilesx86 = [environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    # if ([Environment]::Is64BitOperatingSystem)
    # powershell v1 doesn't have is 64 bit flag.
    if ($ProgramFilesx86)
    {
        $androidRegistryKey = "HKLM:\SOFTWARE\Wow6432Node\Android SDK Tools"

        #Set the default value to use in case the reg key isn't set
        $path = "$ProgramFilesx86\Android\android-sdk"
    }
    else
    {
        $androidRegistryKey = "HKLM:\SOFTWARE\Android SDK Tools"

        #Set the default value to use in case the reg key isn't set
        $ProgramFiles = [environment]::GetEnvironmentVariable("ProgramFiles")
        $path = "$ProgramFiles\Android\android-sdk"
    }

    if (Test-Path $androidRegistryKey)
    {
        $path = (Get-ItemProperty $androidRegistryKey Path).Path
    }

    return $path
}

Function Format-List([string[]]$List)
{
    if ($List.Count -gt 0)
    {
        return $List -join ", "
    }
    return "(none)"
}

Function Get-PackageInfo([string]$PackageName)
{
    # install-root:
    #   Where to put the contents of the zip file, which is also where to find the
    #   source.properties of the already installed package.

    $packageInfo = @{
        "tools" = @{
            "version" = "25.2.5";
            "file-name" = "tools_r25.2.5-windows.zip";
            "install-root" = "tools";
        };
        "platform-tools" = @{
            "version" = "25.0.3";
            "file-name" = "platform-tools_r25.0.3-windows.zip";
            "install-root" = "platform-tools";
        };
        "extra-android-m2repository" = @{
            "version" = "41.0.0";
            "file-name" = "android_m2repository_r41.zip";
            "install-root" = "extras\android\m2repository";
        };
        "emulator" = @{
            "version" = "26.0.0";
            "file-name" = "emulator-windows-3833124.zip";
            "install-root" = "emulator";
        };
        "extra-intel-Hardware_Accelerated_Execution_Manager" = @{
            "version" = "6.0.5";
            "file-name" = "haxm-windows_r6_0_5.zip";
            "install-root" = "extras\intel\Hardware_Accelerated_Execution_Manager";
            "source.properties" = @{
                "Extra.VendorId" = "intel";
            };
        };
        "build-tools-23.0.3" = @{
            "version" = "23.0.3";
            "file-name" = "build-tools_r23.0.3-windows.zip";
            "install-root" = "build-tools\23.0.3";
        };
        "build-tools-22.0.1" = @{
            "version" = "22.0.1";
            "file-name" = "build-tools_r22.0.1-windows.zip";
            "install-root" = "build-tools\22.0.1";
        };
        "build-tools-21.1.2" = @{
            "version" = "21.1.2";
            "file-name" = "build-tools_r21.1.2-windows.zip";
            "install-root" = "build-tools\21.1.2";
        };
        "build-tools-19.1.0" = @{
            "version" = "19.1.0";
            "file-name" = "build-tools_r19.1-windows.zip";
            "install-root" = "build-tools\19.1.0";
        };
        "android-19" = @{
            "version" = "4";
            "file-name" = "android-19_r04.zip";
            "install-root" = "platforms\android-19";
        };
        "android-21" = @{
            "version" = "2";
            "file-name" = "android-21_r02.zip";
            "install-root" = "platforms\android-21";
        };
        "android-22" = @{
            "version" = "2";
            "file-name" = "android-22_r02.zip";
            "install-root" = "platforms\android-22";
        };
        "android-23" = @{
            "version" = "3";
            "file-name" = "platform-23_r03.zip";
            "install-root" = "platforms\android-23";
        };
        "addon-google_apis-google-19" = @{
            "version" = "20";
            "file-name" = "google_apis-19_r20.zip";
            "install-root" = "add-ons\addon-google_apis-google-19";
            "source.properties" = @{
                "AndroidVersion.ApiLevel" = "19";
                "Addon.NameId" = "google_apis";
                "Addon.VendorId" = "google";
            };
        };
        "addon-google_apis-google-23" = @{
            "version" = "1";
            "file-name" = "google_apis-23_r01.zip";
            "install-root" = "add-ons\addon-google_apis-google-23";
            "source.properties" = @{
                "AndroidVersion.ApiLevel" = "23";
                "Addon.NameId" = "google_apis";
                "Addon.VendorId" = "google";
            };
        };
        "sys-img-x86-google_apis-23" = @{
            "version" = "19";
            "file-name" = "x86-23_r19.zip";
            "install-root" = "system-images\android-23\google_apis\x86";
            "remove-source.properties" = @("Addon.VendorId");
        };
        "sys-img-armeabi-v7a-google_apis-23" = @{
            "version" = "19";
            "file-name" = "armeabi-v7a-23_r19.zip";
            "install-root" = "system-images\android-23\google_apis\armeabi-v7a";
            "remove-source.properties" = @("Addon.VendorId");
        };
        "sys-img-x86-android-19" = @{
            "version" = "5";
            "file-name" = "x86-19_r05.zip";
            "install-root" = "system-images\android-19\default\x86";
            "remove-source.properties" = @("Addon.VendorId");
        };
        "sys-img-armeabi-v7a-android-19" = @{
            "version" = "5";
            "file-name" = "armeabi-v7a-19_r05.zip";
            "install-root" = "system-images\android-19\default\armeabi-v7a";
            "remove-source.properties" = @("Addon.VendorId");
        };
    }

    return $packageInfo.Item($PackageName);
}


Function Install-Package ([string]$PackageName, [string]$Operation, [string]$AndroidHome)
{
    Write-Host "`nInstalling package $PackageName"

    $packageInfo = Get-PackageInfo -PackageName $PackageName
    if (-not $packageInfo)
    {
        Write-Host "- Unrecognized package: $PackageName"
        return $false;
    }

    if ($Operation -ne "Repair")
    {
        $currentVersion = Get-CurrentPackageVersion -PackageName $PackageName -PackageInfo $packageInfo -AndroidHome $AndroidHome
        $requiredVersion = New-Object System.Version (Get-ThreeDigitVerion -Version $packageInfo["version"])

        if ($currentVersion -ge $requiredVersion)
        {
            Write-Host "- Nothing to do, since version $currentVersion is already installed"
            return $true
        }
    }

    $result = $true
    try
    {
        # Kill ADB process to avoid access denied errors
        Kill-ADB

        $installPath = $packageInfo["install-root"]

        $targetInstallFolder = Join-Path $AndroidHome $installPath
        if (Test-Path $targetInstallFolder)
        {
            # Try to create a temporary folder to back up the existing package folder. We back it up to
            # another folder in the same parent folder to ensure we have access rights to this folder.
            # We do this first so we don't waste our time continuing if we don't have access rights.
            $currentPackageTempPath = Create-TempFolder -Parent $AndroidHome -Reason "backup of existing package"
            $currentPackageTempPathPackageFolder = Join-Path $currentPackageTempPath $installPath
            New-Item -ItemType Directory -Path $currentPackageTempPath -ErrorAction SilentlyContinue
        }

        $packageTargetFile = Join-Path $PSScriptRoot $packageInfo["file-name"]

        # Backup existing package if it exists
        if (Test-Path $targetInstallFolder)
        {
            Move-FolderWithRetry -Path $targetInstallFolder -Destination $currentPackageTempPath -Reason "Moving existing package to temporary folder"
            $existingPackageBackedUp = $true
        }

        # Unzip package to temp folder in android-sdk folder (this is important to get correct permissions)
        $newPackageTempPath = Create-TempFolder -Parent $AndroidHome -Reason "new package"
        Unzip-File -Source $packageTargetFile -Destination $newPackageTempPath

        # Move the correct contents of the zip file to the destination. If the zip file contained a single root
        # folder, then we copy the contents of that folder. Otherwise we just copy the contents of the zip file.
        # This is based on the Android SDK Manager logic.
        $packageSourcePath = $newPackageTempPath
        $zipContents = Get-ChildItem -Path $newPackageTempPath
        if ($zipContents -and $zipContents.GetType().Name -eq "DirectoryInfo")
        {
            $packageSourcePath = Join-Path $packageSourcePath $zipContents.Name
        }

        $packageDestinationPath = Join-Path $AndroidHome $packageInfo["install-root"]
        Move-FolderContentsWithRetry -Path $packageSourcePath -Destination $packageDestinationPath -Reason "Moving new package into place"

        # Make any required updates to source.properties
        Update-SourceProperties -PackageName $PackageName -PackageInfo $packageInfo -AndroidHome $AndroidHome

        $newPackageInstalled = $true
    }
    catch
    {
        $innerException = Get-InnermostException -Exception $_.Exception
        Write-Host "  - $($innerException.Message)"
        $result = $false
    }
    finally
    {
        Write-Host "- Cleaning up..."

        if ($existingPackageBackedUp -and -not $newPackageInstalled)
        {
            # If we succeeded in backing up the existing package, but failed to install the new one, try to move the existing package back.
            try
            {
                Move-FolderContentsWithRetry -Path $currentPackageTempPathPackageFolder -Destination $targetInstallFolder -Reason "Restoring existing package"
            }
            catch
            {
                $innerException = Get-InnermostException -Exception $_.Exception
                Write-Host "  - WARNING: Restoring existing package failed: $($innerException.Message)"
                $result = $false # presumably this will already have been set, but good to be sure
            }
        }

        if ($currentPackageTempPath)
        {
            Write-Host "  - Removing temporary folder created to back up existing package"
            Remove-Folder $currentPackageTempPath
        }

        if ($newPackageTempPath)
        {
            Write-Host "  - Removing temporary folder created to unzip new package"
            Remove-Folder $newPackageTempPath
        }
    }

    return $result
}

Function Remove-Folder([string]$Path)
{
    Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable ErrorOut
    if ($ErrorOut)
    {
        # If it fails, it could be because of long paths. Fall back to ROBOCOPY trick
        # (which empties the directory, then we have to delete it again).
        $exception = Get-InnermostException -Exception $ErrorOut.Exception[0]
        Write-Host "  - Removing folder '$Path' failed with error: $($exception.message)"
        Write-Host "  - Trying again using ROBOCOPY."
        $emptyFolder = Create-TempFolder -Parent ([System.IO.Path]::GetTempPath())
        robocopy $emptyFolder $path /MIR

        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $emptyFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Function Update-SourceProperties([string]$PackageName, $PackageInfo, [string]$AndroidHome)
{
    # Some packages (like HAXM) don't include source.properties, so we write it out with enough information
    # that we don't try to update it again (version) and SDK Manager recognizes it.

    $sourcePropertiesPath = Join-Path $AndroidHome (Join-Path $PackageInfo["install-root"] "source.properties")
    if (-not (Test-Path $sourcePropertiesPath))
    {
        Write-Host "- Writing Pkg.Revision=$($PackageInfo['version']) to source.properties"
        Add-Content $sourcePropertiesPath "Pkg.Revision=$($PackageInfo['version'])"

        if ($PackageInfo["source.properties"])
        {
            ForEach ($property in $PackageInfo["source.properties"].keys)
            {
                Write-Host "- Writing $property=$($PackageInfo['source.properties'][$property]) to source.properties"
                Add-Content $sourcePropertiesPath "$property=$($PackageInfo['source.properties'][$property])"
            }
        }
    }

    # The SDK Manager overwrites source.properties even if the package contains it. Usually what's in the package
    # is all we need, but sometimes it contains properties that confuse the SDK Manager (meaning it detects the
    # package as broken). Remove those if requested.
    $propertiesToRemove = $PackageInfo["remove-source.properties"]
    if ($propertiesToRemove)
    {
        $sourceProperties = (Get-Content $sourcePropertiesPath) -join "`n"
        ForEach ($propertyToRemove in $propertiesToRemove)
        {
            $removePropertyRegex = "$propertyToRemove=.+"
            $match = ([regex]::Matches($sourceProperties, $removePropertyRegex))
            if ($match -and $match[0].Groups)
            {
                Write-Host "- Removing $($match[0].Groups[0].Value) from source.properties"
                $index = $match[0].Groups[0].Index
                $length = $match[0].Groups[0].Length + 1 # add 1 to remove line break
                $sourceProperties = $sourceProperties.remove($index,$length)
            }
        }
        Set-Content -Path $sourcePropertiesPath -Value $sourceProperties
    }
}

Function Get-CurrentPackageVersion([string]$PackageName, $PackageInfo, [string]$AndroidHome)
{
    $sourcePropertiesPath = Join-Path $AndroidHome (Join-Path $PackageInfo["install-root"] "source.properties")
    if (Test-Path $sourcePropertiesPath)
    {
        $sourceProperties = Get-Content $sourcePropertiesPath
        $packageRevisionRegex = 'Pkg.Revision=([0-9.]+)'
        $packageRevision = ([regex]::Matches($sourceProperties, $packageRevisionRegex))
        $packageRevision = If ($packageRevision -and $packageRevision[0].Groups) {$packageRevision[0].Groups[1].Value} Else {"0.0.0"}

        # Ensure we have 3 numbers
        $packageRevision = Get-ThreeDigitVerion -Version $packageRevision

        Write-Host "- Currently installed version: $packageRevision"
    }
    else
    {
        Write-Host "- Not currently installed"
        $packageRevision = "0.0.0"
    }

    return New-Object System.Version $packageRevision
}

Function Get-ThreeDigitVerion([string]$Version)
{
    $versionArray = $Version.split(".")
    while ($versionArray.Count -lt 3)
    {
        $versionArray += "0"
    }
    return $versionArray -join "."
}

Function Unzip-File([String]$Source, [String]$Destination)
{
    $startTime = Get-Date
    Write-Host "- Expanding '$Source' to '$Destination'";

    if ($PSVersionTable.PSVersion.Major -ge 3)
    {
        Add-Type -assembly "System.IO.Compression.FileSystem"
        [System.IO.Compression.ZipFile]::ExtractToDirectory($Source, $Destination)
    }
    else
    {
        $shell = New-Object -com shell.application
        $zip = $shell.NameSpace($Source)
        $dest = $shell.NameSpace($Destination)
        # Option flags 4: No progress box, 16: Click Yes to All, 512: Don't Confirm new Dir, 1024: Suppress error UI
        $dest.CopyHere($zip.Items(), 4 + 16 + 512 + 1024)
    }
    Write-Host "- Expand took $((Get-Date).Subtract($startTime).TotalSeconds) second(s)"
}

Function Create-TempFolder($Parent, $Reason)
{
    if (-not $Parent)
    {
        $Parent = [System.IO.Path]::GetTempPath()
    }

    # Passing a max length of 5, since that is the length of the shortest target folder ("tools"), so that our temp
    # path is never longer than the target path (so we don't introduce unnecessary max path problems)
    [string]$dirName = Get-RandomFileName -MaxLength 5
    $targetTempPath = Join-Path $Parent $dirName
    if ($Reason)
    {
        Write-Host "- Creating temporary folder '$targetTempPath' for $Reason"
    }
    $createdTempPath = New-Item -ItemType Directory -Path $targetTempPath -ErrorAction SilentlyContinue -ErrorVariable ErrorOut
    if (-not $createdTempPath)
    {
        throw $ErrorOut.Exception
    }
    return $createdTempPath
}

Function Get-RandomFileName($MaxLength)
{
    $filename = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName())
    if ($MaxLength -and $filename.Length -gt $MaxLength)
    {
        $filename = $filename.Substring(0, $MaxLength)
    }
    return $filename
}

Function Move-FolderContentsWithRetry($Path, $Destination, $Reason)
{
    try
    {
        New-Item -ItemType Directory -Path $Destination
        Move-FolderContents -Path $Path -Destination $Destination -Reason $Reason
    }
    catch
    {
        Write-Host "  - $($_.Exception.Message)"
        Write-Host "  - Retrying."
        Move-FolderContents -Path $Path -Destination $Destination -Reason $Reason
    }
}

Function Move-FolderContents($Path, $Destination, $Reason)
{
    Write-Host "- $($Reason): Moving folder contents from '$Path' to '$Destination'"

    # Wait a second before trying to move a folder's contents, to help ensure previous actions are fully processed.
    Start-Sleep -Milliseconds 1000

    if (!(Test-Path $Destination))
    {
        New-Item -ItemType Directory -Path $Destination -ErrorAction SilentlyContinue -ErrorVariable ErrorOut
        if ($ErrorOut)
        {
            throw $ErrorOut.Exception
        }
    }

    Get-ChildItem -Path $Path | Move-Item -Destination $Destination -ErrorAction SilentlyContinue -ErrorVariable ErrorOut

    if ($ErrorOut)
    {
        throw $ErrorOut.Exception
    }
}

Function Move-FolderWithRetry($Path, $Destination, $Reason)
{
    $i = 0
    do
    {
        try
        {
            Move-Folder -Path $Path -Destination $Destination -Reason $Reason
            return
        }
        catch
        {
            Write-Host "  - $($_.Exception.Message)"
            Write-Host "  - Retrying."
            $i++
        }
    } until ($i -ge 30)

    #30 seconds have passed and it's still failing. Try one last time without
    #catching the error so it gets thrown
    Move-Folder -Path $Path -Destination $Destination -Reason $Reason
}

Function Move-Folder($Path, $Destination, $Reason)
{
    Write-Host "- $($Reason): Moving folder '$Path' to '$Destination'"

    # Wait a second before trying to move a folder, to help ensure previous actions are fully processed.
    Start-Sleep -Milliseconds 1000

    if (!(Test-Path $Destination))
    {
        New-Item -ItemType Directory -Path $Destination -ErrorAction SilentlyContinue -ErrorVariable ErrorOut
        if ($ErrorOut)
        {
            throw $ErrorOut.Exception
        }
    }

    Move-Item -Path $Path -Destination $Destination -ErrorAction SilentlyContinue -ErrorVariable ErrorOut
    if ($ErrorOut)
    {
        throw $ErrorOut.Exception
    }
}

Function Get-InnermostException($Exception)
{
    if ($Exception.InnerException -and $Exception.InnerException -ne $Exception)
    {
        return Get-InnermostException -Exception $Exception.InnerException
    }
    return $Exception
}

Function Kill-ADB
{
    # We need to kill adb process before installing packages, otherwise it can cause an access violation,
    # and after installing, otherwise it can cause setup to hang. Also, need to have -erroraction
    # silentlycontinue, otherwise we'll get an error when adb doesn't exist.
    $processAdb = Get-Process adb -erroraction silentlycontinue 
    if ($processAdb)
    {
        Write-Host "- Stopping ADB process"
        $processAdb.Kill()
    }
}

Function Get-AVDConfiguration([String]$FilePath)
{
    $result = @{}

    if (Test-Path $FilePath)
    {
        ForEach ($pair in (Get-Content $FilePath) -split "`n")
        {
            $pair = $pair -split "="

            if ($pair.Count -eq 2)
            {
                $result[$pair[0]] = $pair[1]
            }
        }
    }

    return $result
}

Function Set-AVDConfiguration([String]$FilePath, [Hashtable]$configHashtable)
{
    Remove-Item $FilePath

    ForEach ($key in $configHashtable.Keys | Sort-Object)
    {
        $keyValuePair = "$key=$($configHashtable[$key])"
        Add-Content $FilePath $keyValuePair
    }
}

Function Get-AVDPath([string]$AVDName)
{
    $packageRegex = "Path: ((?:.*)\\$AVDName.avd)"
    $androidBatch = Join-Path $androidHome "tools\android.bat"
    [array]$avdListArray = & $androidBatch list avd
    $avdListString = ($avdListArray -join "`n")

    $availablePackages = [regex]::Matches($avdListString, $packageRegex)
    if ($availablePackages.Count -eq 0)
    {
        return $null;
    }

    return $availablePackages[0].Groups[1];
}

Function Create-AVD([String]$Name, [String]$ABI, [String]$Target, [Hashtable]$ConfigurationOptions)
{
    if (-not $Name -or -not $ABI -or -not $Target)
    {
        return
    }

    Write-Host "- Creating AVD '$Name'"

    $processArgs = @("create avd",
                     "-n $Name",
                     "-t $Target",
                     "-b $ABI",
                     "--sdcard 512M",
                     "--force")

    # Create the AVD
    $process = Invoke-InteractiveProcess `
                    -FilePath "$androidHome\tools\android.bat" `
                    -ArgumentList $processArgs

    Write-Host "  - Command: ""$androidHome\tools\android.bat"" $processArgs"

    while (-not $process.StandardOutput.EndOfStream)
    {
        # Answer 'no' to: Do you wish to create a custom hardware profile [no]
        $firstChar = $process.StandardOutput.Peek()
        if ($firstChar -eq 68)
        {
            $process.StandardInput.WriteLine("no")
        }

        $line = $process.StandardOutput.ReadLine()

        Write-Host "    - $line"
    }

    Cleanup -Process $process

    $avdPath = Get-AVDPath -AVDName $Name
    if ($avdPath)
    {
        $avdConfigFile = "$avdPath\config.ini"
        if (Test-Path $avdConfigFile)
        {
            $configHashtable = Get-AVDConfiguration $avdConfigFile

            foreach ($key in $ConfigurationOptions.Keys)
            {
                $configHashtable[$key] = $ConfigurationOptions[$key]
            }

            Set-AVDConfiguration $avdConfigFile $configHashtable

            Write-Host "  - Updating AVD '$Name' to the following hardware config:$([Environment]::NewLine)"

            Get-Content $avdConfigFile

            Write-Host "$([Environment]::NewLine)"
        }
    }
}

Function Get-CannotInstallHaxmReason
{
    $PF_VIRT_FIRMWARE_ENABLED = 21
    if (-not (Get-IsProcessorFeaturePresent $PF_VIRT_FIRMWARE_ENABLED))
    {
        return "Intel HAXM requires hardware virtualization, which is not available. This could be because:`n" + `
            "* Your hardware does not support hardware virtualization.`n" + `
            "* Hardware virtualization is not enabled in your BIOS.`n" + `
            "* You are running in a virtual machine.`n" + `
            "* Hyper-V or DeviceGuard is running."
    }

    $ProcessorManufacturer = (Get-Item HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0).GetValue("VendorIdentifier")
    if ($ProcessorManufacturer -ne "GenuineIntel")
    {
        return "Intel HAXM requires an Intel processor. This machine reports the manufacturer as '$ProcessorManufacturer'."
    }

    $PF_NX_ENABLED = 12
    if (-not (Get-IsProcessorFeaturePresent $PF_NX_ENABLED))
    {
        return "Intel HAXM requires the Execute Disable bit enabled. It is either not supported by your hardware, or not enabled in your BIOS."
    }

    return $null
}

Function Get-IsProcessorFeaturePresent([uint32] $processorFeature)
{
    $assemblyName = New-Object System.Reflection.AssemblyName("Kernel32Lib")
    $assembly = [AppDomain]::CurrentDomain.DefineDynamicAssembly($assemblyName, "Run")
    $module = $assembly.DefineDynamicModule("Kernel32Lib", $False)
    $type = $module.DefineType("Kernel32", "Public, Class")
    $method = $type.DefineMethod(
        "IsProcessorFeaturePresent",
        "Public, Static",
        [Bool],
        [Type[]] @([uint32]))
    $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, @("kernel32.dll")
    $method.SetCustomAttribute($attr)
    $kernel32 = $type.CreateType()
    return $kernel32::IsProcessorFeaturePresent($processorFeature)
}

Function Get-IsHaxmInstalled
{
    $HaxmServiceInfo = Get-Service -Name IntelHaxm -ErrorAction SilentlyContinue
    return [boolean]$HaxmServiceInfo
}

Function Cleanup([System.Diagnostics.Process]$Process)
{
    # We need to kill adb process after installing packages, otherwise it can cause setup to hang.
    # need to have -erroraction silentlycontinue, otherwise we'll get an error when adb doesn't exist.
    $processAdb = Get-Process adb -erroraction silentlycontinue 
    if ($processAdb)
    {
        $processAdb.Kill()
    }
    if (!$Process.HasExited)
    {
	    $Process.CloseMainWindow()
    }
    $Process.Dispose()
}

Function Install-Packages([String]$SkipHaxmReason, [String[]]$Packages, [String]$Operation)
{
    $startTime = Get-Date

    Write-Host "`nInstall Android packages: -Packages $($Packages -join ', ') -Operation $Operation"

    $failedPackages = @()
    ForEach ($packageName in $Packages)
    {
        if ($packageName -eq $haxmPackage -and $SkipHaxmReason)
        {
            Write-Host "`nSkipping package $($haxmPackage): $SkipHaxmReason"
            continue
        }

        $result = Install-Package -PackageName $packageName -Operation $Operation -AndroidHome $androidHome
        if (-not $result)
        {
            $failedPackages += $packageName
        }
    }

    # Kill ADB process to prevent setup hanging
    Kill-ADB

    if ($failedPackages.Count -gt 0)
    {
        Write-Host "`nError: The following packages failed to install: $($failedPackages -join ', ')"
        exit 1
    }

    Write-Host "`nAndroid SDK packages successfully updated"
    Write-Host "Elapsed time: $((Get-Date).Subtract($startTime).TotalSeconds) second(s)"
}

# INPUT:
# [String[]]$Packages, 
# [String]$Operation,
# [String[]]$RequestedAVDs


# Get Start Time
$startDTM = (Get-Date)

$sdkInstallLogMessage = "AndroidSDKInstall: -Packages $Packages -Operation $Operation"
if ($RequestedAVDs)
{
    $sdkInstallLogMessage += " -RequestedAVDs $RequestedAVDs"
}

Write-Host $sdkInstallLogMessage
Write-Host "Android SDK Install starting ..."

$androidHome = Get-AndroidHomeFromRegistry
$haxmPackage = "extra-intel-Hardware_Accelerated_Execution_Manager"

# if androidHome doesn't exist then we don't have to select products.
if (!$androidHome)
{
    Write-Host "No Android SDK detected."
    exit 3
}

Write-Host "AndroidHome: $androidHome"

$androidBatch = Join-Path $androidHome "tools\android.bat"
if (-not (Test-Path $androidBatch))
{
    if (-not ($Packages -contains "tools"))
    {
        $Packages = @("tools", $Packages)
    }
}

if ($Packages)
{
    if (!$PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $script:MyInvocation.MyCommand.Path
    }

    $haxmRequested = $Packages -contains $haxmPackage
    $skipHaxmReason = $null
    if ($haxmRequested)
    {
        # Don't try to download or install HAXM if this machine doesn't support it
        $skipHaxmReason = Get-CannotInstallHaxmReason
        if (-not $skipHaxmReason -and $Operation -ne "Repair" -and (Get-IsHaxmInstalled))
        {
            # If HAXM is already installed, don't try to download it (that is, don't ask Android SDK
            # to "install" it), unless we're doing a repair.
            $skipHaxmReason = "Intel HAXM is already installed."
        }
    }

    Install-Packages -SkipHaxmReason $skipHaxmReason -Packages $Packages -Operation $Operation

    if ($haxmRequested -and -not $skipHaxmReason)
    {
        # Since "installing" HAXM using the Android SDK just downloads the installer, we now have to run it.
        # But only if it isn't already installed, or repair was requested.

        Write-Host "`nRunning Intel HAXM installer..."
        $haxmInstallProcess = Start-Process -WorkingDirectory $androidHome\extras\intel\Hardware_Accelerated_Execution_Manager -FilePath silent_install.bat -Wait -PassThru -WindowStyle Hidden -ArgumentList $("-log", "output.log") -ErrorAction SilentlyContinue

        # Might be null if Android SDK Manager install process above failed for some reason
        if ($haxmInstallProcess)
        {
            # Write content of HAXM installer output to our log, ignoring blank lines and start and end times
            $haxmLog = Get-Content $androidHome\extras\intel\Hardware_Accelerated_Execution_Manager\output.log -ErrorAction SilentlyContinue
            $processedHaxmLog = ""
            if ($haxmLog)
            {
                ForEach ($haxmLogLine in $haxmLog)
                {
                    if ($haxmLogLine.StartsWith("=== Logging stopped"))
                    {
                        break
                    }

                    if ($haxmLogLine -and -not $haxmLogLine.StartsWith("=="))
                    {
                        if (-not $processedHaxmLog)
                        {
                            $processedHaxmLog = ">> $haxmLogLine"
                        }
                        else
                        {
                            $processedHaxmLog = $processedHaxmLog + "`n>> $haxmLogLine"
                        }
                    }
                }
            }

            if ($processedHaxmLog)
            {
                Write-Host "Intel HAXM installer log:"
                Write-Host $processedHaxmLog
            }

            if ($haxmInstallProcess.ExitCode -eq 0)
            {
                Write-Host "Intel HAXM install successful."
            }
            else
            {
                Write-Host "Intel HAXM install failed."
            }
        }
    }
}

# If specific AVDs are requested, create them if they don't already exist
if ($RequestedAVDs)
{
    Write-Host "Creating requested AVDs:"

    # If we're not repairing, only create AVDs that don't already exist
    if ($Operation -ne "Repair")
    {
        [array]$existingAVDs = & $androidBatch list avd -c
    }

    ForEach ($avd in $RequestedAVDs)
    {
        # Each AVD should be provided in the form device\abi\skin\target\chipset (for example,
        # "phone\google_apis/x86\768x1280\android-23\x86" or "tablet\google_apis/armeabi-v7a\768x1280\android-23\arm")
        $avd = $avd.split("\")
        $deviceType = $avd[0]
        $avdAbi = $avd[1]
        $avdTarget = $avd[3]
        $avdChipset = $avd[4]
        $avdName = "VisualStudio_$($avdTarget)_$($avdChipset)_$deviceType"

        if ($Operation -ne "Repair" -and $existingAVDs -icontains $avdName)
        {
            Write-Host "- Skipping creating AVD '$avdName' as it already exists"
        }
        else
        {
            Create-AVD `
                -Name $avdName `
                -ABI $avdAbi `
                -Target $avdTarget `
                -ConfigurationOptions @{"disk.dataPartition.size" = "200M";
                                        "hw.gpu.enabled" = "yes";
                                        "hw.keyboard" = "no";
                                        "hw.ramSize" = "768";
                                        "hw.accelerometer" = "yes";
                                        "hw.battery" = "yes";
                                        "hw.camera.back" = "emulated";
                                        "hw.camera.front" = "webcam0";
                                        "hw.dPad" = "no";
                                        "hw.gps" = "yes";
                                        "hw.lcd.density" = "320";
                                        "hw.mainKeys" = "no";
                                        "hw.sensors.orientation" = "yes";
                                        "hw.sensors.proximity" = "yes";
                                        "hw.trackBall" = "yes";
                                        "sdcard.size" = "512M";
                                        "skin.dynamic" = "no";
                                        "skin.name" = $avd[2];
                                        "skin.path" = $avd[2];
                                        "vm.heapSize" = "64"}
        }
    }
}

Write-Host "Android SDK Install is successful."

# Get End Time
$endDTM = (Get-Date)
Write-Host "Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

exit 0
# SIG # Begin signature block
# MIIatgYJKoZIhvcNAQcCoIIapzCCGqMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGL8UGsUcs7ftsRM1IBC1NaaD
# ke2gghWDMIIEwzCCA6ugAwIBAgITMwAAAMlkTRbbGn2zFQAAAAAAyTANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODU0
# WhcNMTgwOTA3MTc1ODU0WjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OkIxQjctRjY3Ri1GRUMyMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAotVXnfm6iRvJ
# s2GZXZXB2Jr9GoHX3HNAOp8xF/cnCE3fyHLwo1VF+TBQvObTTbxxdsUiqJ2Ew8DL
# jW8dolC9WqrPuP9Wj0gJNAdhnAYjtZN5fYEoGIsHBtuR3k+UxD2W7VWfjPDTY2zH
# e44WzfDvL2aXL2fomH73B7cx7YjT/7Du7vSdAHbr7SEdIyGJ5seMa+Y9MBJI48wZ
# A9CSnTGTFvhMXCYJuoR6Xc34A0EdHiTzfxY2tEWSiw5Xr+Oottc4IIHksNttYMgw
# HCu+tKqUlDkq5EdELh067r2Mv+OVkUkDQnLd1Vh/bP+yz92NKw7THQDYN7/4MTD2
# faNVsutryQIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFB7ZK3kpWqMOy6M4tybE49oI
# BMpsMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBACvoEvJ84B3DuFj+SDfpkM3OCxYon2F4wWTOQmpDmTwysrQ0
# grXhxNqMVL7QRKk34of1uvckfIhsjnckTjkaFJk/bQc8n5wwTzCKJ3T0rV/Vasoh
# MbGm4y3UYEh9nflmKbPpNhps20EeU9sdNIkxsrpQsPwk59wv13STtUjywuTvpM5s
# 1dQOIiUWrAMR14ZzOSBA7kgWI+UEj5iaGYOczxD+wH+07llzwlIC4TyRXtgKFuMF
# AONNNYUedbi6oOX7IPo0hb5RVPuVqAFxT98xIheJXNod9lf2JLhGD+H/pXnkZJRr
# VjJFcuJeEAnYAe7b97+BfhbPgv8V9FIAwqTxgxIwggTtMIID1aADAgECAhMzAAAB
# QJap7nBW/swHAAEAAAFAMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBMB4XDTE2MDgxODIwMTcxN1oXDTE3MTEwMjIwMTcxN1owgYMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# HjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBANtLi+kDal/IG10KBTnk1Q6S0MThi+ikDQUZWMA81ynd
# ibdobkuffryavVSGOanxODUW5h2s+65r3Akw77ge32z4SppVl0jII4mzWSc0vZUx
# R5wPzkA1Mjf+6fNPpBqks3m8gJs/JJjE0W/Vf+dDjeTc8tLmrmbtBDohlKZX3APb
# LMYb/ys5qF2/Vf7dSd9UBZSrM9+kfTGmTb1WzxYxaD+Eaxxt8+7VMIruZRuetwgc
# KX6TvfJ9QnY4ItR7fPS4uXGew5T0goY1gqZ0vQIz+lSGhaMlvqqJXuI5XyZBmBre
# ueZGhXi7UTICR+zk+R+9BFF15hKbduuFlxQiCqET92ECAwEAAaOCAWEwggFdMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSc5ehtgleuNyTe6l6pxF+QHc7Z
# ezBSBgNVHREESzBJpEcwRTENMAsGA1UECxMETU9QUjE0MDIGA1UEBRMrMjI5ODAz
# K2Y3ODViMWMwLTVkOWYtNDMxNi04ZDZhLTc0YWU2NDJkZGUxYzAfBgNVHSMEGDAW
# gBTLEejK0rQWWAHJNy4zFha5TJoKHzBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNDb2RTaWdQQ0Ff
# MDgtMzEtMjAxMC5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BDQV8wOC0z
# MS0yMDEwLmNydDANBgkqhkiG9w0BAQUFAAOCAQEAa+RW49cTHSBA+W3p3k7bXR7G
# bCaj9+UJgAz/V+G01Nn5XEjhBn/CpFS4lnr1jcmDEwxxv/j8uy7MFXPzAGtOJar0
# xApylFKfd00pkygIMRbZ3250q8ToThWxmQVEThpJSSysee6/hU+EbkfvvtjSi0lp
# DimD9aW9oxshraKlPpAgnPWfEj16WXVk79qjhYQyEgICamR3AaY5mLPuoihJbKwk
# Mig+qItmLPsC2IMvI5KR91dl/6TV6VEIlPbW/cDVwCBF/UNJT3nuZBl/YE7ixMpT
# Th/7WpENW80kg3xz6MlCdxJfMSbJsM5TimFU98KNcpnxxbYdfqqQhAQ6l3mtYDCC
# BbwwggOkoAMCAQICCmEzJhoAAAAAADEwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmS
# JomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UE
# AxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTEwMDgz
# MTIyMTkzMloXDTIwMDgzMTIyMjkzMloweTELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQ
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCycllcGTBkvx2aYCAg
# Qpl2U2w+G9ZvzMvx6mv+lxYQ4N86dIMaty+gMuz/3sJCTiPVcgDbNVcKicquIEn0
# 8GisTUuNpb15S3GbRwfa/SXfnXWIz6pzRH/XgdvzvfI2pMlcRdyvrT3gKGiXGqel
# cnNW8ReU5P01lHKg1nZfHndFg4U4FtBzWwW6Z1KNpbJpL9oZC/6SdCnidi9U3RQw
# WfjSjWL9y8lfRjFQuScT5EAwz3IpECgixzdOPaAyPZDNoTgGhVxOVoIoKgUyt0vX
# T2Pn0i1i8UU956wIAPZGoZ7RW4wmU+h6qkryRs83PDietHdcpReejcsRj1Y8wawJ
# XwPTAgMBAAGjggFeMIIBWjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTLEejK
# 0rQWWAHJNy4zFha5TJoKHzALBgNVHQ8EBAMCAYYwEgYJKwYBBAGCNxUBBAUCAwEA
# ATAjBgkrBgEEAYI3FQIEFgQU/dExTtMmipXhmGA7qDFvpjy82C0wGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwHwYDVR0jBBgwFoAUDqyCYEBWJ5flJRP8KuEKU5VZ
# 5KQwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUFBwEB
# BEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwDQYJKoZIhvcNAQEFBQADggIBAFk5
# Pn8mRq/rb0CxMrVq6w4vbqhJ9+tfde1MOy3XQ60L/svpLTGjI8x8UJiAIV2sPS9M
# uqKoVpzjcLu4tPh5tUly9z7qQX/K4QwXaculnCAt+gtQxFbNLeNK0rxw56gNogOl
# VuC4iktX8pVCnPHz7+7jhh80PLhWmvBTI4UqpIIck+KUBx3y4k74jKHK6BOlkU7I
# G9KPcpUqcW2bGvgc8FPWZ8wi/1wdzaKMvSeyeWNWRKJRzfnpo1hW3ZsCRUQvX/Ta
# rtSCMm78pJUT5Otp56miLL7IKxAOZY6Z2/Wi+hImCWU4lPF6H0q70eFW6NB4lhhc
# yTUWX92THUmOLb6tNEQc7hAVGgBd3TVbIc6YxwnuhQ6MT20OE049fClInHLR82zK
# wexwo1eSV32UjaAbSANa98+jZwp0pTbtLS8XyOZyNxL0b7E8Z4L5UrKNMxZlHg6K
# 3RDeZPRvzkbU0xfpecQEtNP7LN8fip6sCvsTJ0Ct5PnhqX9GuwdgR2VgQE6wQuxO
# 7bN2edgKNAltHIAxH+IOVN3lofvlRxCtZJj/UBYufL8FIXrilUEnacOTj5XJjdib
# Ia4NXJzwoq6GaIMMai27dmsAHZat8hZ79haDJLmIz2qoRzEvmtzjcT3XAH5iR9HO
# iMm4GPoOco3Boz2vAkBq/2mbluIQqBC0N1AI1sM9MIIGBzCCA++gAwIBAgIKYRZo
# NAAAAAAAHDANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZImiZPyLGQBGRYDY29tMRkw
# FwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDcwNDAzMTI1MzA5WhcNMjEwNDAz
# MTMwMzA5WjB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCfoWyx39tIkip8ay4Z4b3i48WZUSNQrc7dGE4kD+7R
# p9FMrXQwIBHrB9VUlRVJlBtCkq6YXDAm2gBr6Hu97IkHD/cOBJjwicwfyzMkh53y
# 9GccLPx754gd6udOo6HBI1PKjfpFzwnQXq/QsEIEovmmbJNn1yjcRlOwhtDlKEYu
# J6yGT1VSDOQDLPtqkJAwbofzWTCd+n7Wl7PoIZd++NIT8wi3U21StEWQn0gASkdm
# EScpZqiX5NMGgUqi+YSnEUcUCYKfhO1VeP4Bmh1QCIUAEDBG7bfeI0a7xC1Un68e
# eEExd8yb3zuDk6FhArUdDbH895uyAc4iS1T/+QXDwiALAgMBAAGjggGrMIIBpzAP
# BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQjNPjZUkZwCu1A+3b7syuwwzWzDzAL
# BgNVHQ8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwgZgGA1UdIwSBkDCBjYAUDqyC
# YEBWJ5flJRP8KuEKU5VZ5KShY6RhMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eYIQea0WoUqgpa1Mc1j0BxMuZTBQBgNVHR8E
# STBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsG
# AQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFJvb3RDZXJ0LmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0B
# AQUFAAOCAgEAEJeKw1wDRDbd6bStd9vOeVFNAbEudHFbbQwTq86+e4+4LtQSooxt
# YrhXAstOIBNQmd16QOJXu69YmhzhHQGGrLt48ovQ7DsB7uK+jwoFyI1I4vBTFd1P
# q5Lk541q1YDB5pTyBi+FA+mRKiQicPv2/OR4mS4N9wficLwYTp2OawpylbihOZxn
# LcVRDupiXD8WmIsgP+IHGjL5zDFKdjE9K3ILyOpwPf+FChPfwgphjvDXuBfrTot/
# xTUrXqO/67x9C0J71FNyIe4wyrt4ZVxbARcKFA7S2hSY9Ty5ZlizLS/n+YWGzFFW
# 6J1wlGysOUzU9nm/qhh6YinvopspNAZ3GmLJPR5tH4LwC8csu89Ds+X57H2146So
# dDW4TsVxIxImdgs8UoxxWkZDFLyzs7BNZ8ifQv+AeSGAnhUwZuhCEl4ayJ4iIdBD
# 6Svpu/RIzCzU2DKATCYqSCRfWupW76bemZ3KOm+9gSd0BhHudiG/m4LBJ1S2sWo9
# iaF2YbRuoROmv6pH8BJv/YoybLL+31HIjCPJZr2dHYcSZAI9La9Zj7jkIeW1sMpj
# tHhUBdRBLlCslLCleKuzoJZ1GtmShxN1Ii8yqAhuoFuMJb+g74TKIdbrHk/Jmu5J
# 4PcBZW+JC33Iacjmbuqnl84xKf8OxVtc2E0bodj6L54/LlUWa8kTo/0xggSdMIIE
# mQIBATCBkDB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSMw
# IQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQQITMwAAAUCWqe5wVv7M
# BwABAAABQDAJBgUrDgMCGgUAoIG2MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRo
# EA9kFBtZDpMsw8uw22rqVxPRJjBWBgorBgEEAYI3AgEMMUgwRqAsgCoAQQBuAGQA
# cgBvAGkAZABTAGQAawBJAG4AcwB0AGEAbABsAC4AcABzADGhFoAUaHR0cDovL21p
# Y3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAlZp3C90QZMHxJ/v7JWs2JUI+
# 2N70r99w2wXbp68o7X4AgPWafnlqaSL3D4j24mXWnK9SAItsgkXEAmhTfqsySWJ7
# 70vmaWuS5AaYGPtxum9qbGI5/2lkipNZ8xeOICPHXBgSpWcSQGIiD48iQc8IEyKQ
# Ehih/TIEaE5mzL0HIJ7ohsDID6QN+zA0YJHpzCz5sQI55kTXrSTRaL885dYdasRV
# yYOY2K8wWFxSVClFwE0qMKQYlWLxFzIhrdR9E55852Rx8/buNhiKCl6fNd+7wY3f
# XJqw4m8DeKomPOtw1WRtX7dZtVBB+IiOBvvUmF6jVFnWmOHDOCqe+Ef2ZOTTjqGC
# AigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGltZS1T
# dGFtcCBQQ0ECEzMAAADJZE0W2xp9sxUAAAAAAMkwCQYFKw4DAhoFAKBdMBgGCSqG
# SIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE3MDUxNzA0MzAy
# NlowIwYJKoZIhvcNAQkEMRYEFFwguy6txv8eC4PAnUp+tOb9gZU5MA0GCSqGSIb3
# DQEBBQUABIIBAFoRp2EGhsUOHNonq89n7QymCTkzCk9nCvU1vfiVKCNumaiYLwQ+
# tJc0AadsP1T1Zp5lVumnPJ1DMF5NWdgtbNwy6u1aKsiOXBlc9nfkVd+PWgfFFfD+
# IBCqWtfijUzKCcrPsAmNNUpClPAlUt849QcmSd0lmVQgn5U5yXoWpXjKGuo6cQtV
# eFeVIkSfMjiBLarRPMYT04EcV8U2V6cBsw9qZe8KwzSbI6c4yfszqgq5/BlZbSKl
# a7nO7n+COB9ZF0tVclGG+5oZgmiTnRgIGLhNNWTKjv+CuEmrQoDibDvVKnnpPFb9
# lmCCD+tpMce0IsbJ2HkunZaz9yMR5UpUnkc=
# SIG # End signature block
