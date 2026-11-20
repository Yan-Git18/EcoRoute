import { pathToFileURL } from "node:url";

const publicFields = [
  "reportNumber", "categoryId", "categoryName", "categoryIcon", "description",
  "priority", "status", "latitude", "longitude", "address", "createdAt",
  "updatedAt", "imagePaths", "imageUrls", "evidenceImagePath",
  "evidenceImagePaths", "evidenceImageUrl", "evidenceImageUrls",
];
const string = (stringValue) => ({ stringValue });
const integer = (value) => ({ integerValue: String(value) });
const array = (values) => ({ arrayValue: { values } });
const strings = (items) => items.filter((item) => item?.stringValue?.trim());
const id = (document) => document.name.split("/").at(-1);
const isStaff = (user) => ["staff", "personal"].includes(user?.fields?.role?.stringValue);

function patch(document, fields, mask = Object.keys(fields)) {
  return {
    update: { name: document.name, fields },
    updateMask: { fieldPaths: mask },
    currentDocument: { updateTime: document.updateTime },
  };
}

function normalizedReport(report) {
  const fields = { ...report.fields };
  const location = fields.location?.mapValue?.fields ?? {};
  for (const key of ["latitude", "longitude", "address"]) {
    if (location[key]) fields[key] = location[key];
  }

  const previousImages = fields.images?.arrayValue?.values ?? [];
  const nestedPhotos = strings(previousImages.map((entry) => entry.mapValue?.fields?.url ?? entry));
  if (nestedPhotos.length) {
    const photos = strings([...nestedPhotos, ...(fields.imageUrls?.arrayValue?.values ?? [])]);
    fields.imageUrls = array([...new Set(photos.map((photo) => photo.stringValue))].map(string));
    const originals = previousImages.flatMap((entry) => {
      if (!entry.mapValue?.fields?.url?.stringValue) return entry.stringValue ? [] : [entry];
      const { url: _url, ...metadata } = entry.mapValue.fields;
      return Object.keys(metadata).length ? [{ mapValue: { fields: metadata } }] : [];
    });
    if (originals.length) {
      fields.images = array(originals);
    } else {
      delete fields.images;
    }
  }
  if (!fields.evidenceImagePath && !fields.evidenceImagePaths?.arrayValue?.values?.length &&
      !fields.evidenceImageUrls?.arrayValue?.values?.length && !fields.evidenceImageUrl &&
      fields.evidencePhoto?.stringValue?.trim()) {
    fields.evidenceImageUrl = fields.evidencePhoto;
    delete fields.evidencePhoto;
  }
  return fields;
}

