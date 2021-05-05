
# GitHub Action | Python3.7 Pyinstaller

**Please note:** This repository is currently in **beta** phase.

# Usage
## Pre-requisites
Create a workflow `.yml` file in your `.github/workflows` directory. An [example workflow](#example-workflow---create-a-release) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

**Please note:** Make sure you have ``.spec`` file for more info [read here](https://pyinstaller.readthedocs.io/en/stable/man/pyi-makespec.html), and if you have ``.gitignore`` please exclude ``*.spec``. All docker images have python3.x with preinstalled `tk-dev` make sure to ``excludes=["tkinter"]`` in ``.spec`` file if you are not using tk in project.

## Inputs

- `path`: Directory containing source code & `.spec` file (optional `requirements.txt`). Required: `true`
- `pypi_url`: Specify a custom URL for PYPI. Required: `false`
- `pypi_index_url`: Specify a custom URL for PYPI Index. Required: `false`
- `spec`: Specify a file path for `.spec` file in case you have multi `.spec` files. Required: `true`
- `requirements`: Specify a file path for requirements.txt file. Required: `true`, Default: `requirements.txt`
- `rename`: Rename the binary file, this will only work when you have `--onefile` binary. Required: `false`

## Outputs
For more information on these outputs, see the [Documentation](https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#setting-an-output-parameter) for an example of what these outputs look like.

- `location`: Binary file location or Directory location.
- `filename`: Binary file name or NULL.
- `content_type`: File content type or NULL.

**Please note:**  Github action's outputs are depend on the pyinstaller's output if it's single file or not, ``location`` will return the binary file location when pyinstaller make single file `--onefile` or it will return the directory location same with `filename` and `content_type` they will return `NULL` because there is not a single file.

## Supported Versions
Python3.8.9 pyinstaller with arch: `amd64`  is  ``action-python/pyinstaller-py3.8@amd64``. Python3.7.9 pyinstaller with arch: `amd64`  is  ``action-python/pyinstaller-py3.7@amd64`` .

### Python versions available
- python3.8
- python3.7

### Architecture available  with ``branch``
- amd64
- i386
- win32
- win64

## Example workflow - create a release
```
name: Make release with Build binaries

on:
  push:
    # Sequence of patterns matched against refs/tags
    tags:
      - 'v*' # Push events to matching v*, i.e. v1.0, v20.15.10
 
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master

    - name: PyInstaller Linux amd64
      id: amd64
      uses: action-python/pyinstaller-py3.8@amd64
      with:
        path: .

    - name: Create Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false

    - name: Upload Linux File amd64
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
          upload_url: ${{ steps.create_release.outputs.upload_url }} 
          asset_path: ${{ steps.amd64.outputs.location }}
          asset_name: ${{ steps.amd64.outputs.filename }}
          asset_content_type: ${{ steps.amd64.outputs.content_type }}
```
This uses the `GITHUB_TOKEN` provided by the [virtual environment](https://help.github.com/en/github/automating-your-workflow-with-github-actions/virtual-environments-for-github-actions#github_token-secret), so no new token is needed.

## Sources 

This is customized and advanced version of  [# Chris R](https://github.com/cdrx/docker-pyinstaller) docker files and [# Jack McKew](https://github.com/JackMcKew/pyinstaller-action-windows) github action with multi architecture support with different versions of python3. 

## Contributing
We would love you to contribute to [`@action-python/pyinstaller-py3.8`](https://github.com/action-python/pyinstaller-py3.8) and [`@action-python/pyinstaller-py3.7`](https://github.com/action-python/pyinstaller-py3.7), make sure to be clear and detailed description in pull requests, you are welcome!
