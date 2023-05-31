# get-public-ip

A GitHub Action which discovers and returns the current public IP address

[![.github/workflows/main.yml](https://github.com/champ-oss/action-get-public-ip/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/champ-oss/action-get-public-ip/actions/workflows/main.yml)

## Features
- Discovers the public IP address of the GitHub runner using ipify.org
- Uses curl, which is pre-installed on GitHub runners

## Example Usage

```yaml
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - id: ip
        uses: champ-oss/action-get-public-ip
      - run: echo "PUBLIC_IP=${{ steps.ip.outputs.ipv4 }}" >> $GITHUB_ENV
```



## Parameters
| Parameter | Required | Description                               |
| --- | --- |-------------------------------------------|
| retries | false | Number of retry attempts (defaults to 60) |


## Contributing
