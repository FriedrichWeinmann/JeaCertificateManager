function Get-IssuedCertificate {
	<#
	.SYNOPSIS
		List all certificates that have been issued.
	
	.DESCRIPTION
		List all certificates that have been issued.
		Only returns certificates from templates you have been granted access to.
	
	.PARAMETER CommonName
		Filter by CN of the certificate.
	
	.PARAMETER RequestID
		Specify the RequestID by which the certificate has been issued.
	
	.PARAMETER Requester
		Filter by who requested the certificate.
	
	.PARAMETER TemplateName
		Filter by template based on which the certificate was issued.
	
	.EXAMPLE
		PS C:\> Get-IssuedCertificate

		List all certificates that have been issued for templates you have access to.
	
	.EXAMPLE
		PS C:\> Get-IssuedCertificate -TemplateName WebServer

		List all WebServer certificates that have been issued.
	#>
	[CmdletBinding()]
	param (
		[string]
		$CommonName,

		[int]
		$RequestID,

		[string]
		$Requester,

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
		$param = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand Get-PkiCaIssuedCertificate
		Get-PkiCaIssuedCertificate @param | Where-Object {
			$isAdmin -or
			$_.TemplateDisplayName -in $allowedTemplates
		}
	}
}