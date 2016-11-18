Set-NetFirewallProfile -Profile public,private,domain -Enabled false
Set-item WSMan:\localhost\Client\TrustedHosts -Value * -Force
