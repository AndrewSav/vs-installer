Start-Process .\vs_professional.exe -ArgumentList "--layout professional --passive" -Wait
Start-Process .\vs_community.exe -ArgumentList "--layout community --passive" -Wait
Start-Process .\vs_enterprise.exe -ArgumentList "--layout enterprise --passive" -Wait

