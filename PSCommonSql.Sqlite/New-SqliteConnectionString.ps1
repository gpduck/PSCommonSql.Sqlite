function New-SQLiteConnectionString {
    [cmdletbinding()]
    [OutputType([String])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions")]
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
		Begin {
				$SqliteFactory = Get-SqliteDbProviderFactory
		}
    Process
    {
        foreach($DataSRC in $DataSource)
        {
						$ConnectionStringBuilder = $SqliteFactory.CreateConnectionStringBuilder()
						
            Write-Verbose "Creating connection string for Data Source '$DataSRC'"
						
						$PSBoundParameters.Keys | ForEach-Object {
								$Name = $_
								switch($Name) {
										"Password" {
												$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
												$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
												$ConnectionStringBuilder.Password = $PlainPassword					
										}
										"DataSource" {
											$ConnectionStringBuilder.DataSource = $DataSrc
										}
										default {
												if($PSBoundParameters[$Name] -is [System.Management.Automation.SwitchParameter]) {
													$Value = [Boolean]$PSBoundParameters[$Name]
												} else {
													$Value = $PSBoundParameters[$Name]
												}
												$ConnectionStringBuilder."$Name" = $Value
										}
								}
						}
						
						$ConnectionString = $ConnectionStringBuilder.ConnectionString
            Write-Debug "ConnectionString $ConnectionString"
						[PSCustomObject]@{
            		ConnectionString = $ConnectionString
             	 	DbProviderName = "System.Data.SQLite" 
            }
        }
    }
}