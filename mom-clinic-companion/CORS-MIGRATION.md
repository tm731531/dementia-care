# iDempiere CORS Filter — Production Migration Guide

**目的**：讓 GitHub Pages 上的就診小幫手（跟其他未來的前端）可以跨域呼叫 iDempiere REST API。

**實測背景**：
- 瀏覽器從 `https://tm731531.github.io` fetch 到 `https://idempiere.tomting.com/api/v1/*` 會被 CORS policy 擋
- Preflight (OPTIONS) 200 回來但沒有 `Access-Control-Allow-Origin` header
- TrekGlobal REST API plugin **沒有內建 CORS**（bytecode 掃過確認）
- 解法：用 Jetty 內建的 `CrossOriginFilter`（class 已在 classpath，不用裝 jar）

---

## 要改的檔案

```
<IDEMPIERE_HOME>/plugins/com.trekglobal.idempiere.rest.api_0.1.0.202601201427/WEB-INF/web.xml
```

**注意**：plugin 資料夾版本號可能不同（例如不是 `0.1.0.202601201427`），先 `ls $IDEMPIERE_HOME/plugins/ | grep trekglobal.idempiere.rest.api` 確認。

**權限**：通常是 root 擁有，需要 `sudo`。

---

## 操作步驟

### 1. 備份原檔

```bash
IDEMPIERE_HOME=/opt/idempiere-server/x86_64
PLUGIN_DIR=$(ls -d $IDEMPIERE_HOME/plugins/com.trekglobal.idempiere.rest.api_* | head -1)
WEB_XML=$PLUGIN_DIR/WEB-INF/web.xml

sudo cp $WEB_XML ${WEB_XML}.bak.$(date +%Y%m%d-%H%M%S)
ls -la $PLUGIN_DIR/WEB-INF/
```

### 2. 用新版本覆蓋

把下面整段寫成一個檔案（例如 `/tmp/web.xml.new`），然後覆蓋：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">

    <!-- ================================================================ -->
    <!-- CORS filter (added 2026-04-21)                                   -->
    <!-- To add/remove origins: edit allowedOrigins param below.          -->
    <!-- Must restart iDempiere for changes to take effect.               -->
    <!-- ================================================================ -->
    <filter>
        <filter-name>cross-origin</filter-name>
        <filter-class>org.eclipse.jetty.ee8.servlets.CrossOriginFilter</filter-class>
        <init-param>
            <param-name>allowedOrigins</param-name>
            <param-value>https://tm731531.github.io,http://localhost:8787,http://127.0.0.1:8787,http://localhost:8000,http://127.0.0.1:8000</param-value>
        </init-param>
        <init-param>
            <param-name>allowedMethods</param-name>
            <param-value>GET,POST,PUT,DELETE,OPTIONS,HEAD</param-value>
        </init-param>
        <init-param>
            <param-name>allowedHeaders</param-name>
            <param-value>Authorization,Content-Type,Accept,Origin,X-Requested-With</param-value>
        </init-param>
        <init-param>
            <param-name>exposedHeaders</param-name>
            <param-value>Content-Disposition</param-value>
        </init-param>
        <init-param>
            <param-name>preflightMaxAge</param-name>
            <param-value>86400</param-value>
        </init-param>
        <init-param>
            <param-name>allowCredentials</param-name>
            <param-value>false</param-value>
        </init-param>
        <init-param>
            <param-name>chainPreflight</param-name>
            <param-value>false</param-value>
        </init-param>
    </filter>
    <filter-mapping>
        <filter-name>cross-origin</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>

    <servlet>
        <servlet-name>com.trekglobal.idempiere.rest.api.v1.ApplicationV1</servlet-name>
        <servlet-class>org.glassfish.jersey.servlet.ServletContainer</servlet-class>
        <init-param>
            <param-name>javax.ws.rs.Application</param-name>
            <param-value>com.trekglobal.idempiere.rest.api.v1.ApplicationV1</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>com.trekglobal.idempiere.rest.api.v1.ApplicationV1</servlet-name>
        <url-pattern>/*</url-pattern>
    </servlet-mapping>
</web-app>
```

```bash
sudo cp /tmp/web.xml.new $WEB_XML
sudo diff ${WEB_XML}.bak.* $WEB_XML | head -50   # sanity check
```

### 3. 重啟 iDempiere

**依你啟動方式**，常見選一：

```bash
# systemd
sudo systemctl restart idempiere

# 或 init.d 腳本
sudo $IDEMPIERE_HOME/idempiere-server.sh stop
sudo $IDEMPIERE_HOME/idempiere-server.sh start

# 或用你既有腳本
cd $IDEMPIERE_HOME && sudo ./stop.sh && sudo ./start.sh
```

等 Jetty 完全啟動（看 log 看到 `Server ready`），通常 30-60 秒。

### 4. 驗證

**測 A：curl OPTIONS preflight 應回 CORS header**

```bash
curl -s -i -X OPTIONS https://idempiere.tomting.com/api/v1/auth/tokens \
  -H "Origin: https://tm731531.github.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" | head -20
```

**預期看到**：
```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://tm731531.github.io
Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS,HEAD
Access-Control-Allow-Headers: Authorization,Content-Type,Accept,Origin,X-Requested-With
Access-Control-Max-Age: 86400
```

**測 B：從 GitHub Pages 實際瀏覽器打**

<https://tm731531.github.io/dementia-care/mom-clinic-companion/>

登入 Tom / Tom，預期看到「載入中」或實際資料，**不再是「網路錯誤: Failed to fetch」**。

---

## 回退（如出事）

```bash
sudo cp ${WEB_XML}.bak.20260421-124909 $WEB_XML    # 用你剛剛備份的時間戳
sudo systemctl restart idempiere
```

---

## 加新的 origin（未來）

例如未來想加一個 staging domain `https://preview.tomting.com`：

1. `sudo nano $WEB_XML`
2. 在 `<param-name>allowedOrigins</param-name>` 下面那行 `<param-value>…</param-value>` 加上逗號跟新 origin
3. 存檔 → 重啟 iDempiere

---

## 安全注意

- **不要用 `*` 作為 allowedOrigins**（等於開放所有網站都能打你的 API，即使有 Bearer token 驗證也不建議）
- **不要開 `allowCredentials=true`** 除非真的要讓 cookie 跨域流動（這個系統用 Bearer token 就夠）
- **新 origin 加入前想一下**：這個 domain 你信任嗎？會不會被人拿去掛釣魚頁？

---

## Troubleshooting

**重啟後 curl 還是沒 CORS header**:
- 檢查 iDempiere 真的有重啟（`ps aux | grep idempiere` 看 PID 有換）
- 檢查 plugin 版本路徑正確（版本號可能更新）
- 檢查 web.xml syntax（`xmllint --noout $WEB_XML`）

**瀏覽器還是 blocked by CORS policy**:
- 確認 Origin 有在 allowedOrigins 裡（逗號分隔，不是空格）
- 清瀏覽器 cache（preflight 可能被 cache 了 86400 秒）
- F12 看 Network 的 OPTIONS request/response headers

**iDempiere 啟動失敗**:
- 看 log：`tail -f $IDEMPIERE_HOME/log/*.log`
- 檢查 web.xml XML 格式是否正確
- 用備份還原：`sudo cp ${WEB_XML}.bak.* $WEB_XML`
