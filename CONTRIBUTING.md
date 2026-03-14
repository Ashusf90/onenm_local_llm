# Contributing to 1nm

Thanks for your interest in contributing!

At this stage of the project, we are only accepting contributions related to model support.

## What you can contribute

- Add new supported models to the model registry
- Test models on real Android devices
- Report issues with specific models
- Improve model documentation

## What we are NOT accepting right now

- Runtime changes (llama.cpp integration)
- Plugin architecture changes
- Large refactors
- Feature additions

These areas are maintained by the core maintainers.

## Adding a new model

When adding a model, please include:

- Model name
- Exact GGUF version
- Quantization level
- Model size
- RAM usage
- Test device used
- Whether it works with the plugin

### Example:

```
Model: TinyLlama 1.1B Chat
Format: GGUF Q4_K_M
RAM usage: ~1.3GB
Tested on: Pixel 7
Status: Works
```

Then add the model to the registry.

## Before opening a PR

- Make sure the model runs with llama.cpp
- Confirm it works with the plugin
- Add it to the registry
- Update the supported models list

## Reporting Issues

When filing a bug report, please include:

- Device model and Android version
- Flutter version (`flutter --version`)
- Full error message / stack trace
- Steps to reproduce

## Code of Conduct

Be kind, be respectful. We're all here to build something useful together.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
