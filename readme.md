# JEA Certificate Manager

Welcome to the JEA-based Certificate Manager project.
This project aims to provide tools to better delegate parts of the certificate lifecycle management.

It is an implementation of the Just Enough Administration technology to delegate access to a workflow, rather than privileges over a system.
Fundamentally, it allows you to grant ...

> ... permission to read or revoke certificates for a specific template

Without granting any further privileges.

This project does _not_ provide any GUI elements, but can be called from such a GUI.

## Profit

> As the setup can be a bit intimidating, we'll start with what the tool can do for us

To actually use this system, we first need to establish a connection from our client computer to the CA host the setup (see below) has been performed on:

```powershell
$session = New-PSSession -ComputerName '<InsertNameHere>' -ConfigurationName 'JeaCertificateManager'
Import-PSSession -AllowClobber -Session $session -DisableNameChecking -ModuleName JeaCertificateManager -FormatTypeName PkiExtension.IssuedCertificate, PkiExtension.ExpiringCertificate
```

Then we can use the commands provided by the tool:

```powershell
# Read all issued certificates
Get-IssuedCertificate

# Find all expiring certificates
Get-ExpiringCertificate

# Revoke all certificates of the specified template
Get-IssuedCertificate -TemplateName 'Test Template' | Revoke-Certificate
```

> This is a project to offer fine-tuned delegation of certificate management.
> If you do not care about least privileges and just want the admin tools, [check out this project here](https://github.com/FriedrichWeinmann/PkiExtension).
> All we really do here, is wrap around the PkiExtension module's tools.

## Installation

Setup for this project is a bit more involved:

> 1: Provide the modules

```powershell
Install-Module JeaCertificateManager
```

This project must be installed on the PKI itself.
If this server does not have direct internet access, internal redistribution may be required:

```powershell
Save-Module JeaCertificateManager -Path .
```

Then copy the modules to `C:\Program Files\WindowsPowerShell\Modules`.
This module _must_ be placed in that specific path.

> 2: Prepare Active Directory

This tool requires a group Managed Service Account (gMSA), which must be provided ahead of time.
The gMSA needs permissions on the PKI to manage certificates.

Further needed is a group for all users supposed to work with this project operationally (irrespective of the actual permission grants provided in a later step).

> 3: Setup Just Enough Administration

This must be executed on the CA-hosting server in a console executed "as administrator".
Registering a JEA endpoint will restart WinRM, interrupting all existing PowerShell remoting connections!

```powershell
# Replace gMSA (ServiceAccount) and name of the group (AccessGroup) as needed
Register-JeaCertificateManager -ServiceAccount 'contoso\svcCertManager' -AccessGroup 'contoso\JEA-CertificateManager-Access'
```

Note: This command will temporarily create a self-deleting scheduled task to restart WinRM service.
In some OS versions, the service will not automatically restart after registering a JEA endpoint, leading to locking yourself out from the machine without that task.

> 4: Setup Access Roles

With the current setup, Domain Admins will be able to fully use the tool, but nobody else will, defeating the entire purpose of this tool.
To wrap things up, we now need to define roles per Certificate Template, for which we want to delegate access.

```powershell
# Create reader role and assign an AD group to it
New-CertificateTemplateRole -TemplateName 'Test Server Cert' -Action Read -ADMember JEA-CM-TestServerCert-Read

# Create revoker role and assign an AD group to it
New-CertificateTemplateRole -TemplateName 'Test Server Cert' -Action Revoke -ADMember JEA-CM-TestServerCert-Revoke
```

These commands must be run on the CA-Host and require one of:

+ A SID for a ADMember (e.g.: S-1-5-21-3710217024-1956168353-80067308-500)
+ Network access for LDAP (e.g. interactive console through RDP, PS Remoting with CredSSP or Kerberos Constrained Delegation).

_Recommendations and notes on the roles:_

+ Create one AD Group per role (Group must be created first, before running the command)
+ Do not add individual users to roles
+ Manage all individual rights directly in AD only -> The directly attached AD Group is the only role member
+ Members of the built-in "Admin" role have global access to everything the gMSA can do and JEA exposes
+ Users who are not in the "Admin" role can only access certificates of the specific template they have been assigned - there is no "default" permission set.

_Adding a principal to the Admin role:_

```powershell
Add-RoleMember -Role Admin -ADMember S-1-5-21-3710217024-1956168353-80067308-500 -System certificatemanager
```

## Dependencies

This project uses a few other dependencies to make the magic happen:

+ [PSFramework](https://psframework.org) - for logging and tooling
+ [PkiExtension](https://github.com/FriedrichWeinmann/PkiExtension) - Actual implementation of certificate operations. If you are looking for the tools without the delegation, look here.
+ [Roles](https://www.powershellgallery.com/packages/Roles) - Toolkit to implement your own RBAC on resource level for JEA Endpoints.
