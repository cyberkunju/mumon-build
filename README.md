# mumon-build

Build runner for the Mumon browser. The source lives in a private repository;
this repository holds only the workflows that build and check it, so they run on
GitHub's larger public runners.

- Run a build by hand: *Actions → build → Run workflow*, choose targets
  (`windows-x86_64`, `linux-x86_64`, `linux-arm64`, `macos-arm64`, `macos-x86_64`).
- It reads the source with a read-only deploy key, builds the browser (a Firefox
  build with patches applied), and publishes each package as a release.
- A package is an encrypted 7z. The key is not published.
- *verify* checks a build on each OS and, when every check passes, attaches the
  `mumon` program for that OS (`mumon-cli-<os>-<arch>`) to its release.
- Nothing runs on a push or a pull request, so no secret is reachable from a fork.

## Install

The `mumon` program installs and updates the browser and runs crawls; it needs
no Python. With the package key in `MUMON_PACKAGE_KEY` (or a `package.key` file
in Mumon's config folder), the scripts below put `mumon` on your PATH and run
`mumon install`:

```powershell
irm https://raw.githubusercontent.com/cyberkunju/mumon-build/main/install.ps1 | iex    # Windows
```

```sh
curl -fsSL https://raw.githubusercontent.com/cyberkunju/mumon-build/main/install.sh | sh   # Linux, macOS
```

Then `mumon verify`, and `mumon --help` for a crawl.

There is no support and no guarantee. The browser is a build of Firefox 158 with
Mumon's patches (MPL-2.0).
