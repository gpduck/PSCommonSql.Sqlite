#handle PS2
    if(-not $PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }

#Get public and private function definition files.
    $Public  = Get-ChildItem $PSScriptRoot\*.ps1 -Exclude *.Tests.ps1 -ErrorAction SilentlyContinue
    #$Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue

#Pick and import assemblies:
    if([IntPtr]::size -eq 8) #64
    {
        $SQLiteAssembly = Join-path $PSScriptRoot "bin\x64\System.Data.SQLite.dll"
    }
    elseif([IntPtr]::size -eq 4) #32
    {
        $SQLiteAssembly = Join-path $PSScriptRoot "bin\x86\System.Data.SQLite.dll"
    }
    else
    {
        Throw "Something is odd with bitness..."
    }

    if( -not ($Library = Add-Type -path $SQLiteAssembly -PassThru -ErrorAction stop) )
    {
        Throw "This module requires the ADO.NET driver for SQLite:`n`thttp://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki"
    }
    
#Dot source the files
    Foreach($import in @($Public))
    {
        Try
        {
            #PS2 compatibility
            if($import.fullname)
            {
                . $import.fullname
            }
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname): $_"
        }
    }

#Create some aliases, export public functions
    Export-ModuleMember -Function $($Public | Select -ExpandProperty BaseName)
    
#Register the SQLite provider factory
    $Assembly = ($Library | Select-Object -First 1).Assembly
    PSCommonSql\Register-DbProvider -DbProviderFactory   @{
        Name = "SQLite Data Provider"
        Description = ".NET Framework Data Provider for SQLite"
        Invariant = "System.Data.SQLite"
        Type = "System.Data.SQLite.SQLiteFactory, $($Assembly.Fullname)"
    }
    
 $Script:DbProviderName = "System.Data.Sqlite"
