import { app, BrowserWindow } from 'electron';
import { join } from 'node:path';
import { registerDesktopHandlers } from './services/app-config.js';

function createWindow() {
  const window = new BrowserWindow({
    width: 1420,
    height: 920,
    minWidth: 1200,
    minHeight: 760,
    backgroundColor: '#f4efe4',
    title: 'Model Desktop Manager',
    webPreferences: {
      preload: join(__dirname, '../preload/index.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  if (process.env.ELECTRON_RENDERER_URL) {
    void window.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    void window.loadFile(join(__dirname, '../renderer/index.html'));
  }
}

app.whenReady().then(() => {
  registerDesktopHandlers();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
