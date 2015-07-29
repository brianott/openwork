#!powershell

# WANT_JSON
# POWERSHELL_COMMON

Import-Module WebAdministration;

$params = Parse-Args $args;

$result = New-Object PSObject -Property @{
    changed = $FALSE
}

If ($params.name) {
    $name = $params.name
}
Else {
    Fail-Json $result "missing required argument: name"
}

$iisPath = "IIS:\Sites\$name"

If ($params.state) {
    $state = $params.state.ToString().ToLower()
    If (($state -ne 'present') -and ($state -ne 'absent')) {
        Fail-Json $result "state is '$state'; must be 'present' or 'absent'"
    }
}
Elseif (!$params.state) {
    $state = "present"
}

If ( $state -eq 'present' ) 
{ #ensure website exists
    #if we are creating a new website, we need a path to it
    $physicalpath = Get-Attr $params "physicalpath" $FALSE 
    If ($physicalpath -eq $FALSE)
    {
      Fail-Json $result "missing required argument: physicalpath" 
    }

  $arg_bindings = Get-Attr $params "bindings" $FALSE
  $src_bindings = @()
  If ($arg_bindings -eq $FALSE)
  {
    #default bindings
    $src_bindings += @{protocol="http";bindingInformation="*:80:*"}
  }
  Else
  {
     ForEach ($arg_binding in $arg_bindings)
     {
         $src_binding_protocol = $arg_binding.protocol
         if ($src_binding_protocol -ne "net.tcp" -and $src_binding_protocol -ne "http" -and $src_binding_protocol -ne "https")
         {
            Fail-Json $result "invalid binding protocol $src_binding_protocol"
         }
         $src_binding_bindingInformation = $arg_binding.bindingInformation
         #just check if the bindingInformation is in the right format, IIS is not very restrictive in regards to this itself
         if ($src_binding_bindingInformation -notmatch ".+\:.+\:.+" )
         {
          Fail-Json $result "invalid bindingInformation $src_binding_bindingInformation"
         } 
         $src_bindings += @{protocol="$src_binding_protocol";bindingInformation="$src_binding_bindingInformation"}
     }
  }
  try
  {
    if (!(Test-Path "$iisPath")) 
    {
        New-Item "$iisPath" -bindings $src_bindings -physicalPath $physicalpath -force
        $result.changed = $TRUE
    }
    else 
    {
        $dest_iissite = get-item $iisPath
        $dest_physicalpath = $dest_iissite.PhysicalPath
        if ( $physicalpath.CompareTo($dest_physicalpath))
        {
            Set-ItemProperty "$iisPath" -Name PhysicalPath -Value $physicalpath
            $result.changed = $TRUE
        }
        $dest_bindings = get-webbinding -Name $name
        #find and remove destination bindings that are not in the src list
        ForEach ($dest_binding in $dest_bindings)
        {
            if (!(($src_bindings.bindingInformation) -Contains ($dest_binding.bindingInformation)))
            {
                $splitbindingInformation = $dest_binding.bindingInformation.Split(":")
                get-webbinding -Name $name -Protocol $dest_binding.protocol -IPAddress $splitbindingInformation[0] -Port $splitbindingInformation[1] -HostHeader $splitbindingInformation[2] | remove-webbinding
                $result.changed = $TRUE
            }
        }
        $dest_bindings = get-webbinding -Name $name
        #add bindings not found in the destination that are in the src list
        ForEach ($src_binding in $src_bindings)
        {
            if (!(($dest_bindings.bindingInformation) -Contains ($src_binding.bindingInformation) ))
            {
                $splitbindingInformation = $src_binding.bindingInformation.Split(":")
                new-webbinding -Name $name -Protocol $src_binding.protocol -IPAddress $splitbindingInformation[0] -Port $splitbindingInformation[1] -HostHeader $splitbindingInformation[2]
                $result.changed = $TRUE
            }
        }
    }
  }
  catch 
  {
        Fail-Json $result $_.Exception.Message
  }
}
Elseif ($state -eq "absent") 
{
    try 
    {
        if (Test-Path "$iisPath") 
        {
           Remove-Item "$iisPath" -force -Recurse -confirm:$false
           $result.changed = $TRUE
        }
    }
    catch 
    {
        Fail-Json $result $_.Exception.Message
    }
}

Exit-Json $result
