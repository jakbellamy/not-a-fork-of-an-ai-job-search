# Setup Guide

This guide is written for a fresh machine and assumes you have only the bare minimum installed already. The preferred path is to run the bootstrap scripts at the repository root:

- Windows: [setup-windows.ps1](setup-windows.ps1)
- macOS: [setup-macos.sh](setup-macos.sh)

If one of the scripts fails, use the manual fallback section below to install the same pieces step by step.

## 1. Before you start

The setup flow assumes:

- You have internet access.
- You can install software with administrator privileges when required.
- The repository folder is writable.
- You can open a terminal in the repo root.

The most common things that are often assumed to already exist but are not guaranteed on a fresh machine are:

- Windows: PowerShell, winget, and a working network connection
- macOS: Homebrew, Xcode Command Line Tools, and permission to install apps
- GitHub account access if you want to fork and clone from GitHub rather than download the repo manually

If you do not have GitHub CLI installed, you can still clone the repo manually from GitHub and skip the `gh` step.

## 2. Preferred path: run the setup scripts

### Windows

From PowerShell in the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

What the script installs:

- Git
- Python 3.12
- Node.js LTS
- Bun
- MiKTeX
- Poppler (optional, for `pdftotext`)
- Claude Code
- The job-portal CLI dependencies under [.agents/skills](.agents/skills)

If you are prompted for installation approvals, allow them. Some steps may take several minutes.

### macOS

From a terminal in the repository root:

```bash
chmod +x ./setup-macos.sh
./setup-macos.sh
```

What the script installs:

- Homebrew (if missing)
- Git
- Python 3.12
- Node.js
- Bun
- Homebrew packages for LaTeX and PDF tooling
- Claude Code
- The job-portal CLI dependencies under [.agents/skills](.agents/skills)

The script uses Homebrew and BasicTeX by default. If you prefer a fuller LaTeX install such as MacTeX, replace the BasicTeX step manually.

### What to expect after the script finishes

Open a fresh terminal and verify the core tools:

```bash
python3 --version
node --version
bun --version
claude --version
lualatex --version
xelatex --version
```

On Windows, use `py --version` or `python --version` if `python3` is not available.

## 3. Manual fallback if the script fails

Use this path if the script stopped on an install step, a package source was unavailable, or your machine has a policy that blocks the automated installer.

### 3.1 Windows manual setup

1. Install prerequisites that are not guaranteed to exist:
   - Install winget from the Microsoft Store if it is missing.
   - Install Git from the official installer or via winget.
   - Install Python 3.10+ and make sure `py` or `python` resolves in PowerShell.
   - Install Node.js LTS.

2. Install Bun:

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://bun.sh/install.ps1 | iex"
```

If `bun` is not recognized, close and reopen your terminal. The installer updates the user PATH for new shells.

3. Install LaTeX:
   - Recommended: MiKTeX from https://miktex.org/download
   - The CV templates compile with `lualatex`.
   - The cover-letter template compiles with `xelatex`.

4. Install optional PDF-text extraction tooling:

```powershell
winget install --id GnuWin32.Poppler --silent --accept-source-agreements --accept-package-agreements
```

5. Install Claude Code:

```powershell
npm install -g @anthropic-ai/claude-code
```

6. Install the job-portal CLI dependencies from the repo root:

```powershell
$tools = @("jobbank-search", "jobdanmark-search", "jobindex-search", "jobnet-search", "linkedin-search", "freehire-search")
foreach ($tool in $tools) {
  Set-Location ".agents/skills/$tool/cli"
  bun install
  Set-Location "..\..\..\.."
}
```

7. If you prefer a lighter manual install, you can skip `linkedin-search` and `freehire-search` for now. They are optional and the repo still works for the main workflow without them.

### 3.2 macOS manual setup

1. Install Xcode Command Line Tools if needed:

```bash
xcode-select --install
```

2. Install Homebrew if it is missing:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Install the core toolchain:

```bash
brew update
brew install git python@3.12 node@20
brew link --overwrite node@20 || true
```

4. Install Bun:

```bash
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

5. Install LaTeX and PDF tooling:

```bash
brew install --cask basictex poppler
export PATH="/Library/TeX/texbin:$PATH"
```

