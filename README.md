Simple Dapr app that uses Reminders
===================================

Its really difficult to run more than one instance of a dapr app, so unfortunately we have to break out the nuclear hammer that is kubernetes. This stack requires `kind`, but it may work with others, you'll have to edit the requires files yourself.

How to start:

1. Create kind cluster `kind create cluster`
2. cd into `terraform` dir
3. `terraform init` and `terraform apply`
4. Wait until all services are up
5. Port forward the api: `kubectl port-forward --namespace dapr-reminder service/dapr-reminder 8080:80`
6. Call the endpoint: `http :8080/create`
7. Tail the logs of the service for any error messages

If you need to change the source code:
- adjust docker image path in `Taskfile.yml` and terraform `dapr-reminder.tf`
- modify source code, build and push with `task docker-build`
- restart the `dapr-reminder` deployment in kubernetes, to pick up new image

There are some provisions for running this thing without k8s, but don't expect it to work without tweaking:
- cd to the root of the repo
- `dapr init`
- `docker compose up -d`
- cd into `DaprReminder`
- `dapr run --app-id dapr-reminder --resources-path ../components --app-port 5000 --dapr-http-port 3500 -- dotnet run --urls http://+:5000`

Tools used
- Kind: https://kind.sigs.k8s.io/
- Terraform: https://developer.hashicorp.com/terraform/downloads
- Kubectl: https://kubernetes.io/docs/tasks/tools/
- Httpie: https://httpie.io/docs/cli/installation
- Task: https://taskfile.dev/installation/
- k9s: https://k9scli.io/topics/install/
- Docker
