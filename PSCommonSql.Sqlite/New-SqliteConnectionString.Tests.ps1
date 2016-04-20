[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText","")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
Import-Module $here

Describe "New-SqliteConnectionString" {
    It "Generates a valid connection string with DataSource" {
        $ConnectionString = New-SqliteConnectionString -DataSource "c:\pester.db"
        $ConnectionString.ConnectionString | Should Be "DataSource=c:\pester.db"
    }
    
    It "Generates a valid connection string with DataSource and Password" {
        $PesterPassword = ConvertTo-SecureString -AsPlainText -Force -String "pass"
        $ConnectionString = New-SqliteConnectionString -DataSource "c:\pester.db" -Password $PesterPassword
        $ConnectionString.ConnectionString | Should Be "DataSource=c:\pester.db;Password=pass"
    }
    
    It "Generates a valid connection string with DataSource and ReadOnly" {
        $ConnectionString = New-SqliteConnectionString -DataSource "c:\pester.db" -ReadOnly
        $ConnectionString.ConnectionString | Should Be "DataSource=c:\pester.db;ReadOnly=True"
    }
    
    It "Includes the DbProviderName" {
        $ConnectionString = New-SqliteConnectionString -DataSource "c:\pester.db"
        $ConnectionString.DbProviderName | Should Be "System.Data.Sqlite" 
    }
}
