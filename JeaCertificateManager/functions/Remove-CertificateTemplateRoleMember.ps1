function Remove-CertificateTemplateRoleMember {
	<#
	.SYNOPSIS
		Unassigns membership in a role granting access to certificates of a template.
	
	.DESCRIPTION
		Unassigns membership in a role granting access to certificates of a template.
	
	.PARAMETER TemplateName
		The name of the template for which's associated role to unassign membership.
	
	.PARAMETER Action
		The action that may no longer be performed.
	
	.PARAMETER ADMember
		Whose access to revoke.
	
	.EXAMPLE
		PS C:\> Remove-CertificateTemplateRoleMember -TemplateName 'Test Server Cert' -Action Revoke -ADMember JEA-CM-TestServerCert-Revoke
		
		Removes the AD group "JEA-CM-TestServerCert-Revoke" from the role allowed to revoke certificates of the template "Test Server Cert"
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('PkiExtension.TemplateName')]
		[string]	
		$TemplateName,

		[Parameter(Mandatory = $true)]
		[ValidateSet('Read','Revoke')]
		[string]
		$Action,

		[string[]]
		$ADMember
	)
	process {
		$roleName = '{0}-{1}' -f $TemplateName, $Action

		foreach ($member in $ADMember) {
			Remove-RoleMember -Role $roleName -ADMember $member
		}
	}
}