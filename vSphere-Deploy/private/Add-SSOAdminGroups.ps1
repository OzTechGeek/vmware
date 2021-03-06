function Add-SSOAdminGroups {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER Deployment
	
    .PARAMETER ADInfo
	
    .PARAMETER VIHandle

    .EXAMPLE
        The example below shows the command line use with Parameters.

        Add-SSOAdminGroups -Deployment < > -ADInfo < > -VIHandle < >

        PS C:\> Add-SSOAdminGroups

    .NOTES
        Author: Michael van Blijdesteijn
        Last Edit: 2019-10-24
        Version 1.0 - Add-SSOAdminGroups
    #>
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)]
		$Deployment,
		[Parameter(Mandatory=$true)]
		$ADInfo,
		[Parameter(Mandatory=$true)]
		$VIHandle
	)

	Write-Output "============ Add AD Groups to SSO Admin Groups ============" | Out-String

	$subDomain 		 = $Deployment.SSODomainName.Split(".")[0]
	$domainExtension = $Deployment.SSODomainName.Split(".")[1]

	# Active Directory variables
	$adAdminsGroupSID = (Get-ADgroup -Identity $ADInfo.ADvCenterAdmins).sid.value

	$versionRegex = '\b\d{1}\.\d{1}\.\d{1,3}\.\d{1,5}\b'
	$script 	  = "echo `'" + $Deployment.VCSARootPass + "`' | appliancesh 'com.vmware.appliance.version1.system.version.get'"

	Write-Output $script | Out-String

	$viVersion = $(Invoke-ExecuteScript $script $Deployment.Hostname "root" $Deployment.VCSARootPass $VIHandle).Scriptoutput.Split("") | Select-String -pattern $versionRegex

	Write-Output $viVersion

	if ($Deployment.Parent) {
		$LDAPServer = $Deployment.Parent
	} else {
		$LDAPServer = $Deployment.Hostname
	}

	$commandList = $null
	$commandList = @()

	# Set Default SSO Identity Source Domain
	if ($viVersion -match "6.5.") {
		$commandList += "echo -e `"dn: cn=$($Deployment.SSODomainName),cn=Tenants,cn=IdentityManager,cn=Services,dc=$subDomain,dc=$domainExtension`" >> defaultdomain.ldif"
		$commandList += "echo -e `"changetype: modify`" >> defaultdomain.ldif"
		$commandList += "echo -e `"replace: vmwSTSDefaultIdentityProvider`" >> defaultdomain.ldif"
		$commandList += "echo -e `"vmwSTSDefaultIdentityProvider: $($ADInfo.ADDomain)`" >> defaultdomain.ldif"
		$commandList += "echo -e `"-`" >> defaultdomain.ldif"
		$commandList += "/opt/likewise/bin/ldapmodify -f /root/defaultdomain.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'$($Deployment.VCSARootPass)`'"
	}

	# Add AD vCenter Admins to Component Administrators SSO Group.
	$commandList += "echo -e `"dn: cn=ComponentManager.Administrators,dc=$subDomain,dc=$domainExtension`" >> groupadd_cma.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_cma.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_cma.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_cma.ldif"
	$commandList += "echo -e `"-`" >> groupadd_cma.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_cma.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Add AD vCenter Admins to License Administrators SSO Group.
	$commandList += "echo -e `"dn: cn=LicenseService.Administrators,dc=$subDomain,dc=$domainExtension`" >> groupadd_la.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_la.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_la.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_la.ldif"
	$commandList += "echo -e `"-`" >> groupadd_la.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_la.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Add AD vCenter Admins to Administrators SSO Group.
	$commandList += "echo -e `"dn: cn=Administrators,cn=Builtin,dc=$subDomain,dc=$domainExtension`" >> groupadd_adm.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_adm.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_adm.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_adm.ldif"
	$commandList += "echo -e `"-`" >> groupadd_adm.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_adm.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Add AD vCenter Admins to Certificate Authority Administrators SSO Group.
	$commandList += "echo -e `"dn: cn=CAAdmins,cn=Builtin,dc=$subDomain,dc=$domainExtension`" >> groupadd_caa.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_caa.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_caa.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_caa.ldif"
	$commandList += "echo -e `"-`" >> groupadd_caa.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_caa.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Add AD vCenter Admins to Users SSO Group.
	$commandList += "echo -e `"dn: cn=Users,cn=Builtin,dc=$subDomain,dc=$domainExtension`" >> groupadd_usr.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_usr.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_usr.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_usr.ldif"
	$commandList += "echo -e `"-`" >> groupadd_usr.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_usr.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Add AD vCenter Admins to System Configuration Administrators SSO Group.
	$commandList += "echo -e `"dn: cn=SystemConfiguration.Administrators,dc=$subDomain,dc=$domainExtension`" >> groupadd_sca.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_sca.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_sca.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_sca.ldif"
	$commandList += "echo -e `"-`" >> groupadd_sca.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_sca.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Add AD vCenter Admins to System Configuration Administrators SSO Group.
	$commandList += "echo -e `"dn: cn=SystemConfiguration.BashShellAdministrators,dc=$subDomain,dc=$domainExtension`" >> groupadd_scbsa.ldif"
	$commandList += "echo -e `"changetype: modify`" >> groupadd_scbsa.ldif"
	$commandList += "echo -e `"add: member`" >> groupadd_scbsa.ldif"
	$commandList += "echo -e `"member: externalObjectId=$adAdminsGroupSID`" >> groupadd_scbsa.ldif"
	$commandList += "echo -e `"-`" >> groupadd_scbsa.ldif"
	$commandList += "/opt/likewise/bin/ldapmodify -f /root/groupadd_scbsa.ldif -h $LDAPServer -D `"cn=Administrator,cn=Users,dc=$subDomain,dc=$domainExtension`" -w `'" + $Deployment.VCSARootPass + "`'"

	# Remove all ldif files.
	$commandList += 'rm /root/*.ldif'

	# Excute the commands in $commandList on the vcsa.
	Invoke-ExecuteScript $commandList $Deployment.Hostname "root" $Deployment.VCSARootPass $VIHandle
}