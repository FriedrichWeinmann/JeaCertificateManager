function Add-CertificateTemplateRoleMember {
	<#
	.SYNOPSIS
		Adds an Active Directory principal to a role specific to certificates of a template.
	
	.DESCRIPTION
		Adds an Active Directory principal to a role specific to certificates of a template.
	
	.PARAMETER TemplateName
		The Certificate Template the role addresses.
	
	.PARAMETER Action
		The action the new member is supposed to be able to do.
	
	.PARAMETER ADMember
		The AD Principal (group / User / ...) to add.
	
	.EXAMPLE
		PS C:\> Add-CertificateTemplateRoleMember -TemplateName 'Test Server Cert' -Action Revoke -ADMember JEA-CM-TestServerCert-Revoke
		
		Adds the AD group "JEA-CM-TestServerCert-Revoke" to the role allowed to revoke certificates of the template "Test Server Cert"
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
			Add-RoleMember -Role $roleName -ADMember $member
		}
	}
}