$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$publicDocuments = [Environment]::GetFolderPath("CommonDocuments")
if ([string]::IsNullOrWhiteSpace($publicDocuments)) {
    $publicDocuments = Join-Path $env:PUBLIC "Documents"
}
$cacheRoot = Join-Path $publicDocuments "proglab2-cache\$userSid"
$repositoryPath = Join-Path $cacheRoot "repository"

New-Item -ItemType Directory -Force -Path $repositoryPath | Out-Null

$existingMavenOpts = [Environment]::GetEnvironmentVariable("MAVEN_OPTS", "User")
$cleanMavenOpts = [regex]::Replace(
    [string]$existingMavenOpts,
    '(?<!\S)-Dmaven\.repo\.local=(?:"[^"]*"|\S+)',
    ''
).Trim()
$repositoryOption = "-Dmaven.repo.local=`"$repositoryPath`""
$newMavenOpts = ($cleanMavenOpts, $repositoryOption | Where-Object { $_ }) -join ' '

[Environment]::SetEnvironmentVariable("MAVEN_USER_HOME", $cacheRoot, "User")
[Environment]::SetEnvironmentVariable("MAVEN_OPTS", $newMavenOpts, "User")
$env:MAVEN_USER_HOME = $cacheRoot
$env:MAVEN_OPTS = $newMavenOpts

if ($projectRoot -match '[^\x00-\x7F]' -or $projectRoot -match '\s' -or $projectRoot -match 'OneDrive') {
    Write-Warning "プロジェクトは C:\proglab2 など、日本語・空白・OneDriveを含まない場所へ移動してください: $projectRoot"
}

$javaCommand = Get-Command java -ErrorAction SilentlyContinue
if ($null -eq $javaCommand) {
    throw "Javaを実行できません。Java 25 LTSをインストールしてから再実行してください。"
}
$javaVersion = (& java -version 2>&1 | Select-Object -First 1)
if ($javaVersion -notmatch 'version "25(?:\.|\")') {
    throw "Java 25 LTSではありません: $javaVersion"
}

Push-Location $projectRoot
try {
    & .\mvnw.cmd --version
    if ($LASTEXITCODE -ne 0) {
        throw "Maven Wrapperの初期化に失敗しました。"
    }
}
finally {
    Pop-Location
}

Write-Host "Windows用のMavenキャッシュを設定しました。"
Write-Host "MAVEN_USER_HOME: $cacheRoot"
Write-Host "ローカルリポジトリ: $repositoryPath"
Write-Host "このPowerShellではすぐ使用できます。ほかのアプリには、次回のWindowsサインイン後に確実に反映されます。"
