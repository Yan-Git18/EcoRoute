import { strict as assert } from "node:assert";
import { randomUUID } from "node:crypto";
import { test } from "node:test";
import { migrateReportOperations } from "../migrate-report-operations.mjs";

const project = process.env.GCLOUD_PROJECT ?? "demo-ecoroute";
const firestore = process.env.FIRESTORE_EMULATOR_HOST;
const auth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const emulator = { skip: (!firestore || !auth) && "Requires Firestore and Auth emulators" };
const db = `projects/${project}/databases/(default)/documents`;
const string = (stringValue) => ({ stringValue });
const integer = (value) => ({ integerValue: String(value) });
const bool = (booleanValue) => ({ booleanValue });
const map = (fields) => ({ mapValue: { fields } });
const array = (values) => ({ arrayValue: { values } });
const nullable = (value) => value == null ? { nullValue: null } : string(value);
const publicFields = [
  "reportNumber", "categoryId", "categoryName", "categoryIcon", "description",
  "priority", "status", "latitude", "longitude", "address", "imagePaths",
  "evidenceImagePath", "evidenceImagePaths",
];

function request(path, token, body, method = body ? "POST" : "GET") {
  return fetch(`http://${firestore}/v1/${db}${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
}

function write(path, fields, { merge = false, timestamp = "updatedAt", transforms = [] } = {}) {
  const updateTransforms = [
    ...(timestamp ? [{ fieldPath: timestamp, setToServerValue: "REQUEST_TIME" }] : []),
    ...transforms,
  ];
  return {
    update: { name: `${db}/${path}`, fields },
    ...(merge ? { updateMask: { fieldPaths: Object.keys(fields) } } : {}),
    ...(updateTransforms.length ? { updateTransforms } : {}),
  };
}

async function commit(token, status, ...writes) {
  const response = await request(":commit", token, { writes });
  assert.equal(response.status, status, status === 200 && !response.ok ? await response.text() : undefined);
}

async function register(role = "citizen") {
  const email = `${randomUUID()}@example.com`;
  const signup = await fetch(`http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=test`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test-password", returnSecureToken: true }),
  });
  assert.equal(signup.status, 200);
  const { localId: id, idToken: token } = await signup.json();
  const profile = `users/${id}`;
  const data = { id: string(id), name: string("Vecino"), email: string(email), role: string("citizen"), isActive: bool(true) };
  await commit(token, 403, write(profile, { ...data, role: string("admin") }));
  await commit(token, 200, write(profile, data));
  if (role !== "citizen") await commit("owner", 200, write(profile, { role: string(role) }, { merge: true }));
  return { id, token, profile, role };
}

function report(owner) {
  const id = randomUUID();
  const path = `reports/${id}`;
  const coords = { latitude: { doubleValue: -7.158 }, longitude: { doubleValue: -78.518 }, address: string("Av. Cajamarca") };
  return {
    id, path, publicPath: `communityReports/${id}`,
    data: {
      id: string(id), citizenId: string(owner.id), reportNumber: string("#100"),
      citizenName: string("Vecino"), citizenPhone: string("999555333"),
      categoryId: string("waste"), categoryName: string("Residuos"), categoryIcon: string("delete"),
      description: string("Residuos en la vía"), status: string("pending"), priority: string("medium"),
      ...coords, location: map(coords), imagePaths: array([string(`${path}/media/photo_0`)]),
    },
  };
}

function media(length = 16) {
  return {
    contentType: string("image/jpeg"),
    data: { bytesValue: Buffer.alloc(length, 42).toString("base64") },
  };
}

function historyWrite(item, id, actor, before, after) {
  return write(`${item.path}/history/${id}`, {
    previousStatus: string(before), newStatus: string(after), changedByUserId: string(actor.id),
    changedByUserName: string("Vecino"), changedByUserRole: string(actor.role), comment: string("Registro de prueba"),
  }, { timestamp: "timestamp" });
}

function publicWrite(item, data, { create = false, merge = false } = {}) {
  const projection = Object.fromEntries(publicFields.filter((key) => key in data).map((key) => [key, data[key]]));
  return write(item.publicPath, projection, {
    merge,
    transforms: create ? [{ fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" }] : [],
  });
}

function creation(item, owner) {
  const id = randomUUID();
  return [
    write(item.path, { ...item.data, statusEventId: string(id) }, {
      transforms: [{ fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" }],
    }),
    publicWrite(item, item.data, { create: true }),
    historyWrite(item, id, owner, "none", "pending"),
    ...(item.data.imagePaths?.arrayValue.values ?? []).map((path) => write(path.stringValue, media())),
  ];
}

function crewCounter(crewId, field, delta, details, status) {
  const activity = field === "memberCount" ? "memberActivity" : "reportActivity";
  return write(`crews/${crewId}`, {
    [activity]: map(details), ...(status ? { status: string(status) } : {}),
  }, {
    merge: true, timestamp: status ? "updatedAt" : null,
    transforms: [
      { fieldPath: field, increment: integer(delta) },
      ...(field === "memberCount" ? [{ fieldPath: "memberActivity.updatedAt", setToServerValue: "REQUEST_TIME" }] : []),
    ],
  });
}

function statusChange(item, owner, actor, status, extra = {}, activeIds = [], releaseCrew = true) {
  const id = randomUUID();
  const path = `${owner.profile}/notifications/${id}`;
  const previous = item.data.status.stringValue;
  const data = { status: string(status), statusEventId: string(id), ...extra };
  const change = write(item.path, data, { merge: true });
  if (status === "resolved") {
    change.updateTransforms.push({ fieldPath: "resolvedAt", setToServerValue: "REQUEST_TIME" });
  }
  const projection = publicWrite(item, data, { merge: true });
  const history = historyWrite(item, id, actor, previous, status);
  const related = [projection, history];
  const oldCrew = ["assigned", "in_progress"].includes(previous) ? item.data.assignedToTeamId?.stringValue : null;
  const newCrew = ["assigned", "in_progress"].includes(status)
    ? (data.assignedToTeamId ?? item.data.assignedToTeamId)?.stringValue : null;
  if (oldCrew !== newCrew) {
    for (const [crewId, delta] of [[oldCrew, -1], [newCrew, 1]]) {
      if (crewId) related.push(crewCounter(crewId, "openReportCount", delta, {
        reportId: string(item.id), eventId: string(id),
      }, delta > 0 ? "onRoute" : releaseCrew ? "available" : null));
    }
  }
  const active = ["in_progress", "resolved"].includes(status) ? write(`${actor.profile}/operations/activeTask`, {
    reportIds: array((status === "in_progress" ? [item.id] : activeIds).map(string)),
    reportId: string(item.id), eventId: string(id),
  }) : null;
  if (active) related.push(active);
  return {
    path, change, history, active, related,
    notice: write(path, {
      reportId: string(item.id), reportNumber: item.data.reportNumber, status: string(status),
      readAt: { nullValue: null }, pushPending: bool(true),
    }, { timestamp: "createdAt" }),
  };
}

async function createCrew(admin) {
  const id = randomUUID();
  await commit(admin.token, 200, crewCreation(id));
  return id;
}

function crewCreation(id) {
  return write(`crews/${id}`, {
    name: string("Cuadrilla de prueba"), openReportCount: integer(0), memberCount: integer(0),
  });
}

function crewMembership(worker, teamId, previousTeam = null) {
  return [
    write(worker.profile, { role: string("staff"), teamId: nullable(teamId) }, { merge: true }),
    ...[[previousTeam, -1], [teamId, 1]].filter(([crewId]) => crewId).map(([crewId, delta]) =>
      crewCounter(crewId, "memberCount", delta, { userId: string(worker.id) })),
  ];
}

async function dispatch(admin, item, owner, teamId) {
  const extra = { assignedToTeamId: string(teamId) };
  const assignment = statusChange(item, owner, admin, "assigned", extra);
  await commit(admin.token, 200, assignment.change, ...assignment.related,
    ...(item.data.status.stringValue === "assigned" ? [] : [assignment.notice]));
  Object.assign(item.data, { status: string("assigned"), ...extra });
}

async function start(staff, item, owner) {
  const extra = { assignedStaffId: string(staff.id) };
  const started = statusChange(item, owner, staff, "in_progress", extra);
  await commit(staff.token, 200, started.change, ...started.related, started.notice);
  Object.assign(item.data, { status: string("in_progress"), ...extra });
}

test("la bandeja pagina por cursor y el mapa devuelve solo los reportes recientes", emulator, async (t) => {
  const admin = await register("admin");
  const citizen = await register();
  const now = Date.now();
  const timestampAtDaysAgo = (days) => ({
    timestampValue: new Date(now - days * 86_400_000).toISOString(),
  });
  const from = (collectionId) => [{ collectionId }];
  const orderBy = [
    { field: { fieldPath: "createdAt" }, direction: "DESCENDING" },
    { field: { fieldPath: "__name__" }, direction: "DESCENDING" },
  ];
  const recentCount = 110;
  const totalCount = 180;
  const fixture = Array.from({ length: totalCount }, (_, index) => {
    const item = report(citizen);
    const createdAt = timestampAtDaysAgo(index < recentCount ? 7 : 45);
    const status = index < 15 ? string(index % 2 === 0 ? "resolved" : "Resuelto") : item.data.status;
    return [
      write(item.path, { ...item.data, status, createdAt }, { timestamp: null }),
      write(item.publicPath, {
        createdAt, status, latitude: item.data.latitude, longitude: item.data.longitude,
      }, { timestamp: null }),
    ];
  }).flat();

  async function query(token, structuredQuery) {
    const started = performance.now();
    const response = await request(":runQuery", token, { structuredQuery });
    assert.equal(response.status, 200, response.ok ? undefined : await response.text());
    const rows = await response.json();
    return {
      documents: rows.filter((row) => row.document).map((row) => row.document),
      ms: Math.round(performance.now() - started),
    };
  }

  async function count(token, structuredQuery) {
    const response = await request(":runAggregationQuery", token, {
      structuredAggregationQuery: {
        structuredQuery,
        aggregations: [{ count: {}, alias: "total" }],
      },
    });
    assert.equal(response.status, 200, response.ok ? undefined : await response.text());
    const rows = await response.json();
    return Number(rows.find((row) => row.result).result.aggregateFields.total.integerValue);
  }

  async function measurePair(token, fullQuery, limitedQuery) {
    const full = [];
    const limited = [];
    for (let i = 0; i < 5; i++) {
      if (i % 2 === 0) {
        full.push((await query(token, fullQuery)).ms);
        limited.push((await query(token, limitedQuery)).ms);
      } else {
        limited.push((await query(token, limitedQuery)).ms);
        full.push((await query(token, fullQuery)).ms);
      }
    }
    const median = (sample) => sample.sort((a, b) => a - b)[2];
    return [median(full), median(limited)];
  }

  await commit("owner", 200, ...fixture);
  try {
    const reportsQuery = { from: from("reports"), orderBy };
    const firstPageQuery = { ...reportsQuery, limit: 31 };
    const adminFull = await query(admin.token, reportsQuery);
    const first = await query(admin.token, firstPageQuery);
    const firstPage = first.documents.slice(0, 30);
    const last = firstPage.at(-1);
    const second = await query(admin.token, {
      from: from("reports"), orderBy, limit: 31,
      startAt: { before: false, values: [last.fields.createdAt, { referenceValue: last.name }] },
    });
    assert.equal(adminFull.documents.length, totalCount);
    assert.equal(first.documents.length, 31);
    assert.equal(last.fields.createdAt.timestampValue, second.documents[0].fields.createdAt.timestampValue);
    assert.deepEqual(
      [...firstPage, ...second.documents.slice(0, 30)].map((document) => document.name),
      adminFull.documents.slice(0, 60).map((document) => document.name),
    );

    assert.equal(await count(admin.token, { from: from("reports") }), totalCount);
    assert.equal(await count(admin.token, {
      from: from("reports"),
      where: { fieldFilter: {
        field: { fieldPath: "status" }, op: "IN",
        value: array(["resolved", "RESOLVED", "resuelto", "Resuelto", "RESUELTO"].map(string)),
      } },
    }), 15);

    const communityQuery = { from: from("communityReports") };
    const mapFull = await query(citizen.token, communityQuery);
    const mapQuery = {
      ...communityQuery,
      where: { fieldFilter: {
        field: { fieldPath: "createdAt" }, op: "GREATER_THAN_OR_EQUAL", value: timestampAtDaysAgo(30),
      } },
      orderBy: orderBy.slice(0, 1),
    };
    const recentQuery = { ...mapQuery, limit: 100 };
    const recent = await query(citizen.token, recentQuery);
    const inWindow = await query(citizen.token, mapQuery);
    assert.equal(mapFull.documents.length, totalCount);
    assert.equal(recent.documents.length, 100);
    assert.equal(inWindow.documents.length, recentCount);
    assert.ok(recent.documents.every((document) => Date.parse(document.fields.createdAt.timestampValue)
      >= Date.parse(timestampAtDaysAgo(30).timestampValue)));

    const [adminFullMs, firstPageMs] = await measurePair(admin.token, reportsQuery, firstPageQuery);
    const [mapFullMs, recentMs] = await measurePair(citizen.token, communityQuery, recentQuery);
    t.diagnostic(`Municipio: ${adminFull.documents.length} documentos (${adminFullMs} ms) → ${first.documents.length} (${firstPageMs} ms).`);
    t.diagnostic(`Mapa ciudadano: ${mapFull.documents.length} documentos (${mapFullMs} ms) → ${recent.documents.length} (${recentMs} ms).`);
  } finally {
    await commit("owner", 200, ...fixture.map(({ update }) => ({ delete: update.name })));
  }
});

test("el acceso operativo sigue a la cuadrilla y la toma de la tarea tiene un solo ganador", emulator, async () => {
  const [owner, admin, first, second, outsider, unassigned] = await Promise.all([
    register(), register("admin"), register("staff"), register("staff"),
    register("staff"), register("staff"),
  ]);
  const [teamId, otherTeamId] = await Promise.all([createCrew(admin), createCrew(admin)]);
  await commit(first.token, 403, ...crewMembership(first, teamId));
  await commit(admin.token, 403, crewMembership(first, randomUUID())[0]);
  await commit(admin.token, 403, crewMembership(first, teamId)[0]);
  await commit(admin.token, 200, ...crewMembership(first, teamId));
  await commit(admin.token, 200, ...crewMembership(second, teamId));
  await commit(admin.token, 200, ...crewMembership(outsider, otherTeamId));
  assert.equal((await request(`/crews/${teamId}`, first.token)).status, 200);
  assert.equal((await request(`/crews/${otherTeamId}`, first.token)).status, 403);
  assert.equal((await request("/crews", first.token)).status, 403);

  const pending = report(owner);
  const item = report(owner);
  const personal = report(owner);
  for (const candidate of [pending, item, personal]) {
    await commit(owner.token, 200, ...creation(candidate, owner));
  }
  await commit("owner", 200, write(personal.path, {
    status: string("asignado"), assignedStaffId: string(unassigned.id),
  }, { merge: true }));
  const read = async (actor, report) => (await request(`/${report.path}`, actor.token)).status;
  assert.equal(await read(first, pending), 403);
  const earlyStart = statusChange(pending, owner, first, "in_progress", { assignedStaffId: string(first.id) });
  await commit(first.token, 403, earlyStart.change, ...earlyStart.related, earlyStart.notice);
  await dispatch(admin, item, owner, teamId);
  assert.equal(await read(first, item), 200);
  assert.equal(await read(second, item), 200);
  assert.equal(await read(outsider, item), 403);
  assert.equal(await read(unassigned, item), 403);
  assert.equal(await read(unassigned, personal), 200);
  assert.equal(await read(first, personal), 403);

  const fieldFilter = (fieldPath, op, value) => ({ fieldFilter: { field: { fieldPath }, op, value } });
  const equal = (field, value) => fieldFilter(field, "EQUAL", string(value));
  const statuses = (...values) => fieldFilter("status", "IN", { arrayValue: { values: values.map(string) } });
  const compound = (op, ...filters) => ({ compositeFilter: { op, filters } });
  const byWorker = (worker) => compound("AND", equal("assignedStaffId", worker.id),
    statuses("assigned", "asignado", "in_progress", "en proceso", "resolved", "resuelto"));
  const byCrew = (id) => compound("AND", equal("assignedToTeamId", id), statuses("assigned", "asignado"));
  async function query(actor, status, where) {
    const response = await request(":runQuery", actor.token, {
      structuredQuery: {
        from: [{ collectionId: "reports" }],
        ...(where ? { where } : {}),
      },
    });
    assert.equal(response.status, status, status === 200 && !response.ok ? await response.text() : undefined);
    if (response.ok) {
      return (await response.json()).flatMap((row) => row.document?.name.split("/").at(-1) ?? []);
    }
  }

  assert.deepEqual(await query(first, 200, compound("OR", byWorker(first), byCrew(teamId))), [item.id]);
  assert.deepEqual(await query(unassigned, 200, byWorker(unassigned)), [personal.id]);
  await query(outsider, 403, compound("OR", byWorker(outsider), byCrew(teamId)));
  await query(first, 403);
  await query(owner, 403);
  assert.ok((await query(owner, 200, equal("citizenId", owner.id))).includes(item.id));
  const foreignStart = statusChange(item, owner, outsider, "in_progress", { assignedStaffId: string(outsider.id) });
  await commit(outsider.token, 403, foreignStart.change, ...foreignStart.related, foreignStart.notice);

  const preemptiveResolution = statusChange(item, owner, first, "resolved", {
    assignedStaffId: string(first.id), evidenceImagePath: string(`${item.path}/media/evidence`),
  });
  const evidence = write(`${item.path}/media/evidence`, media());
  await commit(first.token, 403, preemptiveResolution.change, ...preemptiveResolution.related, preemptiveResolution.notice, evidence);

  const contenders = [first, second];
  const responses = await Promise.all(contenders.map((worker) => {
    const attempt = statusChange(item, owner, worker, "in_progress", { assignedStaffId: string(worker.id) });
    return request(":commit", worker.token, { writes: [attempt.change, ...attempt.related, attempt.notice] });
  }));
  const results = await Promise.all(responses.map(async (response) => [response.status, await response.text()]));
  assert.deepEqual(results.map(([status]) => status).sort(), [200, 403], JSON.stringify(results));
  const winner = contenders[responses.findIndex((response) => response.ok)];
  const teammate = contenders.find((worker) => worker !== winner);
  Object.assign(item.data, { status: string("in_progress"), assignedStaffId: string(winner.id) });
  assert.equal(await read(winner, item), 200);
  assert.equal(await read(teammate, item), 403);
  assert.deepEqual(await query(teammate, 200, compound("OR", byWorker(teammate), byCrew(teamId))), []);

  const resolution = statusChange(item, owner, winner, "resolved", {
    assignedStaffId: string(winner.id), evidenceImagePath: string(`${item.path}/media/evidence`),
  });
  await commit(teammate.token, 403, resolution.change, ...resolution.related, resolution.notice, evidence);
  await commit(admin.token, 200, ...crewMembership(winner, otherTeamId, teamId));
  await query(winner, 403, compound("OR", byWorker(winner), byCrew(teamId)));
  assert.deepEqual(await query(winner, 200, compound("OR", byWorker(winner), byCrew(otherTeamId))), [item.id]);
  await commit(winner.token, 200, resolution.change, ...resolution.related, resolution.notice, evidence);
  const closed = await (await request(`/${item.path}`, winner.token)).json();
  assert.equal(closed.fields.resolvedAt.timestampValue, closed.fields.updatedAt.timestampValue);
  assert.equal(await read(winner, item), 200);
  assert.equal(await read(teammate, item), 403);
  assert.equal((await request(`/${item.path}/media/evidence`, teammate.token)).status, 403);
  assert.equal((await request(`/${item.path}/media/evidence`, owner.token)).status, 200);
});

test("los turnos guardan cambios atómicos por trabajador con fecha del servidor", emulator, async () => {
  const [staff, other, admin] = await Promise.all([register("staff"), register("staff"), register("admin")]);
  const shift = `${staff.profile}/operations/shift`;
  const eventId = () => randomUUID().replaceAll("-", "").slice(0, 20);
  const transition = (status, id, sessionId = id) => {
    const fields = { status: string(status), sessionId: string(sessionId) };
    return [
      write(shift, { ...fields, eventId: string(id) }, { timestamp: "changedAt" }),
      write(`${staff.profile}/shiftEvents/${id}`, fields, { timestamp: "changedAt" }),
    ];
  };
  const firstSession = eventId();
  const [shiftStart, startEvent] = transition("on_duty", firstSession);
  await commit(staff.token, 403, ...transition("on_break", eventId()));
  await commit(staff.token, 403, shiftStart);
  await commit(staff.token, 403, startEvent);
  await commit(other.token, 403, shiftStart, startEvent);
  await commit(admin.token, 403, shiftStart, startEvent);
  await commit(staff.token, 200, shiftStart, startEvent);
  await commit(staff.token, 403, ...transition("on_break", eventId()));
  await commit(staff.token, 200, ...transition("on_break", eventId(), firstSession));
  await commit(staff.token, 200, ...transition("on_duty", eventId(), firstSession));
  await commit(staff.token, 200, ...transition("off_duty", eventId(), firstSession));
  assert.equal((await request(`/${shift}`, other.token)).status, 403);
  const saved = await request(`/${shift}`, admin.token);
  assert.equal(saved.status, 200);
  const current = (await saved.json()).fields;
  assert.equal(current.status.stringValue, "off_duty");
  assert.equal(current.sessionId.stringValue, firstSession);
  const [restarted, reentry] = transition("on_duty", eventId());
  await commit(staff.token, 200, restarted, reentry);
  await commit(staff.token, 403, write(`${staff.profile}/shiftEvents/${firstSession}`, { status: string("off_duty") }));
});

test("las fotos se guardan junto con el reporte y la evidencia con la resolución y el aviso", emulator, async () => {
  const [owner, staff, admin] = await Promise.all([register(), register("staff"), register("admin")]);
  const teamId = await createCrew(admin);
  await commit(admin.token, 200, ...crewMembership(staff, teamId));
  const item = report(owner);
  const paths = Array.from({ length: 4 }, (_, index) => `${item.path}/media/photo_${index}`);
  item.data.imagePaths = array(paths.map(string));
  const [create, published, history, ...photos] = creation(item, owner);
  await commit(owner.token, 403, ...photos);
  await commit(owner.token, 403, create, published, history, ...photos.slice(0, 3));
  await commit(owner.token, 403, create, published, ...photos);
  await commit(owner.token, 200, create, published, history, ...photos);
  assert.equal((await request(`/${paths[0]}`, staff.token)).status, 403);
  await dispatch(admin, item, owner, teamId);
  assert.equal((await request(`/${paths[0]}`, staff.token)).status, 200);
  await start(staff, item, owner);

  const evidencePath = `${item.path}/media/evidence`;
  const evidence = write(evidencePath, media());
  const resolution = statusChange(item, owner, staff, "resolved", {
    assignedStaffId: string(staff.id), evidenceImagePath: string(evidencePath),
  });
  await commit(owner.token, 403, resolution.change, ...resolution.related, evidence, resolution.notice);
  await commit(staff.token, 403, resolution.change, ...resolution.related, evidence);
  await commit(staff.token, 403, resolution.change, ...resolution.related, resolution.notice);
  await commit(staff.token, 403, resolution.change, ...resolution.related, evidence, resolution.notice,
    write(`${item.path}/media/evidence_1`, media()));
  await commit(staff.token, 200, resolution.change, ...resolution.related, evidence, resolution.notice);
  assert.equal((await request(`/${evidencePath}`, owner.token)).status, 200);
});

test("Solo el personal puede guardar todas las fotos de resolución junto con el aviso", emulator, async () => {
  const [owner, staff, admin] = await Promise.all([register(), register("staff"), register("admin")]);
  const teamId = await createCrew(admin);
  await commit(admin.token, 200, ...crewMembership(staff, teamId));
  const item = report(owner);
  await commit(owner.token, 200, ...creation(item, owner));
  await dispatch(admin, item, owner, teamId);
  await start(staff, item, owner);
  const paths = ["evidence", "evidence_1", "evidence_2", "evidence_3"]
    .map((id) => `${item.path}/media/${id}`);
  const photos = paths.map((path) => write(path, media()));
  const resolution = statusChange(item, owner, staff, "resolved", {
    assignedStaffId: string(staff.id),
    evidenceImagePath: string(paths[0]),
    evidenceImagePaths: { arrayValue: { values: paths.map(string) } },
  });
  await commit(owner.token, 403, resolution.change, ...resolution.related, resolution.notice, ...photos);
  await commit(staff.token, 403, resolution.change, ...resolution.related, resolution.notice, ...photos.slice(0, 3));
  await commit(staff.token, 200, resolution.change, ...resolution.related, resolution.notice, ...photos);
  assert.equal((await request(`/${paths[3]}`, owner.token)).status, 200);
});

test("la bandeja sigue al estado, respeta preferencias y solo permite leer al titular", emulator, async () => {
  const [owner, admin, staff] = await Promise.all([register(), register("admin"), register("staff")]);
  const teamId = await createCrew(admin);
  await commit(admin.token, 200, ...crewMembership(staff, teamId));
  const item = report(owner);
  await commit(owner.token, 200, ...creation(item, owner));
  const assignment = statusChange(item, owner, admin, "assigned", { assignedToTeamId: string(teamId) });
  await commit(owner.token, 403, assignment.change, ...assignment.related, assignment.notice);
  await commit(admin.token, 403, assignment.notice);
  await commit(admin.token, 403, assignment.change, ...assignment.related);
  await commit(admin.token, 200, assignment.change, ...assignment.related, assignment.notice);
  Object.assign(item.data, { status: string("assigned"), assignedToTeamId: string(teamId) });
  assert.equal((await request(`/${assignment.path}`, owner.token)).status, 200);
  assert.equal((await request(`/${assignment.path}`, staff.token)).status, 403);
  await commit(owner.token, 200, {
    transform: {
      document: `${db}/${assignment.path}`,
      fieldTransforms: [{ fieldPath: "readAt", setToServerValue: "REQUEST_TIME" }],
    },
  });
  const settings = `${owner.profile}/settings/notifications`;
  await commit(owner.token, 200, write(settings, {
    reportUpdates: bool(false), nearbyTruck: bool(true), campaigns: bool(false),
  }, { timestamp: null }));
  assert.equal((await request(`/${settings}`, staff.token)).status, 403);
  const started = statusChange(item, owner, staff, "in_progress", { assignedStaffId: string(staff.id) });
  await commit(staff.token, 403, started.change, ...started.related, started.notice);
  await commit(staff.token, 200, started.change, ...started.related);
  assert.equal((await request(`/${started.path}`, owner.token)).status, 404);
});

test("apoyos y calificaciones requieren participación y conteo coherentes", emulator, async () => {
  const [owner, neighbor, outsider] = await Promise.all([register(), register(), register()]);
  const item = report(owner);
  await commit(owner.token, 200, ...creation(item, owner));
  const summary = `${item.path}/community/summary`;
  const participant = (actor, data) => write(`${item.path}/participants/${actor.id}`, data, {
    merge: true, timestamp: null,
  });
  const counts = (data) => write(summary, data, { merge: true, timestamp: null });
  const support = participant(neighbor, { supported: bool(true) });
  const oneSupport = counts({ supportCount: integer(1) });
  await commit(neighbor.token, 403, support);
  await commit(neighbor.token, 403, oneSupport);
  await commit(neighbor.token, 403, support, counts({ supportCount: integer(2) }));
  await commit(owner.token, 403, participant(owner, { supported: bool(true) }), oneSupport);
  await commit(neighbor.token, 200, support, oneSupport);
  await commit(neighbor.token, 403, support, oneSupport);
  await commit(neighbor.token, 403, participant(neighbor, { rating: integer(4) }),
    counts({ ratingCount: integer(1), ratingTotal: integer(4) }));
  await commit("owner", 200, write(item.path, { status: string("resolved") }, { merge: true }),
    publicWrite(item, { status: string("resolved") }, { merge: true }));
  const firstRating = counts({ ratingCount: integer(1), ratingTotal: integer(5) });
  await commit(outsider.token, 403, participant(outsider, { rating: integer(5) }), firstRating);
  await commit(owner.token, 200, participant(owner, { rating: integer(5) }), firstRating);
  await commit(neighbor.token, 200, participant(neighbor, { rating: integer(3) }),
    counts({ ratingCount: integer(2), ratingTotal: integer(8) }));
  await commit(owner.token, 403, participant(owner, { rating: integer(1) }),
    counts({ ratingCount: integer(3), ratingTotal: integer(9) }));
  const saved = (await (await request(`/${item.path}`, owner.token)).json()).fields;
  assert.equal(saved.priority.stringValue, "medium");
});

test("el avatar y los dispositivos tienen permisos acotados", emulator, async () => {
  const [owner, other] = await Promise.all([register(), register()]);
  const avatarPath = `${owner.profile}/media/avatar`;
  const avatar = write(avatarPath, media());
  const profile = write(owner.profile, { avatarPath: string(avatarPath) }, { merge: true });
  await commit(owner.token, 403, avatar);
  await commit(owner.token, 403, profile);
  await commit(other.token, 403, avatar, profile);
  await commit(owner.token, 403, write(avatarPath, media(96 * 1024 + 1)), profile);
  await commit(owner.token, 200, avatar, profile);
  await commit(owner.token, 200, avatar, profile);
  assert.equal((await request(`/${avatarPath}`, other.token)).status, 403);
  const device = `citizenPushDevices/${randomUUID()}`;
  await commit(other.token, 403, write(device, { uid: string(owner.id) }));
  await commit(owner.token, 200, write(device, { uid: string(owner.id) }));
  assert.equal((await request(`/${device}`, owner.token)).status, 403);
  await commit(other.token, 200, write(device, { uid: string(other.id) }));
  assert.equal((await request(`/${device}`, owner.token, undefined, "DELETE")).status, 403);
  assert.equal((await request(`/${device}`, other.token, undefined, "DELETE")).status, 200);
});

test("se conservan el despacho municipal, el catálogo y la cancelación del propio reporte", emulator, async () => {
  const [owner, other, admin] = await Promise.all([register(), register(), register("admin")]);
  const crew = crewCreation(randomUUID());
  await commit(owner.token, 403, crew);
  await commit(admin.token, 200, crew);

  const categoryPath = `report_categories/${randomUUID()}`;
  await commit(admin.token, 200, write(categoryPath, { name: string("Residuos") }));
  assert.equal((await request(`/${categoryPath}`, owner.token)).status, 200);

  const item = report(owner);
  await commit(owner.token, 200, ...creation(item, owner));
  const priority = write(item.path, { priority: string("high") }, { merge: true });
  await commit(owner.token, 403, priority);
  await commit(admin.token, 403, priority);
  await commit(admin.token, 200, priority, publicWrite(item, { priority: string("high") }, { merge: true }));
  const cancellation = statusChange(item, owner, owner, "cancelled", { cancellationReason: string("Duplicado") });
  await commit(other.token, 403, cancellation.change, ...cancellation.related);
  await commit(owner.token, 403, cancellation.change, ...cancellation.related.filter((write) => write !== cancellation.history));
  await commit(owner.token, 200, cancellation.change, ...cancellation.related);
  await commit(owner.token, 403, historyWrite(item, randomUUID(), owner, "pending", "cancelled"));
});

test("el mapa muestra fotos y estado sin publicar el contacto ni el historial privado", emulator, async () => {
  const [owner, neighbor, admin] = await Promise.all([register(), register(), register("admin")]);
  const item = report(owner);
  const [create, projection, history, photo] = creation(item, owner);
  await commit(owner.token, 403, create, history, photo);
  await commit(owner.token, 200, create, projection, history, photo);

  const historyPath = history.update.name.split("/documents/").at(-1);
  for (const actor of [owner, admin]) {
    const privateReport = await request(`/${item.path}`, actor.token);
    assert.equal(privateReport.status, 200);
    assert.equal((await privateReport.json()).fields.citizenPhone.stringValue, "999555333");
    assert.equal((await request(`/${historyPath}`, actor.token)).status, 200);
  }
  assert.equal((await request(`/${item.path}`, neighbor.token)).status, 403);
  assert.equal((await request(`/${historyPath}`, neighbor.token)).status, 403);
  const listing = await request("/communityReports", neighbor.token);
  assert.equal(listing.status, 200);
  const visible = (await listing.json()).documents.find((doc) => doc.name.endsWith(`/${item.id}`)).fields;
  for (const field of ["citizenId", "citizenName", "citizenPhone", "reference", "location"]) {
    assert.ok(!(field in visible));
  }
  assert.equal(visible.status.stringValue, "pending");
  assert.equal((await request(`/${item.path}/media/photo_0`, neighbor.token)).status, 200);
});

test("las altas requieren foto, campos válidos y coordenadas dentro de Cajamarca", emulator, async () => {
  const owner = await register();
  const noPhoto = report(owner);
  noPhoto.data.imagePaths = array([]);
  await commit(owner.token, 403, ...creation(noPhoto, owner));

  const outside = report(owner);
  outside.data.latitude = outside.data.location.mapValue.fields.latitude = { doubleValue: -12.04 };
  await commit(owner.token, 403, ...creation(outside, owner));
  outside.data.latitude = { doubleValue: -7.158 };
  await commit(owner.token, 403, ...creation(outside, owner));

  const blank = report(owner);
  blank.data.description = string("     ");
  await commit(owner.token, 403, ...creation(blank, owner));
  blank.data.description = string("Residuos acumulados\nEn segunda línea");
  await commit(owner.token, 200, ...creation(blank, owner));
});

test("dos inicios simultáneos de la misma cuenta dejan una tarea activa hasta el cierre", emulator, async () => {
  const [owner, admin, staff] = await Promise.all([register(), register("admin"), register("staff")]);
  const crewId = await createCrew(admin);
  await commit(admin.token, 200, ...crewMembership(staff, crewId));
  const tasks = [report(owner), report(owner)];
  for (const item of tasks) {
    await commit(owner.token, 200, ...creation(item, owner));
    await dispatch(admin, item, owner, crewId);
  }
  const attempts = tasks.map((item) => statusChange(item, owner, staff, "in_progress", {
    assignedStaffId: string(staff.id),
  }));
  const responses = await Promise.all(attempts.map(({ change, related, notice }) =>
    request(":commit", staff.token, { writes: [change, ...related, notice] })));
  assert.deepEqual(responses.map((response) => response.status).sort(), [200, 403]);
  const winnerIndex = responses.findIndex((response) => response.ok);
  const active = tasks[winnerIndex];
  const waiting = tasks[1 - winnerIndex];
  Object.assign(active.data, { status: string("in_progress"), assignedStaffId: string(staff.id) });
  const resolution = statusChange(active, owner, staff, "resolved", {
    assignedStaffId: string(staff.id), evidenceImagePath: string(`${active.path}/media/evidence`),
  }, [], false);
  const evidence = write(`${active.path}/media/evidence`, media());
  await commit(staff.token, 403, resolution.change, resolution.notice, evidence,
    ...resolution.related.filter((write) => write !== resolution.active));
  await commit(staff.token, 200, resolution.change, ...resolution.related, resolution.notice, evidence);
  await start(staff, waiting, owner);
});

test("la baja de una cuadrilla espera al despacho y a la reasignación del personal", emulator, async () => {
  const [owner, admin, staff] = await Promise.all([register(), register("admin"), register("staff")]);
  const [first, second] = await Promise.all([createCrew(admin), createCrew(admin)]);
  const crewPath = `/crews/${first}`;
  const drop = () => request(crewPath, admin.token, undefined, "DELETE");
  await commit(admin.token, 200, ...crewMembership(staff, first));
  assert.equal((await drop()).status, 403);
  const item = report(owner);
  await commit(owner.token, 200, ...creation(item, owner));
  await dispatch(admin, item, owner, first);
  assert.equal((await (await request(crewPath, admin.token)).json()).fields.status.stringValue, "onRoute");
  await commit(admin.token, 200, ...crewMembership(staff, second, first));
  assert.equal((await drop()).status, 403);
  await commit(admin.token, 403, write(`crews/${first}`, { openReportCount: integer(0) }, { merge: true }));
  await dispatch(admin, item, owner, second);
  assert.equal((await (await request(crewPath, admin.token)).json()).fields.status.stringValue, "available");
  assert.equal((await drop()).status, 200);
  assert.equal((await request(`/crews/${second}`, admin.token, undefined, "DELETE")).status, 403);
});

test("la migración conserva fotos antiguas y reconstruye tareas activas y cuadrillas", emulator, async () => {
  const [owner, neighbor, admin, staff] = await Promise.all([
    register(), register(), register("admin"), register("staff"),
  ]);
  const crewId = randomUUID();
  const item = report(owner);
  const extra = report(owner);
  const legacy = {
    status: string("en proceso"), assignedStaffId: string(staff.id), assignedToTeamId: string(crewId),
    images: array([map({ url: string("https://example.test/foto.jpg") })]),
  };
  for (const candidate of [item, extra]) {
    delete candidate.data.imagePaths;
    Object.assign(candidate.data, legacy);
  }
  await commit("owner", 200, write(`crews/${crewId}`, { name: string("Cuadrilla anterior") }));
  await commit("owner", 200, write(staff.profile, { teamId: string(crewId) }, { merge: true }));
  await commit("owner", 200, write(item.path, item.data), write(extra.path, extra.data));

  const params = { project, emulator: firestore, token: "owner" };
  await migrateReportOperations(params);
  assert.equal((await request(`/${item.publicPath}`, neighbor.token)).status, 404);
  for (let pass = 0; pass < 2; pass += 1) {
    await migrateReportOperations({ ...params, apply: true });
  }
  const projection = (await (await request(`/${item.publicPath}`, neighbor.token)).json()).fields;
  assert.equal(projection.imageUrls.arrayValue.values[0].stringValue, "https://example.test/foto.jpg");
  assert.equal(projection.citizenPhone, undefined);
  const crew = (await (await request(`/crews/${crewId}`, admin.token)).json()).fields;
  assert.equal(crew.openReportCount.integerValue, "2");
  assert.equal(crew.memberCount.integerValue, "1");

  const slot = (await (await request(`/${staff.profile}/operations/activeTask`, staff.token)).json()).fields;
  assert.deepEqual(slot.reportIds.arrayValue.values.map((id) => id.stringValue), [item.id, extra.id].sort());
  item.data.status = string("in_progress");
  const resolution = statusChange(item, owner, staff, "resolved", {
    assignedStaffId: string(staff.id), evidenceImagePath: string(`${item.path}/media/evidence`),
  }, [extra.id], false);
  await commit(staff.token, 200, resolution.change, ...resolution.related, resolution.notice,
    write(`${item.path}/media/evidence`, media()));
});


test("el despacho individual comparte el reporte y reserva a cada persona hasta el cierre", emulator, async () => {
  const [owner, admin, first, second, outsider] = await Promise.all([
    register(), register("admin"), register("staff"), register("staff"), register("staff"),
  ]);
  const item = report(owner);
  const other = report(owner);
  await commit(owner.token, 200, ...creation(item, owner));
  await commit(owner.token, 200, ...creation(other, owner));
  const assignment = (target, members) => {
    const extra = { assignedStaffIds: array(members.map(({ id }) => string(id))) };
    const { change, related, notice } = statusChange(target, owner, admin, "assigned", extra);
    const reservations = members.map((staff) => write(`${staff.profile}/operations/dispatch`, {
      reportId: string(target.id),
    }));
    return { extra, writes: [change, ...related, notice, ...reservations] };
  };

  const firstAssignment = assignment(item, [first, second]);
  await commit(admin.token, 200, ...firstAssignment.writes);
  Object.assign(item.data, { status: string("assigned"), ...firstAssignment.extra });
  assert.equal((await request(`/${item.path}`, first.token)).status, 200);
  assert.equal((await request(`/${item.path}`, second.token)).status, 200);
  assert.equal((await request(`/${item.path}`, outsider.token)).status, 403);
  const query = await request(":runQuery", first.token, {
    structuredQuery: {
      from: [{ collectionId: "reports" }],
      where: {
        compositeFilter: {
          op: "AND",
          filters: [
            { fieldFilter: { field: { fieldPath: "assignedStaffIds" }, op: "ARRAY_CONTAINS", value: string(first.id) } },
            { fieldFilter: { field: { fieldPath: "status" }, op: "IN", value: array(["assigned", "asignado"].map(string)) } },
          ],
        },
      },
    },
  });
  assert.equal(query.status, 200, query.ok ? undefined : await query.text());
  assert.ok((await query.json()).some(({ document }) => document?.name.endsWith(`/${item.id}`)));

  await commit(admin.token, 403, ...assignment(other, [first]).writes);
  await commit(admin.token, 403, ...assignment(other, [outsider, outsider]).writes);
  await start(first, item, owner);
  assert.equal((await request(`/${item.path}`, second.token)).status, 403);
  await commit(admin.token, 403, ...assignment(other, [second]).writes);
  const resolution = statusChange(item, owner, first, "resolved", {
    assignedStaffId: string(first.id), evidenceImagePath: string(`${item.path}/media/evidence`),
  });
  await commit(first.token, 200, resolution.change, ...resolution.related, resolution.notice,
    write(`${item.path}/media/evidence`, media()));
  await commit(admin.token, 200, ...assignment(other, [second]).writes);
});

test("un equipo reserva el camión y sus integrantes en la misma operación", emulator, async () => {
  const [admin, first, second, third] = await Promise.all([
    register("admin"), register("staff"), register("staff"), register("staff"),
  ]);
  const truck = randomUUID();
  const crew = randomUUID();
  const otherCrew = randomUUID();
  const truckPath = `vehicles/${truck}`;
  const fields = { status: string("available") };
  await commit(admin.token, 403, write(`crews/${truck}`, {
    ...fields, vehicleOnly: bool(true), openReportCount: integer(0), memberCount: integer(0),
  }));
  await commit(first.token, 403, write(truckPath, fields));
  await commit(admin.token, 200, write(truckPath, fields));
  const membership = (staff, id) => write(staff.profile, { teamId: nullable(id) }, { merge: true });
  const create = (id, members) => [
    write(`crews/${id}`, {
      name: string("Equipo"), status: string("available"), vehicleId: string(truck),
      openReportCount: integer(0), memberCount: integer(2), crewMembersCount: integer(2),
      memberIds: array(members.map(({ id }) => string(id))),
    }),
    write(truckPath, { assignedCrewId: string(id) }, { merge: true, timestamp: null }),
    ...members.map((member) => membership(member, id)),
  ];

  await commit(admin.token, 403, ...create(crew, [first, first]));
  await commit(admin.token, 200, ...create(crew, [first, second]));
  await commit(admin.token, 403, { delete: `${db}/${truckPath}` });
  await commit(admin.token, 403, ...create(otherCrew, [first, third]));
  await commit(admin.token, 403, write(`crews/${crew}`, {
    memberIds: array([first.id, third.id].map(string)),
  }, { merge: true }), membership(third, crew));
  await commit(admin.token, 200, write(`crews/${crew}`, {
    memberIds: array([first.id, third.id].map(string)),
  }, { merge: true }), membership(second, null), membership(third, crew));
  await commit(admin.token, 200, membership(first, null), membership(third, null),
    write(truckPath, { assignedCrewId: nullable(null) }, { merge: true, timestamp: null }),
    { delete: `${db}/crews/${crew}` });
  await commit(admin.token, 200, ...create(otherCrew, [first, second]));
});

test("la edición libera el camión anterior y admite reemplazar cinco integrantes", emulator, async () => {
  const [admin, ...people] = await Promise.all([
    register("admin"), ...Array.from({ length: 10 }, () => register("staff")),
  ]);
  const oldMembers = people.slice(0, 5);
  const newMembers = people.slice(5);
  const crewId = randomUUID();
  const firstTruck = randomUUID();
  const secondTruck = randomUUID();
  const crew = `crews/${crewId}`;
  const truck = (id) => `vehicles/${id}`;
  const memberIds = (members) => array(members.map(({ id }) => string(id)));
  const membership = (staff, id) => write(staff.profile, { teamId: nullable(id) }, { merge: true });
  const truckOwner = (id, team) => write(truck(id), { assignedCrewId: nullable(team) }, { merge: true, timestamp: null });
  const vehicleFields = { status: string("available") };
  await commit(admin.token, 200, write(truck(firstTruck), vehicleFields), write(truck(secondTruck), vehicleFields));
  await commit(admin.token, 200,
    write(crew, {
      vehicleId: string(firstTruck), memberIds: memberIds(oldMembers),
      openReportCount: integer(0), memberCount: integer(5), crewMembersCount: integer(5),
    }),
    truckOwner(firstTruck, crewId), ...oldMembers.map((person) => membership(person, crewId)));

  const changeTruck = write(crew, { vehicleId: string(secondTruck) }, { merge: true });
  await commit(admin.token, 403, changeTruck, truckOwner(secondTruck, crewId));
  const partialReplacement = write(crew, {
    memberIds: memberIds([...oldMembers.slice(0, 4), newMembers[0]]),
  }, { merge: true });
  await commit(admin.token, 403, partialReplacement, membership(newMembers[0], crewId));
  await commit(admin.token, 200, partialReplacement, membership(oldMembers[4], null),
    membership(newMembers[0], crewId));
  await commit(admin.token, 200, write(crew, { memberIds: memberIds(oldMembers) }, { merge: true }),
    membership(newMembers[0], null), membership(oldMembers[4], crewId));
  await commit(admin.token, 200,
    write(crew, { vehicleId: string(secondTruck), memberIds: memberIds(newMembers) }, { merge: true }),
    truckOwner(firstTruck, null), truckOwner(secondTruck, crewId),
    ...oldMembers.map((person) => membership(person, null)),
    ...newMembers.map((person) => membership(person, crewId)));

  const deleteCrew = { delete: `${db}/${crew}` };
  const releaseMembers = newMembers.map((person) => membership(person, null));
  await commit(admin.token, 403, deleteCrew, ...releaseMembers);
  await commit(admin.token, 200, deleteCrew, ...releaseMembers, truckOwner(secondTruck, null));
});

test("un administrador amplía el equipo de dos a cinco integrantes", emulator, async () => {
  const [owner, admin, ...people] = await Promise.all([
    register(), register("admin"), ...Array.from({ length: 6 }, () => register("staff")),
  ]);
  const crewId = randomUUID();
  const crew = `crews/${crewId}`;
  const roster = (size, declaredSize = size) => ({
    memberIds: array(people.slice(0, size).map(({ id }) => string(id))),
    memberCount: integer(size), crewMembersCount: integer(declaredSize),
  });
  const addMember = ({ profile }) => write(profile, { teamId: string(crewId) }, { merge: true });
  await commit("owner", 200, write(crew, {
    ...roster(2), openReportCount: integer(0),
  }), ...people.slice(0, 2).map(addMember));

  for (const size of [3, 4, 5]) {
    const newcomer = people[size - 1];
    for (const operation of ["dispatch", "activeTask"]) {
      assert.equal((await request(`/${newcomer.profile}/operations/${operation}`, admin.token)).status, 404);
    }
    await commit(admin.token, 403, write(crew, roster(size, size - 1), { merge: true }), addMember(newcomer));
    await commit(admin.token, 200, write(crew, roster(size), { merge: true }), addMember(newcomer));
    assert.deepEqual((await (await request(`/${crew}`, admin.token)).json()).fields.memberIds, roster(size).memberIds);
  }
  await commit(admin.token, 403, write(crew, roster(6), { merge: true }), addMember(people[5]));
  await commit(admin.token, 403, write(crew, roster(1), { merge: true }),
    ...people.slice(1, 5).map(({ profile }) => write(profile, { teamId: nullable(null) }, { merge: true })));

  const item = report(owner);
  const worker = people[2];
  await commit(owner.token, 200, ...creation(item, owner));
  await dispatch(admin, item, owner, crewId);
  const getTeam = async () => (await (await request(`/${crew}`, worker.token)).json()).fields;
  assert.equal((await getTeam()).status.stringValue, "onRoute");
  await start(worker, item, owner);
  const resolution = statusChange(item, owner, worker, "resolved", {
    evidenceImagePath: string(`${item.path}/media/evidence`),
  });
  await commit(worker.token, 200, resolution.change, ...resolution.related, resolution.notice,
    write(`${item.path}/media/evidence`, media()));
  const available = await getTeam();
  assert.equal(available.status.stringValue, "available");
  assert.equal(available.openReportCount.integerValue, "0");
});

test("un equipo anterior puede editar sus datos y completar su dotación después del relleno de contadores", emulator, async () => {
  const [admin, first, second, third, idleMember] = await Promise.all([
    register("admin"), register("staff"), register("staff"), register("staff"), register("staff"),
  ]);
  const crewId = randomUUID();
  const crew = `crews/${crewId}`;
  await commit("owner", 200, write(crew, { name: string("Equipo anterior") }),
    write(first.profile, { teamId: string(crewId) }, { merge: true }));
  await commit(admin.token, 200, write(crew, { name: string("Equipo Norte"), zone: string("Norte") }, { merge: true }));
  const completeRoster = [
    write(crew, {
      memberIds: array([first, second, third].map(({ id }) => string(id))),
      memberCount: integer(3), crewMembersCount: integer(3),
    }, { merge: true }),
    ...[second, third].map(({ profile }) => write(profile, { teamId: string(crewId) }, { merge: true })),
  ];
  await commit(admin.token, 403, ...completeRoster);
  const idleId = randomUUID();
  const idleCrew = `crews/${idleId}`;
  await commit("owner", 200, write(idleCrew, { name: string("Equipo sin actividad") }),
    write(idleMember.profile, { teamId: string(idleId) }, { merge: true }));
  await migrateReportOperations({ project, emulator: firestore, token: "owner", apply: true });
  const migrated = (await (await request(`/${crew}`, admin.token)).json()).fields;
  assert.deepEqual(migrated.memberIds.arrayValue.values, [string(first.id)]);
  await commit(admin.token, 403, { delete: `${db}/${crew}` });
  await commit(admin.token, 200, ...completeRoster);
  await commit(admin.token, 200, { delete: `${db}/${idleCrew}` },
    write(idleMember.profile, { teamId: nullable(null) }, { merge: true }));
});

test("un equipo antiguo con un integrante se puede eliminar sin completar la dotación", emulator, async () => {
  const [admin, member, other] = await Promise.all([
    register("admin"), register("personal"), register("staff"),
  ]);
  const crewId = randomUUID();
  const crew = `crews/${crewId}`;
  await commit("owner", 200, write(crew, {
    name: string("Equipo anterior"), memberCount: integer(1), openReportCount: integer(0),
  }), write(member.profile, { teamId: string(crewId) }, { merge: true }));

  const recordRoster = (person) => write(crew, {
    memberIds: array([string(person.id)]), crewMembersCount: integer(1),
  }, { merge: true, timestamp: null });
  const deletion = { delete: `${db}/${crew}` };
  await commit(admin.token, 403, deletion);
  await commit(member.token, 403, recordRoster(member));
  await commit(admin.token, 403, recordRoster(other));
  await commit(admin.token, 200, recordRoster(member));
  await commit(admin.token, 403, deletion);
  await commit(admin.token, 200, deletion,
    write(member.profile, { teamId: nullable(null) }, { merge: true }));
  assert.equal((await request(`/${crew}`, admin.token)).status, 404);
});

test("Personal permite cambios de rol al administrador con un vínculo anterior vacío", emulator, async () => {
  const [admin, worker, other] = await Promise.all([
    register("administrador"), register("ciudadano"), register("staff"),
  ]);
  await commit("owner", 200, write(worker.profile, { teamId: string("") }, { merge: true }));
  const role = (value) => write(worker.profile, { role: string(value) }, { merge: true });
  await commit(other.token, 403, role("staff"));
  await commit(admin.token, 403, role("admin"));
  await commit(admin.token, 200, role("staff"));
  for (const document of ["dispatch", "activeTask"]) {
    const path = `/${worker.profile}/operations/${document}`;
    assert.equal((await request(path, admin.token)).status, 404);
    assert.equal((await request(path, other.token)).status, 403);
  }
  const demote = write(worker.profile, { role: string("citizen") }, { merge: true });
  demote.updateMask.fieldPaths.push("teamId");
  await commit(admin.token, 200, demote);
  const profile = await (await request(`/${worker.profile}`, admin.token)).json();
  assert.equal(profile.fields.role.stringValue, "citizen");
  assert.equal(profile.fields.teamId, undefined);
});

test("la migración traslada camiones y conserva los vínculos de equipos", emulator, async () => {
  const teamId = randomUUID();
  const truckId = randomUUID();
  const embeddedId = randomUUID();
  const truck = `crews/${truckId}`;
  const team = `crews/${teamId}`;
  const embedded = `crews/${embeddedId}`;
  const params = { project, emulator: firestore, token: "owner", vehiclesOnly: true };
  await commit("owner", 200,
    write(truck, { vehicleOnly: bool(true), assignedCrewId: string(teamId),
      vehiclePlate: string("OLD001"), status: string("available"), memberCount: integer(0) }),
    write(team, { vehicleId: string(truckId) }),
    write(embedded, { vehiclePlate: string("OLD002"), openReportCount: integer(1) }));
  const preview = await migrateReportOperations(params);
  assert.equal(preview.movedVehicles, 1);
  assert.equal(preview.extractedVehicles, 1);
  assert.equal((await request(`/${truck}`, "owner")).status, 200);

  await migrateReportOperations({ ...params, apply: true });
  assert.equal((await request(`/${truck}`, "owner")).status, 404);
  const fields = async (path) => (await (await request(`/${path}`, "owner")).json()).fields;
  const moved = await fields(`vehicles/${truckId}`);
  assert.equal(moved.assignedCrewId.stringValue, teamId);
  assert.equal(moved.vehiclePlate.stringValue, "OLD001");
  assert.equal(moved.memberCount, undefined);
  assert.equal((await fields(team)).vehicleId.stringValue, truckId);
  const extractedId = (await fields(embedded)).vehicleId.stringValue;
  assert.equal((await fields(`vehicles/${extractedId}`)).assignedCrewId.stringValue, embeddedId);
  assert.equal((await fields(embedded)).openReportCount.integerValue, "1");
  const retry = await migrateReportOperations({ ...params, apply: true });
  assert.equal(retry.movedVehicles + retry.extractedVehicles, 0);
});
