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
  const sessionRepo = new SessionRepository(storage);

  return {
    storage,
    sessionRepo,
  };
}