# `minio-mirror` GitHub Action

This action exposes the [min.io](https://min.io/) `mirror` subcommand.

## Example Use Case: Artifact Upload

The original use case for this GitHub action was to upload build artifacts to a self-hosted Minio instance.

**Note**: In the following, we assume that you have, on your local dev machine, administrator access to a Minio cluster with local alias `MYCLUSTER`.
(I.e., we assume that you have configured access to that cluster on your machine using `mc config host add MYCLUSTER https://...`).

### Step 1: Create a Minio user, bucket, and access policy

We want a dedicated bucket for the CI artifacts, and a dedicated user for the workflow that has access to only that bucket.

We therefore need to 
* create a Minio user
* create a Minio bucket
* create a  Minio policy that allows access to just that bucket
* assign the Minio user we just created that policy in order to give it access to the bucket

This repository ships with a convenience script that creates above resources (with a random password):

```bash
scripts/create-user-and-bucket.bash \
    MYCLUSTER \
    projectname-ci-artifact-uploader \
    projectname-ci-artifacts \
    noreplace
```

Please have a look at the script before you run it on a production installation ;)

The output should end with the following lines:

```text
SUCCESS
Use the following environment variable to impersonate the user create above:
MC_HOST_myalias=https://projectname-ci-artifact-uploader:<SOMERANDOMPASSWORD>@<cluster-url-from-mc-config-host-list>
```

### Step 2: Add the step to your workflow.yml file

```yaml
- name: Upload Artifacts
  uses: 49nord/action-minio-mirror@v1
  with:
      host: ${{ secrets.ARTIFACT_UPLOAD_HOST }}
      bucket: ${{ secrets.ARTIFACT_UPLOAD_BUCKET }}
      src: ./artifacts
      dst: ${{ github.sha }}
```

### Step 3: Add the secrets to your GitHub repo config

(At the time of writing, secrets are configured in *RepoView*/*Settings*/*Secrets*)

| Secret Name            | Example Value                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| ARTIFACT_UPLOAD_HOST   | `https://projectname-ci-artifact-uploader:<SOMERANDOMPASSWORD>@<cluster-url-from-mc-config-host-list>` |
| ARTIFACT_UPLOAD_BUCKET | `projectname-ci-artifacts`                                                                             |

### Commit changes to your workflow file, push, done!