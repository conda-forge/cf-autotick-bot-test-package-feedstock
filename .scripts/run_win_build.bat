:: PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
:: will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
:: changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
:: benefit from the improvement.

:: Note: we assume a Miniforge installation is available

:: INPUTS (required environment variables)
:: CONFIG: name of the .ci_support/*.yaml file for this job
:: CI: azure, github_actions, or unset
:: UPLOAD_PACKAGES: true or false
:: UPLOAD_ON_BRANCH: true or false

setlocal enableextensions enabledelayedexpansion

call :start_group "Configuring conda"

:: Activate the base conda environment
call activate base
:: Configure the solver
set "CONDA_SOLVER=libmamba"
if !errorlevel! neq 0 exit /b !errorlevel!
set "CONDA_LIBMAMBA_SOLVER_NO_CHANNELS_FROM_INSTALLED=1"

:: Provision the necessary dependencies to build the recipe later
echo Installing dependencies
mamba.exe install "python=3.10" pip mamba conda-build conda-forge-ci-setup=4 -c conda-forge --strict-channel-priority --yes
if !errorlevel! neq 0 exit /b !errorlevel!
pip.exe install git+https://github.com/mamba-org/boa

:: Set basic configuration
echo Setting up configuration
setup_conda_rc .\ ".\recipe" .\.ci_support\%CONFIG%.yaml
if !errorlevel! neq 0 exit /b !errorlevel!
echo Running build setup
CALL run_conda_forge_build_setup


if !errorlevel! neq 0 exit /b !errorlevel!

if EXIST LICENSE.txt (
    echo Copying feedstock license
    copy LICENSE.txt "recipe\\recipe-scripts-license.txt"
)

call :end_group

:: Build the recipe
echo Building recipe
conda.exe mambabuild "recipe" -m .ci_support\%CONFIG%.yaml --suppress-variables %EXTRA_CB_OPTIONS%
if !errorlevel! neq 0 exit /b !errorlevel!

:: Prepare some environment variables for the upload step
if /i "%CI%" == "github_actions" (
    set "FEEDSTOCK_NAME=%GITHUB_REPOSITORY:*/=%"
    set "GIT_BRANCH=%GITHUB_REF:refs/heads/=%"
    if /i "%GITHUB_EVENT_NAME%" == "pull_request" (
        set "IS_PR_BUILD=True"
    ) else (
        set "IS_PR_BUILD=False"
    )
    set "TEMP=%RUNNER_TEMP%"
)
if /i "%CI%" == "azure" (
    set "FEEDSTOCK_NAME=%BUILD_REPOSITORY_NAME:*/=%"
    set "GIT_BRANCH=%BUILD_SOURCEBRANCHNAME%"
    if /i "%BUILD_REASON%" == "PullRequest" (
        set "IS_PR_BUILD=True"
    ) else (
        set "IS_PR_BUILD=False"
    )
    set "TEMP=%UPLOAD_TEMP%"
)

:: Validate
call :start_group "Validating outputs"
validate_recipe_outputs "%FEEDSTOCK_NAME%"
if !errorlevel! neq 0 exit /b !errorlevel!
call :end_group

if /i "%UPLOAD_PACKAGES%" == "true" (
    if /i "%IS_PR_BUILD%" == "false" (
        call :start_group "Uploading packages"
        if not exist "%TEMP%\" md "%TEMP%"
        set "TMP=%TEMP%"
        upload_package --validate --feedstock-name="%FEEDSTOCK_NAME%" .\ ".\recipe" .ci_support\%CONFIG%.yaml
        if !errorlevel! neq 0 exit /b !errorlevel!
        call :end_group
    )
)

exit

:: Logging subroutines

:start_group
if /i "%CI%" == "github_actions" (
    echo ::group::%~1
    exit /b
)
if /i "%CI%" == "azure" (
    echo ##[group]%~1
    exit /b
)
echo %~1
exit /b

:end_group
if /i "%CI%" == "github_actions" (
    echo ::endgroup::
    exit /b
)
if /i "%CI%" == "azure" (
    echo ##[endgroup]
    exit /b
)
exit /b
