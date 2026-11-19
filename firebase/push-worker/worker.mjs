const MAX_NOTICES = 3;
const MAX_DEVICES = 5;
const ONE_DAY = 24 * 60 * 60 * 1000;
const SCOPES = [
  "https://www.googleapis.com/auth/datastore",
  "https://www.googleapis.com/auth/firebase.messaging",
].join(" ");

export default {
  scheduled(_event, env, context) {
    if (!env.GOOGLE_SERVICE_ACCOUNT) return;
    context.waitUntil(deliverPending(env));
  },
};

function base64Url(value) {
  const input = typeof value === "string" ? value : String.fromCharCode(...value);
  return btoa(input).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

export async function googleAccessToken(env, fetcher = fetch) {
  const account = JSON.parse(env.GOOGLE_SERVICE_ACCOUNT);
  const key = Uint8Array.from(
    atob(account.private_key.replace(/-----[^-]+-----|\s/g, "")),
    (char) => char.charCodeAt(0),
  );
  const privateKey = await crypto.subtle.importKey(
    "pkcs8", key, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const endpoint = "https://oauth2.googleapis.com/token";
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT", kid: account.private_key_id }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email, scope: SCOPES, aud: endpoint, iat: now, exp: now + 600,
  }));
  const unsigned = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", privateKey, new TextEncoder().encode(unsigned),
  );
  const response = await fetcher(endpoint, {
    method: "POST",
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64Url(new Uint8Array(signature))}`,
    }),
  });
  if (!response.ok) throw new Error(`Google OAuth: ${response.status}`);
  return (await response.json()).access_token;
}

function googleApi(projectId, token, fetcher) {
  const root = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
  const fcm = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  async function request(url, { method = "GET", body, missingOk = false } = {}) {
    const response = await fetcher(url, {
      method,
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (missingOk && response.status === 404) return null;
    if (!response.ok) {
      const error = new Error(`Google API: ${response.status}`);
      error.status = response.status;
      error.code = (await response.json().catch(() => null))?.error?.details
        ?.find((detail) => detail.errorCode)?.errorCode;
      throw error;
    }
    return response.json();
  }
  async function query(collectionId, fieldPath, value, limit, allDescendants = false) {
    const results = await request(`${root}:runQuery`, {
      method: "POST",
      body: {
        structuredQuery: {
          from: [{ collectionId, allDescendants }],
          where: { fieldFilter: { field: { fieldPath }, op: "EQUAL", value } },
          limit,
        },
      },
    });
    return results.flatMap(({ document }) => document ? [document] : []);
  }

  const docUrl = (name) => `${root}/${name.split("/documents/")[1].split("/").map(encodeURIComponent).join("/")}`;
  return {
    notices: () => query("notifications", "pushPending", { booleanValue: true }, MAX_NOTICES, true),
    devices: (uid) => query("citizenPushDevices", "uid", { stringValue: uid }, MAX_DEVICES),
    profile: (uid) => request(`${root}/users/${encodeURIComponent(uid)}`, { missingOk: true }),
    preferences: (uid) => request(
      `${root}/users/${encodeURIComponent(uid)}/settings/notifications`, { missingOk: true },
    ),
    finish: (notice) => request(`${docUrl(notice.name)}?updateMask.fieldPaths=pushPending&currentDocument.exists=true`, {
      method: "PATCH",
      body: { fields: { pushPending: { booleanValue: false } } },
    }),
    dropDevice: (device) => request(
      `${docUrl(device.name)}?currentDocument.updateTime=${encodeURIComponent(device.updateTime)}`,
      { method: "DELETE", missingOk: true },
    ),
    send: (device, uid, noticeId) => request(fcm, {
      method: "POST",
      body: {
        message: {
          token: device.name.split("/").at(-1),
          notification: { title: "EcoRoute", body: "Tienes una actualización en tu bandeja." },
          data: { type: "report_status", recipientId: uid, noticeId },
          android: { ttl: "3600s", notification: { tag: noticeId } },
        },
      },
    }),
  };
}

export async function drainNotices(api, now = Date.now()) {
  for (const notice of await api.notices()) {
    const match = /\/documents\/users\/([^/]+)\/notifications\/([^/]+)$/.exec(notice.name);
    if (!match) continue;
    const [, uid, noticeId] = match;
    if (!(now - Date.parse(notice.fields.createdAt?.timestampValue) < ONE_DAY)) {
      await api.finish(notice);
      continue;
    }
    const [profile, settings] = await Promise.all([api.profile(uid), api.preferences(uid)]);
    const role = profile?.fields.role?.stringValue ?? "citizen";
    if (!profile || !["citizen", "ciudadano"].includes(role) ||
        profile.fields.isActive?.booleanValue === false ||
        settings?.fields.reportUpdates?.booleanValue === false) {
      await api.finish(notice);
      continue;
    }
    let retry = false;
    for (const device of await api.devices(uid)) {
      if (!(now - Date.parse(device.fields.updatedAt?.timestampValue) < 30 * ONE_DAY)) continue;
      try {
        await api.send(device, uid, noticeId);
      } catch (error) {
        if (error.code === "UNREGISTERED") {
          await api.dropDevice(device).catch(() => null);
        } else {
          retry = true;
        }
      }
    }
    if (!retry) await api.finish(notice);
  }
}

async function deliverPending(env, fetcher = fetch) {
  const token = await googleAccessToken(env, fetcher);
  await drainNotices(googleApi(env.FIREBASE_PROJECT_ID, token, fetcher));
}
