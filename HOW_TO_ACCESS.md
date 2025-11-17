# 🌐 如何正確訪問 API

## ❌ 錯誤的網址

**不要使用：** `http://0.0.0.0:8000/`

這個網址**永遠無法**在瀏覽器中打開！

---

## ✅ 正確的網址

請使用以下**任一**網址：

### 1. API 文檔（推薦 - 最簡單）
```
http://localhost:8000/docs
```
**這是互動式 API 文檔，可以直接測試查詢！**

### 2. API 首頁
```
http://localhost:8000
```

### 3. 健康檢查
```
http://localhost:8000/health
```

---

## 📝 快速步驟

### 方法 1：直接輸入網址
1. 打開瀏覽器（Chrome、Edge、Firefox 等）
2. 在地址欄輸入：`http://localhost:8000/docs`
3. 按 Enter
4. 您應該會看到 API 文檔頁面

### 方法 2：使用 HTML 文件
1. 雙擊 `OPEN_THIS.html` 文件
2. 點擊頁面上的「📚 打開 API 文檔」按鈕
3. 會自動打開正確的網址

---

## 🔍 如果還是無法連接

### 檢查伺服器是否運行
1. 查看是否有 PowerShell 窗口正在運行後端
2. 應該看到：`Uvicorn running on http://0.0.0.0:8000`
3. 如果沒有，需要啟動伺服器

### 啟動伺服器
```powershell
cd backend
venv\Scripts\activate
python main.py
```

### 等待伺服器啟動
- 等待 10-15 秒
- 看到 "Uvicorn running" 訊息後再試

---

## 💡 重要說明

- `0.0.0.0` = 伺服器綁定地址（伺服器用）
- `localhost` = 本地訪問地址（瀏覽器用）
- `127.0.0.1` = 與 localhost 相同

**伺服器綁定到 0.0.0.0，但您要用 localhost 連接！**

---

## 🧪 測試查詢

打開 API 文檔後：
1. 點擊 `POST /query`
2. 點擊 "Try it out"
3. 輸入：
   ```json
   {
     "query": "What is LangChain?"
   }
   ```
4. 點擊 "Execute"
5. 等待 30-60 秒查看結果

---

## ✅ 確認連接成功

如果看到以下任一內容，表示連接成功：
- API 文檔頁面（Swagger UI）
- `{"message": "Google Intelligent Group API", "status": "running"}`
- `{"status": "healthy"}`

---

**🎯 現在試試：http://localhost:8000/docs**

