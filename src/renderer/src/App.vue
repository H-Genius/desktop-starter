<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import type { GitBashStatus, ProviderManifest, ProviderModelOption, WorkspaceSnapshot } from '../../shared/contracts.js';

const snapshot = ref<WorkspaceSnapshot | null>(null);
const authContent = ref('');
const configContent = ref('');
const saveState = ref<'idle' | 'saving' | 'saved'>('idle');
const notice = ref('准备就绪。');
const selectedProviderId = ref('');
const selectedInstallOptionId = ref('');
const gitBashStatus = ref<GitBashStatus | null>(null);

const installableProviders = computed<ProviderManifest[]>(() => {
  const platform = snapshot.value?.platform;
  const providers = snapshot.value?.providers ?? [];

  if (!platform) {
    return [];
  }

  return providers.filter((provider) =>
    (provider.modelOptions ?? []).some((option) => option.supportedPlatforms.includes(platform))
  );
});
const selectedProvider = computed<ProviderManifest | null>(() => {
  if (!snapshot.value || !selectedProviderId.value) {
    return null;
  }

  return installableProviders.value.find((provider) => provider.id === selectedProviderId.value) ?? null;
});
const availableModelOptions = computed<ProviderModelOption[]>(() => {
  const platform = snapshot.value?.platform;
  const options = selectedProvider.value?.modelOptions ?? [];

  if (!platform) {
    return [];
  }

  return options.filter((option) => option.supportedPlatforms.includes(platform));
});
const selectedModelOption = computed<ProviderModelOption | null>(() => {
  if (!selectedInstallOptionId.value) {
    return null;
  }

  return availableModelOptions.value.find((option) => option.id === selectedInstallOptionId.value) ?? null;
});
const canApplyTemplate = computed(() => {
  return Boolean(selectedModelOption.value?.authTemplate || selectedModelOption.value?.configTemplate);
});
const isWindows = computed(() => snapshot.value?.platform === 'win32');
const terminalEnvironmentLabel = computed(() => {
  if (isWindows.value) {
    return 'Windows Git Bash';
  }

  if (snapshot.value?.platform === 'darwin') {
    return 'macOS 终端环境';
  }

  return 'Linux 终端环境';
});
const authStatus = computed(() => {
  if (!snapshot.value) {
    return '未加载';
  }

  if (!snapshot.value.auth.exists) {
    return '未创建';
  }

  return snapshot.value.authValidJson ? 'JSON 有效' : 'JSON 待修正';
});

async function refreshGitBashStatus() {
  if (!isWindows.value) {
    gitBashStatus.value = null;
    return;
  }

  gitBashStatus.value = await window.modelDesktop.checkGitBash();
}

async function refreshWorkspace() {
  const next = await window.modelDesktop.loadWorkspace();
  snapshot.value = next;
  authContent.value = next.auth.content;
  configContent.value = next.config.content;

  if (!selectedProviderId.value || !next.providers.some((provider) => provider.id === selectedProviderId.value)) {
    const providerWithInstall = next.providers.find((provider) =>
      (provider.modelOptions ?? []).some((option) => option.supportedPlatforms.includes(next.platform))
    );
    selectedProviderId.value = providerWithInstall?.id ?? '';
  }

  const nextOptions =
    next.providers.find((provider) => provider.id === selectedProviderId.value)?.modelOptions?.filter((option) =>
      option.supportedPlatforms.includes(next.platform)
    ) ?? [];

  if (!nextOptions.some((option) => option.id === selectedInstallOptionId.value)) {
    selectedInstallOptionId.value = nextOptions[0]?.id ?? '';
  }

  await refreshGitBashStatus();
}

async function saveWorkspace() {
  saveState.value = 'saving';
  notice.value = '正在写入 auth.json 和 config.toml ...';

  try {
    const next = await window.modelDesktop.saveWorkspace({
      authContent: authContent.value,
      configContent: configContent.value,
    });
    snapshot.value = next;
    saveState.value = 'saved';
    notice.value = '写入完成。';
  } catch (error) {
    saveState.value = 'idle';
    notice.value = `写入失败: ${String(error)}`;
  }
}

async function seedTemplates() {
  const next = await window.modelDesktop.seedTemplates();
  snapshot.value = next;
  authContent.value = next.auth.content;
  configContent.value = next.config.content;
  notice.value = '已写入示例模板。';
}

async function openWorkspaceDirectory() {
  await window.modelDesktop.openWorkspaceDirectory();
}

async function installGitBash() {
  notice.value = '正在打开 Git Bash 安装窗口...';

  try {
    await window.modelDesktop.installGitBash();
    notice.value = '已调起 Git Bash 安装窗口，安装完成后请点刷新。';
  } catch (error) {
    notice.value = `无法启动 Git Bash 安装: ${String(error)}`;
  }
}

async function installSelectedModel() {
  if (!selectedProvider.value || !selectedModelOption.value) {
    notice.value = '当前没有可执行的模型脚本。';
    return;
  }

  notice.value = `正在打开终端执行 ${selectedModelOption.value.name} 脚本...`;

  try {
    await window.modelDesktop.installProvider({
      providerId: selectedProvider.value.id,
      modelOptionId: selectedModelOption.value.id,
    });
    notice.value =
      `已调起系统终端，请在终端窗口中执行 ${selectedModelOption.value.name} 脚本。`;
  } catch (error) {
    notice.value = `无法执行模型目标动作: ${String(error)}`;
  }
}

