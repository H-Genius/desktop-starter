import { homedir } from 'node:os';
import { join } from 'node:path';

export function resolveWorkspaceHome() {
  return process.env.MODEL_DESKTOP_HOME || process.env.CODEX_HOME || join(homedir(), '.codex');
}

export function resolveManagedFiles(workspaceHome: string) {
  return {
    authPath: join(workspaceHome, 'auth.json'),
    configPath: join(workspaceHome, 'config.toml'),
  };
}
