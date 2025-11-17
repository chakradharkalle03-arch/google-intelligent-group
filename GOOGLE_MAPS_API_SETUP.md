# Google Maps API 設定指南

## 問題：REQUEST_DENIED 錯誤

這個錯誤通常表示 Google Maps API 金鑰沒有正確設定或缺少必要的 API 權限。

## 解決步驟

### 1. 更新 .env 檔案

請手動編輯 `backend\.env` 檔案，確保包含以下內容：

```env
# Gemini API Key
GEMINI_API_KEY=AIzaSyCePb8_afE2fvq1tWCRITYGNHp-MIezk44

# Google Maps API Key (for GoogleMap Agent)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 2. 啟用必要的 Google Maps API

您的 Google Maps API 金鑰需要啟用以下 API：

1. **Places API** (必要)
   - 用於搜尋附近的地點
   - 網址：https://console.cloud.google.com/apis/library/places-backend.googleapis.com

2. **Geocoding API** (必要)
   - 用於將地址轉換為座標
   - 網址：https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

3. **Places API (New)** (建議)
   - 新版本的 Places API
   - 網址：https://console.cloud.google.com/apis/library/places-backend.googleapis.com

### 3. 檢查 API 金鑰設定

在 Google Cloud Console 中：

1. 前往：https://console.cloud.google.com/apis/credentials
2. 點擊您的 API 金鑰
3. 確認以下設定：

   **API 限制**：
   - 選擇「限制金鑰」
   - 確保已勾選：
     - Places API
     - Geocoding API
     - Places API (New) (如果使用)

   **應用程式限制**：
   - 如果只是本地測試，可以選擇「無」
   - 或設定「IP 位址」並加入 `127.0.0.1`

### 4. 確認計費已啟用

Google Maps API 需要啟用計費帳戶（即使有免費額度）：

1. 前往：https://console.cloud.google.com/billing
2. 確認已連結計費帳戶
3. 免費額度：每月 $200 的 Google Maps Platform 額度

### 5. 重新啟動後端伺服器

更新 `.env` 檔案後，需要重新啟動後端：

1. 關閉當前的後端 PowerShell 視窗
2. 重新執行：`.\run_web.ps1`
   或
   執行：`.\start_backend_only.ps1`

## 測試 API 金鑰

您可以使用以下 PowerShell 命令測試 API 金鑰：

```powershell
$apiKey = "your_google_maps_api_key_here"
$url = "https://maps.googleapis.com/maps/api/geocode/json?address=Taipei&key=$apiKey"
Invoke-WebRequest -Uri $url | Select-Object -ExpandProperty Content
```

如果成功，應該會看到 JSON 回應。如果看到 `REQUEST_DENIED`，請檢查上述設定。

## 常見錯誤

### REQUEST_DENIED
- **原因**：API 未啟用、金鑰限制過嚴、或計費未啟用
- **解決**：啟用必要的 API 並檢查金鑰限制

### OVER_QUERY_LIMIT
- **原因**：超過免費額度或配額
- **解決**：檢查使用量或升級計費帳戶

### INVALID_REQUEST
- **原因**：請求參數錯誤
- **解決**：檢查程式碼中的 API 呼叫

## 需要幫助？

如果問題持續存在，請檢查：
1. Google Cloud Console 中的 API 使用情況
2. 後端伺服器的錯誤日誌
3. 瀏覽器開發者工具中的網路請求

