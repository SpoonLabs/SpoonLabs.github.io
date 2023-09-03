# Spoon website
This is the Spoon website hosted on GitHub pages. It is automatically generated
and deployed with a GitHub Actions workflow. See
[.github/workflows/deploy.yml](.github/workflows/deploy.yml).

> **Note:** The deploy workflow overwrites everything on the main branch
> _except_ for the [.github](.github) directory. Therefore, everything in the
> [.github](.github) directory is retained on automatic deployment, and you can
> edit its contents as usual, but files anywhere else are removed or overwritten.
