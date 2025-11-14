if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -notmatch '^#') {
            $name, $value = $_ -split '=', 2
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
} else {
    Write-Host "Error: .env file not found."
    exit 1
}

$imageName = $args[0]
$dockerFilePath = "./ci/build/Dockerfile"
$projectDir = "/c/Users/simon/workspaces/home-projects/Whispr"
$containerWorkDir = "/app"

# Hardcoded path for wow_addons_dir
# $wowAddonsDir = "/d/World of Warcraft/_retail_/Interface/AddOns"
# $wowAddonsDirPtr = "/d/World of Warcraft/_xptr_/Interface/AddOns"
$wowAddonsDir = "/c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"

Write-Host "Building Docker image: $imageName"
docker build -t $imageName -f $dockerFilePath .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed."
    exit 1
}

Write-Host "Running Docker container and mounting project directory.."
docker run --rm -ti `
    -v "${projectDir}:${containerWorkDir}" `
    -v "${wowAddonsDir}:${wowAddonsDir}" `
    -v "${wowAddonsDirPtr}:${wowAddonsDirPtr}" `
    $imageName bash

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start Docker container."
    exit 1
}
