# eSignet Login Edge Function

This Supabase Edge Function verifies eSignet authentication and maps the returned UIN to an existing Supabase user.

## Environment Variables

- `SUPABASE_URL` — your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` — your Supabase service role key
- `ESIGNET_TOKEN_ENDPOINT` — eSignet token endpoint URL

## Request Format

POST JSON body:

- `code` (optional): authorization code returned by eSignet
- `uin` (optional): direct unique identity number returned by eSignet
- `redirect_uri` (required when `code` is provided): the exact callback URI registered with eSignet

Example:

```json
{
  "code": "AUTH_CODE_FROM_ESIGNET",
  "redirect_uri": "http://localhost:3000/callback"
}
```

or

```json
{
  "uin": "1234567890123456"
}
```

## Response

- `200`: existing user verified. Returns `user` with `id`, `role`, `profile`, `userData`, and optionally `license`.
- `401`: user not registered or role not supported.
- `400`: invalid request or missing data.
