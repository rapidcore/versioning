function Update-Clone {
    # $path: the path to navigate to, where we should update versions and all that
    # $goTo: where to navigate after we are done
    # $version: The version to apply
    # $updatePackageRef: whether we should update the RapidCore package reference - should be false when operating on rapidcore it self.
    Param ([string]$path, [string]$goTo, [string]$version, [bool]$updatePackageRef)
    
    Write-Host "updating " $path 
    Set-Location $path
    $output = (& git checkout master 2>&1)
    $output = (& git pull 2>&1)
    $output = (& dotnet restore  2>&1)
    
    # Update reference to RapidCore new version
    if ($updatePackageRef -eq $true) {
        $output = (& dotnet add package RapidCore -v $version --no-restore 2>&1)
        $commitMsg = -join("Update RapidCore to v",$version);
        $output = (& git add -Av 2>&1)
        $output = (& git commit -m $commitMsg 2>&1)
    }

    # Invoke the dotnet version tool to create version commit + git tag
    $newVersion = & dotnet version --output-format=json $version | ConvertFrom-Json | Select-Object -ExpandProperty newVersion

    Set-Location $goTo
    return $newVersion
}

$updateStrategy = $args[0]
Write-Host "Update strategy: " $updateStrategy

# Go to the rapidcore repo and update
$newVersion = Update-Clone -path .\rapidcore\src -goTo ..\..\ -version $updateStrategy -updatePackageRef $false
Write-Host "Version of rapidcore is: " $newVersion " setting this explicit version on all other rapidcore libs"

Update-Clone -path .\rapidcore.mongo\src -goTo ..\..\ -version $newVersion -updatePackageRef $true |Out-Null
Update-Clone -path .\rapidcore.redis\src -goTo ..\..\ -version $newVersion -updatePackageRef $true |Out-Null
Update-Clone -path .\rapidcore.xunit\src -goTo ..\..\ -version $newVersion -updatePackageRef $true |Out-Null