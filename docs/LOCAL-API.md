# Calling the local engine from your own programs

The engine listens on `127.0.0.1:18100` only. It speaks the OpenAI-style API under `/v1`.

## The access token

An engine built from Core main refuses any request that does not carry the per-install bearer token. The alpha-20261026.2 release still ships engine `19173f9e…` (Core `59b05a71`), which does not check the token. Enforcement arrives with the first release that ships a Core build with auth.

The `aienos` wizard creates the token the first time it starts the engine and keeps it from then on:

| Path | Mode | Contents |
|---|---|---|
| `~/.local/share/aienos/auth/` | `0700`, yours | the folder |
| `~/.local/share/aienos/auth/bearer-token` | `0600`, yours | 64 lowercase hex digits from 32 `getrandom` bytes, then a newline |

The wizard never prints or logs the token. It passes the token to the engine through the environment, so the token never appears in the engine's command line.

A local program run by the same user reads the file and sends the token in an `Authorization: Bearer` header:

```sh
TOKEN=$(cat ~/.local/share/aienos/auth/bearer-token)
curl -sS http://127.0.0.1:18100/v1/chat/completions \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"hello"}],"max_tokens":32}'
```

A request with no token or a wrong token gets HTTP 401.

Other users on the machine cannot read the file. If you need another account to call the engine, run the program as the installing user. Do not loosen the file's mode: the wizard refuses to start the engine when the folder is not `0700` or the file is not `0600`.

## Replacing the token

1. Stop the engine with `aienos`.
2. Remove `~/.local/share/aienos/auth`.
3. Run `aienos` again. It writes a new token, and every client must re-read the file.

The wizard also refuses a token that is damaged, the wrong length or a symbolic link, and tells you to do the same thing.

## Known gap

`oh-infer-volunteer`, the lending program, sends the token only from aien-dev/open-humanity#54 (draft, not merged) on. The wizard already passes it `--engine-token-file ~/.local/share/aienos/auth/bearer-token`; the program pinned today (open-humanity c0484649) ignores that option, so against an engine that enforces the token its requests get 401 until the pin moves to a commit that includes #54.
