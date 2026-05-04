import { contextBridge, ipcRenderer } from 'electron';
import type {
  ApplyModelTemplatePayload,
  DesktopBridge,
  InstallProviderPayload,
  WorkspaceSavePayload,
} from '../shared/contracts.js';

const api: DesktopBridge = {
  loadWorkspace: () => ipcRenderer.invoke('workspace:load'),
  saveWorkspace: (payload: WorkspaceSavePayload) => ipcRenderer.invoke('workspace:save', payload),
  seedTemplates: () => ipcRenderer.invoke('workspace:seed'),
  openWorkspaceDirectory: () => ipcRenderer.invoke('workspace:open-workspace-directory'),
  installProvider: (payload: InstallProviderPayload) => ipcRenderer.invoke('workspace:install-provider', payload),
  checkProviderInstalled: (payload: InstallProviderPayload) => ipcRenderer.invoke('workspace:check-provider-installed', payload),
  getModelTemplate: (payload: ApplyModelTemplatePayload) => ipcRenderer.invoke('workspace:model-template', payload),
  installEnvironment: () => ipcRenderer.invoke('workspace:install-environment'),
};

contextBridge.exposeInMainWorld('modelDesktop', api);
