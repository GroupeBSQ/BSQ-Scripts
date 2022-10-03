$from_user_name = read-host -Prompt "entré le nom d'usager qui est la source des groupes"
$to_user_name = read-host -Prompt "entré le nom d'usager qui est la Destination des groupes"

write-host $from_user_name
$grp_src = Get-ADPrincipalGroupMembership $from_user_name | select-object distinguishedName

#write-host $to_user_name
#et-ADPrincipalGroupMembership $to_user_name | select-object distinguishedName


foreach ($grp in $grp_src) {
    add-adgroupmember $grp -members $to_user_name
}

write-host $to_user_name
Get-ADPrincipalGroupMembership $to_user_name | select-object distinguishedName
