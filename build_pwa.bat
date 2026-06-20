@echo off
REM ============================================================================
REM  Campaignza PWA build script
REM
REM  WHAT THIS SCRIPT IS FOR
REM  -----------------------
REM  Builds the Flutter web app for GitHub Pages, configured for the
REM  /CampaignzaV01/ subpath. Run this from the project root:
REM
REM      build_pwa.bat          (double-click, or run in a terminal)
REM
REM  The deployable site is written to:  build\web\
REM  After it finishes, deploy build\web\ the same way you do today
REM  (e.g. push it to your gh-pages repo / GitHub Pages source).
REM
REM
REM  WHAT IT DOES (step by step)
REM  ---------------------------
REM  1. flutter clean
REM       Wipes stale build artifacts so no old cached files leak into the
REM       new deploy (important for PWA updates).
REM
REM  2. flutter pub get
REM       Makes sure dependencies are in sync.
REM
REM  3. flutter build web --release --base-href="/CampaignzaV01/"
REM       The actual build with the required base path. The --base-href is
REM       CRITICAL for GitHub Pages: without it the build resets the base href
REM       to "/", which breaks every asset URL under /CampaignzaV01/.
REM
REM  4. Verifies the base href
REM       Scans build\web\index.html for <base href="/CampaignzaV01/"> and
REM       ABORTS if it is wrong, so you can never accidentally ship a broken
REM       build.
REM
REM  Each step is followed by an errorlevel check, so if flutter clean or the
REM  build fails, the script stops immediately instead of claiming success.
REM
REM  NOTE: This script only BUILDS. It does not deploy. Deploy build\web\ the
REM  same way you deploy today.
REM
REM  QUICK SANITY CHECK: open build\web\index.html and confirm line ~18 reads
REM      <base href="/CampaignzaV01/">
REM ============================================================================

setlocal

set "BASE_HREF=/CampaignzaV01/"
set "BUILD_DIR=build\web"

echo.
echo === Cleaning previous build ===
call flutter clean
if errorlevel 1 goto :error

echo.
echo === Fetching dependencies ===
call flutter pub get
if errorlevel 1 goto :error

echo.
echo === Building web (release, base-href=%BASE_HREF%) ===
call flutter build web --release --base-href="%BASE_HREF%"
if errorlevel 1 goto :error

echo.
echo === Verifying base href ===
findstr /C:"<base href=\"%BASE_HREF%\"" "%BUILD_DIR%\index.html" >nul
if errorlevel 1 (
    echo [WARNING] base href not found in %BUILD_DIR%\index.html.
    echo          Expected: ^<base href="%BASE_HREF%"^>
    echo          Aborting so you can investigate before deploying.
    goto :error
) else (
    echo [OK] base href is correct in %BUILD_DIR%\index.html
)

echo.
echo ============================================================
echo  BUILD SUCCEEDED
echo  Output: %BUILD_DIR%\
echo  Deploy that folder the same way you deploy today.
echo ============================================================
echo.
endlocal
exit /b 0

:error
echo.
echo [ERROR] Build failed. See messages above.
endlocal
exit /b 1
