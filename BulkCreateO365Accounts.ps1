<#
.SYNOPSIS
	Bulk create AzureAD accounts and assign administrative rights
.DESCRIPTION
	This script bulk creates AzureAD accounts using a csv file as a source of account information. The script is rough but (mostly) works. There are some intermittent issues with role assignments.
	Format of the csv file: FirstName,LastName,Email,AdminName,Division,Title,TempPassword,GlobalAdministrator,GlobalReader,ExchangeAdmin,HelpdeskAdmin,ServiceAdmin,SharePointAdmin,TeamsServiceAdmin,UserAdmin,BillingAdmin,ComplianceAdmin,SecurityAdmin,SecurityOperator,SecurityReader,StreamAdmin,
.PARAMETER csvfile
    The csvfile parameter is used to specify the input file containing the list of accounts and permissions to add to AzureAD
.EXAMPLE
	.\BulkCreateO365Accounts.ps1
	Example of running the script using the default azureadusers.csv filename
.EXAMPLE
	.\BulkCreateO365Accounts.ps1 -csvfile input.csv
	Run the script using input.csv as the source of account information
.NOTES
	Script:		BulkCreateO365Accounts.ps1
	Author:		Mike Daniels
	
	Changelog
		0.1		Initial version, very rough, mostly works; intermittent errors assigning role permissions
	
	Pre-requisites
	install-module AzureAD
	install-module MSOnline
	Change the field tha $admupn variable line to your tenant domain, this will be changed to a variable in a future version for easier access
		
	References
	https://docs.microsoft.com/en-us/powershell/module/azuread/new-azureaduser?view=azureadps-2.0
	https://docs.microsoft.com/en-us/microsoft-365/enterprise/assign-roles-to-user-accounts-with-microsoft-365-powershell?view=o365-worldwide#:~:text=see%20these%20instructions.-,Use%20the%20Azure%20Active%20Directory%20PowerShell%20for%20Graph%20module,user%20principal%20name%20(UPN).
	https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-userstates

	Known Issues
	FWIW, the default header of the csvfile contains a field for a password; this is inherently a bad idea to leave a plaintext file lying around with a bunch of passwords, even if they are only temporary; will be replaced with something better in the future, maybe
	The script uses both AzureAD components and MSOnline components so you are promtped to login to your tenant twice, once when connecting with AzureAD, once when connecting with MSOnline
	This was a quick and dirty script that has no error checking, I may fix this script in the future to address some of these issues
	
#>

[CmdletBinding()]

Param(
	[string]$csvfile = "azureadusers.csv"
)

# Start of script

# Import AzureAD PowerShell Module
Import-Module AzureAD
Import-Module MSOnline

# Connect to AzureAD; used for account creation
Connect-AzureAD

# Connect to MSOnline; used to enable MFA and set role memberships
Connect-MsolService

$azureaduserfile = Import-Csv -Path $csvfile
ForEach ($azureaduser in $azureaduserfile)
{
	# Concatenate variables to create display name and UPN
	$displayname = $azureaduser.FirstName + " " + $azureaduser.LastName
	$admupn = $azureaduser.AdminName + "@tiptoptoys.onmicrosoft.com"
	
	# Set initial password, and require change at next login
	$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
	$PasswordProfile.Password = $azureaduser.TempPassword
	$PasswordProfile.ForceChangePasswordNextLogin = $true
	
	# Create new Azure AD User
	New-AzureADUser -DisplayName $displayname -GivenName $azureaduser.FirstName -Surname $azureaduser.LastName -UserPrincipalName $admupn -MailNickname $azureaduser.AdminName -OtherMails $azureaduser.Email -AccountEnabled $true -ShowInAddressList $false -PasswordProfile $PasswordProfile

	# Wait for user creation
	Sleep 5

	# Turn on enforced MFA
	$enablemfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
	$enablemfa.RelyingParty = "*"
	$enablemfa.State = "Enforced"
	$enablemfa_array = @($enablemfa)

	# Change the following UserPrincipalName to the user you wish to change state
	Set-MsolUser -UserPrincipalName $admupn -StrongAuthenticationRequirements $enablemfa_array

	# Assign O365 roles based on spreadsheet settings
	If ($azureaduser.GlobalAdministrator -eq "X")
	{
		Write-Host "GlobalAdministrator"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Company Administrator"
	}
	
	If ($azureaduser.GlobalReader -eq "X")
	{
		Write-Host "GlobalReader"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Global Reader"
	}
	If ($azureaduser.ExchangeAdmin -eq "X")
	{
		Write-Host "ExchangeAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Exchange Service Administrator"
	}
	If ($azureaduser.HelpdeskAdmin -eq "X")
	{
		Write-Host "HelpdeskAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Helpdesk Administrator"
	}
	If ($azureaduser.ServiceAdmin -eq "X")
	{
		Write-Host "ServiceAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Service Support Administrator"
	}
	If ($azureaduser.SharePointAdmin -eq "X")
	{
		Write-Host "SharePointAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "SharePoint Service Administrator"
	}	
	If ($azureaduser.TeamsServiceAdmin -eq "X")
	{
		Write-Host "TeamsServiceAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Teams Service Administrator"
	}
	If ($azureaduser.UserAdmin -eq "X")
	{
		Write-Host "UserAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "User Account Administrator"
	}
	If ($azureaduser.BillingAdmin -eq "X")
	{
		Write-Host "BillingAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Billing Administrator"
	}
	If ($azureaduser.ComplianceAdmin -eq "X")
	{
		Write-Host "ComplianceAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Compliance Administrator"
	}
	If ($azureaduser.SecurityAdmin -eq "X")
	{
		Write-Host "SecurityAdmin"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Security Administrator"
	}
	If ($azureaduser.SecurityOperator -eq "X")
	{
		Write-Host "SecurityOperator"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Security Operator"
	}
	If ($azureaduser.SecurityReader -eq "X")
	{
		Write-Host "SecurityReader"
		Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Security Reader"
	}
	If ($azureaduser.StreamAdmin -eq "X")
	{
		Write-Host "StreamAdmin"
		#Add-MsolRoleMember -RoleMemberEmailAddress $admupn -RoleName "Stream Admin"
	}
}