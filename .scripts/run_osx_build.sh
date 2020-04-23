#!/usr/bin/env bash

set -x



echo "Installing a fresh version of Miniconda."
if [[ ${CI} == "travis" ]]; then
  echo -en 'travis_fold:start:install_miniconda\\r'
fi
MINICONDA_URL="https://github.com/conda-forge/miniforge/releases/download/4.8.3-2"
MINICONDA_FILE="Miniforge3-MacOSX-x86_64.sh"
curl -L -O "${MINICONDA_URL}/${MINICONDA_FILE}"
bash $MINICONDA_FILE -b
if [[ ${CI} == "travis" ]]; then
  echo -en 'travis_fold:end:install_miniconda\\r'
fi

echo "Configuring conda."
if [[ ${CI} == "travis" ]]; then
  echo -en 'travis_fold:start:configure_conda\\r'
fi

source ${HOME}/miniconda3/etc/profile.d/conda.sh
conda activate base

conda install -n base -c conda-forge --quiet --yes conda-forge-ci-setup=2 conda-build

echo "Mangling homebrew in the CI to avoid conflicts."
if [[ ${CI} == "travis" ]]; then
  echo -en 'travis_fold:start:mangle_homebrew\\r'
fi
/usr/bin/sudo mangle_homebrew
/usr/bin/sudo -k
if [[ ${CI} == "travis" ]]; then
  echo -en 'travis_fold:end:mangle_homebrew\\r'
fi

mangle_compiler ./ ./recipe .ci_support/${CONFIG}.yaml
setup_conda_rc ./ ./recipe ./.ci_support/${CONFIG}.yaml

source run_conda_forge_build_setup


if [[ ${CI} == "travis" ]]; then
  echo -en 'travis_fold:end:configure_conda\\r'
fi

set -e

make_build_number ./ ./recipe ./.ci_support/${CONFIG}.yaml

conda build ./recipe -m ./.ci_support/${CONFIG}.yaml --clobber-file ./.ci_support/clobber_${CONFIG}.yaml

if [[ "${UPLOAD_PACKAGES}" != "False" ]]; then
  upload_package ./ ./recipe ./.ci_support/${CONFIG}.yaml
fi