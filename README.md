# get-public-ip

A GitHub Action which discovers and returns the current public IP address

[![.github/workflows/main.yml](https://github.com/champ-oss/action-get-public-ip/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/champ-oss/action-get-public-ip/actions/workflows/main.yml)

## Features
- Discovers the public IPv4 address of the GitHub runner using ipify.org
- Uses curl, which is pre-installed on GitHub runners

## Example Usage

```yaml
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - id: ip
        uses: champ-oss/action-get-public-ip@main
      - run: echo "PUBLIC_IP=${{ steps.ip.outputs.ipv4 }}" >> "$GITHUB_ENV"
```



## Parameters
| Parameter | Required | Description                                                                           |
| --- | --- |---------------------------------------------------------------------------------------|
| retries | false | Number of retry attempts (defaults to 60)                                             |
| service | false | URL that responds with the caller's IPv4 address (defaults to https://api.ipify.org/) |

## Outputs
| Output | Description                       |
| --- |-----------------------------------|
| ipv4 | The validated public IPv4 address |

## Contributing
Run the tests locally (requires bash, curl and python3):

```shell
tests/integration-test.sh
```

This serves good and bad responses from a local mock service and checks that only valid public IPs are output.
CI also runs the action end to end on Linux, macOS and Windows runners.
