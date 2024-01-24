function Get-ExpiringCertificate {
	<#
	.SYNOPSIS
		Get all issued certificates that are about to expire.
	
	.DESCRIPTION
		Get all issued certificates that are about to expire.
		Shows for each certificate, whether it has already been renewed.
	
	.PARAMETER DaysExpirationThreshold
		How many days until expiration shall be considered "about to expire".
		Defaults to 14
	
	.PARAMETER TemplateName
		Name of the template based on which the certificate was issued.
	
	.EXAMPLE
		PS C:\> Get-ExpiringCertificate
		
		List all certificates that will expire in the next 14 days for all templates you have access to.

	.EXAMPLE
		PS C:\> Get-ExpiringCertificate -TemplateName WebServer -DaysExpirationThreshold 30
		
		List all WebServer certificates that will expire in the next 30 days for all templates you have access to.
	#>
	[CmdletBinding()]
	param (
		[int]
		$DaysExpirationThreshold = 14,
		
		[PsfArgumentCompleter('PkiExtension.TemplateName')]
		[string]
		$TemplateName
	)
	begin {
		$currentRoles = (Get-Role | Where-Object { Test-RoleMembership -Role $_.Name }).Name
		$allowedTemplates = $currentRoles | Where-Object { $_ -match '-Read$' } | ForEach-Object {
			$_ -replace '-Read$'
		}
		$isAdmin = $currentRoles -contains 'Admin'

		if ($PSSenderInfo) {
			Write-PSFMessage -Message 'Remotely connected as {0} ({1})' -StringValues $PSSenderInfo.UserInfo.Identity.Name, $PSSenderInfo.UserInfo.WindowsIdentity.User.Value
		}
	}
	process {
		$param = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand Get-PkiCaExpiringCertificate
		Get-PkiCaExpiringCertificate @param | Where-Object {
			$isAdmin -or
			$_.TemplateDisplayName -in $allowedTemplates
		}
	}
}