# Vanity

纯前端的美妆藏品管理界面：React + Vite，无需后端、数据库或账户，藏品直接保存在当前浏览器中。

- `frontend/`：界面、图片资源与构建配置。
- `docs/previews/`：界面截图。

## 本地开发

```powershell
npm --prefix frontend ci
npm run dev
```

打开 http://localhost:5173。开发服务器不需要任何后端进程。

## 构建与托管

```powershell
npm run build
npm run preview
```

构建产物输出到 `frontend/dist/`，可以直接托管为静态站点。产物不发起任何 `/api` 请求，不需要反向代理或数据库。

## 数据存放与限制

- 藏品保存在当前浏览器的 `localStorage`（键名 `vanity.collection.v2`），主题偏好保存在 `vanity.theme`。
- 数据不跨浏览器、不跨设备、不同步；更换浏览器、使用隐私模式或清理站点数据后藏品不会保留。
- 若浏览器禁止站点存储，界面仍可临时使用，但关闭页面后数据会丢失，页面底部会持续提示。
- 旧版本的本地藏品（`vanity.collection.v1`）不会被自动覆盖。若页面底部出现「此浏览器有 N 件旧藏品」，点击「导入此浏览器的藏品」即可按 `id` 合并去重导入；旧数据保持原样。