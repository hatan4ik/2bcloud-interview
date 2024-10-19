const express = require('express');
const app = express();
const port = 3000;

// Azure Key Vault SDK
const { SecretClient } = require('@azure/keyvault-secrets');
const { DefaultAzureCredential } = require('@azure/identity');

// Key Vault configuration (replace with your values)
const keyVaultName = '<your-key-vault-name>';
const secretName = '<your-secret-name>';
const keyVaultUri = `https://${keyVaultName}.vault.azure.net`;

// Create a SecretClient
const credential = new DefaultAzureCredential();
const client = new SecretClient(keyVaultUri, credential);

async function getSecret() {
  try {
    const latestSecret = await client.getSecret(secretName);
    return latestSecret.value;
  } catch (error) {
    console.error('Error retrieving secret:', error);
    return 'default-secret'; // Fallback value
  }
}

app.get('/', async (req, res) => {
  const appSecret = await getSecret();
  res.send(`Hello World! Secret: ${appSecret}`);
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