async function applySelectedModelTemplate() {
  if (!selectedProvider.value || !selectedModelOption.value) {
    notice.value = '当前没有可套用的模型模板。';
    return;
  }

  try {
    const template = await window.modelDesktop.getModelTemplate({
      providerId: selectedProvider.value.id,
      modelOptionId: selectedModelOption.value.id,
    });

    if (template.authContent) {
      authContent.value = template.authContent;
    }

    if (template.configContent) {
      configContent.value = template.configContent;
    }

    notice.value = `已将 ${selectedModelOption.value.name} 的配置模板填入编辑区，请确认后保存。`;
  } catch (error) {
    notice.value = `无法套用模型模板: ${String(error)}`;
  }
}

onMounted(() => {
  void refreshWorkspace();
});

watch(selectedProviderId, () => {
  selectedInstallOptionId.value = availableModelOptions.value[0]?.id ?? '';
});
</script>

<template>
  <div class="shell">
    <aside class="sidebar">
      <div class="hero">
        <p class="eyebrow">Desktop Starter</p>
      </div>

      <div class="panel">
        <div class="panel-head">
          <span>工作区</span>
          <strong>{{ snapshot?.platform ?? '--' }}</strong>
        </div>
        <dl v-if="snapshot" class="facts">
          <div>
            <dt>配置目录</dt>
            <dd>{{ snapshot.workspaceHome }}</dd>
          </div>
          <div>
            <dt>auth.json</dt>
            <dd>{{ authStatus }}</dd>
          </div>
          <div>
            <dt>config.toml</dt>
            <dd>{{ snapshot.config.exists ? '已存在' : '未创建' }}</dd>
          </div>
        </dl>
      </div>

      <div class="panel">
        <div class="panel-head">
          <span>环境前提</span>
          <strong>{{ snapshot?.environmentPrerequisites.length ?? 0 }} items</strong>
        </div>
        <div class="requirements">
          <ul>
            <li v-for="item in snapshot?.environmentPrerequisites ?? []" :key="item">{{ item }}</li>
          </ul>
        </div>
      </div>

      <div class="panel">
        <div class="panel-head">
          <span>模型安装</span>
          <strong>{{ snapshot?.platform ?? '--' }}</strong>
        </div>
        <div class="install-form">
          <div class="requirements">
            <p>{{ terminalEnvironmentLabel }}</p>
            <ul>
              <li v-if="isWindows && gitBashStatus?.available">已检测到 Git Bash{{ gitBashStatus.path ? `：${gitBashStatus.path}` : '' }}</li>
              <li v-else-if="isWindows">未检测到 Git Bash，Windows 下执行 `.sh` 脚本前需要先安装。</li>
              <li v-else>当前系统已自带 Bash / Terminal，可直接执行安装脚本。</li>
            </ul>
            <button
              v-if="isWindows && !gitBashStatus?.available"
              class="ghost install-button"
              @click="installGitBash"
            >
              安装 Git Bash
            </button>
          </div>

          <label>
            <span>提供方</span>
            <select v-model="selectedProviderId">
              <option
                v-for="provider in installableProviders"
                :key="provider.id"
                :value="provider.id"
              >
                {{ provider.name }}
              </option>
            </select>
          </label>

          <label>
            <span>模型目标</span>
            <select v-model="selectedInstallOptionId">
              <option
                v-for="option in availableModelOptions"
                :key="option.id"
                :value="option.id"
              >
                {{ option.name }}
              </option>
            </select>
          </label>

          <p class="install-description">
            {{ selectedModelOption?.description ?? '当前提供方没有适用于此平台的模型目标。' }}
          </p>

          <div v-if="selectedModelOption?.requirements?.length" class="requirements">
            <p>额外前提</p>
            <ul>
              <li v-for="item in selectedModelOption.requirements" :key="item">{{ item }}</li>
            </ul>
          </div>

          <button class="primary install-button" :disabled="!selectedModelOption" @click="installSelectedModel">
            执行安装脚本
          </button>
          <button class="ghost install-button" :disabled="!canApplyTemplate" @click="applySelectedModelTemplate">
            套用到配置
          </button>
        </div>
      </div>
    </aside>

    <main class="workspace">
      <header class="toolbar">
        <div>
          <p class="eyebrow">配置编辑</p>
          <h2>模型配置目录</h2>
        </div>
        <div class="toolbar-actions">
          <button class="ghost" @click="refreshWorkspace">刷新</button>
          <button class="ghost" @click="seedTemplates">写入模板</button>
          <button class="ghost" @click="openWorkspaceDirectory">打开目录</button>
          <button class="primary" @click="saveWorkspace">
            {{ saveState === 'saving' ? '保存中...' : '保存文件' }}
          </button>
        </div>
      </header>

      <p class="notice">{{ notice }}</p>

      <section class="editor-grid">
        <article class="editor-card">
          <div class="editor-head">
            <div>
              <p class="eyebrow">JSON</p>
              <h3>auth.json</h3>
            </div>
            <span class="chip">{{ authStatus }}</span>
          </div>
          <p class="path">{{ snapshot?.auth.path }}</p>
          <textarea
            v-model="authContent"
            spellcheck="false"
          />
        </article>

        <article class="editor-card">
          <div class="editor-head">
            <div>
              <p class="eyebrow">TOML</p>
              <h3>config.toml</h3>
            </div>
            <span class="chip">{{ snapshot?.config.exists ? '已加载' : '待创建' }}</span>
          </div>
          <p class="path">{{ snapshot?.config.path }}</p>
          <textarea
            v-model="configContent"
            spellcheck="false"
          />
        </article>
      </section>
    </main>
  </div>
</template>
