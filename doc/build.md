# Nginx Demo Container Image

## Building The Image

Images built from this code are available at
[`ghcr.io/clifford2/nginx-demo`](https://ghcr.io/clifford2/nginx-demo).

If you prefer to build your own container images, there are a couple of ways to do that, namely:

- Build manually, using [GNU Make](https://www.gnu.org/software/make/), by running `make build-release && make test-release`
- With [GitHub Actions](https://github.com/features/actions) - sample configuration available in [`.github/workflows/build-image.yaml`](.github/workflows/build-image.yaml)
- With [Jenkins](https://www.jenkins.io/) - sample configuration available in [`Jenkinsfile`](Jenkinsfile)
- With an [Azure DevOps Pipeline](https://azure.microsoft.com/en-us/products/devops/pipelines) - sample configuration available in [`azure-pipelines.yml`](azure-pipelines.yml)
- With [GitLab CI/CD pipelines](https://docs.gitlab.com/ci/pipelines/) - sample configuration available in [`.gitlab-ci.yml`](.gitlab-ci.yml)
