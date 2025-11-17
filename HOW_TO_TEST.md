# 🧪 如何測試 API

## ✅ 您已成功連接到 API 文檔！

您現在看到的是 Swagger UI 介面，可以互動式測試 API。

---

## 🎯 測試 /query 端點

### 步驟 1：點擊 POST /query
在 API 文檔頁面上，找到 `POST /query` 端點

### 步驟 2：點擊 "Try it out"
點擊藍色的 "Try it out" 按鈕

### 步驟 3：輸入查詢
在 Request body 區域，您會看到：
```json
{
  "query": "string"
}
```

將 `"string"` 替換為您的查詢，例如：
```json
{
  "query": "What is LangChain?"
}
```

### 步驟 4：點擊 "Execute"
點擊綠色的 "Execute" 按鈕

### 步驟 5：等待結果
- 簡單查詢：10-30 秒
- Google Maps 查詢：30-60 秒
- 研究查詢：20-40 秒

---

## 📋 測試查詢範例

### 1. 研究查詢（Research Agent）
```json
{
  "query": "What is LangChain?"
}
```

### 2. GoogleMap 查詢（GoogleMap Agent）
```json
{
  "query": "Find coffee shops in Taipei"
}
```

### 3. Calendar 查詢（Calendar Agent）
```json
{
  "query": "Show today's schedule"
}
```

### 4. 預約查詢（Calendar Agent）
```json
{
  "query": "Book dinner reservation for tomorrow at 7 PM"
}
```

### 5. 組合查詢（多個 Agent）
```json
{
  "query": "Find Italian restaurant near Taipei 101 and book dinner for tomorrow at 7 PM"
}
```

---

## 📊 回應格式

成功後，您會看到類似這樣的回應：

```json
{
  "response": "完整的回應內容...",
  "agent_outputs": {
    "supervisor": "Supervisor 訊息",
    "googleMap": "GoogleMap Agent 結果",
    "calendar": "Calendar Agent 結果",
    "telephone": "Telephone Agent 結果",
    "research": "Research Agent 結果"
  },
  "message": "Query processed successfully"
}
```

---

## ⏱️ 回應時間

- **簡單查詢**：10-30 秒
- **Google Maps 查詢**：30-60 秒（需要調用 Google Maps API）
- **研究查詢**：20-40 秒（需要調用 Gemini API）
- **組合查詢**：60-90 秒（多個 Agent 協作）

**這些時間是正常的** - 系統需要調用外部 API（Google Maps、Gemini）

---

## 🔍 查看結果

### 在 API 文檔中
- 點擊 "Execute" 後，向下滾動查看回應
- 您會看到：
  - **Response body**：完整的 JSON 回應
  - **Response headers**：HTTP 標頭
  - **Curl**：命令列範例
  - **Request URL**：實際請求的 URL

### 各 Agent 的輸出
回應中的 `agent_outputs` 包含每個 Agent 的結果：
- `supervisor`：Supervisor Agent 的協調訊息
- `googleMap`：GoogleMap Agent 的搜尋結果
- `calendar`：Calendar Agent 的日程結果
- `telephone`：Telephone Agent 的呼叫狀態
- `research`：Research Agent 的研究結果

---

## ✅ 成功指標

如果看到以下內容，表示成功：
- ✅ HTTP 狀態碼：200
- ✅ `"message": "Query processed successfully"`
- ✅ `"response"` 包含完整回應
- ✅ `"agent_outputs"` 包含各 Agent 的結果

---

## 🐛 常見問題

### 查詢超時
- **正常**：API 調用需要時間
- **解決**：等待 60-90 秒

### 錯誤訊息
- 檢查查詢格式是否正確（JSON）
- 確認 `query` 欄位存在
- 查看伺服器視窗的錯誤訊息

### 沒有回應
- 確認伺服器正在運行
- 檢查伺服器視窗是否有錯誤
- 重新啟動伺服器

---

## 🎉 開始測試

現在就試試：
1. 點擊 `POST /query`
2. 點擊 "Try it out"
3. 輸入：`{"query": "What is LangChain?"}`
4. 點擊 "Execute"
5. 等待並查看結果！

---

**祝測試順利！** 🚀

