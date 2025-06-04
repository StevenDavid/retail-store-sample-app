# Retail Store Sample App - Load Generator

This is a utility component to generate synthetic load on the sample application, which is useful for scenarios such as autoscaling, observability and resiliency testing. It primarily consists of a scenario for [Artillery](https://github.com/artilleryio/artillery), as well a script to help run it.

## Usage

### Local

1. Install AWS CLI - see instructions here: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
2. Install NVM: 

```bash
bash curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
```
3. Install Node: 

```bash
bash nvm install node
```
4. Install Artillery: 

```bash
bash npm install -g artillery@latest
```
5. Install playwright dependencies: npx playwright install-deps

```bash
bash npx playwright install-deps
```
6. Run Artillery locally

```bash
bash npx artillery run ./tests/retail-store-test.yml
```

6. Run Artillery in ECS Fargate

```bash
bash artillery run-fargate ./tests/retail-store-test.yml --count 10
```
