# AWS Emulator + AWS CLI + Terraform (Windows PowerShell)

## 1. What this setup does

This setup runs AWS Emulator locally in Docker and lets AWS CLI and
Terraform send AWS API requests to:

``` text
https://127.0.0.1:9297
```

It is intended for local learning and testing, not for creating
resources in a real AWS account.

### What persists

  -------------------------------------------------------------------------------
  Item                    Where it is stored              What to expect
  ----------------------- ------------------------------- -----------------------
  Docker image            Docker's local image store      Remains until removed

  Named container         Docker's local container store  Can be stopped and
                                                          started again

  Emulator files and      `%USERPROFILE%\.aws\emulator`   Persist on the host
  certificates                                            because the folder is
                                                          mounted into the
                                                          container

  PowerShell environment  Current PowerShell process      Must be set again in
  variables                                               each new PowerShell
                                                          session

  Emulator resources      Emulator runtime                Treat resources as
                                                          temporary; verify after
                                                          restarting the emulator

  Terraform configuration Your project folder             Stored locally in the
  and state                                               Terraform project
  -------------------------------------------------------------------------------

The container is named `aws-emulator`, uses the `unless-stopped` restart
policy, and mounts the host emulator directory into the container.

## 2. One-time setup already completed

The Docker image was built from the project's `Dockerfile` and tagged:

``` text
aws-emulator
```

The host directory was created:

``` powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.aws\emulator"
```

The named container was created with:

``` powershell
docker run -d `
  --name aws-emulator `
  --restart unless-stopped `
  --memory=2g `
  --memory-swap=2g `
  -p "127.0.0.1:9297:9297" `
  -v "$env:USERPROFILE\.aws\emulator:/home/emulator/.aws/emulator" `
  aws-emulator -p 9297
```

Do not run this `docker run` command every time. It creates the
container and will fail if a container with the same name already
exists.

## 3. Reuse the setup in a new session

### Step 1 --- Start Docker Desktop

Wait until Docker Desktop reports that its engine is running.

### Step 2 --- Check or start the container

Open PowerShell and check:

``` powershell
docker ps
```

If `aws-emulator` is not running, start the existing container:

``` powershell
docker start aws-emulator
```

To see all containers, including stopped ones:

``` powershell
docker ps -a
```

Do not create a second container if `aws-emulator` already exists.

### Step 3 --- Set AWS environment variables

Run these commands in the PowerShell window where you will use AWS CLI
and Terraform. Repeat them in every new PowerShell session.

``` powershell
$env:AWS_ENDPOINT_URL = "https://127.0.0.1:9297"

$env:AWS_SHARED_CREDENTIALS_FILE = "$env:USERPROFILE\.aws\emulator\9297\emulator_credentials"

$env:AWS_CONFIG_FILE = "$env:USERPROFILE\.aws\emulator\9297\config"

$env:AWS_CA_BUNDLE = "$env:USERPROFILE\.aws\emulator\9297\ca.pem"

$env:AWS_EC2_METADATA_DISABLED = "true"

$env:AWS_DISABLE_HOST_PREFIX_INJECTION = "true"

$env:AWS_REGION = "us-east-1"

$env:AWS_DEFAULT_REGION = "us-east-1"
```

Remove potentially conflicting AWS credential/profile variables from
this PowerShell session:

``` powershell
Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN, Env:AWS_PROFILE -ErrorAction SilentlyContinue
```

**Do not run `aws configure` for this emulator setup.** The emulator
supplies its own credentials and configuration files. The environment
variables above tell AWS CLI where those files are.

### Step 4 --- Verify the emulator health

``` powershell
curl.exe --cacert "$env:USERPROFILE\.aws\emulator\9297\ca.pem" `
  https://127.0.0.1:9297/__admin/health
```

Expected output:

``` text
ok
```

### Step 5 --- Verify AWS CLI is using the emulator

``` powershell
aws sts get-caller-identity
```

The expected account ID is:

``` text
000000000000
```

This is the local emulator account, not a real AWS account. If the
command fails, check that the container is running and that the
credential and certificate files exist:

``` powershell
Test-Path "$env:USERPROFILE\.aws\emulator\9297\emulator_credentials"
Test-Path "$env:USERPROFILE\.aws\emulator\9297\ca.pem"
```

If either file is missing, inspect the container logs before proceeding:

``` powershell
docker logs aws-emulator
```

## 4. Useful Docker commands

  Task                       Command
  -------------------------- -------------------------------
  Check running containers   `docker ps`
  Check all containers       `docker ps -a`
  Start emulator             `docker start aws-emulator`
  Stop emulator              `docker stop aws-emulator`
  View emulator logs         `docker logs aws-emulator`
  Follow logs live           `docker logs -f aws-emulator`
  Restart emulator           `docker restart aws-emulator`

Stopping Docker Desktop or the container does not delete the named
container. Avoid `docker rm` unless you intentionally want to delete it.

## 5. Important reminders

-   The Docker image and named container are reusable; do not rebuild or
    recreate them for every session.
-   The host folder `%USERPROFILE%\.aws\emulator` is mounted into the
    container, so emulator-generated files written there can persist
    across container restarts.
-   PowerShell environment variables are session-specific. Re-run the
    environment-variable commands whenever you open a new PowerShell
    window.
-   Do not assume emulator credentials or local resources are permanent.
    Check the credential files and verify the emulator after a restart.
-   Local emulator resources are not real AWS resources. Emulator
    support varies by AWS service and API operation.
-   Keep the emulator running while using AWS CLI or Terraform.
-   Before running Terraform, confirm that its AWS provider is
    explicitly configured to use the emulator endpoint. Setting the AWS
    CLI endpoint alone does not guarantee Terraform uses it.

## 6. Next practice

After the health check and `aws sts get-caller-identity` succeed,
continue with the Terraform EC2 exercise in the project. First review
the provider endpoint configuration and confirm that the emulator
supports the required EC2 operations. Run `terraform plan` before
approving `terraform apply`.

## ⚠️ Start the whole env using script
run
```bash
.\start-aws-emulator.ps1
```