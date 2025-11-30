# Project Title: 2bcloud-interview

> A sample Node.js web application for the 2bcloud interview process, demonstrating integration with Azure Key Vault.

[![NPM Version][npm-image]][npm-url] [![Build Status][build-image]][build-url]

This project is a simple web server built with Express.js. It is designed as a technical demonstration to showcase the ability to securely manage and retrieve application secrets using Azure Key Vault, a common requirement in modern cloud-native applications. The server starts up and exposes a basic "Hello World" endpoint.

## Table of Contents

*   [Installation](#installation)
*   [Usage](#usage)
*   [Endpoints](#endpoints)
*   [Running Tests](#running-tests)
*   [Contributing](#contributing)
*   [License](#license)

## Installation

To get started with this project, clone the repository and install the required dependencies using npm.

```bash
# Clone the repository
# Note: Replace 'your-username' with your actual GitHub username.
git clone https://github.com/your-username/2bcloud-interview.git

# Navigate to the project directory
cd 2bcloud-interview

# Install dependencies
npm install
```

## Usage

Provide clear instructions and code examples on how to use your project.

### Example 1: Basic Usage

```javascript
// Import the necessary modules
const project = require('./index');

// Example of how to use a function from your project
project.someFunction();
```

### Example 2: Advanced Usage

Show a more complex example if applicable.

```javascript
const { anotherFunction } = require('./index');

anotherFunction({
  optionA: 'valueA',
  optionB: true
});
```

## API Reference

If this project is a library, document the public API here.

*   `someFunction(arg1, arg2)` - Brief description of what this function does.
*   `anotherFunction(options)` - Description of this function and its parameters.

## Infrastructure (Terraform)

The repo includes Terraform to stand up the Azure landing zone and deploy the app:

- **Providers**: `azurerm`, `azuread`, `kubernetes`, `helm`, and `random` (CLI auth driven).
- **Networking**: VNet plus subnets, NSGs, and route tables via reusable modules.
- **Platform services**: Key Vault (stores ACR SP secret), ACR (no admin user), and an AKS cluster with Azure CNI, system identity, and RBAC role assignments for ACR pull and Key Vault secret access.
- **Ingress**: Static public IP and Helm-managed `ingress-nginx` controller.
- **App deploy**: Builds/pushes Docker image to ACR, then creates namespace, image pull secret, Deployment/Service/Ingress for `myapp` using the tag in `image_tag.txt`.
- **State**: Currently local (`terraform.tfstate`); configure a remote backend before team use.

## Running Tests

To run the test suite for this project, use the following command:

```bash
npm test
```

## Contributing

Contributions are welcome! Please read the contributing guidelines for details on how to submit pull requests, report issues, and more.

## License

This project is licensed under the MIT License.

<!-- Badges -->
[npm-image]: https://img.shields.io/npm/v/your-package-name.svg
[npm-url]: https://www.npmjs.com/package/your-package-name
[downloads-image]: https://img.shields.io/npm/dm/your-package-name.svg
[downloads-url]: https://www.npmjs.com/package/your-package-name
[build-image]: https://img.shields.io/travis/your-username/2bcloud-interview.svg
[build-url]: https://travis-ci.org/your-username/2bcloud-interview
[coverage-image]: https://img.shields.io/coveralls/your-username/2bcloud-interview/master.svg
[coverage-url]: https://coveralls.io/github/your-username/2bcloud-interview?branch=master
