export type DesktopPlatform = 'darwin' | 'linux' | 'win32';

export type ProviderModelOption = {
  id: string;
  name: string;
  description: string;
  supportedPlatforms: DesktopPlatform[];
  requirements?: string[];
  scriptFile?: string;
  checkCommand?: string;  // 用于检查是否已安装的命令，如 'qwen'、'codex'
  authTemplate?: string;
  configTemplate?: string;
};

export type ProviderInstallStatus = {
  providerId: string;
  modelOptionId: string;
  installed: boolean;
  version?: string;
};

export type ProviderManifest = {
  id: string;
  name: string;
  vendor: string;
  description: string;
  homepage?: string;
  tags: string[];
  managedFiles: string[];
  modelOptions?: ProviderModelOption[];
};

export type ManagedFileState = {
  path: string;
  exists: boolean;
  content: string;
};

export type EnvironmentRequirementStatus = {
  id: string;
  label: string;
  applicable: boolean;
  installed: boolean;
};

export type WorkspaceSnapshot = {
  platform: DesktopPlatform;
  workspaceHome: string;
  environmentPrerequisites: string[];
  environmentStatuses: EnvironmentRequirementStatus[];
  auth: ManagedFileState;
  config: ManagedFileState;
  providers: ProviderManifest[];
  authValidJson: boolean;
};

export type WorkspaceSavePayload = {
  authContent: string;
  configContent: string;
};

export type InstallProviderPayload = {
  providerId: string;
  modelOptionId: string;
};

export type ApplyModelTemplatePayload = {
  providerId: string;
  modelOptionId: string;
};

export type ModelTemplatePayload = {
  authContent: string;
  configContent: string;
};

export type DesktopBridge = {
  loadWorkspace: () => Promise<WorkspaceSnapshot>;
  saveWorkspace: (payload: WorkspaceSavePayload) => Promise<WorkspaceSnapshot>;
  seedTemplates: () => Promise<WorkspaceSnapshot>;
  openWorkspaceDirectory: () => Promise<void>;
  installProvider: (payload: InstallProviderPayload) => Promise<void>;
  checkProviderInstalled: (payload: InstallProviderPayload) => Promise<ProviderInstallStatus>;
  getModelTemplate: (payload: ApplyModelTemplatePayload) => Promise<ModelTemplatePayload>;
  installEnvironment: () => Promise<void>;
};
