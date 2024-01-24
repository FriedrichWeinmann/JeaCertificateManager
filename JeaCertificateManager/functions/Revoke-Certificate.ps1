function Revoke-Certificate {
	<#
	.SYNOPSIS
		Revoke a specific certificate.
	
	.DESCRIPTION
		Revoke a specific certificate.
	
	.PARAMETER Certificate
		The certificate to revoke.
		Must be a X509Certificate2 object (such as found in the certificate store) or an object as returned by Get-IssuedCertificate.
	
	.PARAMETER Reason
		Why the certificate is being revoked.
		Defaults to "Unspecified"
	
	.PARAMETER RevocationDate
		Starting when the certificate is considered invalid.
		Defaults to "now"
	
	.EXAMPLE
		PS C:\> Get-IssuedCertificate -TemplateName 'Test Template' | Revoke-Certificate

		Revokes all certificates from the "Test Template" certificate template.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		$Certificate,

		[ValidateSet('Unspecified', 'KeyCompromise', 'CACompromise', 'AffiliationChanged', 'Superseded', 'CessationOfOperation', 'CertificateHold')]
		[string]
		$Reason = 'Unspecified',

		[DateTime]
		$RevocationDate = [DateTime]::Now
	)
	Begin {
		$currentRoles = (Get-Role | Where-Object { Test-RoleMembership -Role $_.Name }).Name
		$allowedTemplates = $currentRoles | Where-Object { $_ -match '-Revoke$' } | ForEach-Object {
			$_ -replace '-Revoke$'
		}
		$isAdmin = $currentRoles -contains 'Admin'

		if ($PSSenderInfo) {
			Write-PSFMessage -Message 'Remotely connected as {0} ({1})' -StringValues $PSSenderInfo.UserInfo.Identity.Name, $PSSenderInfo.UserInfo.WindowsIdentity.User.Value
		}
	}
	process {
		if ($Certificate.IssuedRequestID) {
			$foundCert = Get-IssuedCertificate -RequestID $Certificate.IssuedRequestID
		}
		else {
			$certificateObject = $Certificate
			if ($Certificate.certificate) { $certificateObject = $Certificate.certificate }
			if ($Certificate -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
				Write-Error "Bad input certificate type! Must be a certificate object (e.g. as returned by Get-IssuedCertificate). Received: $_"
				return
			}

			$foundCert = Get-IssuedCertificate | Where-Object { $_.Certificate.Thumbprint -eq $certificateObject.THumbprint }
		}

		if (-not $foundCert) {
			Write-Error "Certificate not found! Ensure you have the necessary "
			return
		}

		if (-not $isAdmin -and $foundCert.TemplateDisplayName -notin $allowedTemplates) {
			Write-Error "Certificate found, but you do not have permission to revoke certificates of template $($foundCert.TemplateDisplayName)"
			return
		}

		$param = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand Revoke-PkiCaCertificate
		Revoke-PkiCaCertificate @param
	}
}