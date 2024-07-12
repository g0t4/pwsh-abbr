# $env:nugetapikey=(Get-Clipboard)
Publish-Module -Path . -Verbose -NuGetApiKey $env:nugetapikey -WhatIf