If you prefer a fuller LaTeX experience, use MacTeX instead of BasicTeX.

6. Install the required TeX packages for the stock CV and cover-letter templates:

```bash
tlmgr init-usertree
tlmgr install moderncv fontawesome5 fontawesome6 academicons import luatexbase pgf titlesec textpos xltxtra xunicode cite realscripts
```

If the above command fails because `tlmgr` is not available yet, reopen the terminal and retry after the BasicTeX install finishes.

7. Install Claude Code:

```bash
npm install -g @anthropic-ai/claude-code
```

8. Install the repo’s CLI dependencies from the repository root:

```bash
for tool in jobbank-search jobdanmark-search jobindex-search jobnet-search linkedin-search freehire-search; do
  cd .agents/skills/$tool/cli && bun install && cd ../../../..
done
```

## 4. Repository-specific setup after the tools are installed

Once the core tools are available, clone or open the repo and run the onboarding workflow:

```bash
claude
```

Then inside Claude Code:

```text
/setup
```

Claude will offer three paths:

- Path A: point it at a folder containing your CV, LinkedIn export, diplomas, references, or prior applications under [documents](documents)
- Path B: paste or attach a single CV or resume
- Path C: answer a structured interview to build the profile from scratch

This populates the profile files used by the rest of the workflow, including [CLAUDE.md](CLAUDE.md) and the files under [.claude/skills](.claude/skills).

## 5. Optional but recommended setup

### Salary benchmarking

If you want salary lookup support, install the optional Python dependency:

```bash
python3 -m pip install --user --upgrade pip pytest openpyxl
```

If you already have salary data, you can then run the conversion tool in [tools](tools):

```bash
python3 tools/convert_salary_excel.py path/to/salary-data.xlsx --source "My Salary Data 2025"
```

This creates `salary_data.json` for the salary lookup workflow. If you skip it, the workflow simply omits salary data.

### PDF text-layer checks

The `/apply` flow can perform ATS-style parseability checks if `pdftotext` is installed. If it is not installed, the workflow falls back to a visual review of the generated PDF and still works.

## 6. Verification steps

After installation, verify the main pieces before using the workflow:

```bash
python3 --version
node --version
bun --version
claude --version
lualatex --version
xelatex --version
```

You should also smoke-test the stock LaTeX templates:

```bash
cd cv && lualatex -interaction=nonstopmode -halt-on-error main_example.tex && cd ..
```

And for the cover-letter template:

```bash
cd cover_letters && xelatex -interaction=nonstopmode -halt-on-error cover_example.tex && cd ..
```

## 7. Troubleshooting

### `bun` is not recognized

- Windows: close and reopen the terminal after the installer finishes.
- macOS: open a new shell or add `~/.bun/bin` to your `PATH`.

### `python3` or `py` is not found

- On Windows, install Python and reopen PowerShell.
- On macOS, Homebrew usually installs Python as `python3`.

### LaTeX compile errors

- CVs use `lualatex`.
- Cover letters use `xelatex`.
- If you installed a minimal TeX distribution, make sure the extra packages listed above are available.

### Fonts are missing in the cover letter

The template expects the bundled fonts under [cover_letters/OpenFonts](cover_letters/OpenFonts). Keep that directory intact.

### Old Claude settings are blocking commands

If you cloned the repo before the newer permission model, remove stale local settings that may override the defaults:

```bash
rm .claude/settings.local.json
```

## 8. Backlog and future workflow notes

This repository already has a planned backlog for multi-application tracking and scraped-job handling in [docs/backlog/README.md](docs/backlog/README.md). Those items do not require new packages today, but they will depend on the repo staying writable and on the workflow creating or updating a small set of local state files such as:

- [job_search_tracker.csv](job_search_tracker.csv)
- [job_scraper/seen_jobs.json](job_scraper/seen_jobs.json)
- [documents/applications](documents/applications)

No extra setup is required for those backlog features right now, but the repo should be kept in a normal working state so that future `/status`, `/outcome`, and application-tracking improvements can write their files without issue.

## 9. Next steps

Once the setup finishes, run:

```text
/setup
/scrape
/apply <job-url-or-description>
```

For the full command reference and workflow guidance, see [docs/user-guide.md](docs/user-guide.md).
