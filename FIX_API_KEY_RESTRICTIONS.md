# 修復 Google Maps API 金鑰限制問題

## 🔴 問題診斷

錯誤訊息：`API keys with referer restrictions cannot be used with this API`

**原因**：您的 Google Maps API 金鑰設定了 HTTP referrer（網站）限制，這會阻止後端伺服器使用該 API 金鑰。

## ✅ 解決步驟

### 方法 1：移除應用程式限制（推薦用於開發測試）

1. 前往 Google Cloud Console：
   https://console.cloud.google.com/apis/credentials

2. 點擊您的 Google Maps API 金鑰（`AIzaSyDoNIZHHTT89h3lxRB7QHaw-Ra912pTtsM`）

3. 在「應用程式限制」部分：
   - 選擇「無」或「IP 位址」
   - 如果選擇「IP 位址」，可以加入 `127.0.0.1` 和 `localhost`

4. 點擊「儲存」

### 方法 2：使用 IP 位址限制（更安全）

1. 前往：https://console.cloud.google.com/apis/credentials

2. 點擊您的 API 金鑰

3. 在「應用程式限制」中選擇「IP 位址」

4. 新增以下 IP：
   - `127.0.0.1`
   - `localhost`
   - 您的本機 IP 位址（如果需要從其他裝置訪問）

5. 點擊「儲存」

### 方法 3：建立新的 API 金鑰（用於後端）

1. 前往：https://console.cloud.google.com/apis/credentials

2. 點擊「建立憑證」→「API 金鑰」

3. 設定新金鑰：
   - **名稱**：`Backend Server API Key`
   - **應用程式限制**：選擇「IP 位址」或「無」
   - **API 限制**：限制為「Places API」和「Geocoding API」

4. 複製新的 API 金鑰

5. 更新 `backend\.env` 檔案：
   ```
   GOOGLE_MAPS_API_KEY=your_new_api_key_here
   ```

## 🔧 確認 API 已啟用

確保以下 API 已啟用：

1. **Places API**
   - https://console.cloud.google.com/apis/library/places-backend.googleapis.com
   - 點擊「啟用」

2. **Geocoding API**
   - https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com
   - 點擊「啟用」

## 💰 確認計費已啟用

Google Maps API 需要啟用計費帳戶（即使有免費額度）：

1. 前往：https://console.cloud.google.com/billing
2. 確認已連結計費帳戶
3. 免費額度：每月 $200 的 Google Maps Platform 額度

## ✅ 測試修復

修復後，執行測試腳本：

```powershell
.\test_google_maps_api.ps1
```

如果看到 "✅ Geocoding API: Working!" 和 "✅ Places API: Working!"，表示問題已解決。

## 🔄 重新啟動後端

修復 API 金鑰限制後，需要重新啟動後端伺服器：

```powershell
# 關閉當前的後端視窗，然後執行：
.\run_web.ps1
```

## 📝 注意事項

- **安全性**：如果選擇「無」限制，請確保 API 金鑰不會公開在 GitHub 或其他公開位置
- **生產環境**：在生產環境中，建議使用 IP 位址限制或建立專用的後端 API 金鑰
- **配額**：注意 API 使用配額，避免超出免費額度

