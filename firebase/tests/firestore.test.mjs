import { strict as assert } from "node:assert";
import { randomUUID } from "node:crypto";
import { test } from "node:test";

const project = "demo-ecoroute";
const firestore = process.env.FIRESTORE_EMULATOR_HOST;
const auth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const emulator = { skip: (!firestore || !auth) && "Requires Firestore and Auth emulators" };
const db = `projects/${project}/databases/(default)/documents`;
const string = (stringValue) => ({ stringValue });
const integer = (value) => ({ integerValue: String(value) });
const bool = (booleanValue) => ({ booleanValue });

function request(path, token, body, method = body ? "POST" : "GET") {
  return fetch(`http://${firestore}/v1/${db}${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
}

function write(path, fields, { merge = false, timestamp = "updatedAt" } = {}) {
  return {
    update: { name: `${db}/${path}`, fields },
    ...(merge ? { updateMask: { fieldPaths: Object.keys(fields) } } : {}),
    ...(timestamp ? {
      updateTransforms: [{ fieldPath: timestamp, setToServerValue: "REQUEST_TIME" }],
    } : {}),
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
  return { id, token, profile };
}

function report(owner) {
  const id = randomUUID();
  return {
    id,
    path: `reports/${id}`,
    data: {
      id: string(id), citizenId: string(owner.id), reportNumber: string("#100"),
      description: string("Residuos en la vía"), status: string("pending"), priority: string("medium"),
    },
  };
}

function media(length = 16) {
  return {
    contentType: string("image/jpeg"),
    data: { bytesValue: Buffer.alloc(length, 42).toString("base64") },
  };
}

function statusChange(report, owner, status, extra = {}) {
  const id = randomUUID();
  const path = `${owner.profile}/notifications/${id}`;
  const change = write(report.path, { status: string(status), statusEventId: string(id), ...extra }, { merge: true });
  if (status === "resolved") {
    change.updateTransforms.push({ fieldPath: "resolvedAt", setToServerValue: "REQUEST_TIME" });
  }
  return {
    path,
    change,
    notice: write(path, {
      reportId: string(report.id), reportNumber: string("#100"), status: string(status),
      readAt: { nullValue: null }, pushPending: bool(true),
    }, { timestamp: "createdAt" }),
  };
}

async function createCrew(admin) {
  const id = randomUUID();
  await commit(admin.token, 200, write(`crews/${id}`, { name: string("Cuadrilla de prueba") }));
  return id;
}

function crewMembership(worker, teamId) {
  return write(worker.profile, {
    role: string("staff"),
    teamId: string(teamId),
  }, { merge: true });
}

async function dispatch(admin, item, owner, teamId) {
  const assignment = statusChange(item, owner, "assigned", {
    assignedToTeamId: string(teamId),
  });
  await commit(admin.token, 200, assignment.change, assignment.notice);
}

async function start(staff, item, owner) {
  const started = statusChange(item, owner, "in_progress", { assignedStaffId: string(staff.id) });
  await commit(staff.token, 200, started.change, started.notice);
}

test("el acceso operativo sigue a la cuadrilla y la toma de la tarea tiene un solo ganador", emulator, async () => {
  const [owner, admin, first, second, outsider, unassigned] = await Promise.all([
    register(), register("admin"), register("staff"), register("staff"),
    register("staff"), register("staff"),
  ]);
  const [teamId, otherTeamId] = await Promise.all([createCrew(admin), createCrew(admin)]);
  await commit(first.token, 403, crewMembership(first, teamId));
  await commit(admin.token, 403, crewMembership(first, randomUUID()));
  await commit(admin.token, 200, crewMembership(first, teamId),
    crewMembership(second, teamId), crewMembership(outsider, otherTeamId));
  assert.equal((await request(`/crews/${teamId}`, first.token)).status, 200);
  assert.equal((await request(`/crews/${otherTeamId}`, first.token)).status, 403);
  assert.equal((await request("/crews", first.token)).status, 403);

  const pending = report(owner);
  const item = report(owner);
  const personal = report(owner);
  await commit(owner.token, 200, ...[pending, item, personal].map((r) => write(r.path, r.data)));
  await commit("owner", 200, write(personal.path, {
    status: string("asignado"), assignedStaffId: string(unassigned.id),
  }, { merge: true }));
  const read = async (actor, report) => (await request(`/${report.path}`, actor.token)).status;
  assert.equal(await read(first, pending), 403);
  const earlyStart = statusChange(pending, owner, "in_progress", { assignedStaffId: string(first.id) });
  await commit(first.token, 403, earlyStart.change, earlyStart.notice);
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
  assert.ok((await query(owner, 200)).includes(item.id));
  const foreignStart = statusChange(item, owner, "in_progress", { assignedStaffId: string(outsider.id) });
  await commit(outsider.token, 403, foreignStart.change, foreignStart.notice);

  const preemptiveResolution = statusChange(item, owner, "resolved", {
    assignedStaffId: string(first.id), evidenceImagePath: string(`${item.path}/media/evidence`),
  });
  const evidence = write(`${item.path}/media/evidence`, media());
  await commit(first.token, 403, preemptiveResolution.change, preemptiveResolution.notice, evidence);

  const contenders = [first, second];
  const responses = await Promise.all(contenders.map((worker) => {
    const attempt = statusChange(item, owner, "in_progress", { assignedStaffId: string(worker.id) });
    return request(":commit", worker.token, { writes: [attempt.change, attempt.notice] });
  }));
  const results = await Promise.all(responses.map(async (response) => [response.status, await response.text()]));
  assert.deepEqual(results.map(([status]) => status).sort(), [200, 403], JSON.stringify(results));
  const winner = contenders[responses.findIndex((response) => response.ok)];
  const teammate = contenders.find((worker) => worker !== winner);
  assert.equal(await read(winner, item), 200);
  assert.equal(await read(teammate, item), 403);
  assert.deepEqual(await query(teammate, 200, compound("OR", byWorker(teammate), byCrew(teamId))), []);

  const resolution = statusChange(item, owner, "resolved", {
    assignedStaffId: string(winner.id), evidenceImagePath: string(`${item.path}/media/evidence`),
  });
  await commit(teammate.token, 403, resolution.change, resolution.notice, evidence);
  await commit(admin.token, 200, crewMembership(winner, otherTeamId));
  await query(winner, 403, compound("OR", byWorker(winner), byCrew(teamId)));
  assert.deepEqual(await query(winner, 200, compound("OR", byWorker(winner), byCrew(otherTeamId))), [item.id]);
  await commit(winner.token, 200, resolution.change, resolution.notice, evidence);
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
  await commit(admin.token, 200, crewMembership(staff, teamId));
  const item = report(owner);
  const paths = Array.from({ length: 4 }, (_, index) => `${item.path}/media/photo_${index}`);
  const photos = paths.map((path) => write(path, media()));
  const create = write(item.path, { ...item.data, imagePaths: { arrayValue: { values: paths.map(string) } } });
  await commit(owner.token, 403, ...photos);
  await commit(owner.token, 403, create, ...photos.slice(0, 3));
  await commit(owner.token, 200, create, ...photos);
  assert.equal((await request(`/${paths[0]}`, staff.token)).status, 403);
  await dispatch(admin, item, owner, teamId);
  assert.equal((await request(`/${paths[0]}`, staff.token)).status, 200);
  await start(staff, item, owner);

  const evidencePath = `${item.path}/media/evidence`;
  const evidence = write(evidencePath, media());
  const resolution = statusChange(item, owner, "resolved", {
    assignedStaffId: string(staff.id), evidenceImagePath: string(evidencePath),
  });
  await commit(owner.token, 403, resolution.change, evidence, resolution.notice);
  await commit(staff.token, 403, resolution.change, evidence);
  await commit(staff.token, 403, resolution.change, resolution.notice);
  await commit(staff.token, 403, resolution.change, evidence, resolution.notice,
    write(`${item.path}/media/evidence_1`, media()));
  await commit(staff.token, 200, resolution.change, evidence, resolution.notice);
  assert.equal((await request(`/${evidencePath}`, owner.token)).status, 200);
});

test("Solo el personal puede guardar todas las fotos de resolución junto con el aviso", emulator, async () => {
  const [owner, staff, admin] = await Promise.all([register(), register("staff"), register("admin")]);
  const teamId = await createCrew(admin);
  await commit(admin.token, 200, crewMembership(staff, teamId));
  const item = report(owner);
  await commit(owner.token, 200, write(item.path, item.data));
  await dispatch(admin, item, owner, teamId);
  await start(staff, item, owner);
  const paths = ["evidence", "evidence_1", "evidence_2", "evidence_3"]
    .map((id) => `${item.path}/media/${id}`);
  const photos = paths.map((path) => write(path, media()));
  const resolution = statusChange(item, owner, "resolved", {
    assignedStaffId: string(staff.id),
    evidenceImagePath: string(paths[0]),
    evidenceImagePaths: { arrayValue: { values: paths.map(string) } },
  });
  await commit(owner.token, 403, resolution.change, resolution.notice, ...photos);
  await commit(staff.token, 403, resolution.change, resolution.notice, ...photos.slice(0, 3));
  await commit(staff.token, 200, resolution.change, resolution.notice, ...photos);
  assert.equal((await request(`/${paths[3]}`, owner.token)).status, 200);
});

test("la bandeja sigue al estado, respeta preferencias y solo permite leer al titular", emulator, async () => {
  const [owner, admin, staff] = await Promise.all([register(), register("admin"), register("staff")]);
  const teamId = await createCrew(admin);
  await commit(admin.token, 200, crewMembership(staff, teamId));
  const item = report(owner);
  await commit(owner.token, 200, write(item.path, item.data));
  const assignment = statusChange(item, owner, "assigned", { assignedToTeamId: string(teamId) });
  await commit(owner.token, 403, assignment.change, assignment.notice);
  await commit(admin.token, 403, assignment.notice);
  await commit(admin.token, 403, assignment.change);
  await commit(admin.token, 200, assignment.change, assignment.notice);
  await commit(admin.token, 403, assignment.change, assignment.notice);
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
  const started = statusChange(item, owner, "in_progress", { assignedStaffId: string(staff.id) });
  await commit(staff.token, 403, started.change, started.notice);
  await commit(staff.token, 200, started.change);
  assert.equal((await request(`/${started.path}`, owner.token)).status, 404);
});

test("apoyos y calificaciones requieren participación y conteo coherentes", emulator, async () => {
  const [owner, neighbor, outsider] = await Promise.all([register(), register(), register()]);
  const item = report(owner);
  await commit(owner.token, 200, write(item.path, item.data));
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
  await commit("owner", 200, write(item.path, { status: string("resolved") }, { merge: true }));
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
  const crewPath = `crews/${randomUUID()}`;
  const crew = write(crewPath, { name: string("Cuadrilla de prueba") });
  await commit(owner.token, 403, crew);
  await commit(admin.token, 200, crew);

  const categoryPath = `report_categories/${randomUUID()}`;
  await commit(admin.token, 200, write(categoryPath, { name: string("Residuos") }));
  assert.equal((await request(`/${categoryPath}`, owner.token)).status, 200);

  const item = report(owner);
  await commit(owner.token, 200, write(item.path, item.data));
  const priority = write(item.path, { priority: string("high") }, { merge: true });
  await commit(owner.token, 403, priority);
  await commit(admin.token, 200, priority);
  const cancellation = write(item.path, {
    status: string("cancelled"), cancellationReason: string("Duplicado"),
  }, { merge: true });
  await commit(other.token, 403, cancellation);
  await commit(owner.token, 200, cancellation);
  await commit(owner.token, 200, write(`${item.path}/history/${randomUUID()}`, {
    newStatus: string("cancelled"), changedByUserRole: string("citizen"),
  }, { timestamp: "timestamp" }));
});
