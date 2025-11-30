and updae.const express = require('express');
const helmet = require('helmet'); // Import helmet
const { SecretClient } = require('@azure/keyvault-secrets');
const { DefaultAzureCredential } = require('@azure/identity');

const app = express();
const port = 3000;

app.use(helmet()); // Use helmet middleware

// --- Azure Key Vault Setup ---

// Get the URL of the Key Vault from an environment variable
const keyVaultUrl = process.env.KEY_VAULT_URL;
if (!keyVaultUrl) {
  console.error("ERROR: KEY_VAULT_URL environment variable not set.");
  process.exit(1);
}

// Authenticate using DefaultAzureCredential
const credential = new DefaultAzureCredential();
const secretClient = new SecretClient(keyVaultUrl, credential);

// --- Endpoints ---

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.get('/secret', async (req, res) => {
  try {
    // The name of the secret to fetch
    const secretName = 'my-secret';
    const secret = await secretClient.getSecret(secretName);
    res.send(`The value of secret '${secretName}' is: ${secret.value}`);
  } catch (error) {
    // Check if the error is because the secret was not found
    if (error.code === 'SecretNotFound') {
      console.log(`Secret 'my-secret' not found.`);
      return res.status(404).send(`Secret 'my-secret' not found in the Key Vault.`);
    }
    console.error(error);
    res.status(500).send(`Error fetching secret from Key Vault: ${error.message}`);
  }
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
