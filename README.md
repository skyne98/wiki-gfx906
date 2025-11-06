# GFX906 Wiki

A clean, markdown‑based documentation site for the GFX906 project, powered by **mdBook** and automatically deployed to GitHub Pages via GitHub Actions.
https://skyne98.github.io/wiki-gfx906/

## Project Structure

```
wiki-gfx906/
├── book/               # Generated static site (output of `mdbook build`)
├── src/                # Source markdown files
│   ├── SUMMARY.md
│   ├── intro.md
│   ├── getting_started.md
│   ├── usage.md
│   ├── reference.md
│   └── contributing.md
├── book.toml           # mdBook configuration
└── .github/
    └── workflows/
        └── mdbook.yml  # CI/CD pipeline
```

## Getting Started

1. **Clone the repository**

   ```sh
   git clone https://github.com/yourusername/wiki-gfx906.git
   cd wiki-gfx906
   ```

2. **Install mdBook** (requires Rust)

   ```sh
   cargo install mdbook
   ```

3. **Build the book locally**

   ```sh
   mdbook build
   ```

4. **Preview locally**

   ```sh
   mdbook serve
   ```

   Open <http://localhost:3000> in your browser.

## Adding Content

- Create a new Markdown file in `src/`.
- Add an entry for it in `src/SUMMARY.md`.
- Re‑run `mdbook build` or `mdbook serve` to see the changes.

## CI / Deployment

The repository includes a GitHub Actions workflow (`.github/workflows/mdbook.yml`) that:

1. Checks out the code.
2. Installs the stable Rust toolchain and `mdbook`.
3. Builds the book.
4. Deploys the `book/` directory to GitHub Pages on every push to `main`.

## .gitignore

A basic `.gitignore` is provided at the repository root to exclude generated files:

```
# Built site
/book/
/target/
/**/target/

# Rust artefacts
**/*.rs.bk

# macOS / Linux / Windows junk
.DS_Store
Thumbs.db
```

## Contributing

See `src/contributing.md` for guidelines on how to propose improvements, report issues, or submit pull requests.

## License

This project is licensed under the terms found in the `LICENSE` file.

---

Happy documenting! 🎉
