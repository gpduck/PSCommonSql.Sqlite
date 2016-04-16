properties {
    $currentDir = resolve-path .
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    $baseDir = $psake.build_script_dir
    $version = git.exe describe --abbrev=0 --tags
    $nugetExe = "$baseDir\vendor\tools\nuget"
    $targetBase = "tools"
}

Task default -depends CopyLibraries

Task CopyLibraries {
  $TargetBin = "$baseDir\System.Data.Sqlite\bin"
  $TargetX64 = "$TargetBin\x64"
  $TargetX86 = "$TargetBin\x86"
  $TargetBin,$TargetX64,$TargetX86 | ForEach-Object {
    if(-not (Test-Path $_)) {
      $null = mkdir $_ -Force
    }
  }

  copy "$baseDir\vendor\packages\System.Data.SQLite.Core.*\lib\net40\*.*" "$baseDir\System.Data.SQLite\bin\x64\"
  copy "$baseDir\vendor\packages\System.Data.SQLite.Core.*\lib\net40\*.*" "$baseDir\System.Data.SQLite\bin\x86\"
  copy "$baseDir\vendor\packages\System.Data.SQLite.Core.*\build\net40\*" "$baseDir\System.Data.SQLite\bin" -Force -Recurse
}