# Konnect MCP Setup — Flatpak KiCad on Linux

Notes from setting up [Konnect](https://github.com/mixelpixx/Konnect) (KiCad MCP
server) for this repo, on a system where KiCad is installed via **Flatpak**
rather than natively. Upstream docs only cover native Windows/macOS installs;
Linux is only described as "compiles and passes tests in CI but hasn't had
per-platform QA yet", and Flatpak isn't mentioned at all. This file is meant as
a discussion base for an issue in the Konnect repo to close that doc gap.

## Environment

- KiCad: `org.kicad.KiCad` 10.0.4 via Flathub (`flatpak list --app`)
- Konnect: v0.2.0, `konnect-v0.2.0-x86_64-unknown-linux-gnu.tar.gz` (raw binary,
  not the PCM package — see [Which release asset](#which-release-asset) below)
- Host: no native KiCad, no native `kicad-cli`

## The core problem: Flatpak's private `/tmp`

Konnect's only documented `ipc_address` example is macOS's
`ipc:///tmp/kicad/api.sock`. On Linux, KiCad (native) uses the same
`/tmp/kicad/api.sock` convention when its API server is enabled
(Preferences → Plugins → Enable KiCad API).

Under Flatpak, `/tmp` inside the sandbox is **not** the host's `/tmp` — bwrap
gives each app a private tmpfs there. Checking the sandbox permissions:

```
$ flatpak info --show-permissions org.kicad.KiCad
[Context]
shared=network;ipc;
sockets=x11;
devices=dri;
filesystems=home;/media;/run/media;

[Environment]
TMPDIR=/var/tmp
```

No `--filesystem=/tmp` grant, so a Konnect process running on the bare host
cannot see `/tmp/kicad/api.sock` as such — it's isolated inside the sandbox.

**Finding:** Flatpak's private `/tmp` is itself backed by a real directory
under the app's own data dir, which *is* visible on the host because `home` is
shared:

```
~/.var/app/org.kicad.KiCad/cache/tmp/kicad/api.sock
```

Confirmed the file exists (`srwxr-xr-x`, type `socket`) while KiCad was
running, and confirmed a plain Python `socket.AF_UNIX` connect from the host
(outside any flatpak sandbox) succeeds against that path. So the fix is just:
point `ipc_address` at the real backing path instead of the sandbox-internal
one.

## Which release asset

The repo publishes two Linux artifacts per version:

- `konnect-pcm-v0.2.0-linux.zip` — meant for install via KiCad's own Plugin
  and Content Manager (drops files under
  `<kicad-data>/10.0/3rdparty/plugins/...`)
- `konnect-v0.2.0-x86_64-unknown-linux-gnu.tar.gz` — bare `konnect` binary

Since the MCP server here is launched directly by Claude Code (not from
inside KiCad's plugin manager), the bare binary is the right artifact — no
need to route it through KiCad's PCM/Flatpak sandbox at all. This distinction
isn't spelled out anywhere in the README; it currently only walks through the
PCM install path.

## Working configuration

Binary and wrapper scripts (kicad-cli/kicad aren't on the host `$PATH` at all
when KiCad is Flatpak-only):

```sh
~/.local/bin/konnect                # extracted from the .tar.gz, chmod +x
~/.local/bin/kicad-cli-flatpak      # exec flatpak run --command=kicad-cli org.kicad.KiCad "$@"
~/.local/bin/kicad-flatpak          # exec flatpak run org.kicad.KiCad "$@"
```

`~/.config/konnect/config.toml`:

```toml
kicad_cli = "/home/daniel/.local/bin/kicad-cli-flatpak"
kicad_binary = "/home/daniel/.local/bin/kicad-flatpak"
ipc_address = "ipc:///home/daniel/.var/app/org.kicad.KiCad/cache/tmp/kicad/api.sock"
```

Project `.mcp.json`:

```json
{
  "mcpServers": {
    "konnect": {
      "command": "/home/daniel/.local/bin/konnect",
      "args": ["--config", "/home/daniel/.config/konnect/config.toml"]
    }
  }
}
```

## Verification

Enabled the KiCad API (Preferences → Plugins → Enable KiCad API — persists as
`api.enable_server: true` in `kicad_common.json`), started KiCad, then drove
the MCP server directly over stdio with a hand-built JSON-RPC session:

```
initialize            → ok, serverInfo konnect 0.2.0
tools/list             → 20 tools (project, schematic viewer, design rules, toolset loader, …)
tools/call open_project → {"ipc_address": "...", "kicad_ui_running": true,
                           "message": "KiCAD is running and IPC is available."}
```

Confirms the whole path works end-to-end: Claude Code → `konnect` (host) →
Flatpak-backed IPC socket → running KiCad instance.

## Open points for an upstream issue

- No Linux socket-path documentation at all (only the macOS example exists).
- No mention of Flatpak/sandboxed KiCad anywhere — worth a dedicated
  troubleshooting section given Flathub is a very common Linux KiCad install
  path.
- Unclear from the README when to use the `konnect-pcm-*.zip` (PCM/plugin
  install) vs. the bare `konnect-*.tar.gz` — the two serve different
  integration modes (in-app plugin vs. externally-launched MCP server) but
  the README only walks through the PCM path.
- `kicad_binary` config key isn't explained anywhere (only appears in the
  macOS example snippet) — worth documenting what it's used for vs.
  `kicad_cli`.
