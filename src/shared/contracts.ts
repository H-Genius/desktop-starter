export type DesktopPlatform = 'darwin' | 'linux' | 'win32';

export type ProviderModelOption = {
  id: string;
  name: string;
  description: string;
  supportedPlatforms: DesktopPlatform[];
  requirements?: string[];
  scriptFile?: string;
  authTemplate?: string;
  configTemplate?: string;
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

export type WorkspaceSnapshot = {
  platform: DesktopPlatform;
  workspaceHome: string;
  environmentPrerequisites: string[];
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

export type GitBashStatus = {
  available: boolean;
  path: string | null;
};

export type DesktopBridge = {
  loadWorkspace: () => Promise<WorkspaceSnapshot>;
  saveWorkspace: (payload: WorkspaceSavePayload) => Promise<WorkspaceSnapshot>;
  seedTemplates: () => Promise<WorkspaceSnapshot>;
  openWorkspaceDirectory: () => Promise<void>;
  installProvider: (payload: InstallProviderPayload) => Promise<void>;
  getModelTemplate: (payload: ApplyModelTemplatePayload) => Promise<ModelTemplatePayload>;
  checkGitBash: () => Promise<GitBashStatus>;
  installGitBash: () => Promise<void>;
};
