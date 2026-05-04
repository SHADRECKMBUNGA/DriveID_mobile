import { serve } from "https://deno.land/std@0.201.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ESIGNET_TOKEN_ENDPOINT = Deno.env.get("ESIGNET_TOKEN_ENDPOINT") ?? "";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !ESIGNET_TOKEN_ENDPOINT) {
  throw new Error(
    "Missing environment variables SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, or ESIGNET_TOKEN_ENDPOINT",
  );
}

const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

function decodeJwtPayload(token: string): Record<string, unknown> {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('Invalid JWT format');
  }

  const payload = parts[1];
  const padded = payload.padEnd(payload.length + ((4 - payload.length % 4) % 4), '=')
    .replace(/-/g, '+')
    .replace(/_/g, '/');

  const decoded = atob(padded);
  const bytes = new Uint8Array(decoded.length);
  for (let i = 0; i < decoded.length; i++) {
    bytes[i] = decoded.charCodeAt(i);
  }

  return JSON.parse(new TextDecoder().decode(bytes));
}

function extractUin(payload: Record<string, unknown>): string | null {
  const candidates = [
    payload['uin'],
    payload['UIN'],
    payload['unique_id'],
    payload['national_id'],
    payload['identity_number'],
    payload['sub'],
    payload['uid'],
  ];

  for (const value of candidates) {
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
  }

  return null;
}

async function exchangeCodeForTokens(code: string, redirectUri: string) {
  const body = new URLSearchParams();
  body.set('grant_type', 'authorization_code');
  body.set('code', code);
  body.set('redirect_uri', redirectUri);

  const response = await fetch(ESIGNET_TOKEN_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`eSignet token exchange failed (${response.status}): ${text}`);
  }

  return await response.json();
}

async function supabaseFetch(path: string, init: RequestInit = {}) {
  const url = path.startsWith('http') ? path : `${SUPABASE_URL}${path}`;
  const headers = new Headers(init.headers);
  headers.set('apikey', SUPABASE_SERVICE_ROLE_KEY);
  headers.set('Authorization', `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`);
  headers.set('Accept', 'application/json');

  const response = await fetch(url, { ...init, headers, credentials: 'omit' });
  const body = await response.text();
  if (!response.ok) {
    throw new Error(`Supabase request failed (${response.status}): ${body}`);
  }
  return JSON.parse(body);
}

async function getProfileByUin(uin: string) {
  const encodedUin = encodeURIComponent(uin);
  const rows = await supabaseFetch(
    `${SUPABASE_URL}/rest/v1/profiles?uin=eq.${encodedUin}&select=id,uin`,
    { method: 'GET' },
  );

  if (!Array.isArray(rows) || rows.length === 0) {
    return null;
  }

  return rows[0] as { id: string; uin: string };
}

async function getDriverByAuthUserId(authUserId: string) {
  const rows = await supabaseFetch(
    `${SUPABASE_URL}/rest/v1/drivers?auth_user_id=eq.${encodeURIComponent(authUserId)}&select=*`,
    { method: 'GET' },
  );
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

async function getOfficerByAuthUserId(authUserId: string) {
  const rows = await supabaseFetch(
    `${SUPABASE_URL}/rest/v1/officers?auth_user_id=eq.${encodeURIComponent(authUserId)}&select=*`,
    { method: 'GET' },
  );
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

async function getLicenseForDriver(driverId: string) {
  const rows = await supabaseFetch(
    `${SUPABASE_URL}/rest/v1/licenses?driver_id=eq.${encodeURIComponent(driverId)}&select=*`,
    { method: 'GET' },
  );
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

serve(async (request) => {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON payload' }, 400);
  }

  const code = typeof payload['code'] === 'string' ? payload['code'].trim() : '';
  const uinParam = typeof payload['uin'] === 'string' ? payload['uin'].trim() : '';
  const redirectUri = typeof payload['redirect_uri'] === 'string'
    ? payload['redirect_uri'].trim()
    : '';

  let resolvedUin = uinParam;

  if (!resolvedUin) {
    if (!code) {
      return jsonResponse({ error: 'Missing `code` or `uin` in request' }, 400);
    }
    if (!redirectUri) {
      return jsonResponse({ error: 'Missing `redirect_uri` for code exchange' }, 400);
    }

    const tokenResponse = await exchangeCodeForTokens(code, redirectUri);
    if (!tokenResponse.id_token) {
      return jsonResponse({ error: 'Missing id_token from eSignet response' }, 400);
    }

    const tokenPayload = decodeJwtPayload(tokenResponse.id_token as string);
    resolvedUin = extractUin(tokenPayload);
    if (!resolvedUin) {
      return jsonResponse({ error: 'Unable to extract UIN from eSignet token' }, 400);
    }
  }

  const profile = await getProfileByUin(resolvedUin);
  if (!profile) {
    return jsonResponse({ error: 'User not registered' }, 401);
  }

  const authUserId = profile.id;
  const driver = await getDriverByAuthUserId(authUserId);
  if (driver) {
    const license = await getLicenseForDriver(driver.id);
    return jsonResponse({
      user: {
        id: authUserId,
        email: driver.email ?? null,
        role: 'driver',
        profile,
        userData: driver,
        license,
      },
    });
  }

  const officer = await getOfficerByAuthUserId(authUserId);
  if (officer) {
    return jsonResponse({
      user: {
        id: authUserId,
        email: officer.email ?? null,
        role: officer.role ?? 'officer',
        profile,
        userData: officer,
      },
    });
  }

  return jsonResponse({ error: 'User is not linked to a supported role' }, 401);
});
