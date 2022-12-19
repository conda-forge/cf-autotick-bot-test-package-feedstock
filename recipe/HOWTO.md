# How to use the GPU queue

> Work in progress

On `conda-forge.yml`, add:

```yaml
provider:
  linux:
    - azure  # if you want to keep azure builds, not needed
    - github_actions  # REQUIRED
github_actions:
  self_hosted: true
  self_hosted_labels: 
    - cirun-openstack-gpu
```

And rerender!

