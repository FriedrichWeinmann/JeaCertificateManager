function New-CertificateTemplateRole {
	<#
	.SYNOPSIS
		Creates a new access role for a certificate template.
	
	.DESCRIPTION
		Creates a new access role for a certificate template.
		It is through these roles that access is granted when calling from the JEA endpoint.
	
	.PARAMETER TemplateName
		The ertificate template the role applies to.
	
	.PARAMETER Action
		The action performed against the template that the role allows.
		Think of this as the permission level.

		+ Read: General read access to certificates of the template.
		+ Revoke: Right to revoke a certificate
	
	.PARAMETER ADMember
		The AD Entity(s) granted the role.
		Could be a simple AD Group.
	
	.EXAMPLE
		PS C:\> New-CertificateTemplateRole -TemplateName WebServer -Action Read -ADMember JEA-CM-Role-WebServer-Read
	
		Grants read access to the WebServer template to the AD Group 'JEA-CM-Role-WebServer-Read'
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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

		New-Role -Name $roleName -Description ('{0} Access to certificates of the template {1}' -f $Action, $TemplateName) -ErrorAction Stop

		foreach ($member in $ADMember) {
			Add-RoleMember -Role $roleName -ADMember $member
		}
	}
}