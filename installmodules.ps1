Install-PackageProvider -Name NuGet -force
Install-Module xdscfirewall -force
Set-NetFirewallProfile -Profile public,private,domain -Enabled false
Enable-PSRemoting -Force
