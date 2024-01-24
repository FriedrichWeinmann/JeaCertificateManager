function Get-CertificateTemplateRoleMember {
	<#
	.SYNOPSIS
		List who or what has been assigned what role for a given template.
	
	.DESCRIPTION
		List who or what has been assigned what role for a given template.
		Note that generally it is recommended to have a 1:1 match to an AD Group and manage access in AD.
	
	.PARAMETER TemplateName
		Name of the template to check rolemembership from.
	
	.PARAMETER Action
		What action assignments to check.
	
	.EXAMPLE
		PS C:\> Get-CertificateTemplateRoleMember
		
		Read all role assignments for all templates.
	
	.EXAMPLE
		PS C:\> Get-CertificateTemplateRoleMember -Action Revoke
		
		Read all revocation assignments for all templates.
	#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PkiExtension.TemplateName')]
		[string]	
		$TemplateName,

		[ValidateSet('Read', 'Revoke')]
		[string]
		$Action = @('Read', 'Revoke')
	)
	process {
		$pattern = '{0}-({1})' -f $TemplateName, ($Action -join '|')
		Get-Role | Where-Object Name -Match $pattern | ForEach-Object {
			Get-RoleMember -Role $_.Name
		}
	}
}