export async function migrateReportOperations({ project, emulator, token, apply = false }) {
  const database = `projects/${project}/databases/(default)/documents`;
  const origin = emulator ? `http://${emulator}` : "https://firestore.googleapis.com";

  async function request(path, body) {
    const response = await fetch(`${origin}/v1/${database}${path}`, {
      method: body ? "POST" : "GET",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!response.ok) {
      const error = (await response.json().catch(() => null))?.error;
      throw new Error(`Firestore ${response.status} (${error?.status ?? response.statusText})`);
    }
    return response.json();
  }

  async function list(collection) {
    const documents = [];
    let pageToken;
    do {
      const params = new URLSearchParams({ pageSize: "150" });
      if (pageToken) params.set("pageToken", pageToken);
      const page = await request(`/${collection}?${params}`);
      documents.push(...(page.documents ?? []));
      pageToken = page.nextPageToken;
    } while (pageToken);
    return documents;
  }

  const [reports, users, crews] = await Promise.all([list("reports"), list("users"), list("crews")]);
  const usersById = new Map(users.map((user) => [id(user), user]));
  const counts = new Map(crews.map((crew) => [id(crew), { reports: 0, members: 0 }]));
  const slots = new Map();
  const writes = [];
  let removedTeamLinks = 0;
  const unattendedActiveReports = [];

  for (const user of users) {
    const crewId = user.fields?.teamId?.stringValue;
    if (counts.has(crewId)) {
      counts.get(crewId).members += 1;
    } else if (crewId !== undefined) {
      writes.push(patch(user, {}, ["teamId"]));
      removedTeamLinks += 1;
    }
    if (isStaff(user)) slots.set(id(user), []);
  }

  for (const report of reports) {
    const fields = normalizedReport(report);
    const status = fields.status?.stringValue;
    const crewId = fields.assignedToTeamId?.stringValue;
    if (["assigned", "asignado", "in_progress", "en proceso"].includes(status)) {
      if (counts.has(crewId)) {
        counts.get(crewId).reports += 1;
      } else if (crewId !== undefined) {
        delete fields.assignedToTeamId;
        removedTeamLinks += 1;
      }
    }
    if (["in_progress", "en proceso"].includes(status)) {
      const uid = fields.assignedStaffId?.stringValue;
      const worker = usersById.get(uid);
      if (worker) {
        if (!slots.has(uid)) slots.set(uid, []);
        slots.get(uid).push(id(report));
      }
      if (!isStaff(worker) || worker.fields?.isActive?.booleanValue === false) {
        unattendedActiveReports.push(id(report));
      }
    }
    const original = report.fields ?? {};
    const keys = new Set([...Object.keys(original), ...Object.keys(fields)]);
    const changed = [...keys].filter((key) => JSON.stringify(original[key]) !== JSON.stringify(fields[key]));
    if (changed.length) {
      writes.push(patch(report, Object.fromEntries(
        changed.filter((key) => key in fields).map((key) => [key, fields[key]]),
      ), changed));
    }
    writes.push({
      update: {
        name: `${database}/communityReports/${id(report)}`,
        fields: Object.fromEntries(publicFields.filter((field) => field in fields).map((field) => [field, fields[field]])),
      },
    });
  }
  for (const crew of crews) {
    const count = counts.get(id(crew));
    writes.push(patch(crew, { openReportCount: integer(count.reports), memberCount: integer(count.members) }));
  }
  for (const [uid, reportIds] of slots) {
    writes.push({
      update: {
        name: `${database}/users/${uid}/operations/activeTask`,
        fields: { reportIds: array(reportIds.sort().map(string)) },
      },
    });
  }

  if (apply) {
    let batch = [];
    let size = 0;
    for (const write of writes) {
      const bytes = Buffer.byteLength(JSON.stringify(write));
      if (batch.length >= 150 || size + bytes > 4 * 1024 * 1024) {
        await request(":commit", { writes: batch });
        batch = [];
        size = 0;
      }
      batch.push(write);
      size += bytes;
    }
    if (batch.length) await request(":commit", { writes: batch });
  }

  return {
    project, applied: apply, reports: reports.length, crews: crews.length,
    workersWithActiveTasks: [...slots.values()].filter((ids) => ids.length > 0).length,
    removedTeamLinks, unattendedActiveReports,
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [projectArg, project, ...options] = process.argv.slice(2);
  const emulator = process.env.FIRESTORE_EMULATOR_HOST;
  const token = emulator ? "owner" : process.env.ECOROUTE_MIGRATION_ACCESS_TOKEN;
  if (projectArg !== "--project" || !/^[a-z][a-z0-9-]+$/.test(project ?? "") ||
      options.some((option) => option !== "--apply") || !token) {
    console.error("Uso: node firebase/migrate-report-operations.mjs --project <id> [--apply]");
    console.error("Configura FIRESTORE_EMULATOR_HOST o ECOROUTE_MIGRATION_ACCESS_TOKEN.");
    process.exitCode = 1;
  } else {
    try {
      const result = await migrateReportOperations({ project, emulator, token, apply: options.includes("--apply") });
      console.log(JSON.stringify(result, null, 2));
    } catch (error) {
      console.error(error.message);
      process.exitCode = 1;
    }
  }
}
