<#
.SYNOPSIS
  A simple PowerShell copy/update files/folders script
.DESCRIPTION
  Allows you to copy/update/delete folders, files, folder trees
.PARAMETER SourcePath
    The full path to the source folder that will be copied
.PARAMETER DestPath
    The full path to the destination root folder that will be created where items will be copied.
.PARAMETER DestChildFolder
    Optional - Folder that will be created under the DestPath root folder
.PARAMETER FileName
    Optional - file name that will be copied from the SourcePath to the DestPath/DestChildFolder
.PARAMETER Hide
    Optional - Set the Hidden attribute on the DestPath folder - this is helpful if you want to stage files in the root without users seeing them.
.PARAMETER RemoveOnly
    Optional - Only removes the items specified. No Copy is performed
.PARAMETER RemoveLevel
    Optional - Set to Root, Child or File to remove various levels of file/folder structure.

.NOTES
  Version:          1.1
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:
    1.0 Initial script development
    1.1 Updated Formatting

.EXAMPLE
    Copy all content from SourcePath to DestPath\DestChildFolder and Remove DestPath1 if it exits before copying.
    ProcessContent -SourcePath $SourcePath -DestPath $DestPath -DestChildFolder $DestChild -RemoveLevel Root

.EXAMPLE
    Copy single file from SourcePath to DestPath\DestChildFolder\DestChildFolder and Remove DestChildFile if it exits before copying and Hide the DestPath folder.
    ProcessContent -SourcePath $SourcePath3 -DestPath $DestPath3 -DestChildFolder $DestChild3 -FileName $DestChildFile -RemoveLevel File -Hide

.EXAMPLE
    Remove DestPath and all child content without copying any new content
    ProcessContent -DestPath $DestPath -DestChildFolder $DestChild -RemoveLevel Root -RemoveOnly

#>

Function ProcessContent {
    [cmdletbinding()]
    Param (
        [cmdletbinding(DefaultParameterSetName='Copy')]
        [Parameter(Mandatory=$True, ParameterSetName='Copy')]
        [string]$SourcePath,

        [Parameter(Mandatory=$True, ParameterSetName='Copy')]
        [Parameter(Mandatory=$True, ParameterSetName='Remove')]
        [string]$DestPath,

        [Parameter(ParameterSetName='Copy')]
        [Parameter(ParameterSetName='Remove')]
        [string]$DestChildFolder,

        [Parameter(ParameterSetName='Copy')]
        [Parameter(ParameterSetName='Remove')]
        [string]$FileName,

        [Parameter(ParameterSetName='Copy')]
        [Switch]$Hide,

        [Parameter(Mandatory=$True, ParameterSetName='Remove')]
        [switch]$RemoveOnly,

        [Parameter(ParameterSetName='Copy')]
        [Parameter(Mandatory=$True, ParameterSetName='Remove')]
        [ValidateSet('Root','Child','File')]
        [string]$RemoveLevel

    )

    Try {
        Write-Host "Starting Process Content"
        $RootDestPath = $DestPath
        If($Hide.IsPresent) {
            Write-Host "Setting destination root to hidden: $($RootDestPath)"
            New-Item $RootDestPath -ItemType Directory -Force -ErrorAction SilentlyContinue
            Get-Item $RootDestPath -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Attributes = $_.Attributes -bor 'Hidden' } -ErrorAction SilentlyContinue | Out-Null
        }

        $NewDestPath = If($DestChildFolder) {Join-Path -Path $RootDestPath -ChildPath $DestChildFolder} Else {$RootDestPath}

        If($FileName) {
            $DestFilePath = "$($NewDestPath)\$($FileName)"
        }

        Switch($RemoveLevel)
        {
            "Root" {
                Write-Host "Removing Existing Path: $($RootDestPath)"
                Get-Item -Path $RootDestPath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
                break;
            }
            "Child" {
                If($DestChildFolder) {
                    Write-Host "Removing Existing Path: $($NewDestPath)"
                    Get-Item -Path $NewDestPath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
                }
                break;
            }
            "File" {
                If($FileName) {
                    Write-Host "Removing Existing File: $($DestFilePath)"
                    Get-Item -Path $DestFilePath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
                }
                break;
            }
            default {
                break;
            }
        }

        If($SourcePath -and (!($RemoveOnly.IsPresent))) {
            If(Test-Path -Path $SourcePath -ErrorAction SilentlyContinue) {
                If($FileName) {
                    $SourceFile = "$($SourcePath)\$($FileName)"
                }
                Else {
                    $Sourcefile = Join-Path -Path $SourcePath -ChildPath "*"
                }

                New-Item -Path $NewDestPath -ItemType Directory -Force | Out-Null
                Write-Host "Creating New Destination Path: $($NewDestPath)"

                Write-Host "Copying File: $($SourceFile) to $($NewDestPath)"
                If(Get-Item -Path $Sourcefile -Force -ErrorAction SilentlyContinue) {
                    Copy-Item -Path $Sourcefile -Destination $NewDestPath -Container -Recurse -Force | Out-Null
                }
            }
        }

        Write-Host "Finished Processing Content"
        Return "Complete"
    }
    Catch {
        Write-Host "An error occurred processing content for $($SourcePath)"
        Throw $Error[0]
    }
}