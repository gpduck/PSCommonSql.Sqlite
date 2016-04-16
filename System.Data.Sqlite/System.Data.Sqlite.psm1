#handle PS2
if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

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

function Get-SqliteDbProviderFactory {
  $Assembly = ($Library | Select-Object -First 1).Assembly
  
  @{
    Name = "SQLite Data Provider"
    Description = ".NET Framework Data Provider for SQLite"
    Invariant = "System.Data.SQLite"
    Type = "System.Data.SQLite.SQLiteFactory, $($Assembly.Fullname)"
  }
}

function New-SqliteConnectionString {
    [cmdletbinding()]
    [OutputType([String])]
    param(
        [Parameter( Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQL Server Instance required...' )]
        [Alias( 'Instance', 'Instances', 'ServerInstance', 'Server', 'Servers','cn','Path','File','FullName','Database' )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DataSource,
                
        [Parameter( Position=2,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [System.Security.SecureString]
        $Password,

        [Parameter( Position=3,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Switch]
        $ReadOnly
    )
    Process
    {
        foreach($DataSRC in $DataSource)
        {
            Write-Verbose "Creating connection string for Data Source '$DataSRC'"
            [string]$ConnectionString = "Data Source=$DataSRC;"
            if ($Password) 
            {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                $ConnectionString += "Password=$PlainPassword;"
            }
            if($ReadOnly)
            {
                $ConnectionString += "Read Only=True;"
            }
            Write-Debug "ConnectionString $ConnectionString"
            [PSCustomObject]@{
              ConnectionString = $ConnectionString
              DbProviderName = "System.Data.SQLite" 
            }
            
        }
    }
}