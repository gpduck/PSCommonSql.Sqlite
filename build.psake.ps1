properties {
    $currentDir = resolve-path .
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    $baseDir = $psake.build_script_dir
    $version = git.exe describe --abbrev=0 --tags
    $nugetExe = "$baseDir\vendor\tools\nuget"
    $targetBase = "tools"
}

$ModuleName = "PSCommonSql.Sqlite"

Task default -depends CopyLibraries, Test, Build
Task Build -depends CopyLibraries, Package
Task Package -depends Version-Module, Pack-Nuget, Unversion-Module
Task Release -depends Build, Push-Nuget

Task Test {
    RequireModule "Pester"
    RequireModule "PSCommonSql"
    
    Push-Location $baseDir
    Import-Module Pester -ErrorAction Stop
    $PesterResult = Invoke-Pester -PassThru
    if($PesterResult.FailedCount -gt 0) {
      throw "$($PesterResult.FailedCount) tests failed."
    }
    Pop-Location
}

Task CopyLibraries {
  $TargetBin = "$baseDir\$ModuleName\bin"
  $TargetX64 = "$TargetBin\x64"
  $TargetX86 = "$TargetBin\x86"
  $TargetBin,$TargetX64,$TargetX86 | ForEach-Object {
    if(-not (Test-Path $_)) {
      $null = mkdir $_ -Force
    }
  }

  copy "$baseDir\vendor\packages\System.Data.SQLite.Core.*\lib\net40\*.*" "$baseDir\$ModuleName\bin\x64\"
  copy "$baseDir\vendor\packages\System.Data.SQLite.Core.*\lib\net40\*.*" "$baseDir\$ModuleName\bin\x86\"
  copy "$baseDir\vendor\packages\System.Data.SQLite.Core.*\build\net40\*" "$baseDir\$ModuleName\bin" -Force -Recurse
}

Task Version-Module {
    $v = git.exe describe --abbrev=0 --tags
    $changeset=(git.exe log -1 $($v + '..') --pretty=format:%H)
    (Get-Content "$baseDir\$ModuleName\$ModuleName.psm1") `
      | % {$_ -replace "\`$version\`$", "$version" } `
      | % {$_ -replace "\`$sha\`$", "$changeset" } `
      | Set-Content "$baseDir\$ModuleName\$ModuleName.psm1"
}

Task Unversion-Module {
    Set-Location $baseDir
    git.exe checkout -- $baseDir\$ModuleName\$ModuleName.psm1
    Set-Location $currentDir
}

Task Pack-Nuget {
    if (Test-Path "$baseDir\build") {
      Remove-Item "$baseDir\build" -Recurse -Force
    }

    $null = mkdir "$baseDir\build"
    exec {
      . $nugetExe pack "$baseDir\$ModuleName.nuspec" -OutputDirectory "$baseDir\build" `
      -NoPackageAnalysis -version $version -Properties targetBase=$targetBase
    }
}

Task Push-Nuget {
    $pkg = Get-Item -path $baseDir\build\$ModuleName.*.nupkg
    exec { .$nugetExe push $pkg.FullName }
}

function RequireModule {
  param($Name)
  if(-not (Get-Module -List -Name $Name )) {
    Import-Module PowershellGet
    Find-Package -ForceBootstrap -Name zzzzzz -ErrorAction Ignore
    Install-Module $Name -Scope CurrentUser
  }  
}