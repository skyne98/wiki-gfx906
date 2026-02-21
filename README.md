# GFX906 Wiki

A clean, markdown‑based documentation site for the GFX906 project, powered by **mdBook** and automatically deployed to GitHub Pages via GitHub Actions.
https://skyne98.github.io/wiki-gfx906/. Anyone is welcome to contribute, just create a pull request to this repo.

## Contributing

Contributing can either be done within github itself, or remotely through git.

To contribute through github, all you need is a github account. See [Easy Contribution](#easy-contribution).

To contribute remotely through git, you can deploy this repo locally. An upside to this approach is that you can preview the mdBook site this way. See  [Local Deployment](#local-deployment).

See `src/contributing.md` for guidelines on how to propose improvements, report issues, or submit pull requests.

The basics of contribution are:
- Create a new Markdown file in `src/`.
- Add an entry for it in `src/SUMMARY.md`.
- Optionally run `mdbook build` or `mdbook serve` to see the changes if deployed locally.
- Create a Pull request to the `main` branch.

## Project Structure

```
wiki-gfx906/
├── book/               # Generated static site (output of `mdbook build`)
├── src/                # All Markdown source files go here (intro.md, usage.md, etc.)
│   ├── SUMMARY.md      # The summary shown to the side on the mdBook site
│   ├── *.md            # All other Markdown source files
├── book.toml           # mdBook configuration
└── .github/
    └── workflows/
        └── mdbook.yml  # CI/CD pipeline
```

## Easy Contribution

If you want to simply add or edit some markdown files without touching the command line, follow this method.

#### To edit a markdown file on the wiki:

1. Open it on github and click the "edit" button. You will be prompted to create a fork if you don't already have a fork. Do so.

2. Make your edits and be sure to keep the markdown clean as outlined in `src/contributing.md`.

3. Commit and repeat this process until you are done. Please use descriptive commit messages.

4. Submit a pull request to the "main" branch

#### To add your own existing markdown files:

1. Click the **Fork** button on the top right of the repository page.

2. Click "Add file" on the main page of your fork. Click "Upload Files". Make sure your files contain clean markdown. See `src/contributing.md`.

4. Upload all files you want to add and click "Commit Changes". Please use a descriptive commit message.

5. Update the SUMMARY.md file following the process above to add links to your files to the sidebar. Please try to respect the existing structure of the sidebar.

6. Submit a pull request to the "main" branch

## Local Deployment
This is not necaserry for contribution but allows you to preview your changes.

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

## License

This project is licensed under the terms found in the `LICENSE` file.

---

Happy documenting! 🎉
