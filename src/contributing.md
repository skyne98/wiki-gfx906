# Contributing

Thank you for considering contributing to the **GFX906 Wiki**! This guide outlines how you can help improve the documentation.

## Easy Contribution

If you want to simply add or edit some markdown files without touching the console, follow this method.

#### To edit a markdown file on the wiki:

1. Open it on github and click the "edit" button. You will be prompted to create a fork if you don't already have a fork. Do so.

2. Make your edits and be sure to keep the markdown clean as outlined in [Making Changes](#making-changes).

3. [Commit](#commit-messages) and repeat this process until you are done.

4. Submit a pull request to the "main" branch

#### To add your own existing markdown files:

1. Click the **Fork** button on the top right of the repository page.

2. Click "Add file" on the main page of your fork. Click "Upload Files". Make sure your files contain clean markdown. See [Making Changes](#making-changes).

4. Upload all files you want to add and click "Commit Changes". See [Commits](#commit-messages)

5. Update the SUMMARY.md file following the process above to add links to your files to the sidebar. Please try to respect the existing structure of the sidebar.

6. Submit a pull request to the "main" branch

## Local deployment

1. **Fork the repository**  
   Click the **Fork** button on the top right of the repository page.

2. **Clone your fork**  
   ```sh
   git clone https://github.com/<your-username>/wiki-gfx906.git
   cd wiki-gfx906
   ```

3. **Create a feature branch**  
   ```sh
   git checkout -b <branch-name>
   ```

4. **Install mdBook** (if you haven’t already)  
   ```sh
   cargo install mdbook
   ```

5. **Build and preview locally**  
   ```sh
   mdbook serve
   ```
   Open <http://localhost:3000> in your browser to see your changes live.

## Making Changes

- **Add or edit content** in the `src/` directory.  
- **Update `SUMMARY.md`** to include any new pages you add.  
- Keep markdown clean and consistent:
  - Use headings (`#`, `##`, …) to structure sections.
  - Prefer fenced code blocks with language identifiers.
  - Use relative links for internal navigation.

## Commit Messages

Write clear, concise commit messages. Follow this format:

```
<type>: <short description>

<optional longer description>
```

Common `<type>` values:

- `docs`: documentation updates
- `fix`: typo or small correction
- `feat`: new page or major addition

## Pull Request Process

1. **Push your branch** to your fork:  
   ```sh
   git push origin <branch-name>
   ```

2. **Open a Pull Request** against the `main` branch of the upstream repository.  
   - Provide a descriptive title and summary of changes.  
   - Link to any relevant issue(s) (e.g., `Closes #42`).  

3. **Review** – maintainers will review your PR. Respond to feedback promptly.

## Code of Conduct

We expect all contributors to behave respectfully. Harassment and discrimination of any kind will not be tolerated. See the [CODE_OF_CONDUCT.md](https://github.com/yourusername/wiki-gfx906/blob/main/CODE_OF_CONDUCT.md) for details.

## License

By contributing you agree that your contributions will be licensed under the same license as the project (see `LICENSE`).

---

*Happy documenting!* 🎉
