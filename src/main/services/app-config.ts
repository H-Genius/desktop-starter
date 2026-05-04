import { mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { spawn } from 'node:child_process';
import { app, ipcMain, shell, type IpcMainInvokeEvent } from 'electron';
import type {
  ApplyModelTemplatePayload,
  DesktopPlatform,
  EnvironmentRequirementStatus,
  InstallProviderPayload,
  ModelTemplatePayload,
  ProviderInstallStatus,
  ProviderModelOption,
  ProviderManifest,
  WorkspaceSavePayload,
  WorkspaceSnapshot,
} from '../../shared/contracts.js';
import { resolveManagedFiles, resolveWorkspaceHome } from './workspace-home.js';

const ENVIRONMENT_PREREQUISITES = [
  'uv：Python 包管理器',
  'miniconda：Python 包管理器',
  'nvm：Node.js 版本管理器',
  'bun：JavaScript 运行时与包管理器',
  'nodejs',
  'homebrew：macOS 包管理器',
];

const ENVIRONMENT_REQUIREMENTS: Array<{
  id: string;
  label: string;
  command: string;
  args?: string[];
  platforms?: DesktopPlatform[];
}> = [
  { id: 'uv', label: 'uv：Python 包管理器', command: 'uv', args: ['--version'] },
  { id: 'miniconda', label: 'miniconda：Python 包管理器', command: 'conda', args: ['--version'] },
  { id: 'nvm', label: 'nvm：Node.js 版本管理器', command: 'nvm', args: ['--version'], platforms: ['darwin', 'linux'] },
  { id: 'bun', label: 'bun：JavaScript 运行时与包管理器', command: 'bun', args: ['--version'] },
  { id: 'nodejs', label: 'nodejs', command: 'node', args: ['--version'] },
  { id: 'homebrew', label: 'homebrew：macOS 包管理器', command: 'brew', args: ['--version'], platforms: ['darwin'] },
];

function getResourcesRoot() {
  return app.isPackaged ? process.resourcesPath : join(app.getAppPath(), 'resources');
}

function getScriptsRoot() {
  return join(getResourcesRoot(), 'scripts');
}

function resolveDesktopPlatform(): DesktopPlatform {
  switch (process.platform) {
    case 'darwin':
    case 'linux':
    case 'win32':
      return process.platform;
    default:
      return 'linux';
  }
}

async function fileExists(path: string) {
  try {
    await stat(path);
    return true;
  } catch {
    return false;
  }
}

async function readOptionalFile(path: string) {
  if (!(await fileExists(path))) {
    return '';
  }

  return readFile(path, 'utf8');
}

function isValidJson(content: string) {
  if (!content.trim()) {
    return false;
  }

  try {
    JSON.parse(content);
    return true;
  } catch {
    return false;
  }
}

async function loadProviders() {
  const providersDir = join(getResourcesRoot(), 'providers');
  const files = await readdir(providersDir);
  const manifests: ProviderManifest[] = [];

  for (const file of files) {
    if (!file.endsWith('.json')) {
      continue;
    }

    const raw = await readFile(join(providersDir, file), 'utf8');
    manifests.push(JSON.parse(raw) as ProviderManifest);
  }

  return manifests.sort((left, right) => left.name.localeCompare(right.name));
}

async function buildSnapshot(): Promise<WorkspaceSnapshot> {
  const platform = resolveDesktopPlatform();
  const workspaceHome = resolveWorkspaceHome();
  const { authPath, configPath } = resolveManagedFiles(workspaceHome);
  const [authExists, configExists, authContent, configContent, providers, environmentStatuses] = await Promise.all([
    fileExists(authPath),
    fileExists(configPath),
    readOptionalFile(authPath),
    readOptionalFile(configPath),
    loadProviders(),
    detectEnvironmentStatuses(platform),
  ]);

  return {
    platform,
    workspaceHome,
    environmentPrerequisites: ENVIRONMENT_PREREQUISITES,
    environmentStatuses,
    auth: {
      path: authPath,
      exists: authExists,
      content: authContent,
    },
    config: {
      path: configPath,
      exists: configExists,
      content: configContent,
    },
    providers,
    authValidJson: isValidJson(authContent),
  };
}

async function ensureWorkspaceHome() {
  await mkdir(resolveWorkspaceHome(), { recursive: true });
}

async function copyTemplateIfMissing(targetPath: string, templateName: string) {
  if (await fileExists(targetPath)) {
    return;
  }

  const templatePath = join(getResourcesRoot(), 'templates', templateName);
  const content = await readFile(templatePath, 'utf8');
  await writeFile(targetPath, content, 'utf8');
}

async function seedTemplates() {
  const workspaceHome = resolveWorkspaceHome();
  const { authPath, configPath } = resolveManagedFiles(workspaceHome);
  await ensureWorkspaceHome();
  await copyTemplateIfMissing(authPath, 'auth.example.json');
  await copyTemplateIfMissing(configPath, 'config.example.toml');
  return buildSnapshot();
}

async function saveWorkspace(payload: WorkspaceSavePayload) {
  const workspaceHome = resolveWorkspaceHome();
  const { authPath, configPath } = resolveManagedFiles(workspaceHome);
  await ensureWorkspaceHome();
  await writeFile(authPath, payload.authContent, 'utf8');
  await writeFile(configPath, payload.configContent, 'utf8');
  return buildSnapshot();
}

async function openWorkspaceDirectory() {
  await ensureWorkspaceHome();
  await shell.openPath(resolveWorkspaceHome());
}

function openMacTerminal(scriptPath: string) {
  const command = `chmod +x "${scriptPath}"; bash "${scriptPath}"`;
  const child = spawn('osascript', ['-e', `tell application "Terminal" to do script ${JSON.stringify(command)}`], {
    detached: true,
    stdio: 'ignore',
  });
  child.unref();
}

function openWindowsBatScript(scriptPath: string, elevated = false) {
  const normalizedPath = scriptPath.replace(/\//g, '\\');

  const child = elevated
    ? spawn(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          `Start-Process cmd.exe -Verb RunAs -ArgumentList '/k','"${normalizedPath}"'`,
        ],
        {
          detached: true,
          stdio: 'ignore',
        }
      )
    : spawn('cmd.exe', ['/c', 'start', '"Model Installer"', 'cmd.exe', '/k', normalizedPath], {
        detached: true,
        stdio: 'ignore',
      });

  child.unref();
}

function resolveScriptPath(scriptBaseName: string, platform: DesktopPlatform): string {
  const extension = platform === 'win32' ? '.bat' : '.sh';
  return join(getScriptsRoot(), `${scriptBaseName}${extension}`);
}

async function commandInPath(command: string) {
  try {
    const result = await execCommand('bash', ['-lc', `command -v ${JSON.stringify(command)} >/dev/null 2>&1`]);
    return result.code === 0;
  } catch {
    return false;
  }
}

async function openLinuxTerminal(scriptPath: string) {
  const terminalCommand = `chmod +x "${scriptPath}" && bash "${scriptPath}"`;
  const launchers: Array<[string, string[]]> = [
    ['x-terminal-emulator', ['-e', 'bash', '-lc', terminalCommand]],
    ['gnome-terminal', ['--', 'bash', '-lc', terminalCommand]],
    ['konsole', ['-e', 'bash', '-lc', terminalCommand]],
    ['xfce4-terminal', ['-e', `bash -lc '${terminalCommand.replace(/'/g, "'\\''")}'`]],
  ];

  let lastError: unknown;

  for (const [command, args] of launchers) {
    if (!(await commandInPath(command))) {
      continue;
    }

    try {
      const child = spawn(command, args, {
        detached: true,
        stdio: 'ignore',
      });

      child.on('error', () => {
        // No-op. Failure is handled by the fallback loop.
      });
      child.unref();
      return;
    } catch (error) {
      lastError = error;
    }
  }

  throw new Error(`Unable to launch a terminal for model installation. ${String(lastError ?? '')}`.trim());
}

function execCommand(command: string, args: string[]) {
  return new Promise<{ code: number | null; stdout: string; stderr: string }>((resolve, reject) => {
    const child = spawn(command, args, {
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += String(chunk);
    });

    child.stderr.on('data', (chunk) => {
      stderr += String(chunk);
    });

    child.on('error', reject);
    child.on('close', (code) => {
      resolve({ code, stdout, stderr });
    });
  });
}

async function commandExists(command: string, args: string[] = ['--version']) {
  try {
    const result = await execCommand(command, args);
    return result.code === 0;
  } catch {
    return false;
  }
}

async function detectNvmInstalled() {
  try {
    const result = await execCommand('bash', [
      '-lc',
      'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; command -v nvm >/dev/null 2>&1',
    ]);
    return result.code === 0;
  } catch {
    return false;
  }
}

async function detectEnvironmentStatuses(platform: DesktopPlatform): Promise<EnvironmentRequirementStatus[]> {
  const statuses = await Promise.all(
    ENVIRONMENT_REQUIREMENTS.map(async (requirement) => {
      const applicable = !requirement.platforms || requirement.platforms.includes(platform);

      if (!applicable) {
        return {
          id: requirement.id,
          label: requirement.label,
          applicable: false,
          installed: true,
        };
      }

      const installed =
        requirement.id === 'nvm'
          ? await detectNvmInstalled()
          : await commandExists(requirement.command, requirement.args);

      return {
        id: requirement.id,
        label: requirement.label,
        applicable: true,
        installed,
      };
    })
  );

  return statuses;
}

function assertModelSupport(option: ProviderModelOption) {
  const platform = resolveDesktopPlatform();

  if (!option.supportedPlatforms.includes(platform)) {
    throw new Error(`当前平台 ${platform} 不支持安装 ${option.name}。`);
  }
}

async function findInstallTarget(payload: InstallProviderPayload) {
  const providers = await loadProviders();
  const provider = providers.find((item) => item.id === payload.providerId);

  if (!provider) {
    throw new Error(`Provider not found: ${payload.providerId}`);
  }

  const option = provider.modelOptions?.find((item) => item.id === payload.modelOptionId);

  if (!option) {
    throw new Error(`Model option not found: ${payload.modelOptionId}`);
  }

  return { provider, option };
}

async function getModelTemplate(payload: ApplyModelTemplatePayload): Promise<ModelTemplatePayload> {
  const { option } = await findInstallTarget(payload);

  if (!option.authTemplate && !option.configTemplate) {
    throw new Error(`当前模型目标没有可套用的配置模板: ${option.name}`);
  }

  return {
    authContent: option.authTemplate ?? '',
    configContent: option.configTemplate ?? '',
  };
}

async function checkProviderInstalled(payload: InstallProviderPayload): Promise<ProviderInstallStatus> {
  const { option } = await findInstallTarget(payload);

  if (!option.checkCommand) {
    return {
      providerId: payload.providerId,
      modelOptionId: payload.modelOptionId,
      installed: false,
    };
  }

  // 检查命令是否存在
  const installed = await commandExists(option.checkCommand, ['--version']);

  // 如果已安装，尝试获取版本
  let version: string | undefined;
  if (installed) {
    try {
      const result = await execCommand(option.checkCommand, ['--version']);
      // 取第一行作为版本信息
      version = result.stdout.split('\n')[0].trim() || undefined;
    } catch {
      // 版本获取失败不影响已安装状态
    }
  }

  return {
    providerId: payload.providerId,
    modelOptionId: payload.modelOptionId,
    installed,
    version,
  };
}

async function installProvider(payload: InstallProviderPayload) {
  const { option } = await findInstallTarget(payload);
  assertModelSupport(option);

  if (!option.scriptFile) {
    throw new Error(`当前模型目标没有脚本文件: ${option.name}`);
  }

  const platform = resolveDesktopPlatform();
  const scriptPath = resolveScriptPath(option.scriptFile, platform);

  if (platform === 'win32') {
    // Windows 直接执行 .bat 脚本
    openWindowsBatScript(scriptPath);
    return;
  }

  if (platform === 'darwin') {
    openMacTerminal(scriptPath);
    return;
  }

  await openLinuxTerminal(scriptPath);
}

async function installEnvironment() {
  const platform = resolveDesktopPlatform();
  const scriptPath = resolveScriptPath('install', platform);

  if (platform === 'win32') {
    openWindowsBatScript(scriptPath, true);
    return;
  }

  if (platform === 'darwin') {
    openMacTerminal(scriptPath);
    return;
  }

  await openLinuxTerminal(scriptPath);
}

export function registerDesktopHandlers() {
  ipcMain.handle('workspace:load', () => buildSnapshot());
  ipcMain.handle('workspace:save', (_event: IpcMainInvokeEvent, payload: WorkspaceSavePayload) =>
    saveWorkspace(payload)
  );
  ipcMain.handle('workspace:seed', () => seedTemplates());
  ipcMain.handle('workspace:open-workspace-directory', () => openWorkspaceDirectory());
  ipcMain.handle('workspace:install-provider', (_event: IpcMainInvokeEvent, payload: InstallProviderPayload) =>
    installProvider(payload)
  );
  ipcMain.handle('workspace:check-provider-installed', (_event: IpcMainInvokeEvent, payload: InstallProviderPayload) =>
    checkProviderInstalled(payload)
  );
  ipcMain.handle('workspace:model-template', (_event: IpcMainInvokeEvent, payload: ApplyModelTemplatePayload) =>
    getModelTemplate(payload)
  );
  ipcMain.handle('workspace:install-environment', () => installEnvironment());
}
