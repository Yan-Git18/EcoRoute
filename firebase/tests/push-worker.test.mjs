import { strict as assert } from "node:assert";
import { test } from "node:test";
import { drainNotices } from "../push-worker/worker.mjs";

const now = Date.parse("2026-11-19T12:00:00Z");
const timestampValue = new Date(now - 1000).toISOString();
const notice = { name: "projects/example/databases/(default)/documents/users/sample/notifications/event", fields: {
  createdAt: { timestampValue },
} };
const device = { fields: { updatedAt: { timestampValue } } };

test("el worker conserva el aviso si falla el envío y retira tokens vencidos por FCM", async () => {
  const actions = [];
  const api = {
    notices: async () => [notice],
    profile: async () => ({ fields: {} }),
    preferences: async () => null,
    devices: async () => [device],
    finish: async () => actions.push("finished"),
    dropDevice: async () => actions.push("removed"),
    send: async () => { throw new Error("temporario"); },
  };
  await drainNotices(api, now);
  assert.deepEqual(actions, []);
  api.send = async () => { throw Object.assign(new Error("expired"), { code: "UNREGISTERED" }); };
  await drainNotices(api, now);
  assert.deepEqual(actions, ["removed", "finished"]);
});

test("el worker respeta las preferencias antes de buscar dispositivos", async () => {
  const actions = [];
  await drainNotices({
    notices: async () => [notice],
    profile: async () => ({ fields: {} }),
    preferences: async () => ({ fields: { reportUpdates: { booleanValue: false } } }),
    devices: async () => assert.fail("No debe buscar dispositivos"),
    finish: async () => actions.push("finished"),
  }, now);
  assert.deepEqual(actions, ["finished"]);
});
