# Reusable AWS Modules

Reusable AWS Terraform modules belong in named subdirectories here.

Each module should include:

- clear inputs, typed variables, validation, and outputs
- provider requirements without provider credentials
- secure defaults and documented exceptions
- examples and automated tests
- upgrade and replacement considerations

Modules must not configure a backend or assume a specific state key. Environment root modules own backend and provider configuration.
