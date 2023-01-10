# How to use the GPU queue

> Work in progress

# How to register the cloud provider (only once)

Cirun needs the OpenStack GPU provider added.
We can use the web dashboard manually, or the [`cirun-py`](https://github.com/AktechLabs/cirun-py) tool:

```
$ conda create -n cirun -c conda-forge cirun
$ conda activate cirun
$ cirun --help
```

Then, get an API token from https://cirun.io/admin/api
and export it:

```
export CIRUN_API_KEY=<your-api-key>
```

Now you can use this command to register the cloud provider:

```
$ cirun cloud connect openstack \
  --username XXXXXX \
  --password XXXXXX \
  --auth-url XXXXXX \
  --project-id XXXXXXX \
  --domain-id XXXXXXX \
  --network XXXXXX
```

This only needs to be done once for the entire organization. 
Credentials are in the vault.

## Giving access to repos

First, the given repo must be given access to the Cirun app via
this [API endpoint](https://docs.github.com/en/rest/apps/installations?apiVersion=2022-11-28#add-a-repository-to-an-app-installation
):

```
PUT 
/user/installations/{installation_id}/repositories/{repository_id}
```

`installation_id` is 18453316. It can be obtained from the [Organization settings> GitHub Apps](https://github.com/organizations/conda-forge/settings/installations) panel. Click on "Cirun Application" and get the identifier from the URL.


Then, on the Cirun end, the repo nees to be enabled. `cirun-py` tool makes this easy:

```
$ cirun repo add conda-forge/cf-autotick-bot-test-package-feedstock
```

### Removing access

Very similar! On the Github side:

```
DELETE 
/user/installations/{installation_id}/repositories/{repository_id}
```

On the Cirun side:

```
$ cirun repo remove conda-forge/cf-autotick-bot-test-package-feedstock
```

## Configure the feedstock

On `conda-forge.yml`, add:

```yaml
provider:
  linux:
    - azure  # if you want to keep azure builds, not needed
    - github_actions  # REQUIRED
github_actions:
  self_hosted: true
  self_hosted_labels: 
    - cirun-openstack-gpu  # having a cirun-* label will add the Cirun configs!
```

And rerender! This is what should happen after you open the new PR:

1. A new Github Actions entry is visible in the CI, waiting for a self-hosted runner for around two minutes while Cirun sets things up.
2. Cirun finishes provisioning and a new CI entry pops up. Details are available in Cirun.io.
3. At this point, the self-hosted runner is available and will run the workflow steps. The OpenStack UI should also report a new instance running.

## Troubleshooting

- Cirun never reported anything (CI entry didn't appear). There is a problem with the configuration.  Check `.cirun.yml` and the GHA workflow and make sure the labels match.

## Notes

- Only one conda-forge account should govern the Cirun configuration. We are using `conda-forge-daemon` to avoid issues with double access and other problems with multi-account configurations. This is a current limitation.
- VM Images are built at https://github.com/aktech/nvidia-openstack-image/
