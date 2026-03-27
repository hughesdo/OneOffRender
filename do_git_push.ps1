$git = "C:\Program Files\Git\bin\git.exe"
Write-Host "=== Starting git add -A ===" -ForegroundColor Cyan
& $git add -A 2>&1
Write-Host "=== Add complete, committing... ===" -ForegroundColor Cyan
& $git commit -m "Major update: 200+ new shaders and textures, Rainbow Gyroid Orb, Where Is Her Mind Plasma, Dice shader, per-bin FFT normalization, housekeeping (Junk/Notes excluded), updated README and .gitignore" 2>&1
Write-Host "=== Commit done, pushing... ===" -ForegroundColor Cyan
& $git push origin main 2>&1
Write-Host "=== PUSH COMPLETE ===" -ForegroundColor Green

