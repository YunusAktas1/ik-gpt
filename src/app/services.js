class SessionRepository {
  constructor(storage) {
    this.storage = storage;
    this.key = "tf6:s";
  }

  async get() {
    return this.storage.getJSON(this.key);
  }

  async set(value) {
    await this.storage.setJSON(this.key, value);
  }

  async clear() {
    await this.storage.delete(this.key);
  }
}

class UserRepository {
  constructor(storage) {
    this.storage = storage;
    this.key = "tf6:u";
  }

  async getAll() {
    return (await this.storage.getJSON(this.key)) || {};
  }

  async saveAll(users) {
    await this.storage.setJSON(this.key, users);
  }

  async findByEmail(email) {
    const users = await this.getAll();
    return Object.values(users).find((u) => u.email === email) || null;
  }

  async upsert(user) {
    const users = await this.getAll();
    users[user.id] = user;
    await this.saveAll(users);
    return user;
  }
}

class JobRepository {
  constructor(storage) {
    this.storage = storage;
    this.key = "tf6:j";
  }

  async getAll() {
    return (await this.storage.getJSON(this.key)) || {};
  }

  async saveAll(jobs) {
    await this.storage.setJSON(this.key, jobs);
  }

  async seedIfEmpty(seedJobs) {
    const jobs = await this.getAll();
    if (Object.keys(jobs).length) return jobs;

    const seeded = {};
    seedJobs.forEach((job) => {
      seeded[job.id] = job;
    });

    await this.saveAll(seeded);
    return seeded;
  }
}

class ApplicationRepository {
  constructor(storage) {
    this.storage = storage;
    this.key = "tf6:a";
  }

  async getAll() {
    return (await this.storage.getJSON(this.key)) || {};
  }

  async saveAll(apps) {
    await this.storage.setJSON(this.key, apps);
  }

  async create(app) {
    const apps = await this.getAll();
    apps[app.id] = app;
    await this.saveAll(apps);
    return app;
  }
}

class StorageAdapter {
  get backend() {
    if (typeof window !== "undefined" && window.storage) return "window";
    return "local";
  }

  async getJSON(key) {
    try {
      if (this.backend === "window") {
        const r = await window.storage.get(key);
        return r ? JSON.parse(r.value) : null;
      }
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  async setJSON(key, value) {
    const raw = JSON.stringify(value);
    if (this.backend === "window") {
      await window.storage.set(key, raw);
      return;
    }
    localStorage.setItem(key, raw);
  }

  async delete(key) {
    if (this.backend === "window") {
      await window.storage.delete(key);
      return;
    }
    localStorage.removeItem(key);
  }
}

export function buildServices() {
  const storage = new StorageAdapter();

  return {
    storage,
    sessionRepo: new SessionRepository(storage),
    userRepo: new UserRepository(storage),
    jobRepo: new JobRepository(storage),
    appRepo: new ApplicationRepository(storage),
  };
}
