# $env:nugetapikey=(Get-Clipboard)
Publish-Module -Path .\Abbr -Verbose -NuGetApiKey $env:nugetapikey -WhatIf
