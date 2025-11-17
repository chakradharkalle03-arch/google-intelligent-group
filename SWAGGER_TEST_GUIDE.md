# 🧪 Swagger UI 測試指南

## ✅ 您現在看到的頁面

這是 **Swagger UI** - FastAPI 自動生成的互動式 API 文檔。

---

## 🎯 測試 POST /query 端點

### 步驟 1：找到 POST /query
在頁面上找到 **POST /query** 端點（應該在頁面中間）

### 步驟 2：展開端點
點擊 **POST /query** 標題來展開詳細資訊

### 步驟 3：點擊 "Try it out"
找到藍色的 **"Try it out"** 按鈕並點擊

### 步驟 4：輸入查詢
在 **Request body** 區域，您會看到：
```json
{
  "query": "string"
}
```

**將 `"string"` 替換為您的查詢**，例如：
```json
{
  "query": "What is LangChain?"
}
```

### 步驟 5：點擊 "Execute"
點擊綠色的 **"Execute"** 按鈕

### 步驟 6：查看結果
向下滾動查看回應：
- **Response body**：完整的 JSON 回應
- **Response Code**：應該是 200
- **Curl**：命令列範例

---

## 📋 推薦測試查詢

### 1. 簡單研究查詢
```json
{
  "query": "What is LangChain?"
}
```
**預期時間：** 20-40 秒

### 2. GoogleMap 查詢
```json
{
  "query": "Find coffee shops in Taipei"
}
```
**預期時間：** 30-60 秒

### 3. Calendar 查詢
```json
{
  "query": "Show today's schedule"
}
```
**預期時間：** 10-20 秒

### 4. 預約查詢
```json
{
  "query": "Book dinner reservation for tomorrow at 7 PM"
}
```
**預期時間：** 10-20 秒

### 5. 組合查詢（多 Agent 協作）
```json
{
  "query": "Find Italian restaurant near Taipei 101 and book dinner for tomorrow at 7 PM"
}
```
**預期時間：** 60-90 秒

---

## 📊 回應格式說明

成功後，您會看到類似這樣的回應：

```json
{
  "response": "完整的回應內容，包含所有 Agent 的結果摘要...",
  "agent_outputs": {
    "supervisor": "Supervisor Agent 的協調訊息",
    "googleMap": "GoogleMap Agent 的搜尋結果（如果有使用）",
    "calendar": "Calendar Agent 的日程結果（如果有使用）",
    "telephone": "Telephone Agent 的狀態（如果有使用）",
    "research": "Research Agent 的研究結果（如果有使用）"
  },
  "message": "Query processed successfully"
}
```

---

## ⏱️ 回應時間說明

| 查詢類型 | 預期時間 | 原因 |
|---------|---------|------|
| 簡單查詢 | 10-30 秒 | 基本處理 |
| Google Maps | 30-60 秒 | 需要調用 Google Maps API |
| 研究查詢 | 20-40 秒 | 需要調用 Gemini API |
| 組合查詢 | 60-90 秒 | 多個 Agent 協作 + 多個 API 調用 |

**這些時間是正常的** - 系統需要調用外部 API

---

## 🔍 查看詳細結果

### 在 Swagger UI 中
1. 點擊 "Execute" 後，向下滾動
2. 查看 **Response body** 區域
3. 展開 JSON 查看詳細內容
4. 查看 **agent_outputs** 中每個 Agent 的輸出

### 各 Agent 輸出說明
- **supervisor**：Supervisor Agent 的協調和總結
- **googleMap**：GoogleMap Agent 的搜尋結果（餐廳、地點等）
- **calendar**：Calendar Agent 的日程管理結果
- **telephone**：Telephone Agent 的呼叫狀態
- **research**：Research Agent 的研究結果

---

## ✅ 成功指標

如果看到以下內容，表示成功：
- ✅ **Response Code**: 200
- ✅ **"message"**: "Query processed successfully"
- ✅ **"response"**: 包含完整的回應內容
- ✅ **"agent_outputs"**: 包含各 Agent 的結果

---

## 🐛 常見問題

### 查詢超時
- **正常現象**：API 調用需要時間
- **解決方法**：等待 60-90 秒，或增加超時時間

### 422 錯誤（Validation Error）
- **原因**：JSON 格式錯誤
- **解決方法**：檢查 JSON 格式是否正確
- **正確格式**：
  ```json
  {
    "query": "您的查詢"
  }
  ```

### 500 錯誤（Server Error）
- **原因**：伺服器內部錯誤
- **解決方法**：查看伺服器視窗的錯誤訊息

### 沒有回應
- **檢查**：伺服器是否正在運行
- **檢查**：伺服器視窗是否有錯誤訊息
- **解決**：重新啟動伺服器

---

## 💡 使用技巧

### 1. 複製查詢範例
- 可以直接複製上面的 JSON 範例
- 貼到 Request body 中
- 修改查詢內容

### 2. 查看 Curl 命令
- 點擊 "Execute" 後
- 查看 **Curl** 區域
- 可以複製命令在終端中使用

### 3. 查看 Schema
- 點擊 **Schema** 查看資料結構
- 了解請求和回應的格式

### 4. 測試其他端點
- **GET /**：查看 API 資訊
- **GET /health**：檢查伺服器健康狀態

---

## 🎉 開始測試

**現在就試試：**

1. 點擊 **POST /query**
2. 點擊 **"Try it out"**
3. 輸入：
   ```json
   {
     "query": "What is LangChain?"
   }
   ```
4. 點擊 **"Execute"**
5. 等待 30-60 秒
6. 查看結果！

---

**祝測試順利！** 🚀

