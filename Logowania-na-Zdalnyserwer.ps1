<#
  .SYNOPSIS
  Automatyczne logowanie do zdalnego serwera, wykonywania poleceń i zapisywania wyników
  .DESCRIPTION
  Skrypt łączy się ze zdalnym serwerem via SSH, wykonuje zestaw poleceń i zapisuje wyniki do pliku lokalnego
  
  .PARAMETER Hostname 
  Parametr określa adres serwera docelowego

  .PARAMETER Username
  Parametr określa nazwę użytkownika do logowania
  
  .PARAMETER Password
  Parametr określa hasło do logowania
  
  .PARAMETER Commands
  Parametr określa tabelę poleceń do wykonania (domyślnie: ls, ps)
  
  .PARAMETER OutputFile
  Parametr określa ścieżkę do pliku wyjściowego (domyślnie: output.txt)
  
  .EXAMPLE
  PS D:\GitHub> .\Logowania-na-Zdalnyserwer.ps1 -Hostname "test.rebex.net" -Username "demo" -Password "password" 
  Laczenie z test.rebex.net jako demo 
  Polaczenie nawiazane pomyslnie! 
  Wyniki zapisano do: output.txt 
  PS D:\GitHub>  
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Hostname,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [string[]]$Commands = @("ls -la", "ps aux", "df -h"),
    
    [string]$OutputFile = "output.txt"
)

# Sprawdzenie czy moduł Posh-SSH jest zainstalowany
if (-not (Get-Module -Name Posh-SSH -ListAvailable)) {
    Write-Host "Instalowanie modulu Posh-SSH"
    Install-Module -Name Posh-SSH -Force -AllowClobber
    Import-Module Posh-SSH
}

# Konwersja hasła na SecureString
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

try {
    Write-Host "Laczenie z $Hostname jako $Username"
    
    # Utworzenie sesji SSH
    $Session = New-SSHSession -ComputerName $Hostname -Credential $Credential -AcceptKey:$true
    
    if ($Session.Connected) {
        Write-Host "Polaczenie nawiazane pomyslnie!"
        
        # Inicjalizacja wyniku
        $Result = "=== Wyniki wykonanych polecen na $Hostname ===`n`n"
        $Result += "Data wykonania: $(Get-Date)`n`n"
        
        # Wykonanie każdego polecenia
        foreach ($Command in $Commands) {
            $Result += "=== Polecenie: $Command ===`n"
            $CommandResult = Invoke-SSHCommand -SSHSession $Session -Command $Command
            $Result += $CommandResult.Output + "`n`n"
        }
        
        # Zapis do pliku wyjściowego
        $Result | Out-File -FilePath $OutputFile -Encoding utf8
        Write-Host "Wyniki zapisano do: $OutputFile"
        
        # Zamknięcie sesji
        Remove-SSHSession -SSHSession $Session | Out-Null
    } else {
        Write-Host "Blad: Nie udalo sie nawiazac polaczenia"
    }
}
catch {
    Write-Host "Wystapil blad: $_"
}
finally {
    # Czyszczenie
    if ($Session -and $Session.Connected) {
        Remove-SSHSession -SSHSession $Session | Out-Null
    }
}