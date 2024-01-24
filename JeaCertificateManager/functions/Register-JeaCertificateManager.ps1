function Register-JeaCertificateManager
{
<#
	.SYNOPSIS
		Registers the module's JEA session configuration in WinRM.
	
	.DESCRIPTION
		Registers the module's JEA session configuration in WinRM.
		This effectively enables the module as a remoting endpoint.
	
	.PARAMETER ServiceAccount
		The gMSA to use.
		<Domain>\<SamAccountName>
		e.g.: contoso\svcCertManager
		Do NOT include the trailing "$" of the SamAccountName

	.PARAMETER AccessGroup
		AD Group allowed to connect to the JEA Endpoint / Certificate Manager.
		Note that actual permission grant to certificate operations is handled separately, this is ONLY for overall system access.
		
		See project documentation on how to actual delegate access:
		https://github.com/FriedrichWeinmann/JeaCertificateManager

	.EXAMPLE
		PS C:\> Register-JeaCertificateManager -ServiceAccount 'contoso\svcCertManager' -AccessGroup 'contoso\JEA-CertificateManager-Access'
	
		Register this module in WinRM as a remoting target.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$ServiceAccount,

		[Parameter(Mandatory = $true)]
		[string]
		$AccessGroup
	)
	
	process
	{
		$moduleName = (Get-Item -Path "$script:ModuleRoot\*.psd1").BaseName
		try {
			$null = Get-PSSessionConfiguration -Name $moduleName -ErrorAction Stop
			Unregister-PSSessionConfiguration -Name $moduleName -Force -Confirm:$false
		}
		catch { }

		# Setup the roles system
		if (-not (Get-RoleSystem -Name CertificateManager)) {
			New-RoleSystem -Name CertificateManager
			Select-RoleSystem -Name CertificateManager

			New-Role -Name Admin -Description 'Global Access to all Certificate Manager Operations'
			try { Add-RoleMember -Role Admin -ADMember "$env:USERDOMAIN\Domain Admins" }
			catch {
				Write-Warning "Failed to add Domain Admins to the 'Admin' role. This is not a strict functional requirement, but a convenience. In order to add a group to the admins role, use something like the following line:`nAdd-RoleMember -Role Admin -ADMember `"$env:USERDOMAIN\Domain Admins`" -System certificatemanager"
			}
		}

		# Create Temporary Configuration File
		$configuration = [System.IO.File]::ReadAllText("$script:ModuleRoot\sessionconfiguration.pssc")
		$moduleVersion = (Import-PSFPowerShellDataFile -Path "$script:ModuleRoot\$moduleName.psd1").ModuleVersion
		$resolvedConfiguration = $configuration -replace '%ModuleVersion%',$moduleVersion -replace '%gMSAName%',$ServiceAccount -replace '%ADGroupNT%',$AccessGroup -replace '%ModulePath%',$script:ModuleRoot
		$configFile = New-PSFTempFile -ModuleName JeaCertificateManager -Name ConfigFile -Extension pssc
		$resolvedConfiguration | Set-Content -Path $configFile

		# Plan to start WinRM in case it does not recover from registering the JEA session
		$taskname = "Start-WinRM-$(Get-Random)"
		$action = New-ScheduledTaskAction -Execute powershell.exe -Argument ('-Command Start-Sleep -Seconds 60; Start-Service WinRM -Confirm:$false; Unregister-ScheduledTask -TaskName {0} -Confirm:$false' -f $taskname)
		$principal = New-ScheduledTaskPrincipal -UserId SYSTEM -RunLevel Highest
		$null = Register-ScheduledTask -TaskName $taskname -Action $action -Principal $principal
		Start-ScheduledTask -TaskName $taskname

		Register-PSSessionConfiguration -Name $moduleName -Path $configFile -Force

		Remove-PSFTempItem -ModuleName JeaCertificateManager -Name *
	}
}