$ErrorActionPreference = Stop
Get-ChildItem '.\professional\Archive\' | Select -expand name | %{
  Start-Process .\vs_professional.exe -ArgumentList "--layout professional --clean Archive\$_\Catalog.json" -Wait
  Remove-Item ".\professional\Archive\$_" -Recurse -Force #-Confirm:$false
}

Get-ChildItem '.\community\Archive\' | Select -expand name | %{
  Start-Process .\vs_community.exe -ArgumentList "--layout community --clean Archive\$_\Catalog.json " -Wait
  Remove-Item ".\community\Archive\$_" -Recurse -Force #-Confirm:$false
}

Get-ChildItem '.\enterprise\Archive\' | Select -expand name | %{
  Start-Process .\vs_enterprise.exe -ArgumentList "--layout enterprise --clean Archive\$_\Catalog.json" -Wait
  Remove-Item ".\enterprise\Archive\$_" -Recurse -Force #-Confirm:$false
}
